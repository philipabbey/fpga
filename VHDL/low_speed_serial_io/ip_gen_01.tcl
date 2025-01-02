#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to generate two PLLs and a FIFO with a specified clock frequency for the
# LSSIO interface using 01 sampling and configure the FPGA to test.
#
# source -notrace {<path>\ip_gen.tcl}
#
# P A Abbey, 19 December 2024
#
#####################################################################################

set src [file dirname [get_files *zybo_z7_10.vhdl]]
set ip_dest_file $src/ip

# Clock speed (MHz) for the Low Speed Serial IO under test
# Minimum is supposedly 10 MHz, but synthesis struggled with that value due to jitter setting. 20 MHz was allowed.
# Ref: https://www.01signal.com/electronics/01-signal-sampling/
# "If @stable_clk is three times as fast as @data_clk, that is often enough."
set lssio_freq  135.000
set sample_freq 400.000

foreach ip_inst {fifo_rx pll} {
  puts "NOTE - Creating IP '$ip_inst'"
  set ip_xci $ip_dest_file/$ip_inst/$ip_inst.xci

  # Delete the old version of the PLL before recreating a new
  set temp [get_ips -quiet $ip_inst]
  if {[llength $temp] > 0} {
    set temp [get_property IP_FILE $temp]
    if {[llength $temp] > 0} {
      puts "NOTE - Deleting old IP '$ip_inst'"
      export_ip_user_files -of_objects $temp -no_script -reset -force -quiet
      remove_files -fileset $ip_inst $temp -quiet
    }
  }
  unset temp
  if {[file isdirectory $ip_dest_file/$ip_inst]} {
    file delete -force $ip_dest_file/$ip_inst
  }

  switch $ip_inst {
    pll {
      create_ip \
        -name        clk_wiz \
        -vendor      xilinx.com \
        -library     ip \
        -version     6.0 \
        -module_name $ip_inst \
        -dir         $ip_dest_file

      # The board clock is 125 MHz and fixed.
      set_property \
        -dict [list \
          CONFIG.PRIMITIVE                  {PLL} \
          CONFIG.PRIM_IN_FREQ               {125.000} \
          CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $lssio_freq \
          CONFIG.CLKOUT1_REQUESTED_PHASE    {0.000} \
          CONFIG.CLKOUT2_USED               {true} \
          CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $sample_freq \
          CONFIG.CLKOUT2_REQUESTED_PHASE    {0.000} \
          CONFIG.USE_SAFE_CLOCK_STARTUP     {true} \
          CONFIG.FEEDBACK_SOURCE            {FDBK_AUTO} \
          CONFIG.USE_RESET                  {false} \
          CONFIG.USE_LOCKED                 {true} \
          CONFIG.PRIMARY_PORT               {clk_in} \
          CONFIG.CLK_OUT1_PORT              {clk_out} \
        ] \
        [get_ips $ip_inst]
    }
    fifo_rx {
      create_ip \
        -name        fifo_generator \
        -vendor      xilinx.com \
        -library     ip \
        -version     13.2 \
        -module_name $ip_inst \
        -dir         $ip_dest_file

      set_property \
        -dict [list \
          CONFIG.INTERFACE_TYPE               {Native} \
          CONFIG.Fifo_Implementation          {Independent_Clocks_Distributed_RAM} \
          CONFIG.Performance_Options          {Standard_FIFO} \
          CONFIG.synchronization_stages       {2} \
          CONFIG.Input_Data_Width             {3} \
          CONFIG.Input_Depth                  {16} \
          CONFIG.Dout_Reset_Value             {0} \
          CONFIG.Enable_Reset_Synchronization {true} \
          CONFIG.Full_Flags_Reset_Value       {1} \
        ] \
        [get_ips $ip_inst]
    }
  }

  set ip_xci [get_files $ip_dest_file/$ip_inst/$ip_inst.xci]

  generate_target all $ip_xci

  export_ip_user_files \
    -of_objects $ip_xci \
    -no_script \
    -sync \
    -force \
    -quiet

  create_ip_run $ip_xci
  launch_runs -jobs 6 ${ip_inst}_synth_1

  export_simulation \
    -of_objects          $ip_xci \
    -directory           $ip_dest_file/$ip_inst/sim_scripts \
    -ip_user_files_dir   $ip_dest_file/$ip_inst/ip_user_files \
    -ipstatic_source_dir $ip_dest_file/$ip_inst/ipstatic \
    -lib_map_path [list \
      "modelsim=$ip_dest_file/$ip_inst/compile_simlib/modelsim" \
      "questa=$ip_dest_file/$ip_inst/compile_simlib/questa" \
      "riviera=$ip_dest_file/$ip_inst/compile_simlib/riviera" \
      "activehdl=$ip_dest_file/$ip_inst/compile_simlib/activehdl" \
    ] \
    -use_ip_compiled_libs \
    -force \
    -quiet
}

set pll_inst [get_ips pll]
set clk_req [get_property CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $pll_inst]
set clk_set1 [expr \
  [get_property CONFIG.PRIM_IN_FREQ          $pll_inst] * \
  [get_property CONFIG.MMCM_CLKFBOUT_MULT_F  $pll_inst] / \
  [get_property CONFIG.MMCM_DIVCLK_DIVIDE    $pll_inst] / \
  [get_property CONFIG.MMCM_CLKOUT0_DIVIDE_F $pll_inst]   \
]
if { ($clk_req > $clk_set1 * 0.95) && ($clk_req < $clk_set1 * 1.005) } {
  puts "NOTE - '$pll_inst' data clock got the requested clock frequency of $clk_req MHz +/- 0.5% ($clk_set1 MHz)."
} else {
  puts "WARNING - '$pll_inst' data clock requested clock frequency of $clk_req MHz, got $clk_set1 MHz."
}
set clk_req [get_property CONFIG.CLKOUT2_REQUESTED_OUT_FREQ $pll_inst]
set clk_set2 [expr \
  [get_property CONFIG.PRIM_IN_FREQ          $pll_inst] * \
  [get_property CONFIG.MMCM_CLKFBOUT_MULT_F  $pll_inst] / \
  [get_property CONFIG.MMCM_DIVCLK_DIVIDE    $pll_inst] / \
  [get_property CONFIG.MMCM_CLKOUT1_DIVIDE   $pll_inst]   \
]
if { ($clk_req > $clk_set2 * 0.95) && ($clk_req < $clk_set2 * 1.005) } {
  puts "NOTE - '$pll_inst' sample clock got the requested clock frequency of $clk_req MHz +/- 0.5% ($clk_set2 MHz)."
} else {
  puts "WARNING - '$pll_inst' sample clock requested clock frequency of $clk_req MHz, got $clk_set2 MHz."
}
puts "Ratio of sample to data clocks is [expr $clk_set2 / $clk_set1]"
unset pll_inst clk_req clk_set1 clk_set2

# Synthesise the design
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 14
wait_on_runs impl_1

#open_run impl_1
#report_timing \
#  -through [get_nets {rx[*]}] \
#  -delay_type min_max \
#  -max_paths 10 \
#  -sort_by group \
#  -input_pins \
#  -routable_nets \
#  -name {[get_nets {rx[*]}]}

# Reconfigure the FPGA
open_hw_manager
connect_hw_server -allow_non_jtag -quiet
open_hw_target
set device [get_hw_devices xc7z010_1]
current_hw_device $device
set_property PROGRAM.FILE "[get_property DIRECTORY [get_runs impl_1]]/zybo_z7_10.bit" $device
set_property PROBES.FILE {} $device
set_property FULL_PROBES.FILE {} $device
program_hw_devices $device
refresh_hw_device -update_hw_probes false [lindex $device 0]
close_hw_manager
puts "Target programmed"
