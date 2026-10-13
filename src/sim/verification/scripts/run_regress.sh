#!/usr/bin/env bash
# Parse canonical ITF regression_list.txt and run seeds. No eval / shell re-tokenization.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[regress] $*"; }

LIST="${REGR_LIST:-${TSN_HOME}/scripts/itf/regression_list.txt}"
[[ -f "${LIST}" ]] || fail "Regression list not found: ${LIST}"

NUM_SEEDS="${NUM_SEEDS:-20}"
FIXED_SEED="${FIXED_SEED:-}"
STRICT_UNSUPPORTED="${STRICT_UNSUPPORTED:-0}"

mkdir -p "${LOG_DIR}"
SUMMARY="${LOG_DIR}/regress_summary.txt"
: >"${SUMMARY}"
echo "test sequence seed result reason log" >>"${SUMMARY}"

# Allowlists
RUNTIME_KEYS="sequence seed num_seeds fixed_seed uvm_verbosity verbosity error_count plusargs"
COMPILE_KEYS="perf_en cov_en cov xprop dump_on fsdb_on fsdb_en makefile_cfgs config_name config_options"

is_runtime() { [[ " ${RUNTIME_KEYS} " == *" $1 "* ]]; }
is_compile() { [[ " ${COMPILE_KEYS} " == *" $1 "* ]]; }

executed=0
fails=0
unsup=0
passes=0

lineno=0
while IFS= read -r raw || [[ -n "${raw}" ]]; do
  lineno=$((lineno + 1))
  # trim
  line="${raw#"${raw%%[![:space:]]*}"}"
  [[ -z "${line}" ]] && continue
  [[ "${line:0:1}" == "#" ]] && continue

  # Grammar: testname=NAME [--key=value ...]
  if [[ ! "${line}" =~ ^testname=([A-Za-z0-9_]+)([[:space:]].*)?$ ]]; then
    fail "Line ${lineno}: malformed (expected testname=NAME ...): ${line}"
  fi
  tname="${BASH_REMATCH[1]}"
  rest="${BASH_REMATCH[2]:-}"

  declare -A opts=()
  # tokenize on whitespace only; no quoting support
  # shellcheck disable=SC2206
  tokens=( ${rest} )
  for tok in "${tokens[@]:-}"; do
    [[ -z "${tok}" ]] && continue
    if [[ ! "${tok}" =~ ^--([A-Za-z0-9_]+)=(.+)$ ]]; then
      fail "Line ${lineno}: bad token '${tok}' (expected --key=value)"
    fi
    key="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    if [[ -n "${opts[$key]+x}" ]]; then
      fail "Line ${lineno}: duplicate key --${key}"
    fi
    # unsafe chars
    if [[ "${val}" =~ [\;\|\&\$\`\<\>\(\)\{\}] ]]; then
      fail "Line ${lineno}: unsafe characters in --${key}=${val}"
    fi
    if ! is_runtime "${key}" && ! is_compile "${key}"; then
      fail "Line ${lineno}: unknown key --${key}"
    fi
    opts["${key}"]="${val}"
  done

  seq_name="${opts[sequence]:-}"
  [[ -n "${seq_name}" ]] || fail "Line ${lineno}: missing --sequence="

  # Compile-changing options → UNSUPPORTED unless matching fingerprint defaults (day-1: none supported)
  reason=""
  for ck in ${COMPILE_KEYS}; do
    if [[ -n "${opts[$ck]+x}" ]]; then
      # Allow xprop/dump only if they match env used at compile
      if [[ "${ck}" == "xprop" && "${opts[$ck]}" == "${XPROP}" ]]; then
        continue
      fi
      if [[ "${ck}" == "dump_on" && "${opts[$ck]}" == "${DUMP}" ]]; then
        continue
      fi
      reason="compile-changing option --${ck}=${opts[$ck]} unsupported on shared simv (day-1)"
      break
    fi
  done

  if [[ -n "${reason}" ]]; then
    echo "${tname} ${seq_name} - UNSUPPORTED ${reason} -" | tee -a "${SUMMARY}"
    unsup=$((unsup + 1))
    unset opts
    continue
  fi

  # Seeds
  local_num="${opts[num_seeds]:-${NUM_SEEDS}}"
  local_fixed="${opts[fixed_seed]:-${FIXED_SEED}}"
  row_seed="${opts[seed]:-}"

  seeds=()
  if [[ -n "${row_seed}" ]]; then
    seeds=("${row_seed}")
  elif [[ "${local_fixed}" == "1" ]]; then
    seeds=("1")
  else
    # deterministic seeds 1..N
    for ((i=1; i<=local_num; i++)); do seeds+=("$i"); done
  fi

  verb="${opts[uvm_verbosity]:-${opts[verbosity]:-${VERBOSITY}}}"
  errc="${opts[error_count]:-${ERROR_COUNT}}"
  plus="${opts[plusargs]:-}"

  entry_fail=0
  for s in "${seeds[@]}"; do
    executed=$((executed + 1))
    set +e
    TEST="${tname}" SEQ="${seq_name}" SEED="${s}" VERBOSITY="${verb}" ERROR_COUNT="${errc}" PLUSARGS="${plus}" \
      "${SCRIPT_DIR}/run_sim.sh"
    rc=$?
    set -e
    slog="${LOG_DIR}/${tname}__${seq_name}__s${s}.sim.log"
    if [[ "${rc}" -eq 0 ]]; then
      echo "${tname} ${seq_name} ${s} PASS - ${slog}" | tee -a "${SUMMARY}"
      passes=$((passes + 1))
    else
      echo "${tname} ${seq_name} ${s} FAIL sim_rc=${rc} ${slog}" | tee -a "${SUMMARY}"
      fails=$((fails + 1))
      entry_fail=1
    fi
  done
  unset opts
done <"${LIST}"

{
  echo ""
  echo "TOTAL_EXECUTED=${executed}"
  echo "PASS=${passes}"
  echo "FAIL=${fails}"
  echo "UNSUPPORTED=${unsup}"
} | tee -a "${SUMMARY}"

log "Summary: ${SUMMARY}"

if [[ "${executed}" -eq 0 ]]; then
  fail "Zero tests executed (all UNSUPPORTED or empty list)"
fi
if [[ "${fails}" -gt 0 ]]; then
  fail "${fails} failing seed(s)"
fi
if [[ "${STRICT_UNSUPPORTED}" == "1" && "${unsup}" -gt 0 ]]; then
  fail "${unsup} UNSUPPORTED entries with STRICT_UNSUPPORTED=1"
fi

log "Regress PASSED (${passes} seeds, ${unsup} unsupported)"
