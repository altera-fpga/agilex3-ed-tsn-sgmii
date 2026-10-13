#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../env/setup.sh"

fail() { echo "ERROR: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

need_var() {
  local v="$1"
  if [[ -z "${!v:-}" ]]; then
    fail "Required env var $v is unset"
  fi
  if [[ ! -e "${!v}" ]]; then
    echo "WARN: $v=${!v} does not exist on disk" >&2
  fi
  ok "$v=${!v}"
}

need_cmd() {
  local c="$1"
  command -v "$c" >/dev/null 2>&1 || fail "Required tool not on PATH: $c"
  ok "tool $c -> $(command -v "$c")"
}

echo "=== verification env check ==="

need_var ALTUVM_COMMON_HOME
need_var ALTUVM_BCL_HOME
need_var ALTUVM_AVALON_ST_HOME
need_var ALTUVM_AVALON_MM_HOME
need_var UVM_HOME
need_var ACDS_DEST_ROOT
need_var SYNOPSYS_VIP_ETHERNET
need_var SYNOPSYS_VIP_AMBA
need_var DESIGNWARE_HOME
need_var QUARTUS_ROOTDIR

need_cmd vlogan
need_cmd vcs
need_cmd quartus_sh
need_cmd ip-setup-simulation
need_cmd xvfb-run
need_cmd tclsh
need_cmd python3
need_cmd rsync
need_cmd timeout

# Quartus 26.1 + VDS package
QVER="$(quartus_sh -v 2>&1 | head -n 5 || true)"
echo "--- Quartus version ---"
echo "$QVER"
echo "$QVER" | grep -Eq '26\.1' || fail "Quartus Prime Pro 26.1 required; got: $QVER"

# Prove VDS package loads (headless via xvfb)
tmp_tcl="$(mktemp)"
cat >"$tmp_tcl" <<'EOF'
load_package project
load_package vds
puts "VDS_PACKAGE_OK"
EOF
if ! xvfb-run -a quartus_sh -t "$tmp_tcl" >/tmp/vds_pkg_check.log 2>&1; then
  cat /tmp/vds_pkg_check.log >&2 || true
  rm -f "$tmp_tcl"
  fail "VDS package failed to load under xvfb-run -a quartus_sh"
fi
grep -q VDS_PACKAGE_OK /tmp/vds_pkg_check.log || fail "VDS package load did not report VDS_PACKAGE_OK"
rm -f "$tmp_tcl"
ok "VDS package loads"

# Validate HW top.qsf is VDS-only (read-only check against HW_ROOT)
TOP_QSF="${HW_ROOT}/top.qsf"
[[ -f "$TOP_QSF" ]] || fail "Missing $TOP_QSF"
if grep -Eq '^[[:space:]]*set_global_assignment[[:space:]]+-name[[:space:]]+QSYS_FILE' "$TOP_QSF"; then
  fail "Active QSYS_FILE found in $TOP_QSF — standalone flow requires VDS-only project"
fi
grep -Eq 'VDS_FILE' "$TOP_QSF" || fail "No VDS_FILE assignments in $TOP_QSF"
ok "top.qsf is VDS-only (has VDS_FILE, no active QSYS_FILE)"

echo "--- tool versions ---"
vcs -ID 2>&1 | head -n 20 || true
echo "UVM_HOME=$UVM_HOME"
echo "SYNOPSYS_VIP_ETHERNET=$SYNOPSYS_VIP_ETHERNET"
echo "SYNOPSYS_VIP_AMBA=$SYNOPSYS_VIP_AMBA"
echo "DESIGNWARE_HOME=$DESIGNWARE_HOME"

echo "=== env check PASSED ==="
