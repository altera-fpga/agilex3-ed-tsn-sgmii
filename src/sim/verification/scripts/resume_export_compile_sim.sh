#!/usr/bin/env bash
# Resume after VDS/EMIF SPD generation: export VCS scripts, transform, compile, sim.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[resume] $*"; }

[[ -f "${DUT_SRC}/gen/vds/qsys_top/qsys_top.spd" ]] \
  || fail "Missing ${DUT_SRC}/gen/vds/qsys_top/qsys_top.spd — run make generate first"

mkdir -p "${LOG_DIR}"

# Exclude misplaced src/ip/emif_io96b_hps.spd (creates broken "ip" namespace).
BAD_EMIF_SPD="${DUT_SRC}/src/ip/emif_io96b_hps.spd"
if [[ -f "${BAD_EMIF_SPD}" ]]; then
  log "Removing misplaced EMIF SPD ${BAD_EMIF_SPD}"
  rm -f "${BAD_EMIF_SPD}"
fi

mapfile -t SPD_LIST < <(
  {
    find "${DUT_SRC}/gen/vds" -type f -name '*.spd'
    find "${DUT_SRC}/src/ip" -type f -name '*.spd'
  } | grep -v '/src/ip/emif_io96b_hps\.spd$' | sort -u
)
log "SPD count=${#SPD_LIST[@]}"
[[ "${#SPD_LIST[@]}" -gt 0 ]] || fail "No SPDs found"
printf '%s\n' "${SPD_LIST[@]}" | tee "${LOG_DIR}/spd_list.txt" >/dev/null

for must in qsys_top.spd hps_subsys.spd tsn_subsys.spd; do
  printf '%s\n' "${SPD_LIST[@]}" | grep -q "/${must}$" || fail "Missing ${must}"
done
printf '%s\n' "${SPD_LIST[@]}" | grep -q '/emif_io96b_hps/emif_io96b_hps\.spd$' \
  || fail "Missing correctly-rooted EMIF SPD under src/ip/emif_io96b_hps/"

SPD_CSV="$(IFS=','; echo "${SPD_LIST[*]}")"
rm -rf "${DUT_SIM}"
mkdir -p "${DUT_SIM}"

ip-make-simscript \
  --output-directory="${DUT_SIM}" \
  --spd="${SPD_CSV}" \
  --use-relative-paths \
  --simulator=VCSMX \
  --device=A3CW135BM16AE6S \
  --device-family="Agilex 3" \
  --top-name=agilex5_top \
  2>&1 | tee "${LOG_DIR}/ip-make-simscript.log"

TOP_SETUP="${DUT_SIM}/synopsys/vcsmx/vcsmx_setup.sh"
[[ -f "${TOP_SETUP}" ]] || fail "Missing ${TOP_SETUP}"

COMMON_TCL="${DUT_SIM}/common/vcsmx_files.tcl"
[[ -f "${COMMON_TCL}" ]] || fail "Missing ${COMMON_TCL}"
if grep -q 'src/ip//sim/common/vcsmx_files.tcl\|src/ip/sim/common/vcsmx_files.tcl' "${COMMON_TCL}"; then
  fail "Exported ${COMMON_TCL} still sources broken src/ip/sim namespace (misplaced EMIF SPD)"
fi
# Child IP packages must be present (top-level-only SPD export omits these).
for must_lib in clk_100 agilex_hps intel_mge_phy_0; do
  grep -q "dict set libraries ${must_lib}" "${COMMON_TCL}" \
    || fail "Exported ${COMMON_TCL} missing library ${must_lib} — nested SPDs required"
done

{
  echo "VCSMX_SETUP=${TOP_SETUP}"
  echo "VCSMX_DIR=$(cd "$(dirname "${TOP_SETUP}")" && pwd)"
} | tee "${WORK_DIR}/vcsmx_paths.env"

CUSTOM_HPS="${TSN_HOME}/scripts/itf/custom_hps/custom_hps.v"
[[ -f "${CUSTOM_HPS}" ]] || fail "Missing custom_hps source: ${CUSTOM_HPS}"
mapfile -t HPS_COPIES < <(find "${DUT_SRC}/gen/vds/hps_subsys" "${DUT_SIM}" \
  -type f -name 'hps_subsys.v' 2>/dev/null | sort -u)
[[ "${#HPS_COPIES[@]}" -gt 0 ]] || fail "Missing generated hps_subsys.v"
for HPS_GEN in "${HPS_COPIES[@]}"; do
  log "Applying custom_hps body to ${HPS_GEN}"
  python3 "${SCRIPT_DIR}/apply_custom_hps.py" "${CUSTOM_HPS}" "${HPS_GEN}"
done
HPS_SIM_V="$(find "${DUT_SRC}/gen/vds/hps_subsys/sim" -type f -name 'hps_subsys.v' | head -n 1 || true)"
[[ -n "${HPS_SIM_V}" && -f "${HPS_SIM_V}" ]] || fail "Missing sim/hps_subsys.v"
grep -q 'Custom HPS is here' "${HPS_SIM_V}" \
  || fail "custom_hps transplant failed on ${HPS_SIM_V}"
if grep -q 'agilex_hps ' "${HPS_SIM_V}"; then
  fail "custom_hps transplant failed: ${HPS_SIM_V} still contains agilex_hps"
fi

log "Export/transforms done — compiling"
"${SCRIPT_DIR}/compile.sh"
log "Compile done — simulating"
"${SCRIPT_DIR}/run_sim.sh"
log "DONE"
