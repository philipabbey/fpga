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
## P A Abbey, 11 December 2021
##
#####################################################################################

# Remove any lingering hang-over results and start again, this seems to become necessary
# when using TCL-based constraints file. NB. the OOC constraint files must be at the top
# of the list in order to be processed first.
reset_timing -quiet

# Clock uncertainty (from a timing report), looks to be device independent
set tcu 0.035

# Extract more precise setup and hold times using the TCL function
# 'check_setup_hold_times $tsus $ths 1' post initial synthesis.

# Part: xc7k70tfbv676-1
# Maximum setup time of '0.242 ns' on a 'FLOP_LATCH.flop.FDRE' primtive.
# Maximum hold  time of '0.161 ns' on a 'FLOP_LATCH.flop.FDRE' primtive.

# !! Numbersa not right here, DOUBLE CHECK

# BlockRAMs seem to mess up the automatic timing setup checks 0.564 is extracted, but is then
# WARNING in 'check_setup_hold_times': Specified hold time '0.598] ns' does not match input ports' maximum hold time of '0.564 ns' on a 'BMEM.bram.RAMB18E1' primtive.
# Clock path has net delay 0.672
# Data path has a net delay 0.641
# 0.672 - 0.641 = 0.031, hence something needs amending in TCL 'proc check_setup_hold_times'
# check_ooc_setup 0.624 [expr 0.564 + 0.034]
#set ths  [expr 0.564 + 0.034]

# Distributed RAMs have a different effect
# 0.672 - 0.638 = 0.034
set tsus 0.624
set ths  [expr 0.564 + 0.048]

# Choose these:
#
# Extra slack (on hold time), designer's choice
set txs 0.008
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000

create_clock -period 5.000 -name clk [get_ports clk]

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

# Add manual constraints here for ports where the clock domain cannot be automatically determined.

# Automatically determine the clock domain of each input and output, and assign the appropriate delay.
if {[llength [info procs setup_port_constraints]] == 1} {
    setup_port_constraints $input_delay $output_delay 1
} else {
    puts "You need to 'source -notrace {..\..\TCL\auto_constrain\out_of_context_synth_lib.tcl}' first."
}
