#####################################################################################
##
## Distributed under MIT Licence
##   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
##
#####################################################################################
##
## Out of Context constraints for transfer.vhd in order to experiment with false path
## specification methods.
##
## References:
##  * Specifying Boundary Timing Constraints in Vivado
##    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
##
## P A Abbey, 5 December 2021
##
#####################################################################################

#
# Getting these from timing reports is painful, but only needs doing once per device/part
# Uncomment the required delays based on your project's ${PART}
#
# Use this TCL to generate the correct reports:
#
# config_timing_corners -corner Slow -delay_type max
# config_timing_corners -corner Fast -delay_type none
# report_timing_summary -delay_type max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name slow_max
# config_timing_corners -corner Slow -delay_type min
# report_timing_summary -delay_type min -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name slow_min
#
# Revert the timing corners and generate the full static timing analysis report:
#
# config_timing_corners -corner Slow -delay_type min_max
# config_timing_corners -corner Fast -delay_type min_max
# report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_1

# Remove any lingering hang-over results and start again, this seems to become necessary
# when using TCL-based constraints file. NB. the OOC constraint files must be at the top
# of the list in order to be processed first.
reset_timing -quiet

# Clock uncertainty (from a timing report), looks to be device independent
set tcu 0.035

# Part: xc7k70tfbv676-1
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Slow Process, max delay for Setup times)
set tsus 0.034
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Slow Process, min delay for Hold times)
set ths 0.218

# Choose these:
#
# Extra slack (on hold time), designer's choice
set txs 0.008
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000
 
create_clock -period 5.000 -name clk_src1 [get_ports clk_src1]
create_clock -period 8.000 -name clk_src2 [get_ports clk_src2]
create_clock -period 4.000 -name clk_dest [get_ports clk_dest]

# Standard timing setup, allocate the device delays into the meaningful variables
#
# https://www.xilinx.com/publications/prod_mktg/club_vivado/presentation-2015/paris/Xilinx-TimingClosure.pdf
# Recommended technique for over-constraining a design (can complain if applied at elaboration,
# but still gets applied to synthesis):
if {[string match "rtl*" [get_design -quiet]]} {
    puts "Skipping 'set_clock_uncertainty' command as this is only an elaborated design."
} else {
    set_clock_uncertainty -quiet -setup $tcu_add [get_clocks]
}
 
# Input Hold = Input Setup (slow corner)
set input_delay [expr $ths + $tcu + $txs]
# Output Hold = Output Setup (slow corner)
set output_delay $tsus

# Automatically determine the clock domain of each input and output, and assign the appropriate delay.
if {[llength [info procs setup_port_constraints]] == 1} {
    setup_port_constraints $input_delay $output_delay 1
} else {
    puts "You need to 'source -notrace {/path/to/out_of_context_synth_lib.tcl}' first."
}

# Manage False Paths

# Method 1 - Global and indescriminate, but Xilinx seems to prefer it
#set_clock_groups    \
#  -asynchronous     \
#  -group [get_clocks {clk_src1}] \
#  -group [get_clocks {clk_src2}] \
#  -group [get_clocks {clk_dest}]

# Method 2 - More specific clock directions, but now all clock transitions have to be specified individually
#set_false_path -from [get_clocks clk_src1] -to [get_clocks clk_dest]
#set_false_path -from [get_clocks clk_dest] -to [get_clocks clk_src1]
#set_false_path -from [get_clocks clk_src2] -to [get_clocks clk_dest]
#set_false_path -from [get_clocks clk_dest] -to [get_clocks clk_src2]

# UG903
# IMPORTANT: Although the previous two set_false_path examples perform what is intended, when 
# two or more clock domains are asynchronous and the paths between those clock domains should be 
# disabled in either direction, Xilinx recommends using the set_clock_groups command instead.

# Method 3 - For specific paths, but now all paths between clocks have to be specified individually
set_false_path -from [get_cells {flags_out_reg[*]}] -to [get_cells {conf_src1_r1_reg[*]}]
set_false_path -from [get_cells {flags_out_reg[*]}] -to [get_cells {conf_src2_r1_reg[*]}]
set_false_path -from [get_cells {reg_catch1_reg[*]}] -to [get_cells {reg_dest_r_reg[*]}]
set_false_path -from [get_cells {reg_catch2_reg[*]}] -to [get_cells {reg_dest_r_reg[*]}]

