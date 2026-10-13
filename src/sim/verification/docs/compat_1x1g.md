# 1-port 1G compatibility notes

Target: `a5e065bb32aes1_mdk_1x1G` Agilex 3 VDS project.
Standalone flow uses `+define+TSN_CFG3` → `NUM_PHY=1`, `NUM_INST=1`, and `+define+1G_SPEED`.

## Mandatory setup

| Item | Status |
|------|--------|
| `+define+TSN_CFG3` in `flist/defines.f` | Required |
| `+define+1G_SPEED` in `flist/defines.f` | Required |
| `gdr_modes.txt` → `1G_MGBASET_PCSMAC_SM` | Required |
| `flist/num_phy_assert.sv` compile guard | Required |
| Guard stale `emif_hps_emif_mem_0_mem_alert_n` TB connection under `TSN_CFG3` | Required (shared TB) |
| Default `XPROP=0` until hierarchy validated | Required |
| `config/xprop_1phy.cfg` for `XPROP=1` | PHY0 / MAC0 only |

## Hierarchy / modes

- Runtime speed is **1G MGBASET**:
  - `flist/defines.f`: `+define+1G_SPEED`
  - `testbench/tests/top/gdr_modes.txt` (and `verification/config/gdr_modes.txt`): `…__1G_MGBASET_PCSMAC_SM`
  - DUT `custom_ip/tsn_shell.sv` hardwires `xcvr_mode` to `2'b00` (1G)
- VIP serial/GMII clocks use the 1G branch in `vip_clk_gen.sv` (400 / 4000 ps)
- MRPHY macros in `tsn_tb.sv` index PHY0 when `NUM_PHY==1`
- Sequences under `tsn_seq_lib` branch on `NUM_PHY==1` for CSR/MPHY checks

## UNSUPPORTED policy

Sequences that inherently require more than one PHY must be reported as
`UNSUPPORTED` with a concrete reason — never silently skipped.

Day-1 compile-changing list options (`--perf_en`, coverage, mismatched xprop/dump)
are also `UNSUPPORTED` on the shared `simv`.

## Runtime sequence notes (1G)

| Sequence | Expectation |
|----------|-------------|
| `tsn_csr_regs` | User Space STATUS `[6:4]` = `3'b001` (1G `operating_speed`) |
| `tsn_mphy_regs` | MRPHY `if_mode` (`0x14`) = `16'h9` after 1G `wait_for_linkup` |
| `tsn_mphy_dl_measure` | Path-delay residuals (+987 / +174 ns) and `dl_tol=30` for 1G bring-up |
