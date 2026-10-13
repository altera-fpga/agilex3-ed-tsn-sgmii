#!/usr/bin/env bash
# Compile VDS-generated IP via vcsmx_setup.sh, then inject supplemental DUT/TB once, elaborate top_tb.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[compile] $*"; }

[[ -f "${WORK_DIR}/vcsmx_paths.env" ]] || fail "Missing ${WORK_DIR}/vcsmx_paths.env — run make generate first"
# shellcheck disable=SC1091
source "${WORK_DIR}/vcsmx_paths.env"
[[ -n "${VCSMX_SETUP:-}" && -f "${VCSMX_SETUP}" ]] || fail "VCSMX_SETUP invalid"
[[ -n "${VCSMX_DIR:-}" && -d "${VCSMX_DIR}" ]] || fail "VCSMX_DIR invalid"
export VCSMX_SETUP VCSMX_DIR VERIF_ROOT WORK_DIR XPROP DUMP

# Ensure every hps_subsys.v (especially sim/, which vcsmx compiles) has the
# hollow custom_hps body so the AXI VIP can drive lwhps2fpga without contention.
CUSTOM_HPS="${TSN_HOME}/scripts/itf/custom_hps/custom_hps.v"
[[ -f "${CUSTOM_HPS}" ]] || fail "Missing custom_hps source: ${CUSTOM_HPS}"
mapfile -t HPS_COPIES < <(find "${DUT_SRC}/gen/vds/hps_subsys" "${DUT_SIM}" \
  -type f -name 'hps_subsys.v' 2>/dev/null | sort -u)
[[ "${#HPS_COPIES[@]}" -gt 0 ]] || fail "Missing hps_subsys.v under dut_src/dut_sim"
for HPS_GEN in "${HPS_COPIES[@]}"; do
  log "Ensuring custom_hps body in ${HPS_GEN}"
  python3 "${SCRIPT_DIR}/apply_custom_hps.py" "${CUSTOM_HPS}" "${HPS_GEN}"
done
HPS_SIM_V="$(find "${DUT_SRC}/gen/vds/hps_subsys/sim" -type f -name 'hps_subsys.v' | head -n 1 || true)"
[[ -n "${HPS_SIM_V}" ]] || fail "Missing ${DUT_SRC}/gen/vds/hps_subsys/sim/hps_subsys.v"
grep -q 'Custom HPS is here' "${HPS_SIM_V}" \
  || fail "custom_hps not applied to ${HPS_SIM_V}"
if grep -q 'agilex_hps ' "${HPS_SIM_V}"; then
  fail "${HPS_SIM_V} still contains agilex_hps — AXI CSR path will hang"
fi

mkdir -p "${LOG_DIR}"
COMPILE_LOG="${LOG_DIR}/compile.log"
FP_JSON="${WORK_DIR}/compile_fingerprint.json"

ELAB_OPTS="-ntb_opts uvm -full64 -override_timescale=1ps/1fs +lint=TFIPC-L +lint=PCWM"
if [[ "${DUMP}" == "1" ]]; then
  ELAB_OPTS+=" -debug_access+nomemcbk+dmptf -debug_region+cell -debug_pp +vcs+vcdpluson +memcbk +vcdplusmemon"
fi
if [[ "${XPROP}" == "1" ]]; then
  XPROP_CFG="${VERIF_ROOT}/config/xprop_1phy.cfg"
  [[ -f "${XPROP_CFG}" ]] || fail "XPROP=1 requires ${XPROP_CFG}"
  ELAB_OPTS+=" -xprop=${XPROP_CFG} +define+XPROP"
fi

# Supplemental compile matches ITF: pre-compile UVM, then DUT/TB filelists.
# (Single vlogan with -ntb_opts uvm + VIP flists fails: uvm_pkg not visible to SVT.)
SUPP_VLOGAN="vlogan +define+UVM_PACKER_MAX_BYTES=1500000 -ntb_opts uvm -sverilog"
SUPP_VLOGAN+="; vlogan +define+UVM_PACKER_MAX_BYTES=1500000 +v2k -sverilog +verilog2001ext+.v -full64"
SUPP_VLOGAN+=" -f ${VERIF_ROOT}/flist/tb.f"
SUPP_VLOGAN+=" -l ${LOG_DIR}/vlogan_tb.log"
SUPP_VLOGAN+=" || exit 1"

# Always rebuild working setup from the generated original (re-inject fresh).
WORK_SETUP="${VCSMX_DIR}/vcsmx_setup.verification.sh"
cp -a "${VCSMX_SETUP}" "${WORK_SETUP}"

MARKER="# VERIFICATION_TB_INJECT"
if grep -q 'elaborate top level design' "${WORK_SETUP}"; then
  awk -v inj="${MARKER}\n${SUPP_VLOGAN}\n" '
    /elaborate top level design/ && !done {
      print inj
      done=1
    }
    { print }
  ' "${WORK_SETUP}" >"${WORK_SETUP}.tmp"
  mv "${WORK_SETUP}.tmp" "${WORK_SETUP}"
else
  awk -v inj="${MARKER}\n${SUPP_VLOGAN}\n" '
    { lines[NR]=$0 }
    END {
      inject_at=NR
      for (i=NR; i>=1; i--) {
        if (lines[i] ~ /^[[:space:]]*vcs[[:space:]]/) { inject_at=i; break }
      }
      for (i=1; i<=NR; i++) {
        if (i==inject_at) print inj
        print lines[i]
      }
    }
  ' "${WORK_SETUP}" >"${WORK_SETUP}.tmp"
  mv "${WORK_SETUP}.tmp" "${WORK_SETUP}"
fi

chmod u+x "${WORK_SETUP}"

log "Running setup in ${VCSMX_DIR}"
log "USER_DEFINED_ELAB_OPTIONS=${ELAB_OPTS}"
log "TOP_LEVEL_NAME=-top top_tb"

(
  cd "${VCSMX_DIR}"
  # Export vars used inside filelists
  export VERIF_ROOT TSN_HOME TB_PATH DUT_SRC DUT_SIM ALT_EM10G32_ROOT ALT_MGE_PHY_ROOT
  export ALTUVM_COMMON_HOME ALTUVM_BCL_HOME ALTUVM_AVALON_ST_HOME ALTUVM_AVALON_MM_HOME
  export REG_LOCAL_ROOT_DIR_PATH UVM_HOME SYNOPSYS_VIP_ETHERNET SYNOPSYS_VIP_AMBA DESIGNWARE_HOME
  export ACDS_DEST_ROOT

  # vcsmx_setup.sh does: for expression in "$@"; do eval $expression
  # Values with spaces must use Intel nested-quote form so eval re-parses correctly:
  #   VAR="'-opt a -opt b'"  -> argument VAR='-opt a -opt b'
  sh "./$(basename "${WORK_SETUP}")" \
    "USER_DEFINED_ELAB_OPTIONS='${ELAB_OPTS}'" \
    "TOP_LEVEL_NAME='-top top_tb'" \
    SKIP_SIM=1
) 2>&1 | tee "${COMPILE_LOG}"

[[ -x "${VCSMX_DIR}/simv" ]] || fail "simv not produced in ${VCSMX_DIR}"

# cwd-safe wrapper (never bare symlink)
WRAPPER="${WORK_DIR}/simv"
cat >"${WRAPPER}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "${VCSMX_DIR}"
exec ./simv "\$@"
EOF
chmod u+x "${WRAPPER}"
log "Wrote cwd-safe wrapper ${WRAPPER}"

# Fingerprint
python3 - <<PY
import hashlib, json, os, pathlib, subprocess, time
root = pathlib.Path(os.environ["VERIF_ROOT"])
work = pathlib.Path(os.environ["WORK_DIR"])
files = [
    root/"flist/defines.f",
    root/"flist/dut.f",
    root/"flist/tb.f",
    root/"flist/num_phy_assert.sv",
    work/"vcsmx_paths.env",
]
def h(p):
    p = pathlib.Path(p)
    if not p.exists():
        return None
    return hashlib.sha256(p.read_bytes()).hexdigest()
fp = {
    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S"),
    "xprop": os.environ.get("XPROP","0"),
    "dump": os.environ.get("DUMP","0"),
    "vcsmx_setup": os.environ.get("VCSMX_SETUP"),
    "vcsmx_dir": os.environ.get("VCSMX_DIR"),
    "files": {str(p): h(p) for p in files},
    "elab_opts": """${ELAB_OPTS}""",
}
(work/"compile_fingerprint.json").write_text(json.dumps(fp, indent=2) + "\n")
print("Wrote", work/"compile_fingerprint.json")
PY

log "Compile complete"
