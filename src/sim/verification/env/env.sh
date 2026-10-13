#######################################
###  Environment setup for TSN ED
#######################################
# Enters an ARC shell with VCS / Quartus / Synopsys VIP / ALTUVM.
# Usage (bash):
#   cd src/sim/verification/env
#   source env.sh
#   source setup.sh

echo "Setting VERIF_ROOT"

# Use private names so callers with set -u keep their own SCRIPT_DIR.
if test -n "$BASH" ; then _TSN_ENV_NAME=$BASH_SOURCE
elif test -n "$TMOUT"; then _TSN_ENV_NAME=${.sh.file}
elif test -n "$ZSH_NAME" ; then _TSN_ENV_NAME=${(%):-%x}
elif test ${0##*/} = dash; then x=$(lsof -p $$ -Fn0 | tail -1); _TSN_ENV_NAME=${x#n}
else _TSN_ENV_NAME=$0
fi

_TSN_ENV_DIR="$(cd "$(dirname -- "$_TSN_ENV_NAME")" 2>/dev/null && pwd -P)"
export VERIF_ROOT=$(readlink -f "${_TSN_ENV_DIR}/..")
unset _TSN_ENV_NAME _TSN_ENV_DIR

echo "VERIF_ROOT          " "$VERIF_ROOT"

# shellcheck disable=SC1091
source "${VERIF_ROOT}/env/arc_resource_list.sh"

ARC_RESOURCE="${PYTHON} ${GCC} ${CMAKE} ${VCS} ${QUARTUS_VER} ${SYNOPSYS_VIP} ${SYNOPSYS_VIP_LIC} ${ALTUVM}"

echo "arc shell ${ARC_RESOURCE}"
arc shell ${ARC_RESOURCE}
