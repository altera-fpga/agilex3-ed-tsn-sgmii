# Agilex™ 3 – 1×1G TSN / Multi-rate Ethernet PHY Hardware

HPS + Multi-rate Ethernet PHY system example for **SM TSN Config-3**: one **1 GbE** Ethernet datapath from the HPS EMAC through Multi-rate Ethernet PHY IP (Direct mode, GMII-8) to an external MGBASE-T PHY on the A3CW Rev-B TSN daughterboard (MxL86211).

## Description

- Datapath: **HPS EMAC0 ↔ GMII (8-bit) ↔ `intel_mge_phy` (Direct) ↔ serial XCVR ↔ MxL86211 MGBASE-T PHY** at **1G**.
- Single port (`NUM_PHY=1`); EMAC1/EMAC2 unused.
- MR PHY in Direct PHY mode with GMII adapter (`ENABLE_GMII_ADAPTER=1`, `ENABLE_SGMII=0`, `EXT_PHY_MGBASET=1`).
- IEEE 1588 / PTP enabled on MR PHY and HPS EMAC0 (`emac_ptp_trig` / `emac_ptp_pps`).

```text
 ┌─ agilex5_top ──────────────────────────────────────────────────────────┐
 │                                                                        │
 │  ┌─ subsys_hps ───────────┐  GMII-8  ┌─ subsys_tsn ────────────────┐   │   XCVR   ┌──────────┐
 │  │ CPU + LPDDR4 (EMIF)    │─────────►│ intel_mge_phy_0 (Direct)    │───┼────────►│ MxL86211 │
 │  │ SDMMC / USB / UART     │◄─────────│ SysPLL / IOPLL              │◄──┼─────────│ MGBASE-T │
 │  │ EMAC0  (MAC)           │          │ AXI / MM CSR bridges        │   │          └──────────┘
 │  └───────────┬────────────┘          └──────────────┬──────────────┘   │
 │              │                                      │                  │
 │              │         LW HPS (CSR / control)       │                  │
 │              └──────────► csr_shell / user CSR ◄────┘                  │
 │                           rst_ctrl (+ reserved CSR stubs)              │
 └────────────────────────────────────────────────────────────────────────┘

  Left: HPS SoC + board peripherals          Middle: fabric PHY/TSN          Right: external PHY
  Horizontal arrows: Ethernet packet path    Lower path: register / reset control
```

## Project details

| Item                   | Value                                              |
| ---------------------- | -------------------------------------------------- |
| Family                 | Agilex 3                                           |
| Device                 | `A3CW135BM16AE6S`                                |
| Top entity             | `agilex5_top` (`NUM_PHY=1`)                    |
| Quartus project        | `top.qpf` / `top.qsf`                          |
| Quartus (last compile) | 26.1.0 Pro                                         |
| Ethernet               | 1× 1G, MR PHY Direct + GMII-8 + MGBASE-T          |
| External PHY           | MxL86211 (A3CW Rev-B TSN daughterboard)            |
| Design support         | Compile/timing, hardware, simulation (`src/sim`) |


## Directory layout

```text
a5e065bb32aes1_mdk_1x1G/
├── agilex5_top.v          # Board top (HPS I/O, XCVR, PTP, MDIO, qsys_top + soft RTL)
├── top.qpf / top.qsf      # Quartus project and assignments
├── top_timing.sdc         # Base timing
├── top_user.sdc           # User timing / clock groups
├── jtag.sdc
├── custom_ip/             # Soft shell: reset, CSR, reserved Avalon stubs
├── src/vds/               # VDS sources used by the project
│   ├── qsys_top/
│   ├── hps_subsys/
│   └── tsn_subsys/
├── src/ip/                # Shared IP (e.g. EMIF)
└── output_files/          # Compile outputs (e.g. top.sof)
```

### Custom IP roles

| Module                          | Role                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| `rst_ctrl.sv`                 | PHY / GMII / CSR / PLL reset sequencing with HPS MAC resets  |
| `csr_shell.sv`                | Avalon-MM shell; selects Config-3 user CSR for`NUM_PHY==1` |
| `user_csr_space_config3.v`    | Active soft CSR (status, reset, speed, delay fields)         |
| `user_csr_space_concurrent.v` | Multi-PHY CSR (not used when`NUM_PHY=1`)                   |
| `tsn_rsvd_csr.sv`             | Stub slaves for unused CSR windows                           |
| `debounce/debounce.v`         | Debounce for`fpga_reset_n`                                 |

## Board I/O (Ethernet / TSN)

A3CW Rev-B TSN daughterboard contract (from `top.qsf`):

| Signal                                     | Pin         | Notes                              |
| ------------------------------------------ | ----------- | ---------------------------------- |
| `pp_app_tx_serial_data[0]` / `_n`      | P30 / P29   | FPGA MR PHY TX → MxL86211 RX0     |
| `app_pp_rx_serial_data[0]` / `_n`      | K30 / K29   | MxL86211 TX0 → FPGA MR PHY RX     |
| `c3_emac0_mdio_mdc0` / `mdio0`         | AJ25 / AH26 | EMAC0 MDIO                         |
| `emac_ptp_pps[0]` / `emac_ptp_trig[0]` | T4 / U4     | PTP                                |
| `osc_clk`                                | M24         | 156.25 MHz XCVR / SysPLL reference |
| `fpga_clk_100`                           | AJ27        | 100 MHz fabric clock               |

## CSR map

Accessed from the HPS over the **lightweight HPS-to-FPGA (LWHPS2FPGA)** bridge into `subsys_tsn`. Absolute addresses below use the LWHPS window base **`0x1000_0000`** (same map exercised in simulation as `0x1002_xxxx` for the CSR slice).

### TSN / MR PHY window

| Absolute (HPS) | Offset in TSN map | Slave | Width | Notes |
| -------------- | ----------------- | ----- | ----- | ----- |
| `0x1000_0000`–`0x100F_FFFF` | `0x0`–`0x100000` | `intel_mge_phy_0.reconfig` | 32 | MR PHY / PMA reconfig |
| `0x1002_0100`–`0x1002_013F` | `0x20100`–`0x20140` | `intel_mge_phy_0.avalon_mm_csr` | 16 | MR PHY Avalon CSR |
| `0x1002_0140`–`0x1002_017F` | `0x20140`–`0x20180` | `mm_bridge_2` → `tsn_rsvd_csr` | 16 | Reserved stub |
| `0x1002_0180`–`0x1002_01FF` | `0x20180`–`0x20200` | `mm_bridge_3` → `tsn_rsvd_csr` | 16 | Reserved stub |
| `0x1002_0200`–`0x1002_02FF` | `0x20200`–`0x20300` | `mm_bridge_4` → `tsn_rsvd_csr` | 32 | Reserved stub |
| `0x1002_0300`–`0x1002_037F` | `0x20300`–`0x20380` | `mm_bridge_0` → `csr_shell` / `user_csr_space_config3` | 32 | Soft user CSR (active) |
| `0x1002_0380`–`0x1002_03FF` | `0x20380`–`0x20400` | `mm_bridge_5` → `tsn_rsvd_csr` | 32 | Reserved stub |
| `0x1002_0400`–`0x1002_07FF` | `0x20400`–`0x20800` | `mm_bridge_6` → `tsn_rsvd_csr` | 32 | Reserved stub |

Source: `src/vds/tsn_subsys/tsn_subsys.vds` address map; soft CSR via `custom_ip/csr_shell.sv` → `user_csr_space_config3.v`.

### User CSR (`user_csr_space_config3`) — base `0x1002_0300`

Register offsets are byte addresses within the user CSR window (7-bit Avalon address in RTL).

| Offset | Register | Access | Fields |
| ------ | -------- | ------ | ------ |
| `0x00` | `STATUS_REG` | RO | `[0]` `mrphy_pll_lock`, `[1]` `rx_ready`, `[2]` `tx_ready`, `[3]` `rx_block_lock`, `[6:4]` `op_speed` |
| `0x04` | `RESET_CTRL` | RW | `[0]` `i_rst_n`, `[1]` `i_tx_rst_n`, `[2]` `i_rx_rst_n` |
| `0x08` | `DELAY_TX` | RO | Additional user TX delay |
| `0x0C` | `DELAY_RX` | RO | Additional user RX delay |
| `0x10` | `ERROR` | RW | `[0]` `Unsupported_Speed_Error` |
| `0x14` | `DR_STATUS` | RW/RO | `[0]` `dr_error_status` (RW), `[16]` `dr_new_cfg_applied` (RO) |
| `0x18` | `XCVR_MODE` | RW | `[1:0]` `xcvr_mode` (`2'b00` = 1G in this design) |
| `0x1C` | `PHY0_TX_DELAY` | RO | PHY TX delay |
| `0x20` | `PHY0_RX_DELAY` | RO | PHY RX delay |

## Build

1. Source **Quartus Prime Pro 26.1** (matches the last successful compile in `output_files/`).
2. Change to this directory:

   ```bash
   cd src/hw/dk-a3w135bm16aea
   ```
3. Compile:

   ```bash
   quartus_sh --flow compile top
   ```

   Or open `top.qpf` in the Quartus GUI and run the full compilation flow.
4. Programming file: `output_files/top.sof`.

The project pulls RTL (`agilex5_top.v`, `custom_ip/*`), SDC files, and VDS systems (`src/vds/**/*.vds` and IP) via `top.qsf`.

## Related

- Software / GSRD Yocto: [`../../sw/README.md`](../../sw/README.md)
