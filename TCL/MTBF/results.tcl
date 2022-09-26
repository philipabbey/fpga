# source -notrace {A:\Philip\Work\VHDL\MTBF\results.tcl}

set_property part xczu2cg-sbva484-2-e [current_project]
set num_bits 4
set design synth_1
set jobs 6
# Saved to the local directory
set resultsfile {results.log}

set logfile [open $resultsfile a]
puts $logfile "------------- Configuration -----------------"
puts $logfile "Part:    [get_project_part]"
puts $logfile "Version: [version -short]"
puts $logfile "---------------------------------------------"
close $logfile

for {set reg_depth 2} {$reg_depth <= 5} {incr reg_depth} {
  puts "Loop for reg_depth_g=$reg_depth"
  set_property generic "num_bits_g=$num_bits reg_depth_g=$reg_depth" [current_fileset]
  set d [current_design -quiet]
  if {[llength $d] > 0} {
      puts "Closing design [lindex $d 0]"
      close_design
  }
  reset_run $design
  launch_runs $design -jobs $jobs
  wait_on_run $design
  open_run $design -name $design
  show_schematic [list [get_ports *] [get_cells -hier *]]
  colour_selected_primitives_by_clock_source [get_cells -hier *]

  set logfile [open $resultsfile a]
  puts $logfile ""
  puts $logfile ""
  puts $logfile "------------- New Run -----------------"
  puts $logfile "Generics: [get_property generic [current_fileset]]"
  puts $logfile "clk_src:  [get_property PERIOD [get_clocks clk_src]] ns"
  puts $logfile "clk_dest: [get_property PERIOD [get_clocks clk_dest]] ns"
  puts $logfile "---------------------------------------"
  close $logfile
  report_synchronizer_mtbf -no_header -file $resultsfile -append
}
