# Standalone Makefile verification (1-port 1G)

Local UVM/VCS flow for the Agilex 3 **1-port 1G** VDS project under
`src/hw/a5e065bb32aes1_mdk_1x1G`. Shares DUT generate with the ITF/`reg_exe`
flow via `scripts/generate_dut.sh` and `../scripts/itf/prepare_vds_dut.sh`.

**Configuration**

- Quartus Prime Pro **26.1** + VDS package
- `+define+TSN_CFG3` (`NUM_PHY=1`)
- `+define+1G_SPEED`, `gdr_modes` → `1G_MGBASET`
- Generated artifacts stay under `work/`

## Prerequisites

Load site ARC tools via `env/` (same pattern as the PCIe RP ED), then run make:

```bash
cd src/sim/verification/env
source env.sh      # arc shell: VCS, Quartus 26.1, Synopsys VIP, ALTUVM
source setup.sh    # sets VERIF_ROOT / HW_ROOT / VIP / Quartus paths
cd "$VERIF_ROOT"
make env
```

See [`env/README`](env/README).

## Bring-up

```bash
make generate   # stage + VDS validate/generate + ip-setup-simulation
make compile    # VDS manifest + TB → work/simv wrapper
make sim        # eth_gdr_base_test + tsn_sanity_sequence
make regress    # canonical ../scripts/itf/regression_list.txt
```

## Useful knobs

| Variable | Default | Meaning |
|----------|---------|---------|
| `TEST` | `eth_gdr_base_test` | UVM test |
| `SEQ` | `tsn_sanity_sequence` | `+m_sequence` |
| `SEED` | `1` | single-sim seed |
| `NUM_SEEDS` | `20` | regress seeds per entry |
| `VERBOSITY` | `UVM_MEDIUM` | UVM verbosity |
| `NUM_OF_FRAMES` | `10` | Caps sequence frame count via +num_of_frames |
| `ERROR_COUNT` | `200` | `+UVM_MAX_QUIT_COUNT` |
| `DUMP` | `0` | waveform debug elab opts |
| `XPROP` | `0` | needs `config/xprop_1phy.cfg` when `1` |
| `SIM_TIMEOUT` | `6h` | hung-test kill |
| `REGR_LIST` | `../scripts/itf/regression_list.txt` | override list |
| `STRICT_UNSUPPORTED` | `0` | fail regress if any UNSUPPORTED |

## ITF flow

See [`../scripts/itf/README`](../scripts/itf/README) and the top-level
[`../README.md`](../README.md) for `reg_exe` farm/local usage.
