#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to colour clocked primitives by clock source for visualisation.
#
# Usage:
#   source -notrace ${srcdir}/parts.tcl
#
# Reference:
#   https://blog.abbey1.org.uk/index.php/technology/determining-a-device-s-maximum-clock-speed
#
#####################################################################################

set srcdir {path1/speed_test}
# Path and prefix to Vivado project
set destdir {path2/speed_test/speed_test}

set resfilename "${srcdir}/fmax.txt"
set projdir [get_property DIRECTORY [current_project]]

proc fmax {} {
    set tp [get_timing_paths -max_paths 1 -nworst 1 -setup]
    set maxSetup [get_property SLACK $tp]
    set maxClkPeriod [expr [get_property REQUIREMENT $tp] - $maxSetup]
    # MHz divide by ns * MHz => (1e-9 * 1e6) = 1e-3
    return [expr 1e3 / $maxClkPeriod]
}

# ERROR: [Common 17-577] Internal error: No controller created for part xc7z007sclg400-2. Maximum number of controllers reached!
# WARNING: [Device 21-150] Attempt to create more than 16 speed controllers
#
# Need to have a restartable list as only about 11 devices are tested before Vivado crashes with a part cache error. The remedy
# is to restart Vivado and pick up.
#set parts [get_parts -filter {(SPEED == -2) && (TEMPERATURE_GRADE_LETTER == I || TEMPERATURE_GRADE_LETTER == "")}]
set parts [get_parts {xc7a12tcsg325-2 xczu2cg-sbva484-2-i}]
set devices {}
set cnt 0
set total [llength $parts]

# Initialise this from the existing results file
set devices_done {}
if {[file exists $resfilename]} {
  set resfile [open $resfilename r]
  set linenum 0
  while {[gets $resfile line] >= 0} {
    if {$linenum > 0} {
      if {[string length $line] > 0} {
        set p [get_parts -quiet [lindex [split $line ","] 0]]
        if {[string length $p] > 0} {
          set key "[get_property DEVICE $p][get_property SPEED $p]"
          lappend devices_done $key
        }
      }
    }
    incr linenum
  }
  close $resfile
  puts "NOTE: devices_done = $devices_done"
  set resfile [open $resfilename a+]
} else {
  puts "NOTE: Checking all devices"
  set resfile [open $resfilename a+]
  puts $resfile "Part,Architecture,Device,Speed,Temperature,Flip-flops,LUTs,DSP,BlockRAMs,Slices,Fmax (MHz)"
  flush $resfile
}

foreach i $parts {
  incr cnt
  set key "[get_property DEVICE $i][get_property SPEED $i]"
  # Only try each sort of device once, the results are similar
  if {[lsearch -exact $devices_done $key] == -1} {
    foreach ip [get_ips] {
        set_property is_enabled true [get_files [get_property IP_FILE $ip]]
    }
    # clk_wiz_1 for Artix-7 or Spartan-7, clk_wiz_0 otherwise
    # NB. The VHDL file does not automatically switch the instance used.
    if {[get_property ARCHITECTURE_FULL_NAME $i] == "Artix-7"   ||
        [get_property ARCHITECTURE_FULL_NAME $i] == "Spartan-7" ||
        [get_property ARCHITECTURE_FULL_NAME $i] == "Kintex-7"} {
        set clkwiz [get_ips clk_wiz_1]
        set_property generic clk_wiz_g=1 [current_fileset]
        set_property is_enabled false [get_files [get_property IP_FILE [get_ips clk_wiz_0]]]
    } else {
        set clkwiz [get_ips clk_wiz_0]
        set_property generic clk_wiz_g=0 [current_fileset]
        set_property is_enabled false [get_files [get_property IP_FILE [get_ips clk_wiz_1]]]
    }
    set_property -quiet part $i [current_project]

    upgrade_ip \
      -vlnv xilinx.com:ip:clk_wiz:6.0 \
      -log ip_upgrade.log \
      -quiet \
      $clkwiz

    reset_target -quiet all $clkwiz

    # Can't extract the maximum BUFG frequency for CLKOUT1_REQUESTED_OUT_FREQ
    set_property -dict [list \
      CONFIG.PRIM_IN_FREQ {100.000} \
      CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {400.000} \
      CONFIG.USE_LOCKED {false} \
    ] $clkwiz

    validate_ip -save_ip $clkwiz
    generate_target -quiet -force all $clkwiz

    export_ip_user_files \
      -of_objects $clkwiz \
      -no_script \
      -sync \
      -force \
      -quiet

    create_ip_run -force $clkwiz
    reset_run -quiet ${clkwiz}_synth_1
    launch_runs ${clkwiz}_synth_1 -jobs 1

    export_simulation \
      -of_objects $clkwiz \
      -directory ${destdir}.ip_user_files/sim_scripts \
      -ip_user_files_dir ${destdir}.ip_user_files \
      -ipstatic_source_dir ${destdir}.ip_user_files/ipstatic \
      -lib_map_path [list \
        {modelsim=${destdir}.cache/compile_simlib/modelsim} \
        {questa=${destdir}.cache/compile_simlib/modelsim} \
        {riviera=${destdir}.cache/compile_simlib/riviera} \
        {activehdl=${destdir}.cache/compile_simlib/activehdl} \
      ] \
      -use_ip_compiled_libs \
      -force \
      -quiet

    reset_run -quiet synth_1
    launch_runs impl_1
    # 'wait_on_runs' replaces 'wait_on_run' by Vivado version 2023.2
    wait_on_runs impl_1
    open_run impl_1
    lappend devices_done $key
    puts $resfile "$i,[get_property ARCHITECTURE_FULL_NAME $i],[get_property DEVICE $i],[get_property SPEED $i],[get_property TEMPERATURE_GRADE_LETTER $i],[get_property FLIPFLOPS $i],[get_property LUT_ELEMENTS $i],[get_property DSP $i],[get_property BLOCK_RAMS $i],[get_property SLICES $i],[fmax]"
    flush $resfile
    close_design
    puts "NOTE: $i tested, $cnt of $total completed."
  } else {
    puts "NOTE: $i skipped, $cnt of $total completed."
  }
}

close $resfile
