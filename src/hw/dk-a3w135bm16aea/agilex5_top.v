//****************************************************************************
//
// SPDX-License-Identifier: MIT-0
// Copyright(c) 2019-2021 Intel Corporation.
//
//****************************************************************************
// This is a generated system top level RTL file. 

// Derive channel and width from hps_emif_topology

// Find and print each number individually

module agilex5_top #(parameter NUM_PHY=1)(
//Additional refclk_bti to preserve Etile XCVR
// Clock and Reset
input    wire          fpga_clk_100,

//HPS
// HPS EMIF
output   wire          emif_hps_emif_mem_0_mem_ck_t,
output   wire          emif_hps_emif_mem_0_mem_ck_c,
//output   wire [16:0]   emif_hps_emif_mem_0_mem_a,
//output   wire          emif_hps_emif_mem_0_mem_act_n,
//output   wire [1:0]    emif_hps_emif_mem_0_mem_ba,
//output   wire [1:0]    emif_hps_emif_mem_0_mem_bg,
output   wire          emif_hps_emif_mem_0_mem_cke,
//output   wire          emif_hps_emif_mem_0_mem_cs_n,
//output   wire          emif_hps_emif_mem_0_mem_odt,
output   wire          emif_hps_emif_mem_0_mem_reset_n,
//output   wire          emif_hps_emif_mem_0_mem_par,
//input    wire          emif_hps_emif_mem_0_mem_alert_n,
input    wire          emif_hps_emif_oct_0_oct_rzqin,
input    wire          emif_hps_emif_ref_clk_0_clk,
inout    wire [3:0]    emif_hps_emif_mem_0_mem_dqs_t,
inout    wire [3:0]    emif_hps_emif_mem_0_mem_dqs_c,
inout    wire [31:0]   emif_hps_emif_mem_0_mem_dq,
output wire        emif_hps_emif_mem_0_mem_cs,
output wire [ 5:0] emif_hps_emif_mem_0_mem_ca,
inout  wire [ 3:0] emif_hps_emif_mem_0_mem_dmi,
output   wire          hps_sdmmc_CCLK, 
inout    wire          hps_sdmmc_CMD,          
inout    wire          hps_sdmmc_D0,          
inout    wire          hps_sdmmc_D1,          
inout    wire          hps_sdmmc_D2,        
inout    wire          hps_sdmmc_D3,        

input    wire          usb31_io_vbus_det,                  
input    wire          usb31_io_flt_bar,                   
output   wire [1:0]    usb31_io_usb_ctrl,
input    wire          usb31_io_usb31_id,                  
input    wire          usb31_phy_refclk_p_clk,             
//input    wire          usb31_phy_refclk_p_clk(n),             
input    wire          usb31_phy_rx_serial_n_i_rx_serial_n,
input    wire          usb31_phy_rx_serial_p_i_rx_serial_p,
output   wire          usb31_phy_tx_serial_n_o_tx_serial_n,
output   wire          usb31_phy_tx_serial_p_o_tx_serial_p,
inout    wire          hps_usb1_DATA0,         
inout    wire          hps_usb1_DATA1,      
inout    wire          hps_usb1_DATA2,        
inout    wire          hps_usb1_DATA3,       
inout    wire          hps_usb1_DATA4,        
inout    wire          hps_usb1_DATA5,      
inout    wire          hps_usb1_DATA6,      
inout    wire          hps_usb1_DATA7,         
input    wire          hps_usb1_CLK,         
output   wire          hps_usb1_STP,       
input    wire          hps_usb1_DIR,        
input    wire          hps_usb1_NXT, 
input    wire          hps_uart0_RX,       
output   wire          hps_uart0_TX, 
inout    wire          hps_i2c0_SDA,
inout    wire          hps_i2c0_SCL,
inout    wire          hps_gpio0_io0,
inout    wire          hps_gpio0_io11,

inout wire 			          c3_emac0_mdio_mdio0,
output wire 				  c3_emac0_mdio_mdc0,
output wire 	[NUM_PHY-1:0] pp_app_tx_serial_data,
output wire 	[NUM_PHY-1:0] pp_app_tx_serial_data_n,
input wire      [NUM_PHY-1:0] emac_ptp_trig,
output wire     [NUM_PHY-1:0] emac_ptp_pps,
input wire 		[NUM_PHY-1:0] app_pp_rx_serial_data,
input wire 		[NUM_PHY-1:0] app_pp_rx_serial_data_n,
input wire					  osc_clk,







input    wire          hps_osc_clk,
input    wire          fpga_reset_n
);

wire                   system_clk_100;
wire                   ninit_done;
wire                   fpga_reset_n_debounced_wire;
reg                    fpga_reset_n_debounced;
wire                   system_reset;
wire                 h2f_reset;

assign                combined_reset_n = fpga_reset_n & ~h2f_reset
& ~ninit_done;

altera_reset_synchronizer #(
    .ASYNC_RESET (1),
    .DEPTH       (2)
) sys_rst_inst (
    .reset_in  (~combined_reset_n),
    .clk       (system_clk_100),
    .reset_out (system_reset)
);
             
assign                 system_clk_100   = fpga_clk_100;

wire	app_pp_emac0_mdio_mdi0;		
wire	pp_app_emac0_mdio_mdo0;
wire	pp_app_emac0_mdio_mdoe0;
//wire h2f_reset;
wire csr_rst;
wire avmm_rst;
wire phy_reset;
wire sys_pll_locked;
wire io_pll_locked;
wire pll_reset;
wire    [NUM_PHY-1:0] src_grant, src_priority, src_req;
wire    o_pma_clk;
wire	[NUM_PHY-1:0] reg_mrphy_pll_lock, reg_tx_rdy, reg_rx_rdy, 
						  reg_blk_lock;
wire    [3*NUM_PHY - 1:0] reg_op_speed;						
wire	[NUM_PHY-1:0] phy_tx_rst_n, phy_rx_rst_n;
wire 	[NUM_PHY-1:0] ack_rst_n, ack_tx_rst_n, ack_rx_rst_n;
wire 	[NUM_PHY-1:0] emac_mac_rst_tx_n, emac_mac_rst_rx_n;
wire	[NUM_PHY-1:0] o_rst_n, csr_o_rst_n, sync_ack_i_rst_n, sync_mrphy_pll_lock_i,
		      sync_rx_ready_i, sync_tx_ready_i;
//HPS - MRPHY
wire		[7:0]	hps_mrphy_data 		[NUM_PHY-1:0];
wire		[NUM_PHY-1:0]		hps_mrphy_data_vld;
wire		[NUM_PHY-1:0]		hps_mrphy_err;
wire 		[NUM_PHY-1:0]		gmii8b_rst_tx_n, gmii8b_rst_rx_n, tx_digitalreset, rx_digitalreset;
wire		[7:0]  mrphy_hps_data [NUM_PHY-1:0];
wire		[NUM_PHY-1:0]		mrphy_hps_data_vld;
wire		[NUM_PHY-1:0]		mrphy_hps_err;
wire		[2:0] 	mac_speed [NUM_PHY-1:0];
wire 		[NUM_PHY-1:0]		mac_col_det;
wire		[NUM_PHY-1:0]		mac_car_sense;
wire 		[NUM_PHY-1:0]		mrphy_hps_tx_clk;
wire 		[NUM_PHY-1:0]		mrphy_hps_rx_clk;
wire 		[NUM_PHY-1:0]		hps_mrphy_tx_clk; 
//Avalon interface wires
wire        csr_waitrequest; 
wire [31:0] csr_readdata;     
wire        csr_readdatavalid;
wire [0:0]  csr_burstcount;   
wire [31:0] csr_writedata;    
wire [6:0]  csr_address;      
wire        csr_write;        
wire        csr_read;         
wire [3:0]  csr_byteenable;  
wire        csr_debugaccess;
wire 	    mm_bridge_0140_017f_m0_write;
wire 	    mm_bridge_0140_017f_m0_read;
wire        mm_bridge_0140_017f_m0_waitrequest;
wire [15:0] mm_bridge_0140_017f_m0_readdata;
wire  	    mm_bridge_0140_017f_m0_readdatavalid;
wire        mm_bridge_0380_03ff_m0_write;
wire  	    mm_bridge_0380_03ff_m0_read;
wire  	    mm_bridge_0380_03ff_m0_waitrequest;
wire [31:0] mm_bridge_0380_03ff_m0_readdata;
wire        mm_bridge_0380_03ff_m0_readdatavalid;
wire  	    mm_bridge_0180_01ff_m0_write;
wire        mm_bridge_0180_01ff_m0_read;
wire  	    mm_bridge_0180_01ff_m0_waitrequest;
wire [15:0] mm_bridge_0180_01ff_m0_readdata;
wire        mm_bridge_0180_01ff_m0_readdatavalid;
wire  	    mm_bridge_0200_02ff_m0_write;
wire  	    mm_bridge_0200_02ff_m0_read;
wire        mm_bridge_0200_02ff_m0_waitrequest;
wire [31:0] mm_bridge_0200_02ff_m0_readdata;
wire  	    mm_bridge_0200_02ff_m0_readdatavalid;
wire  	    mm_bridge_0400_07ff_m0_write;
wire  	    mm_bridge_0400_07ff_m0_read;
wire        mm_bridge_0400_07ff_m0_waitrequest;
wire [31:0] mm_bridge_0400_07ff_m0_readdata;
wire  	    mm_bridge_0400_07ff_m0_readdatavalid;

wire [31:0]            f2h_irq1_irq;
wire [63:0]              fpga2hps_interrupt_irq;
wire                   o_pma_cpu_clk;

assign                 f2h_irq1_irq    = {32'b0};
assign                 fpga2hps_interrupt_irq    = {63'b0};

// Qsys Top module
qsys_top soc_inst (
.clk_100_clk                               (system_clk_100),
.ninit_done_ninit_done                     (ninit_done),

 .csr_rst_reset_n							(csr_rst),
 //.ocm_clk1_clk								(),
 //.ocm_reset1_reset							(),
 //.ocm_reset1_reset_req						(),
 .h2f_reset_reset							(h2f_reset),
 .subsys_hps_emac_ptp_clk_clk          	   	   	    ('b0), 
 .subsys_hps_emac_timestamp_data_data_in    	   	    (64'b0),
 .subsys_hps_emac_timestamp_clk_clk    	   	   	    ('b0),
 .subsys_hps_emac0_ptp_mac_ptp_trig			    (emac_ptp_trig[0]),
 .subsys_hps_emac0_ptp_mac_ptp_pps				    (emac_ptp_pps[0]),
 .subsys_hps_emac0_ptp_mac_ptp_tstmp_data			    (),	
 .subsys_hps_emac0_ptp_mac_ptp_tstmp_en			    (),
 .subsys_hps_emac0_mdio_mac_mdc                                (c3_emac0_mdio_mdc0),
 .subsys_hps_emac0_mdio_mac_mdi                                (app_pp_emac0_mdio_mdi0),
 .subsys_hps_emac0_mdio_mac_mdo                                (pp_app_emac0_mdio_mdo0),
 .subsys_hps_emac0_mdio_mac_mdoe                               (pp_app_emac0_mdio_mdoe0),
 .subsys_hps_emac0_mac_tx_clk_o        	   	   	    (hps_mrphy_tx_clk[0]), //HA - Check this, connecting to get rid of IOPLL Fitter error
 .subsys_hps_emac0_mac_tx_clk_i        	   	   	    (mrphy_hps_tx_clk[0]), //HA - Check this, connecting to get rid of IOPLL Fitter error
 .subsys_hps_emac0_mac_rx_clk           		 	   (mrphy_hps_rx_clk[0]),
 .subsys_hps_emac0_mac_rst_tx_n         	   	   	   (emac_mac_rst_tx_n[0]),
 .subsys_hps_emac0_mac_rst_rx_n         	   	   	   (emac_mac_rst_rx_n[0]),
 .subsys_hps_emac0_mac_txen             	   	   	   (hps_mrphy_data_vld[0]),
 .subsys_hps_emac0_mac_txer             	   	   	   (hps_mrphy_err[0]    ),
 .subsys_hps_emac0_mac_rxdv             		 	   (mrphy_hps_data_vld[0]),
 .subsys_hps_emac0_mac_rxer             	   	   	   (mrphy_hps_err[0]    ),
 .subsys_hps_emac0_mac_rxd              	   	   	   (mrphy_hps_data[0]	),
 .subsys_hps_emac0_mac_col              	   	   	   ('b0),
 .subsys_hps_emac0_mac_crs              	   	   	   ('b0),
 .subsys_hps_emac0_mac_speed            		 	   (mac_speed[0]),
 .subsys_hps_emac0_mac_txd_o            	   	   	   (hps_mrphy_data[0]),
// .osc_clk_clk							   (osc_clk),
.emif_hps_emif_mem_ck_0_mem_ck_t           (emif_hps_emif_mem_0_mem_ck_t),
.emif_hps_emif_mem_ck_0_mem_ck_c           (emif_hps_emif_mem_0_mem_ck_c),
//.emif_hps_emif_mem_0_mem_a                 (emif_hps_emif_mem_0_mem_a),
//.emif_hps_emif_mem_0_mem_act_n             (emif_hps_emif_mem_0_mem_act_n),
//.emif_hps_emif_mem_0_mem_ba                (emif_hps_emif_mem_0_mem_ba),
//.emif_hps_emif_mem_0_mem_bg                (emif_hps_emif_mem_0_mem_bg),
.emif_hps_emif_mem_0_mem_cke               (emif_hps_emif_mem_0_mem_cke),
.emif_hps_emif_mem_0_mem_cs             (emif_hps_emif_mem_0_mem_cs),
//.emif_hps_emif_mem_0_mem_odt               (emif_hps_emif_mem_0_mem_odt),
.emif_hps_emif_mem_reset_n_mem_reset_n     (emif_hps_emif_mem_0_mem_reset_n),
//.emif_hps_emif_mem_0_mem_par               (emif_hps_emif_mem_0_mem_par),
//.emif_hps_emif_mem_0_mem_alert_n           (emif_hps_emif_mem_0_mem_alert_n),
.emif_hps_emif_mem_0_mem_dqs_t             (emif_hps_emif_mem_0_mem_dqs_t),
.emif_hps_emif_mem_0_mem_dqs_c             (emif_hps_emif_mem_0_mem_dqs_c),
.emif_hps_emif_mem_0_mem_dq                (emif_hps_emif_mem_0_mem_dq),
.emif_hps_emif_oct_0_oct_rzqin             (emif_hps_emif_oct_0_oct_rzqin),
.emif_hps_emif_ref_clk_0_clk               (emif_hps_emif_ref_clk_0_clk),
.emif_hps_emif_mem_0_mem_ca           (emif_hps_emif_mem_0_mem_ca),
.emif_hps_emif_mem_0_mem_dmi          (emif_hps_emif_mem_0_mem_dmi),
.hps_io_sdmmc_cclk                         (hps_sdmmc_CCLK),   
.hps_io_sdmmc_cmd                          (hps_sdmmc_CMD), 
.hps_io_sdmmc_data0                        (hps_sdmmc_D0),          
.hps_io_sdmmc_data1                        (hps_sdmmc_D1),          
.hps_io_sdmmc_data2                        (hps_sdmmc_D2),         
.hps_io_sdmmc_data3                        (hps_sdmmc_D3),        
.hps_io_uart0_rx                           (hps_uart0_RX),          
.hps_io_uart0_tx                           (hps_uart0_TX), 
.hps_io_i2c0_sda                           (hps_i2c0_SDA),
.hps_io_i2c0_scl                           (hps_i2c0_SCL),
.usb31_io_vbus_det                         (usb31_io_vbus_det), 
.usb31_io_flt_bar                          (usb31_io_flt_bar),                   
.usb31_io_usb_ctrl                         (usb31_io_usb_ctrl),
.usb31_io_usb31_id                         (usb31_io_usb31_id),                  
.usb31_phy_refclk_p_clk                    (usb31_phy_refclk_p_clk),             
//.usb31_phy_refclk_n_clk                    (usb31_phy_refclk_p_clk(n)),             
.usb31_phy_rx_serial_n_i_rx_serial_n       (usb31_phy_rx_serial_n_i_rx_serial_n),
.usb31_phy_rx_serial_p_i_rx_serial_p       (usb31_phy_rx_serial_p_i_rx_serial_p),
.usb31_phy_tx_serial_n_o_tx_serial_n       (usb31_phy_tx_serial_n_o_tx_serial_n),
.usb31_phy_tx_serial_p_o_tx_serial_p       (usb31_phy_tx_serial_p_o_tx_serial_p),
.usb31_phy_pma_cpu_clk_clk                 (o_pma_cpu_clk),
.o_pma_cu_clk_clk                          (o_pma_cpu_clk),
.hps_io_usb1_clk                           (hps_usb1_CLK), 
.hps_io_usb1_stp                           (hps_usb1_STP), 
.hps_io_usb1_dir                           (hps_usb1_DIR),
// Todo clarify for NXT or NXR
.hps_io_usb1_nxt                           (hps_usb1_NXT),
.hps_io_usb1_data0                         (hps_usb1_DATA0),
.hps_io_usb1_data1                         (hps_usb1_DATA1), 
.hps_io_usb1_data2                         (hps_usb1_DATA2), 
.hps_io_usb1_data3                         (hps_usb1_DATA3), 
.hps_io_usb1_data4                         (hps_usb1_DATA4), 
.hps_io_usb1_data5                         (hps_usb1_DATA5),
.hps_io_usb1_data6                         (hps_usb1_DATA6), 
.hps_io_usb1_data7                         (hps_usb1_DATA7),
.hps_io_gpio0                          (hps_gpio0_io0),
.hps_io_gpio11                          (hps_gpio0_io11),
.f2h_irq1_in_irq                              (f2h_irq1_irq),
//.fpga2hps_interrupt_irq                      (fpga2hps_interrupt_irq),
.hps_io_hps_osc_clk                        (hps_osc_clk), 
.o_src_rs_grant_src_rs_grant                         (src_grant), 
.i_src_rs_priority_src_rs_priority                   (src_priority),
.i_src_rs_req_src_rs_req                             (src_req),   
.phy_0_gmii8b_tx_clkin_clk                         			(hps_mrphy_tx_clk[0]),	//HA - Check this, connecting to get rid of IOPLL Fitter error  
.phy_0_gmii8b_tx_rst_n_gmii8b_tx_rst_n             			(gmii8b_rst_tx_n[0]),
.phy_0_gmii8b_rx_rst_n_gmii8b_rx_rst_n            			(gmii8b_rst_rx_n[0]),
.phy_0_gmii8b_rx_clkout_clk                         		(mrphy_hps_rx_clk[0]),		
.phy_0_gmii8b_tx_clkout_clk                         		(mrphy_hps_tx_clk[0]),
.phy_0_rx_clkout_clk						(),			
.phy_0_tx_clkout_clk						(),
//.phy_0_rx_clkout_clk						(rx_clkout[0]),			//HA - Exported to get around fitter error
//.phy_0_tx_clkout_clk						(tx_clkout[0]),
.phy_0_rx_digitalreset_rx_digitalreset              		(rx_digitalreset[0]),
.phy_0_tx_digitalreset_tx_digitalreset                      (tx_digitalreset[0]),
.phy_0_gmii8b_mac_txen_export                               (hps_mrphy_data_vld[0]),
.phy_0_gmii8b_mac_tx_d_export                               (hps_mrphy_data[0]),
.phy_0_gmii8b_mac_txer_export                               (hps_mrphy_err[0]),
.phy_0_gmii8b_mac_rxdv_export                       		(mrphy_hps_data_vld[0]),
.phy_0_gmii8b_mac_rxd_export                                (mrphy_hps_data[0]),
.phy_0_gmii8b_mac_rxer_export                               (mrphy_hps_err[0]),
.phy_0_gmii8b_mac_speed_export                              ({mac_speed[0][2],~mac_speed[0][0]}), //ww23.1-conersion logic as shared by Emil //mac_speed[0][1:0]), 
.phy_0_operating_speed_export                               (reg_op_speed[2:0]),
.phy_0_mrphy_pll_lock_pll_locked_stable             		(reg_mrphy_pll_lock[0]),
//.phy_0_i_src_ch_pause_request_o_src_ch_pause_request        (1'b0),
//.phy_0_o_src_ch_pause_grant_i_src_ch_pause_grant            (),
.phy_0_i_rst_n_i_rst_n                                      (o_rst_n[0]),
.phy_0_o_rst_ack_n_o_rst_ack_n                              (ack_rst_n[0]),
.phy_0_i_tx_rst_n_i_tx_rst_n                       			(phy_tx_rst_n[0]),
.phy_0_i_rx_rst_n_i_rx_rst_n                                (phy_rx_rst_n[0]),
.phy_0_o_tx_rst_ack_n_o_tx_rst_ack_n                        (ack_tx_rst_n[0]),
.phy_0_o_rx_rst_ack_n_o_rx_rst_ack_n                        (ack_rx_rst_n[0]),
.phy_0_tx_ready_tx_ready                                    (reg_tx_rdy[0]),
.phy_0_rx_ready_rx_ready                           			(reg_rx_rdy[0]),
.phy_0_xcvr_mode_export                                     (2'b00),				//HA - Check once
.phy_0_i_pma_cu_clk_clk                                     (o_pma_cpu_clk),
.phy_0_i_system_pll_lock_o_pll_lock                    (sys_pll_locked),
.phy_0_i_src_rs_grant_src_rs_grant                          (src_grant[0]),
.phy_0_o_src_rs_req_src_rs_req                     	    (src_req[0]),
.phy_0_tx_serial_data_o_tx_serial_data                      (pp_app_tx_serial_data[0]),  
.phy_0_tx_serial_data_n_o_tx_serial_data_n                  (pp_app_tx_serial_data_n[0]),
.phy_0_rx_serial_data_i_rx_serial_data                      (app_pp_rx_serial_data[0]),  
.phy_0_rx_serial_data_n_i_rx_serial_data_n                  (app_pp_rx_serial_data_n[0]),
.phy_0_rx_is_lockedtodata_o_rx_is_lockedtodata		    (reg_blk_lock[0]),
.phy_0_tx_pll_refclk_p_clk				    (osc_clk),
//.phy_0_tx_pll_refclk_n_clk				    (),
.phy_0_rx_cdr_refclk_p_clk				    (osc_clk),
//.phy_0_rx_cdr_refclk_n_clk				    (),
//.srcss_o_src_rs_grant_src_rs_grant                 (src_grant),
//.srcss_i_src_rs_priority_src_rs_priority           (src_priority),      //Driving to 0
//.srcss_i_src_rs_req_src_rs_req                     (src_req),           
//.srcss_o_pma_cu_clk_clk                  (o_pma_clk),
.rsif0_write                                               (1'b0),
.rsif0_read                                                (1'b0),
.rsif0_address                                             (18'd0),
.rsif0_byteenable                                          (4'h0),
.rsif0_writedata                                           (32'd0),
.rsif0_readdata                                            (),
.rsif0_waitrequest                                         (),
.rsif0_readdatavalid                                       (),
.mm_bridge_0140_017f_m0_waitrequest	(mm_bridge_0140_017f_m0_waitrequest), 
.mm_bridge_0140_017f_m0_readdata	(mm_bridge_0140_017f_m0_readdata),     
.mm_bridge_0140_017f_m0_readdatavalid	(mm_bridge_0140_017f_m0_readdatavalid),
.mm_bridge_0140_017f_m0_burstcount	(),   
.mm_bridge_0140_017f_m0_writedata	(),    
.mm_bridge_0140_017f_m0_address		(),      
.mm_bridge_0140_017f_m0_write		(mm_bridge_0140_017f_m0_write),        
.mm_bridge_0140_017f_m0_read		(mm_bridge_0140_017f_m0_read),        
.mm_bridge_0140_017f_m0_byteenable	(),   
.mm_bridge_0140_017f_m0_debugaccess	(),
.mm_bridge_0380_03ff_m0_waitrequest	(mm_bridge_0380_03ff_m0_waitrequest), 
.mm_bridge_0380_03ff_m0_readdata	(mm_bridge_0380_03ff_m0_readdata),    
.mm_bridge_0380_03ff_m0_readdatavalid	(mm_bridge_0380_03ff_m0_readdatavalid),
.mm_bridge_0380_03ff_m0_burstcount	(),   
.mm_bridge_0380_03ff_m0_writedata	(),    
.mm_bridge_0380_03ff_m0_address		(),      
.mm_bridge_0380_03ff_m0_write		(mm_bridge_0380_03ff_m0_write),        
.mm_bridge_0380_03ff_m0_read		(mm_bridge_0380_03ff_m0_read),         
.mm_bridge_0380_03ff_m0_byteenable	(),   
.mm_bridge_0380_03ff_m0_debugaccess	(),   	
.mm_bridge_0180_01ff_m0_waitrequest	(mm_bridge_0180_01ff_m0_waitrequest), 
.mm_bridge_0180_01ff_m0_readdata	(mm_bridge_0180_01ff_m0_readdata),    
.mm_bridge_0180_01ff_m0_readdatavalid	(mm_bridge_0180_01ff_m0_readdatavalid),
.mm_bridge_0180_01ff_m0_burstcount	(),   
.mm_bridge_0180_01ff_m0_writedata	(),    
.mm_bridge_0180_01ff_m0_address		(),     
.mm_bridge_0180_01ff_m0_write		(mm_bridge_0180_01ff_m0_write),       
.mm_bridge_0180_01ff_m0_read		(mm_bridge_0180_01ff_m0_read),       
.mm_bridge_0180_01ff_m0_byteenable	(),
.mm_bridge_0180_01ff_m0_debugaccess	(),  
.mm_bridge_0200_02ff_m0_waitrequest	(mm_bridge_0200_02ff_m0_waitrequest),  
.mm_bridge_0200_02ff_m0_readdata	(mm_bridge_0200_02ff_m0_readdata),     
.mm_bridge_0200_02ff_m0_readdatavalid	(mm_bridge_0200_02ff_m0_readdatavalid),
.mm_bridge_0200_02ff_m0_burstcount	(),   
.mm_bridge_0200_02ff_m0_writedata	(),    
.mm_bridge_0200_02ff_m0_address		(),      
.mm_bridge_0200_02ff_m0_write		(mm_bridge_0200_02ff_m0_write),        
.mm_bridge_0200_02ff_m0_read		(mm_bridge_0200_02ff_m0_read),         
.mm_bridge_0200_02ff_m0_byteenable	(),  
.mm_bridge_0200_02ff_m0_debugaccess	(),  
.mm_bridge_0400_07ff_m0_waitrequest	(mm_bridge_0400_07ff_m0_waitrequest),  
.mm_bridge_0400_07ff_m0_readdata	(mm_bridge_0400_07ff_m0_readdata),     
.mm_bridge_0400_07ff_m0_readdatavalid	(mm_bridge_0400_07ff_m0_readdatavalid),
.mm_bridge_0400_07ff_m0_burstcount	(),   
.mm_bridge_0400_07ff_m0_writedata	(),    
.mm_bridge_0400_07ff_m0_address		(),      
.mm_bridge_0400_07ff_m0_write		(mm_bridge_0400_07ff_m0_write),        
.mm_bridge_0400_07ff_m0_read		(mm_bridge_0400_07ff_m0_read),         
.mm_bridge_0400_07ff_m0_byteenable	(),  
.mm_bridge_0400_07ff_m0_debugaccess	(),  
.intel_systemclk_gts_0_o_pll_lock_o_pll_lock                (sys_pll_locked),
.intel_systemclk_gts_0_refclk_xcvr_clk			    (osc_clk),
.i_refclk_rdy_data                                          (1'b1),				//Driving this to 1
.iopll_locked_export								(io_pll_locked),
.iopll_reset_reset  								(pll_reset),
//.iopll_80m_clk_clk  								(),  //clock speed 80M latency_sclk -these both connected internally
//.iopll_153m_clk_clk 								(),  //clock speed 153Mhz for DL(latency_measure_clk)
.mm_bridge_0_m0_waitrequest                                 (csr_waitrequest),
.mm_bridge_0_m0_readdata                                    (csr_readdata),
.mm_bridge_0_m0_readdatavalid                      			(csr_readdatavalid),
.mm_bridge_0_m0_burstcount                                  (csr_burstcount),
.mm_bridge_0_m0_writedata                                   (csr_writedata),
.mm_bridge_0_m0_address                                     (csr_address),
.mm_bridge_0_m0_write                                       (csr_write),
.mm_bridge_0_m0_read                               			(csr_read),
.mm_bridge_0_m0_byteenable                                  (csr_byteenable),
.mm_bridge_0_m0_debugaccess                                 (csr_debugaccess),
.phy_rst_reset                                              (phy_reset),
.avmm_reset_reset					    (avmm_rst),
.reset_reset_n                             (~system_reset)
);
		//Reset controller
		rst_ctrl #(.NUM_PHY(NUM_PHY)) rst_ctrl_inst (
			.app_pp_h2f_reset							 (h2f_reset),
			.app_pp_system_rst_n						 (~system_reset),
			.app_pp_system_clk							 (fpga_clk_100),
			.app_pp_ninit_done							 (ninit_done),
			.app_pp_pll_locked							 (io_pll_locked),    	//Connect this to iopll_locked_export (io_pll_locked),
			.pp_app_pll_rst								 (pll_reset),		//Connect this to iopll_reset_reset
			.pp_app_csr_rst_n							 (csr_rst),
			.pp_app_avmm_rst							 (avmm_rst),
			.csr_o_rst_n								 (csr_o_rst_n),
			.sync_ack_i_rst_n							 (sync_ack_i_rst_n),
			.sync_mrphy_pll_lock_i						 (sync_mrphy_pll_lock_i),
			.sync_rx_ready_i							 (sync_rx_ready_i),
			.sync_tx_ready_i							 (sync_tx_ready_i),
			.o_rst_n									 (o_rst_n),
			.emac_mac_rst_tx_n							 (emac_mac_rst_tx_n),
			.emac_mac_rst_rx_n							 (emac_mac_rst_rx_n),
			.phy_reset                                   (phy_reset),
			.gmii8b_rst_tx_n                             (gmii8b_rst_tx_n),
			.tx_digitalreset                             (tx_digitalreset),
			.gmii8b_rst_rx_n                             (gmii8b_rst_rx_n),
			.rx_digitalreset							 (rx_digitalreset)
		); 
	
		//CSR Register space
		csr_shell #(.NUM_PHY(NUM_PHY)) usr_csr_space (
			//input
			.csr_clk		     	(fpga_clk_100),
			.reset					(avmm_rst),
			.csr_wr_data			(csr_writedata),
			.csr_read				(csr_read),			
            .csr_write				(csr_write),
            .csr_byteenable			(csr_byteenable),
            .csr_address			(csr_address),
			.csr_waitrequest		(csr_waitrequest),	
			.csr_rd_data			(csr_readdata),
			.csr_rd_vld				(csr_readdatavalid),
			.mrphy_pll_lock_i	    (reg_mrphy_pll_lock),
	    	.rx_ready_i				(reg_rx_rdy),
	    	.tx_ready_i             (reg_tx_rdy),
	    	.rx_block_lock_i        (reg_blk_lock),					//Check1 - if this connection is correct
	    	.reg_op_speed            (reg_op_speed),
	    	.ack_i_rst_n            (ack_rst_n),
            .ack_i_tx_rst_n         (ack_tx_rst_n),
            .ack_i_rx_rst_n         (ack_rx_rst_n),
            .we_dr_err_stat_i       (1'b0),							//Check1 - Temp, Driving to 0
            .phy_delay_i			(16'b0),							//Check1 - Temp, Driving to 0
			.csr_o_rst_n			(csr_o_rst_n),
			.o_tx_rst_n			(phy_tx_rst_n),
			.o_rx_rst_n			(phy_rx_rst_n),
			.sync_ack_i_rst_n		(sync_ack_i_rst_n),
			.sync_mrphy_pll_lock_i	(sync_mrphy_pll_lock_i),
			.sync_rx_ready_i		(sync_rx_ready_i),
			.sync_tx_ready_i		(sync_tx_ready_i)
	);

		tsn_rsvd_csr  #(.DATA_WIDTH(16)) 
				csr_0140_017f
			  ( .clk					(fpga_clk_100),
				.rst					(avmm_rst),
				.write_i				(mm_bridge_0140_017f_m0_write),
				.read_i					(mm_bridge_0140_017f_m0_read),
				.waitrequest_o			(mm_bridge_0140_017f_m0_waitrequest),
				.readdata_o				(mm_bridge_0140_017f_m0_readdata),
				.readdatavalid_o		(mm_bridge_0140_017f_m0_readdatavalid)			
		);
		
		tsn_rsvd_csr csr_0380_03ff (
				.clk					(fpga_clk_100),
				.rst					(avmm_rst),
				.write_i				(mm_bridge_0380_03ff_m0_write),
				.read_i					(mm_bridge_0380_03ff_m0_read),
				.waitrequest_o			(mm_bridge_0380_03ff_m0_waitrequest),
				.readdata_o				(mm_bridge_0380_03ff_m0_readdata),
				.readdatavalid_o		(mm_bridge_0380_03ff_m0_readdatavalid)			
		);


		tsn_rsvd_csr #(.DATA_WIDTH(16))
		csr_0180_01ff 
			(	.clk					(fpga_clk_100),
				.rst					(avmm_rst),
				.write_i				(mm_bridge_0180_01ff_m0_write),
				.read_i					(mm_bridge_0180_01ff_m0_read),
				.waitrequest_o			(mm_bridge_0180_01ff_m0_waitrequest),
				.readdata_o				(mm_bridge_0180_01ff_m0_readdata),
				.readdatavalid_o		(mm_bridge_0180_01ff_m0_readdatavalid)			
		);

		tsn_rsvd_csr csr_0200_02ff (
				.clk					(fpga_clk_100),
				.rst					(avmm_rst),
				.write_i				(mm_bridge_0200_02ff_m0_write),
				.read_i					(mm_bridge_0200_02ff_m0_read),
				.waitrequest_o			(mm_bridge_0200_02ff_m0_waitrequest),
				.readdata_o				(mm_bridge_0200_02ff_m0_readdata),
				.readdatavalid_o		(mm_bridge_0200_02ff_m0_readdatavalid)			
		);
	
		tsn_rsvd_csr csr_0400_07ff (
				.clk					(fpga_clk_100),
				.rst					(avmm_rst),
				.write_i				(mm_bridge_0400_07ff_m0_write),
				.read_i					(mm_bridge_0400_07ff_m0_read),
				.waitrequest_o			(mm_bridge_0400_07ff_m0_waitrequest),
				.readdata_o				(mm_bridge_0400_07ff_m0_readdata),
				.readdatavalid_o		(mm_bridge_0400_07ff_m0_readdatavalid)			
		);
		
		


assign c3_emac0_mdio_mdio0 = pp_app_emac0_mdio_mdoe0 ? pp_app_emac0_mdio_mdo0 : 1'bz;
assign app_pp_emac0_mdio_mdi0  = c3_emac0_mdio_mdio0;


assign src_priority = 'b0;


// debounce fpga_reset_n
debounce fpga_reset_n_debounce_inst (
.clk                                       (system_clk_100_internal),
.reset_n                                   (~ninit_done),
.data_in                                   (fpga_reset_n),
.data_out                                  (fpga_reset_n_debounced_wire)
);
defparam fpga_reset_n_debounce_inst.WIDTH = 1;
defparam fpga_reset_n_debounce_inst.POLARITY = "LOW";
defparam fpga_reset_n_debounce_inst.TIMEOUT = 10000;               // at 100Mhz this is a debounce time of 1ms
defparam fpga_reset_n_debounce_inst.TIMEOUT_WIDTH = 32;            // ceil(log2(TIMEOUT))

always @ (posedge system_clk_100_internal or posedge ninit_done)
begin
    if (ninit_done == 1'b1)
        fpga_reset_n_debounced <= 1'b0;
    else
        fpga_reset_n_debounced <= fpga_reset_n_debounced_wire;  
end


endmodule
