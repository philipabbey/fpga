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

# Part: xc7k70tfbv676-1
# FDRE Setup Time (Setup_FDRE_C_D) is 0.058ns, set by Xilinx, see timing reports
set tsu 0.037
# FDRE Propagation Delay (Prop_FDRE_C_Q) is 0.049ns, set by Xilinx, see timing reports
set tpd 0.269
# FDRE Hold Time (Hold_FDRE_C_D) is 0.056 - 0.108ns, set by Xilinx, see timing reports
#set th 0.056
set th 0.218
# Default clock uncertainty 0.035ns, set by Xilinx, see timing reports
set tcu 0.035

# Choose these:
#
# Additional clock uncertainty desired for over constraining the design, set by designer choice
set tcu_add 0.000
# desired slack, set by designer choice
set ds 0.008

create_clock -period 2.500 -name clk [get_ports clk]

set input_ports [get_ports {s_axi_data[*] s_axi_valid m_axi_ready}]
set output_ports [get_ports {s_axi_ready m_axi_data[*] m_axi_valid}]


# https://www.xilinx.com/publications/prod_mktg/club_vivado/presentation-2015/paris/Xilinx-TimingClosure.pdf
# Recommended technique for over-constraining a design:
set_clock_uncertainty $tcu_add [get_clocks]

# From: http://billauer.co.il/blog/2017/04/io-timing-constraints-meaning/, with amendments for additional clock uncertainty when applied to hold times.
#
# $tcu *should* not be required on hold timing analysis since the timing is relative to the same clock edge,
# not the next one. However, it is being included in the timing path analysis by Vivado here, and have yet
# to determine why.
#
# set_input_delay -clock ... -min ... : The minimal clock-to-output of the driving chip. If not given, choose zero (maybe a future revision of the driving chip will be manufactured with a really fast process)
# Actually needs to be > (clock uncertainty 0.035ns + Hold_FDRE_C_D)
# Hold (negative value)
set input_delay_min [expr $tcu + $tcu_add + $th + $ds]
#
# set_input_delay -clock ... -max ... : The maximal clock-to-output of the driving chip + board propagation delay
# Setup
set input_delay_max $tsu
#
# set_output_delay -clock ... -min ...: Minus the t_hold time of the receiving chip (e.g. set to -1 if the hold time is 1 ns).
# Hold (negative value)
#set output_delay_min -$th
# Set to be > -(clock uncertainty 0.035ns + Prop_FDRE_C_Q)
set output_delay_min [expr $tcu + $tcu_add - $tpd + $ds]
#
# set_output_delay -clock ... -max ... : The t_setup time of the receiving chip + board propagation delay
# Setup
set output_delay_max $tsu

set_input_delay  -clock [get_clocks clk] -min $input_delay_min  $input_ports
set_input_delay  -clock [get_clocks clk] -max $input_delay_max  $input_ports
set_output_delay -clock [get_clocks clk] -min $output_delay_min $output_ports
set_output_delay -clock [get_clocks clk] -max $output_delay_max $output_ports
