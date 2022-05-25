#####################################################################################
##
## Distributed under MIT Licence
##   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
##
#####################################################################################
##
## Out of Context synthesis constraints for report_cdc.vhd in order to experiment
## with Vivado's 'report_cdc' TCL command and issue identification.
##
## References:
##  * Specifying Boundary Timing Constraints in Vivado
##    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
##
## P A Abbey, 22 May 2022
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
 
create_clock -period 8.000 -name clk_src [get_ports clk_src]
create_clock -period 5.000 -name clk_dest [get_ports clk_dest]

set input_ports_src [get_ports {\
  flags_in_* \
  reset_src \
  data_in[*] \
  data_valid_in \
}]


set output_ports_src [get_ports {\
  flags_out8 \
}]

set input_ports_dest [get_ports {\
  reset_dest \
}]

set output_ports_dest [get_ports {\
  flags_out1 \
  flags_out2 \
  flags_out3 \
  flags_out4 \
  flags_out5 \
  flags_out6 \
  flags_out7 \
  flags_out9 \
  data_out[*] \
  data_valid_out \
  data_out_bad[*] \
  data_valid_out_bad \
}]
 
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

set_input_delay  -clock [get_clocks clk_src]  -min $input_delay_min  $input_ports_src
set_input_delay  -clock [get_clocks clk_src]  -max $input_delay_max  $input_ports_src

set_output_delay -clock [get_clocks clk_src]  -min $output_delay_min $output_ports_src
set_output_delay -clock [get_clocks clk_src]  -max $output_delay_max $output_ports_src

set_input_delay  -clock [get_clocks clk_dest] -min $input_delay_min  $input_ports_dest
set_input_delay  -clock [get_clocks clk_dest] -max $input_delay_max  $input_ports_dest

set_output_delay -clock [get_clocks clk_dest] -min $output_delay_min $output_ports_dest
set_output_delay -clock [get_clocks clk_dest] -max $output_delay_max $output_ports_dest

# You can use the DIRECT_RESET attribute to specify which reset signal to connect to the register reset pin.
set_property DIRECT_RESET true [get_nets -of_objects [get_ports {reset_src}]]
set_property DIRECT_RESET true [get_nets -of_objects [get_ports {reset_dest}]]

# 1. CDC-3 Info. Safe, synchronised with ASYNC_REG property
set_false_path -from [get_cells {reg_capture_a_reg}] -to [get_cells {sync_reg_1/reg_retime_reg[*]}]
set_property ASYNC_REG true [get_cells {sync_reg_1/reg_retime_reg[*] sync_reg_1/flags_out_reg[*]}]
# 2. CDC-1 Critical - Unknown CDC Circuitry
set_false_path -from [get_cells {reg_capture_b_reg}] -to [get_cells {sync_reg_bad_i/flags_out_reg[0]}]
set_property ASYNC_REG true [get_cells {sync_reg_bad_i/flags_out_reg[0]}]
# 3. CDC-2 Warning - Missing ASYNC_REG Property on 'flags_out3_reg[*]'
set_false_path -from [get_cells {reg_capture_c_reg}] -to [get_cells {sync_reg_3/reg_retime_reg[*]}]
set_property ASYNC_REG true [get_cells {sync_reg_3/reg_retime_reg[*]}]
# 4. CDC-11 Critical - Fanout from launch flop warning
set_false_path -from [get_cells {reg_capture_d_reg}] -to [get_cells {sync_reg_4/reg_retime_reg[*]}]
set_property ASYNC_REG true [get_cells {sync_reg_4/reg_retime_reg[*] sync_reg_4/flags_out_reg[*]}]
set_false_path -from [get_cells {reg_capture_d_reg}] -to [get_cells {sync_reg_5/reg_retime_reg[*]}]
set_property ASYNC_REG true [get_cells {sync_reg_5/reg_retime_reg[*] sync_reg_5/flags_out_reg[*]}]
# 5. CDC-10 Critical - Combinatorial logic detected before synchroniser
set_false_path -from [get_cells {reg_capture_d_reg}] -to [get_cells {sync_reg_6/reg_retime_reg[*]}]
set_false_path -from [get_cells {reg_capture_e_reg}] -to [get_cells {sync_reg_6/reg_retime_reg[*]}]
set_property ASYNC_REG true [get_cells {sync_reg_6/reg_retime_reg[*] sync_reg_6/flags_out_reg[*]}]
# 6. Combinatorial logic between ASYNC_REG registers - Detected as a CDC-1 "Unknown CDC Circuitry"
set_false_path -from [get_cells {reg_capture_e_reg}] -to [get_cells {sync_reg_bad_i/reg_retime_reg}]
set_property ASYNC_REG true [get_cells {sync_reg_bad_i/reg_retime_reg sync_reg_bad_i/flags_out_reg[1]}]
# 7. Validated data CDC
set_false_path -from [get_cells {cdc_validated_data_slow_fast_i/dv_i_reg}] -to [get_cells {cdc_validated_data_slow_fast_i/dv_reg[0]}]
set_false_path -from [get_cells {cdc_validated_data_slow_fast_i/data_i_reg[*]}] -to [get_cells {cdc_validated_data_slow_fast_i/data_out_reg[*]}]
set_property ASYNC_REG true [get_cells {cdc_validated_data_slow_fast_i/dv_reg[*]}]
set_property DIRECT_ENABLE true [get_nets {cdc_validated_data_slow_fast_i/data_valid_in}]
set_property DIRECT_ENABLE true [get_nets -of_objects [get_pins {cdc_validated_data_slow_fast_i/dv_reg[1]/Q}]]
# 8. Invalidated data
set_property DIRECT_ENABLE true [get_nets {cdc_invalid_data_slow_fast_i/data_valid_in}]
set_property DIRECT_ENABLE true [get_nets -of_objects [get_pins {cdc_invalid_data_slow_fast_i/dv_i_reg/Q}]]
set_false_path -from [get_cells {cdc_invalid_data_slow_fast_i/dv_i_reg}] -to [get_cells {cdc_invalid_data_slow_fast_i/data_valid_out_reg}]
set_false_path -from [get_cells {cdc_invalid_data_slow_fast_i/dv_i_reg}] -to [get_cells {cdc_invalid_data_slow_fast_i/data_out_reg[*]}]
set_false_path -from [get_cells {cdc_invalid_data_slow_fast_i/data_i_reg[*]}] -to [get_cells {cdc_invalid_data_slow_fast_i/data_out_reg[*]}]
