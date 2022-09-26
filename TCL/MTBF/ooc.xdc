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
# References:
#  * Specifying Boundary Timing Constraints in Vivado
#    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
#
# P A Abbey, 24 June 2022
#
####################################################################################

# https://support.xilinx.com/s/question/0D52E00006hpcvbSAA/how-to-write-output-delay-constraints-with-device-setup-hold-specified

# Clock uncertainty (from a timing report), looks to be device independent
set tcu 0.035

# Getting these from timing reports is painful, but only needs doing once per device/part
#
# Part: xczu2cg-sbva484-2-e
# FDRE Setup Time (Setup_FDRE_C_D) in ns (Slow Process, max delay for Setup times)
set tsus 0.025
# FDRE Hold Time (Hold_FDRE_C_D) in ns (Fast Process, min delay for Hold times)
set ths 0.046

# Choose these:
#
# Extra slack (on hold time), designer's choice
set txs 0.008
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000
 
create_clock -period 7.000 -name clk_src [get_ports clk_src]
create_clock -period 6.000 -name clk_dest [get_ports clk_dest]

set input_ports_src [get_ports {flags_in[*] reset_src}]
set input_ports_dest [get_ports {reset_dest}]
set output_ports [get_ports {flags_out[*]}]
 
#
# Standard timing setup, allocate the device delays into the meaningful variables
#
# https://www.xilinx.com/publications/prod_mktg/club_vivado/presentation-2015/paris/Xilinx-TimingClosure.pdf
# Recommended technique for over-constraining a design:
set_clock_uncertainty $tcu_add [get_clocks]
 
# Input Hold = Input Setup (slow corner)
set input_delay [expr $ths + $tcu + $txs]
# Output Hold = Output Setup (slow corner)
set output_delay $tsus

set_input_delay  -clock [get_clocks clk_src]  -min $input_delay  $input_ports_src
set_input_delay  -clock [get_clocks clk_src]  -max $input_delay  $input_ports_src

set_input_delay  -clock [get_clocks clk_dest] -min $input_delay  $input_ports_dest
set_input_delay  -clock [get_clocks clk_dest] -max $input_delay  $input_ports_dest
set_output_delay -clock [get_clocks clk_dest] -min $output_delay $output_ports
set_output_delay -clock [get_clocks clk_dest] -max $output_delay $output_ports

# Manage False Paths (small design, taking a short cut here, don't typically recommend blanket turning off
# static timing analysis between clocks like this. Specify the registers more precisely instead.
set_false_path -from [get_clocks clk_src] -to [get_clocks clk_dest]
