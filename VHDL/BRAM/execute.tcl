# source -notrace {execute.tcl}

proc reportClkSpeed {} {
  # Check for setup violations (-delay_type max)
  set maxSetup [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
  puts "Setup: Get max delay timing path (ns): $maxSetup"
  # Check for hold violations (-delay_type min)
  puts -nonewline "Hold:  Get min delay timing path (ns): "
  puts [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -hold]]
  set maxClkPeriod [expr [get_property REQUIREMENT [get_timing_paths -max_paths 1 -nworst 1 -setup]] - $maxSetup]
  set maxClkFreq [expr 1/($maxClkPeriod * 1e-9) / 1e6]
  # Alter to 1 decimal place
  set maxClkFreq [expr {double(round($maxClkFreq * 10)) / 10}]
  puts "Maximum clock period (ns):             [format "%0.3f" $maxClkPeriod]"
  puts "Maximum clock frequency (MHz):         $maxClkFreq"
}

proc calcClkSpeed {} {
  # Check for setup violations (-delay_type max)
  set maxSetup [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
  set maxClkPeriod [expr [get_property REQUIREMENT [get_timing_paths -max_paths 1 -nworst 1 -setup]] - $maxSetup]
  set maxClkFreq [expr 1/($maxClkPeriod * 1e-9) / 1e6]
  # Alter to 1 decimal place
  set maxClkFreq [expr {double(round($maxClkFreq * 10)) / 10}]
  return $maxClkFreq;
}

set_property STEPS.SYNTH_DESIGN.ARGS.MAX_BRAM_CASCADE_HEIGHT -1 [get_runs synth_1]

#refresh_design
if {[get_property PROGRESS [get_runs synth_1]] == "100%"} {
    reset_run synth_1
}

set_property generic \
    {ram_width_g=36 ram_addr_g=12 output_register_g=true} \
    [current_fileset]

# RTL Elaboration
synth_design \
    -rtl \
    -name rtl_1 \
    -top my_ram \
    -mode out_of_context

# Synthesis
launch_runs synth_1 -jobs 6
wait_on_run synth_1
open_run synth_1 -name synth_1

# Get timing information
report_timing_summary \
    -delay_type min_max \
    -report_unconstrained \
    -check_timing_verbose \
    -max_paths 10 \
    -input_pins \
    -routable_nets \
    -name timing_1
reportClkSpeed
