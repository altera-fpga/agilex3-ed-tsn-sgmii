// Compile-time guard for the standalone 1-port 1G Agilex 3 verification flow.
// TSN_CFG3 forces parameter NUM_PHY=1 in testbench/tb/tsn_top_params.svh.
`ifndef TSN_CFG3
  `error "Standalone verification requires +define+TSN_CFG3 (NUM_PHY must be 1)"
`endif

module verification_num_phy_assert;
  // Presence of this module in the compile proves TSN_CFG3 was set.
endmodule
