# Validate and generate VDS systems for standalone sim.
# Usage (from staged DUT_SRC):
#   xvfb-run -a quartus_sh -t generate_vds_sim.tcl <top.qpf> <dut_sim_dir> <meta_file>

set launch_dir [pwd]
if {$argc < 3} {
    puts "ERROR: usage: generate_vds_sim.tcl <top.qpf> <dut_sim_dir> <meta_file>"
    exit 1
}
set qpf_path  [lindex $argv 0]
set dut_sim   [lindex $argv 1]
set meta_file [lindex $argv 2]

load_package project
load_package vds
cd $launch_dir

proc fail {msg} {
    puts "ERROR: $msg"
    exit 1
}

set qpf_dir [file dirname [file normalize $qpf_path]]
cd $qpf_dir

project_open -revision top [file rootname [file tail $qpf_path]]

set qver [get_quartus_legal_string -version]
puts "Quartus version string: $qver"
if {![regexp {26\.1} $qver]} {
    fail "Quartus 26.1 required, got: $qver"
}

set family [get_global_assignment -name FAMILY]
set device [get_global_assignment -name DEVICE]
set topent [get_global_assignment -name TOP_LEVEL_ENTITY]
puts "FAMILY=$family DEVICE=$device TOP=$topent"

if {$family ne "Agilex 3"} {
    fail "Expected FAMILY Agilex 3, got '$family'"
}
if {$device ne "A3CW135BM16AE6S"} {
    fail "Expected DEVICE A3CW135BM16AE6S, got '$device'"
}
if {$topent ne "agilex5_top"} {
    fail "Expected TOP_LEVEL_ENTITY agilex5_top, got '$topent'"
}

# get_all_global_assignments returns a collection handle even when empty —
# inspect members, do not use llength on the handle string.
set qsys_count 0
set qsys_vals {}
foreach_in_collection asgn [get_all_global_assignments -name QSYS_FILE] {
    incr qsys_count
    lappend qsys_vals [lindex $asgn 2]
}
if {$qsys_count > 0} {
    fail "Active QSYS_FILE assignment(s) present; VDS-only project required: $qsys_vals"
}

set meta [open $meta_file w]
puts $meta "quartus_version=$qver"
puts $meta "family=$family"
puts $meta "device=$device"
puts $meta "top_entity=$topent"
puts $meta "qpf=$qpf_path"
puts $meta "cwd=[pwd]"

foreach system {hps_subsys tsn_subsys qsys_top} {
    puts "=== Opening / validating / generating $system ==="
    puts $meta "system_begin=$system"
    vds::open_system $system
    vds::validate_system
    vds::save_system
    # Preserve agilex5_top as Quartus top-level entity
    vds::update_project_setting -incremental -no_entity
    # Synthesis + Synopsys VCS MX simulation file sets (SPD) for ip-setup-simulation.
    puts "Generating VDS synthesis+simulation HDL for $system"
    puts $meta "generate_cmd=vds::generate_system -synthesis VERILOG -simulation VERILOG -simulator VCSMX -parallel -altera_pragmas"
    if {[catch {vds::generate_system -synthesis VERILOG -simulation VERILOG -simulator VCSMX -parallel -altera_pragmas} gen_err]} {
        # Retry with VCS if VCSMX token is rejected on this install
        puts "WARN: VCSMX generate failed ($gen_err); retrying with -simulator VCS"
        puts $meta "generate_retry=vds::generate_system -synthesis VERILOG -simulation VERILOG -simulator VCS -parallel -altera_pragmas"
        if {[catch {vds::generate_system -synthesis VERILOG -simulation VERILOG -simulator VCS -parallel -altera_pragmas} gen_err2]} {
            close $meta
            fail "vds::generate_system failed for $system: $gen_err2"
        }
    }
    vds::close_system $system

    set gen_dir [file join [pwd] gen vds $system]
    if {![file isdirectory $gen_dir]} {
        close $meta
        fail "Missing generated HDL directory for $system: $gen_dir"
    }
    puts $meta "gen_dir_${system}=$gen_dir"
    puts $meta "system_end=$system"
}

project_close
puts $meta "status=OK"
close $meta

puts "VDS validate/generate complete. Meta: $meta_file"
cd $launch_dir
