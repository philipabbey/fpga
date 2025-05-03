####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Synthesis constraints for experimental design for partial reconfiguration.
#
# P A Abbey, 12 February 2025
#
####################################################################################

# The input clock will be defined by the MCMM IP's PLL
#create_clock -period 8.000 -name clk_port -waveform {0.000 4.000} -add [get_ports clk_port]

# This is essential to prevent interface changes that prevent RMs being stitched into the static image later
# This is not working inside a block diagram. Might be better to use SCOPED_TO_REF constraints (No!), or attributes instead
#set_property KEEP_HIERARCHY true [get_cells {ps_pl_i/vhdl_conv_i/U0/wrapper_i/reconfig_rp}]

set_false_path -to [get_cells {ps_pl_i/vhdl_conv_i/U0/wrapper_i/retime_*/reg_retime_reg[*]}]
# These off chip sources and destinations are not synchronous, but we want a clean timing report.
# Time in ns
set_input_delay -clock [get_clocks clk_port] -max 0.200 [get_ports {{btn[*]} {sw[*]}}]
set_input_delay -clock [get_clocks clk_port] -min 0.100 [get_ports {{btn[*]} {sw[*]}}]
set_output_delay -clock [get_clocks clk_port] -max 0.100 [get_ports {disp_sel {sevseg[*]}}]
set_output_delay -clock [get_clocks clk_port] -min -0.100 [get_ports {disp_sel {sevseg[*]}}]
#set_output_delay -clock [get_clocks cfgmclk] -max 0.100 [get_ports {led[*]}]
#set_output_delay -clock [get_clocks cfgmclk] -min -0.100 [get_ports {led[*]}]
set icap_clk [get_clocks -of_objects [get_nets {ps_pl_i/vhdl_conv_i/U0/wrapper_i/icap_clk}]]
set_output_delay -clock $icap_clk -max 0.100 [get_ports {led[*]}]
set_output_delay -clock $icap_clk -min -0.100 [get_ports {led[*]}]

# Pack the final register into the IOB? Keep this auto to avoid hold time violations
set_property IOB TRUE [get_ports {{led[*]} disp_sel {sevseg[*]}}]
