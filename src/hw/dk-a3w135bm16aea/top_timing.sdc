#****************************************************************************
#
# SPDX-License-Identifier: MIT-0
# Copyright(c) 2019-2021 Intel Corporation.
#
#****************************************************************************
#
# Sample SDC for Agilex GHRD.
#
#****************************************************************************

set_time_format -unit ns -decimal_places 3

# 100MHz board input clock, 133.3333MHz for EMIF refclk
#MAIN_CLOCK is the 100MHz clk
create_clock -name MAIN_CLOCK -period 10 [get_ports fpga_clk_100]
#OSC_CLOCK is the system_pll_refclk
create_clock -name OSC_CLOCK -period 6.4 [get_ports osc_clk]
create_clock -name EMIF_REF_CLOCK -period 166.667MHz [get_ports emif_hps_emif_ref_clk_0_clk] 

set_false_path -from [get_ports {fpga_reset_n}]


 
# False Path between debounced and reset synchronizer
set_false_path -from [get_registers {fpga_reset_n_debounced}] -to {soc_inst|rst_controller_*|altera_reset_synchronizer_int_chain[1]}

#DRC constraint


