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
## P A Abbey, 5 December 2021
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
 
create_clock -period 5.000 -name clk_src1 [get_ports clk_src1]
create_clock -period 8.000 -name clk_src2 [get_ports clk_src2]
create_clock -period 4.000 -name clk_dest [get_ports clk_dest]

set input_ports_src1 [get_ports {flags_src1[*] reset_src1}]
set input_ports_src2 [get_ports {flags_src2[*] reset_src2}]
set input_ports_dest [get_ports {reset_dest}]
set output_ports [get_ports {flags_out[*]}]
 
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

set_input_delay  -clock [get_clocks clk_src1] -min $input_delay_min  $input_ports_src1
set_input_delay  -clock [get_clocks clk_src1] -max $input_delay_max  $input_ports_src1

set_input_delay  -clock [get_clocks clk_src2] -min $input_delay_min  $input_ports_src2
set_input_delay  -clock [get_clocks clk_src2] -max $input_delay_max  $input_ports_src2

set_input_delay  -clock [get_clocks clk_dest] -min $input_delay_min  $input_ports_dest
set_input_delay  -clock [get_clocks clk_dest] -max $input_delay_max  $input_ports_dest
set_output_delay -clock [get_clocks clk_dest] -min $output_delay_min $output_ports
set_output_delay -clock [get_clocks clk_dest] -max $output_delay_max $output_ports


# Manage False Paths

# Method 1 - Preferred
set_clock_groups    \
  -asynchronous     \
  -group [get_clocks {clk_src1}] \
  -group [get_clocks {clk_src2}] \
  -group [get_clocks {clk_dest}]

# Method 2 - More specific clock directions, but now all clock transitions have to be specified individually
#set_false_path -from [get_clocks clk_src1] -to [get_clocks clk_dest]
#set_false_path -from [get_clocks clk_dest] -to [get_clocks clk_src1]
#set_false_path -from [get_clocks clk_src2] -to [get_clocks clk_dest]
#set_false_path -from [get_clocks clk_dest] -to [get_clocks clk_src2]

# UG903
# IMPORTANT: Although the previous two set_false_path examples perform what is intended, when 
# two or more clock domains are asynchronous and the paths between those clock domains should be 
# disabled in either direction, Xilinx recommends using the set_clock_groups command instead

# Method 3 - For specific paths, but now all paths between clocks have to be specified individually
#set_false_path -from [get_cells {flags_out_reg[*]}] -to [get_cells {conf_src1_r1_reg[*]}]
#set_false_path -from [get_cells {flags_out_reg[*]}] -to [get_cells {conf_src2_r1_reg[*]}]
#set_false_path -from [get_cells {reg_catch1_reg[*]}] -to [get_cells {reg_dest_r_reg[*]}]
#set_false_path -from [get_cells {reg_catch2_reg[*]}] -to [get_cells {reg_dest_r_reg[*]}]

