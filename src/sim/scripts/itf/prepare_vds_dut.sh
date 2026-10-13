#!/usr/bin/env bash
# Stage a5e065bb32aes1_mdk_1x1G and generate VDS sim artifacts for the ITF flow.
# Reuses verification/scripts/generate_dut.sh; never writes into checked-in HW.
#
# Usage (from ITF qsys run directory):
#   prepare_vds_dut.sh [work_dir]
# Default work_dir: ./itf_vds_work
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TSN_HOME="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERIF_ROOT="${VERIF_ROOT:-${TSN_HOME}/verification}"
HW_ROOT="${HW_ROOT:-${TSN_HOME}/../hw/a5e065bb32aes1_mdk_1x1G}"

WORK_ARG="${1:-./itf_vds_work}"
mkdir -p "${WORK_ARG}"
WORK_DIR="$(cd "${WORK_ARG}" && pwd)"
DUT_SRC="${WORK_DIR}/dut_src"
DUT_SIM="${WORK_DIR}/dut_sim"
LOG_DIR="${WORK_DIR}/logs"
mkdir -p "${LOG_DIR}"

fail() { echo "ERROR: [itf-vds] $*" >&2; exit 1; }
log()  { echo "[itf-vds] $*"; }

[[ -d "${VERIF_ROOT}" ]] || fail "VERIF_ROOT missing: ${VERIF_ROOT}"
[[ -f "${VERIF_ROOT}/scripts/generate_dut.sh" ]] || fail "Missing ${VERIF_ROOT}/scripts/generate_dut.sh"
[[ -d "${HW_ROOT}" ]] || fail "HW_ROOT missing: ${HW_ROOT}"
[[ -f "${HW_ROOT}/top.qpf" ]] || fail "Missing ${HW_ROOT}/top.qpf (expected VDS project)"
[[ -f "${HW_ROOT}/top.qsf" ]] || fail "Missing ${HW_ROOT}/top.qsf"

if grep -Eq '^[[:space:]]*set_global_assignment[[:space:]]+-name[[:space:]]+QSYS_FILE' "${HW_ROOT}/top.qsf"; then
  fail "Active QSYS_FILE in ${HW_ROOT}/top.qsf — ITF VDS flow requires VDS_FILE only"
fi

# Export before sourcing env.sh so defaults do not clobber the ITF work tree
export TSN_HOME VERIF_ROOT HW_ROOT WORK_DIR DUT_SRC DUT_SIM LOG_DIR

log "TSN_HOME=${TSN_HOME}"
log "HW_ROOT=${HW_ROOT}"
log "WORK_DIR=${WORK_DIR}"
log "Running verification generate_dut.sh (VDS → ip-make-simscript)"

# shellcheck disable=SC1091
source "${VERIF_ROOT}/env.sh"
export WORK_DIR DUT_SRC DUT_SIM LOG_DIR HW_ROOT TSN_HOME VERIF_ROOT

bash "${VERIF_ROOT}/scripts/generate_dut.sh" 2>&1 | tee "${LOG_DIR}/itf_prepare_vds.log"

[[ -f "${WORK_DIR}/vcsmx_paths.env" ]] || fail "generate_dut.sh did not write ${WORK_DIR}/vcsmx_paths.env"
# shellcheck disable=SC1091
source "${WORK_DIR}/vcsmx_paths.env"
[[ -n "${VCSMX_SETUP:-}" && -f "${VCSMX_SETUP}" ]] || fail "VCSMX_SETUP missing after generate"
[[ -n "${VCSMX_DIR:-}" && -d "${VCSMX_DIR}" ]] || fail "VCSMX_DIR missing after generate"
[[ -d "${DUT_SRC}/gen/vds/qsys_top" ]] || fail "Missing staged gen/vds/qsys_top"
[[ -d "${DUT_SRC}/gen/vds/hps_subsys" ]] || fail "Missing staged gen/vds/hps_subsys"
[[ -d "${DUT_SRC}/gen/vds/tsn_subsys" ]] || fail "Missing staged gen/vds/tsn_subsys"

PATHS_OUT="$(pwd)/itf_vds_paths.env"
{
  echo "ITF_VDS_WORK=${WORK_DIR}"
  echo "DUT_SRC=${DUT_SRC}"
  echo "DUT_SIM=${DUT_SIM}"
  echo "VCSMX_SETUP=${VCSMX_SETUP}"
  echo "VCSMX_DIR=${VCSMX_DIR}"
  echo "HW_ROOT=${HW_ROOT}"
  echo "VERIF_ROOT=${VERIF_ROOT}"
  echo "TSN_HOME=${TSN_HOME}"
} >"${PATHS_OUT}"

# Stable relative name for ITF child subtests
if [[ "$(pwd)/itf_vds_work" != "${WORK_DIR}" ]]; then
  rm -rf "$(pwd)/itf_vds_work"
  ln -sfn "${WORK_DIR}" "$(pwd)/itf_vds_work"
fi

log "VDS DUT ready"
log "  PATHS=${PATHS_OUT}"
log "  VCSMX_DIR=${VCSMX_DIR}"
log "  VCSMX_SETUP=${VCSMX_SETUP}"
