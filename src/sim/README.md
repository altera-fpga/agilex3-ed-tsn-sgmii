# Simulation

This directory contains the UVM testbench, sequences, and two supported ways to run sim for the **1-port 1G** VDS design (`src/hw/a5e065bb32aes1_mdk_1x1G`).

**Note:** Simulation uses engineering-internal tools/licenses (VCS, Synopsys VIP, Quartus). It is not part of the external ship package.

## Two supported entry points

| Flow | Location | When to use |
|------|----------|-------------|
| **ITF / `reg_exe`** | [`scripts/itf/`](scripts/itf/) | Farm regressions, ARC/ITF infra, SPeTC — VDS DUT via `prepare_vds_dut.sh` |
| **Standalone Makefile** | [`verification/`](verification/) | Local VDS bring-up without ITF runtime |

---

## ITF / `reg_exe` flow

See [`scripts/itf/README`](scripts/itf/README) for full options. Summary:

1. Load site ARC (or equivalent) resources for VCS, VIP, Quartus 26.1, `regutils`/`itf` (see resource list in `scripts/itf/README`).
2. Point regtest at this sim tree:
   ```bash
   export REG_LOCAL_ROOT_DIR_PATH=/path/to/src/sim
   ```
3. From `scripts/itf`, run a test, for example:
   ```bash
   reg_exe --localr --testname=eth_gdr_base_test --sequence=tsn_sanity_sequence \
     --uvm_verbosity=UVM_MEDIUM --seed=7 | tee run.txt
   ```
   The ITF `qsys` stage runs VDS generate into `itf_vds_work/` (shared helper: `verification/scripts/generate_dut.sh`).
4. Farm regression example:
   ```bash
   reg_exe --farm --priority=50 --regr_list=regression_list.txt
   ```

---

## Standalone Makefile flow

Local flow for `src/hw/a5e065bb32aes1_mdk_1x1G` (Quartus 26.1 VDS, 1-port 1G, `NUM_PHY=1`).

```bash
cd verification/env
source env.sh
source setup.sh
cd "$VERIF_ROOT"
make env
make generate && make compile && make sim
```

Details: [`verification/README.md`](verification/README.md).
