// Thin wrapper over shared TB filelists + 1-port assert
-f $VERIF_ROOT/flist/defines.f
-f $VERIF_ROOT/flist/dut.f
-f $TB_PATH/flist/svt_axi_vip.flist
-f $TB_PATH/flist/vip_files.f
-f $TB_PATH/flist/tsn_tb_files.f
$VERIF_ROOT/flist/num_phy_assert.sv
