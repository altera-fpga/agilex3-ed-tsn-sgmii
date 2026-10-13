# Post-ARC path setup for TSN standalone Makefile / UVM flow.
# Source this inside the ARC shell started by env/env.sh:
#   source setup.sh
# Also sourced by verification/scripts/*.sh for project path defaults.
# Intentionally does not enable set -e (safe to source into an interactive shell).

# Use private names so callers with set -u keep their own SCRIPT_DIR.
if test -n "$BASH" ; then _TSN_SETUP_NAME=$BASH_SOURCE
elif test -n "$TMOUT"; then _TSN_SETUP_NAME=${.sh.file}
elif test -n "$ZSH_NAME" ; then _TSN_SETUP_NAME=${(%):-%x}
elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); _TSN_SETUP_NAME=${x#n}
else _TSN_SETUP_NAME=$0
fi

_TSN_SETUP_DIR="$(cd "$(dirname -- "$_TSN_SETUP_NAME")" 2>/dev/null && pwd -P)"
export VERIF_ROOT=$(readlink -f "${_TSN_SETUP_DIR}/..")
unset _TSN_SETUP_NAME _TSN_SETUP_DIR

export WORKDIR="${VERIF_ROOT}"
export TSN_HOME=$(readlink -f "${VERIF_ROOT}/..")
export REG_LOCAL_ROOT_DIR_PATH="${REG_LOCAL_ROOT_DIR_PATH:-${TSN_HOME}}"
export HW_ROOT="${HW_ROOT:-$(readlink -f "${TSN_HOME}/../hw/a5e065bb32aes1_mdk_1x1G")}"
export TSN_ROOTDIR="${HW_ROOT}"
export TB_PATH="${TB_PATH:-${TSN_HOME}/testbench}"
export DUT_SRC="${DUT_SRC:-${VERIF_ROOT}/work/dut_src}"
export DUT_SIM="${DUT_SIM:-${VERIF_ROOT}/work/dut_sim}"
export WORK_DIR="${WORK_DIR:-${VERIF_ROOT}/work}"
export LOG_DIR="${LOG_DIR:-${WORK_DIR}/logs}"

export ALT_EM10G32_ROOT="${ALT_EM10G32_ROOT:-${TSN_HOME}/design/dv_use/alt_em10g32_0}"
export ALT_MGE_PHY_ROOT="${ALT_MGE_PHY_ROOT:-${TSN_HOME}/design/dv_use/alt_mge_phy_0}"

# Defaults match scripts/itf/SetEnv.pm; override if your site uses different installs.
export ALTUVM_COMMON_HOME="${ALTUVM_COMMON_HOME:-/p/psg/flows/common/altuvm/0.9p6/product/common}"
export ALTUVM_BCL_HOME="${ALTUVM_BCL_HOME:-/p/psg/flows/common/altuvm/0.9p6/product/bcl}"
export ALTUVM_AVALON_ST_HOME="${ALTUVM_AVALON_ST_HOME:-/p/psg/flows/common/altuvm/0.9p6/product/altuvm_avalon_st}"
export ALTUVM_AVALON_MM_HOME="${ALTUVM_AVALON_MM_HOME:-/p/psg/flows/common/altuvm/0.9p6/product/altuvm_avalon_mm}"
export ALTUVM_CRU_HOME="${ALTUVM_CRU_HOME:-/p/psg/flows/common/altuvm/0.9p6/product/altuvm_cru}"

# Required from the user / ARC environment (not hardcoded):
#   QUARTUS_ROOTDIR, ACDS_DEST_ROOT, UVM_HOME,
#   SYNOPSYS_VIP_ETHERNET, SYNOPSYS_VIP_AMBA, DESIGNWARE_HOME

export QUARTUS_HOME="${QUARTUS_ROOTDIR:-}"
export QUARTUS_INSTALL_DIR="${QUARTUS_ROOTDIR:-}"
export QUARTUS_ROOTDIR_OVERRIDE="${QUARTUS_ROOTDIR:-}"
if [[ -n "${QUARTUS_ROOTDIR:-}" ]]; then
  export IMPORT_IP_ROOTDIR="${QUARTUS_ROOTDIR}/../ip"
  export ACDS_DEST_ROOT="${ACDS_DEST_ROOT:-${QUARTUS_ROOTDIR}/..}"
fi

# Prefer ARC-provided VIP roots; fall back to common site install.
if [[ -z "${DESIGNWARE_HOME:-}" ]]; then
  export DESIGNWARE_HOME=/p/psg/EIP/synopsys/vip_common/vip_R-2021.03B
fi

export https_proxy="${https_proxy:-http://proxy-dmz.altera.com:912}"
export http_proxy="${http_proxy:-http://proxy-dmz.altera.com:912}"

export SIM_TIMEOUT="${SIM_TIMEOUT:-6h}"
export NUM_SEEDS="${NUM_SEEDS:-20}"
export XPROP="${XPROP:-0}"
export DUMP="${DUMP:-0}"
export VERBOSITY="${VERBOSITY:-UVM_MEDIUM}"
export ERROR_COUNT="${ERROR_COUNT:-200}"
# Cap frames for day-1 regress speed; sequences default to 40–300 without this.
export NUM_OF_FRAMES="${NUM_OF_FRAMES:-10}"
export TEST="${TEST:-eth_gdr_base_test}"
export SEQ="${SEQ:-tsn_sanity_sequence}"
export REGR_LIST="${REGR_LIST:-${TSN_HOME}/scripts/itf/regression_list.txt}"
export STRICT_UNSUPPORTED="${STRICT_UNSUPPORTED:-0}"

mkdir -p "${LOG_DIR}"

echo "[env] VERIF_ROOT=${VERIF_ROOT}"
echo "[env] TSN_HOME=${TSN_HOME}"
echo "[env] HW_ROOT=${HW_ROOT}"
echo "[env] DUT_SRC=${DUT_SRC}"
echo "[env] DUT_SIM=${DUT_SIM}"
echo "VCS                 " "${VCS_HOME:-}"
echo "QUARTUS_HOME        " "${QUARTUS_HOME:-}"
echo "IMPORT_IP_ROOTDIR   " "${IMPORT_IP_ROOTDIR:-}"
echo "DESIGNWARE_HOME     " "${DESIGNWARE_HOME:-}"
echo "SYNOPSYS_VIP_ETHERNET ${SYNOPSYS_VIP_ETHERNET:-}"
echo "SYNOPSYS_VIP_AMBA   " "${SYNOPSYS_VIP_AMBA:-}"
echo "UVM_HOME            " "${UVM_HOME:-}"
echo "[env] Sourced. Run: make env | make generate | make compile | make sim"
