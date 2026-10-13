#!/usr/bin/env bash
# Stage HW → VDS validate/generate → ip-setup-simulation → select top VCS manifest → transforms
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
log()  { echo "[generate] $*"; }

mkdir -p "${LOG_DIR}" "${DUT_SIM}"
META="${LOG_DIR}/generate_meta.txt"
: >"${META}"

# Capture source revision before staging
SRC_REV="unknown"
SRC_DIRTY="unknown"
if git -C "${TSN_HOME}/../.." rev-parse HEAD >/dev/null 2>&1; then
  SRC_REV="$(git -C "${TSN_HOME}/../.." rev-parse HEAD)"
  if git -C "${TSN_HOME}/../.." status --porcelain >/dev/null 2>&1; then
    if [[ -n "$(git -C "${TSN_HOME}/../.." status --porcelain)" ]]; then
      SRC_DIRTY="dirty"
    else
      SRC_DIRTY="clean"
    fi
  fi
fi
{
  echo "timestamp=$(date -Is)"
  echo "source_rev=${SRC_REV}"
  echo "source_dirty=${SRC_DIRTY}"
  echo "hw_root=${HW_ROOT}"
  echo "dut_src=${DUT_SRC}"
  echo "dut_sim=${DUT_SIM}"
} >>"${META}"

[[ -d "${HW_ROOT}" ]] || fail "HW_ROOT missing: ${HW_ROOT}"
[[ -f "${HW_ROOT}/top.qpf" ]] || fail "Missing ${HW_ROOT}/top.qpf"
[[ -f "${HW_ROOT}/top.qsf" ]] || fail "Missing ${HW_ROOT}/top.qsf"

# Reject active QSYS_FILE / refuse qsys-generate usage
if grep -Eq '^[[:space:]]*set_global_assignment[[:space:]]+-name[[:space:]]+QSYS_FILE' "${HW_ROOT}/top.qsf"; then
  fail "Active QSYS_FILE in HW top.qsf — aborting"
fi
command -v qsys-generate >/dev/null 2>&1 && log "NOTE: qsys-generate is on PATH but must NOT be invoked by this flow"

log "Staging HW → ${DUT_SRC} (excluding synthesis/generated artifacts and .qsys)"
mkdir -p "${DUT_SRC}"
# Exclude checked-in generate products: VDS regenerates gen/vds in the stage tree.
# --exclude gen/ also preserves a prior staged gen/vds when SKIP_VDS_REGEN=1.
rsync -a --delete \
  --exclude 'output_files/' \
  --exclude 'qdb/' \
  --exclude 'dni/' \
  --exclude 'tmp-clearbox/' \
  --exclude 'gen/' \
  --exclude 'vds_port/' \
  --exclude '*.qdf' \
  --exclude '*.qsys' \
  "${HW_ROOT}/" "${DUT_SRC}/"

# Prove staged tree has no .qsys
if find "${DUT_SRC}" -name '*.qsys' | grep -q .; then
  fail "Staged tree still contains .qsys files"
fi
echo "stage=rsync_ok" >>"${META}"

VDS_META="${LOG_DIR}/vds_generate_meta.txt"
# Reuse staged gen/vds when present (rsync excludes gen/). Set FORCE_VDS_REGEN=1
# to rebuild systems after VDS source changes. SKIP_VDS_REGEN=1 forces reuse.
if [[ "${FORCE_VDS_REGEN:-0}" != "1" ]] \
  && { [[ "${SKIP_VDS_REGEN:-0}" == "1" ]] || [[ -f "${DUT_SRC}/gen/vds/qsys_top/qsys_top.spd" ]]; } \
  && [[ -f "${DUT_SRC}/gen/vds/qsys_top/qsys_top.spd" ]] \
  && [[ -f "${DUT_SRC}/gen/vds/hps_subsys/hps_subsys.spd" ]] \
  && [[ -f "${DUT_SRC}/gen/vds/tsn_subsys/tsn_subsys.spd" ]]; then
  log "Reusing existing ${DUT_SRC}/gen/vds (set FORCE_VDS_REGEN=1 to rebuild)"
  {
    echo "status=skip_vds_regen"
    echo "skip_vds_regen=1"
  } | tee "${VDS_META}" >>"${META}"
else
  log "Running VDS validate/generate via Quartus 26.1 (xvfb)"
  xvfb-run -a quartus_sh -t "${SCRIPT_DIR}/generate_vds_sim.tcl" \
    "${DUT_SRC}/top.qpf" "${DUT_SIM}" "${VDS_META}" 2>&1 | tee "${LOG_DIR}/vds_generate.log"
  cat "${VDS_META}" >>"${META}"
fi

# Verify gen/vds children exist
for sys in hps_subsys tsn_subsys qsys_top; do
  [[ -d "${DUT_SRC}/gen/vds/${sys}" ]] || fail "Missing staged gen/vds/${sys}"
done

# Standalone EMIF IP needs SPD for ip-make-simscript. Always regenerate from the
# .ip into a wiped output dir AFTER VDS generate:
#   - HW ships a partial synth tree under src/ip/emif_io96b_hps/ (no sim/)
#   - VDS/quartus project generate can rewrite that tree and emit
#     vcsmx_files.tcl sourcing ./../null/sim/... (null::) — IP compile aborts
#   - Generating into a clean directory produces the real child package name
EMIF_IP="${DUT_SRC}/src/ip/emif_io96b_hps.ip"
EMIF_OUT="${DUT_SRC}/src/ip/emif_io96b_hps"
EMIF_SPD="${EMIF_OUT}/emif_io96b_hps.spd"
EMIF_SIM_TCL="${EMIF_OUT}/sim/common/vcsmx_files.tcl"
BAD_EMIF_SPD="${DUT_SRC}/src/ip/emif_io96b_hps.spd"
if [[ -f "${BAD_EMIF_SPD}" ]]; then
  log "Removing misplaced EMIF SPD ${BAD_EMIF_SPD}"
  rm -f "${BAD_EMIF_SPD}"
fi
emif_sim_broken() {
  # Keep the pattern simple: older grep rejects [[:alnum:]] typos as hard errors.
  [[ ! -f "${EMIF_SIM_TCL}" ]] && return 0
  grep -Eq 'null::|/null/sim/' "${EMIF_SIM_TCL}"
}
if [[ -f "${EMIF_IP}" ]]; then
  log "Generating simulation file set for standalone EMIF IP (clean output dir)"
  rm -rf "${EMIF_OUT}"
  mkdir -p "${EMIF_OUT}"
  # qsys-generate on a standalone .ip produces the simulation SPD.
  if ! qsys-generate "${EMIF_IP}" --simulation=VERILOG --simulator=VCSMX --output-directory="${EMIF_OUT}" 2>&1 | tee "${LOG_DIR}/emif_ip_generate.log"; then
    qsys-generate "${EMIF_IP}" --simulation=VERILOG --output-directory="${EMIF_OUT}" 2>&1 | tee -a "${LOG_DIR}/emif_ip_generate.log" \
      || fail "Failed to generate simulation for ${EMIF_IP}"
  fi
  if [[ ! -f "${EMIF_SPD}" ]]; then
    found_spd="$(find "${DUT_SRC}/src/ip" -path '*/emif_io96b_hps/emif_io96b_hps.spd' | head -n 1 || true)"
    [[ -n "${found_spd}" ]] || found_spd="$(find "${DUT_SRC}/src/ip" -name 'emif_io96b_hps.spd' ! -path '*/src/ip/emif_io96b_hps.spd' | head -n 1 || true)"
    [[ -n "${found_spd}" ]] || fail "EMIF SPD still missing after ip simulation generate under ${EMIF_OUT}"
    if [[ "${found_spd}" != "${EMIF_SPD}" ]]; then
      mkdir -p "$(dirname "${EMIF_SPD}")"
      cp -a "${found_spd}" "${EMIF_SPD}"
    fi
  fi
  [[ -f "${EMIF_SPD}" ]] || fail "EMIF SPD still missing after ip simulation generate: ${EMIF_SPD}"
  [[ -f "${EMIF_SIM_TCL}" ]] || fail "EMIF sim script missing after generate: ${EMIF_SIM_TCL}"
  if emif_sim_broken; then
    fail "EMIF sim script still references null:: /null/sim after clean generate: ${EMIF_SIM_TCL}"
  fi
  echo "emif_spd=${EMIF_SPD}" >>"${META}"
fi

# VCS export: VDS registers systems via VDS_FILE (not QIP), so project-level
# ip-setup-simulation often sees only standalone IP_FILE SPDs (e.g. EMIF).
# Collect VDS + EMIF SPDs, including nested leaf packages (clk_100, agilex_hps,
# mge phy, …). Exclude only the misplaced src/ip/emif_io96b_hps.spd.
log "Collecting SPDs for VCS MX export"
mapfile -t SPD_LIST < <(
  {
    find "${DUT_SRC}/gen/vds" -type f -name '*.spd' 2>/dev/null
    find "${DUT_SRC}/src/ip" -type f -name '*.spd' 2>/dev/null
  } | grep -v '/src/ip/emif_io96b_hps\.spd$' | sort -u
)
[[ "${#SPD_LIST[@]}" -gt 0 ]] || fail "No SPD files found under gen/vds or src/ip"
printf '%s\n' "${SPD_LIST[@]}" | tee "${LOG_DIR}/spd_list.txt" >/dev/null
echo "spd_count=${#SPD_LIST[@]}" >>"${META}"

# Require top-level VDS system SPDs + correctly-rooted EMIF SPD
for must in qsys_top.spd hps_subsys.spd tsn_subsys.spd; do
  printf '%s\n' "${SPD_LIST[@]}" | grep -q "/${must}$" \
    || fail "Missing required VDS SPD: ${must}"
done
printf '%s\n' "${SPD_LIST[@]}" | grep -q '/emif_io96b_hps/emif_io96b_hps\.spd$' \
  || fail "Missing correctly-rooted EMIF SPD: ${EMIF_SPD}"

SPD_CSV="$(IFS=','; echo "${SPD_LIST[*]}")"
# Preserve compiled artifacts across export refresh (set FORCE_RECOMPILE=1 to drop).
SIM_STASH=""
VCSMX_KEEP="${DUT_SIM}/synopsys/vcsmx"
if [[ "${FORCE_RECOMPILE:-0}" != "1" && -x "${VCSMX_KEEP}/simv" ]]; then
  SIM_STASH="$(mktemp -d "${LOG_DIR}/sim_stash.XXXXXX")"
  log "Stashing existing simv/libraries before dut_sim refresh → ${SIM_STASH}"
  for keep in simv simv.daidir libraries csrc; do
    [[ -e "${VCSMX_KEEP}/${keep}" ]] && mv "${VCSMX_KEEP}/${keep}" "${SIM_STASH}/"
  done
fi
rm -rf "${DUT_SIM}"
mkdir -p "${DUT_SIM}"

IPMS_CMD=(
  ip-make-simscript
  --output-directory="${DUT_SIM}"
  --spd="${SPD_CSV}"
  --use-relative-paths
  --simulator=VCSMX
  --device=A3CW135BM16AE6S
  --device-family="Agilex 3"
  --top-name=agilex5_top
)
log "Running: ${IPMS_CMD[*]}"
echo "ip_make_simscript_cmd=${IPMS_CMD[*]}" >>"${META}"
("${IPMS_CMD[@]}") 2>&1 | tee "${LOG_DIR}/ip-make-simscript.log" \
  || fail "ip-make-simscript failed"

if [[ -n "${SIM_STASH}" ]]; then
  mkdir -p "${DUT_SIM}/synopsys/vcsmx"
  log "Restoring stashed simv/libraries into ${DUT_SIM}/synopsys/vcsmx"
  mv "${SIM_STASH}"/* "${DUT_SIM}/synopsys/vcsmx/" 2>/dev/null || true
  rmdir "${SIM_STASH}" 2>/dev/null || true
fi

# Canonical top-level setup path for this export layout
TOP_SETUP="${DUT_SIM}/synopsys/vcsmx/vcsmx_setup.sh"
[[ -f "${TOP_SETUP}" ]] || fail "Expected top-level setup missing: ${TOP_SETUP}"
COMMON_TCL="${DUT_SIM}/common/vcsmx_files.tcl"
[[ -f "${COMMON_TCL}" ]] || fail "Missing ${COMMON_TCL}"
if grep -q 'src/ip//sim/common/vcsmx_files.tcl\|src/ip/sim/common/vcsmx_files.tcl' "${COMMON_TCL}"; then
  fail "Exported ${COMMON_TCL} sources broken src/ip/sim namespace (misplaced EMIF SPD)"
fi
if grep -Eq 'null::|/null/sim/' "${COMMON_TCL}" "${EMIF_SIM_TCL}" 2>/dev/null; then
  fail "Exported sim scripts reference null:: /null/sim (broken EMIF child package)"
fi
for must_lib in clk_100 agilex_hps intel_mge_phy_0; do
  grep -q "dict set libraries ${must_lib}" "${COMMON_TCL}" \
    || fail "Exported ${COMMON_TCL} missing library ${must_lib} — nested SPDs required"
done
VCSMX_DIR="$(cd "$(dirname "${TOP_SETUP}")" && pwd)"
VCSMX_SETUP="${TOP_SETUP}"

# Validate VDS IP content in the combined script / file list
if ! grep -Eqi 'hps_subsys|tsn_subsys|intel_mge_phy|qsys_top' "${VCSMX_SETUP}" \
  && ! grep -Eqi 'hps_subsys|tsn_subsys|intel_mge_phy|qsys_top' "${DUT_SIM}/common/"* 2>/dev/null; then
  # Also accept if SPD-driven common files reference them
  if ! grep -REqi 'hps_subsys|tsn_subsys|intel_mge_phy|qsys_top' "${DUT_SIM}/common" "${DUT_SIM}/synopsys" 2>/dev/null; then
    fail "Exported VCS setup does not reference expected VDS systems/IP"
  fi
fi

# Fail on stale paths into checked-in HW_ROOT
if grep -RF "${HW_ROOT}" "${DUT_SIM}" >/dev/null 2>&1; then
  fail "Exported sim scripts reference checked-in HW_ROOT paths"
fi

{
  echo "VCSMX_SETUP=${VCSMX_SETUP}"
  echo "VCSMX_DIR=${VCSMX_DIR}"
} | tee "${WORK_DIR}/vcsmx_paths.env" >>"${META}"

log "Applying compatibility transforms (idempotent, staged-only)"

# Optional encrypted HSSI → plaintext swap (only if pattern present)
PLAIN_PAT='tennm_agilex5_hssi_a_ncrypt.sv'
PLAIN_REPL='tennm_agilex5_hssi_a_plaintext.sv'
if grep -q "${PLAIN_PAT}" "${VCSMX_SETUP}" 2>/dev/null; then
  if [[ -n "${ACDS_DEST_ROOT:-}" ]] && [[ -f "${ACDS_DEST_ROOT}/not_shipped/devices/sim_lib/${PLAIN_REPL}" || -f "${ACDS_DEST_ROOT}/devices/sim_lib/${PLAIN_REPL}" ]]; then
    cp -a "${VCSMX_SETUP}" "${VCSMX_SETUP}.pre_hssi"
    # shellcheck disable=SC2016
    sed -i "s#${PLAIN_PAT}#${PLAIN_REPL}#g" "${VCSMX_SETUP}"
    echo "transform=hssi_plaintext applied" >>"${META}"
  else
    echo "transform=hssi_plaintext skipped (plaintext lib not found)" >>"${META}"
  fi
else
  echo "transform=hssi_plaintext not_applicable" >>"${META}"
fi

# Strip duplicate quartus_dpi.o ELAB append lines if present (ITF workaround)
if grep -q 'append ELAB_OPTIONS \[intel_mge_phy_' "${DUT_SRC}/gen/vds/tsn_subsys"/*/sim/common/vcsmx_files.tcl 2>/dev/null; then
  find "${DUT_SRC}/gen/vds" -name 'vcsmx_files.tcl' -print0 | while IFS= read -r -d '' f; do
    if grep -q 'append ELAB_OPTIONS \[intel_mge_phy_' "$f"; then
      cp -a "$f" "${f}.pre_dpi"
      sed -i '/append ELAB_OPTIONS \[intel_mge_phy_/d' "$f"
      echo "transform=strip_quartus_dpi file=$f" >>"${META}"
    fi
  done
else
  echo "transform=strip_quartus_dpi not_applicable" >>"${META}"
fi

# custom_hps: body-only transplant into EVERY generated hps_subsys.v
# (sim/ and synth/ both exist; vcsmx compiles sim/hps_subsys.v — patching only
# the first find() hit previously left sim with the real HPS and hung AXI CSR.)
CUSTOM_HPS="${TSN_HOME}/scripts/itf/custom_hps/custom_hps.v"
[[ -f "${CUSTOM_HPS}" ]] || fail "Missing custom_hps source: ${CUSTOM_HPS}"
mapfile -t HPS_COPIES < <(find "${DUT_SRC}/gen/vds/hps_subsys" "${DUT_SIM}" \
  -type f -name 'hps_subsys.v' 2>/dev/null | sort -u)
[[ "${#HPS_COPIES[@]}" -gt 0 ]] || fail "Missing generated hps_subsys.v under gen/vds/hps_subsys"
for HPS_GEN in "${HPS_COPIES[@]}"; do
  log "Applying custom_hps body to ${HPS_GEN}"
  python3 "${SCRIPT_DIR}/apply_custom_hps.py" "${CUSTOM_HPS}" "${HPS_GEN}" | tee -a "${META}"
done
# Fail if the sim copy (what vcsmx compiles) still instantiates agilex_hps.
HPS_SIM_V="$(find "${DUT_SRC}/gen/vds/hps_subsys/sim" -type f -name 'hps_subsys.v' | head -n 1 || true)"
[[ -n "${HPS_SIM_V}" ]] || fail "Missing ${DUT_SRC}/gen/vds/hps_subsys/sim/hps_subsys.v"
if grep -q 'agilex_hps ' "${HPS_SIM_V}"; then
  fail "custom_hps transplant failed: ${HPS_SIM_V} still contains agilex_hps"
fi
grep -q 'Custom HPS is here' "${HPS_SIM_V}" \
  || fail "custom_hps transplant failed: ${HPS_SIM_V} missing Custom HPS marker"

echo "status=generate_ok" >>"${META}"
log "Generate complete"
log "VCSMX_SETUP=${VCSMX_SETUP}"
log "VCSMX_DIR=${VCSMX_DIR}"
log "Meta: ${META}"
