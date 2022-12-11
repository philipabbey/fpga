####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Out of Context constraints for transfer.vhd in order to experiment with false path
# specification methods.
#
# To debug the use of this script:
#   1.  Open an elaborated design (synth_design -rtl -name rtl_1 -mode out_of_context)
#   2.  source -notrace {/path/to/ooc.tcl}
#
# References:
#  * Specifying Boundary Timing Constraints in Vivado
#    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
#  * Determining port clock domains for automating input and output constraints
#    https://blog.abbey1.org.uk/index.php/technology/...
#
# P A Abbey, 20 November 2022
#
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

# Kintex-7 Parts: xcku040-ffva1156-2-i and xcku060-ffva1156-2-i
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Slow Process, max delay for Setup times)
set tsus 0.047
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Slow Process, min delay for Hold times)
set ths 0.108

# Zynq Part: xc7z020clg484-1
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Slow Process, max delay for Setup times)
#set tsus 0.169
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Slow Process, min delay for Hold times)
#set ths 0.243

# Choose these:
#
# Extra slack (on hold time), designer's choice
set txs 0.008
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000

create_clock -period 5.000 -name clk_200 [get_ports clk1]
create_clock -period 7.000 -name clk_250 [get_ports clk2]

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
