#!/usr/bin/env bash
# Run one UVM test with timeout, pipefail, and final UVM Report Summary parsing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[sim] $*"; }

TEST_NAME="${TEST:-eth_gdr_base_test}"
SEQ_NAME="${SEQ:-tsn_sanity_sequence}"
SEED_VAL="${SEED:-1}"
VERB="${VERBOSITY:-UVM_MEDIUM}"
ERR_CNT="${ERROR_COUNT:-200}"
NFRAMES="${NUM_OF_FRAMES:-10}"
PLUS="${PLUSARGS:-}"

WRAPPER="${WORK_DIR}/simv"
[[ -x "${WRAPPER}" ]] || fail "Missing ${WRAPPER} — run make compile first"
[[ -f "${WORK_DIR}/compile_fingerprint.json" ]] || fail "Missing compile fingerprint"

# Fingerprint gate: XPROP/DUMP must match compile
python3 - <<'PY'
import json, os, sys
fp = json.loads(open(os.environ["WORK_DIR"]+"/compile_fingerprint.json").read())
for k_env, k_fp in (("XPROP","xprop"), ("DUMP","dump")):
    if str(os.environ.get(k_env,"0")) != str(fp.get(k_fp,"0")):
        print(f"ERROR: {k_env}={os.environ.get(k_env)} does not match compile fingerprint {k_fp}={fp.get(k_fp)}; rebuild with make compile", file=sys.stderr)
        sys.exit(1)
print("fingerprint_ok")
PY

mkdir -p "${LOG_DIR}"
RUN_TAG="${TEST_NAME}__${SEQ_NAME}__s${SEED_VAL}"
SIM_LOG="${LOG_DIR}/${RUN_TAG}.sim.log"
META_LOG="${LOG_DIR}/${RUN_TAG}.meta.txt"

PLUS_EXPANDED=""
if [[ -n "${PLUS}" ]]; then
  # comma-separated -> +arg +arg
  IFS=',' read -r -a _pa <<<"${PLUS}"
  for a in "${_pa[@]}"; do
    [[ -z "${a}" ]] && continue
    if [[ "${a}" == +* ]]; then PLUS_EXPANDED+=" ${a}"; else PLUS_EXPANDED+=" +${a}"; fi
  done
fi

SIM_ARGS=(
  +UVM_TESTNAME="${TEST_NAME}"
  +m_sequence="${SEQ_NAME}"
  +ntb_random_seed="${SEED_VAL}"
  +UVM_VERBOSITY="${VERB}"
  +UVM_MAX_QUIT_COUNT="${ERR_CNT}"
  +UVM_LOG_RECORD
  +UVM_TR_RECORD
  +disable_pause=0
  +disable_ptp=1
  +trans_count=10
  +num_of_frames="${NFRAMES}"
  +ETH_INTERFACE_SELECT=136
  +ETH_FIRST_CASE=1
  +ETH_LAST_CASE=1
  +ETH_BASIC_TEST
  -l "${SIM_LOG}.vcs"
)

# shellcheck disable=SC2206
EXTRA=( ${PLUS_EXPANDED} )

CMD=("${WRAPPER}" "${SIM_ARGS[@]}" "${EXTRA[@]}")

{
  echo "timestamp=$(date -Is)"
  echo "test=${TEST_NAME}"
  echo "sequence=${SEQ_NAME}"
  echo "seed=${SEED_VAL}"
  echo "verbosity=${VERB}"
  echo "error_count=${ERR_CNT}"
  echo "sim_timeout=${SIM_TIMEOUT}"
  echo "cmd=${CMD[*]}"
  if git -C "${TSN_HOME}/../.." rev-parse HEAD >/dev/null 2>&1; then
    echo "source_rev=$(git -C "${TSN_HOME}/../.." rev-parse HEAD)"
    echo "source_dirty=$([[ -n "$(git -C "${TSN_HOME}/../.." status --porcelain)" ]] && echo dirty || echo clean)"
  fi
  echo "compile_fingerprint=${WORK_DIR}/compile_fingerprint.json"
} | tee "${META_LOG}"

log "Running: ${CMD[*]}"
set +e
set -o pipefail
timeout "${SIM_TIMEOUT}" "${CMD[@]}" 2>&1 | tee "${SIM_LOG}"
rc=${PIPESTATUS[0]}
set +o pipefail
set -e

if [[ "${rc}" -eq 124 ]]; then
  echo "RESULT=TIMEOUT" | tee -a "${META_LOG}"
  fail "Simulation timed out after ${SIM_TIMEOUT} (log ${SIM_LOG})"
fi
if [[ "${rc}" -ne 0 ]]; then
  echo "RESULT=FAIL sim_exit=${rc}" | tee -a "${META_LOG}"
  fail "Simulator exit code ${rc} (log ${SIM_LOG})"
fi

# Prefer authoritative -l log if present
PARSE_LOG="${SIM_LOG}.vcs"
[[ -f "${PARSE_LOG}" ]] || PARSE_LOG="${SIM_LOG}"

python3 - "${PARSE_LOG}" <<'PY'
import re, sys
path = sys.argv[1]
text = open(path, errors="replace").read().splitlines()
# Find last complete UVM Report Summary block
start = None
for i, line in enumerate(text):
    if re.search(r"---\s*UVM Report Summary\s*---", line) or re.search(r"UVM Report Summary", line):
        start = i
if start is None:
    print("ERROR: no UVM Report Summary found in", path, file=sys.stderr)
    sys.exit(2)
block = text[start:]
# Look for UVM_ERROR / UVM_FATAL counts in the summary region (next ~80 lines)
region = "\n".join(block[:120])
def count_for(kind):
    # tolerate variable whitespace: UVM_ERROR :    0
    m = re.findall(rf"{kind}\s*:\s*(\d+)", region)
    if not m:
        return None
    return int(m[-1])
fatal = count_for("UVM_FATAL")
error = count_for("UVM_ERROR")
if fatal is None or error is None:
    print("ERROR: truncated/incomplete UVM Report Summary (missing FATAL/ERROR counts)", file=sys.stderr)
    sys.exit(2)
print(f"UVM_FATAL={fatal}")
print(f"UVM_ERROR={error}")
if fatal != 0 or error != 0:
    print("ERROR: non-zero UVM_FATAL/UVM_ERROR in final summary", file=sys.stderr)
    sys.exit(1)
print("uvm_summary_ok")
PY

echo "RESULT=PASS" | tee -a "${META_LOG}"
log "PASS ${RUN_TAG}"
log "Log: ${SIM_LOG}"
