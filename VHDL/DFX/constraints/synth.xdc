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

create_clock -period 8.000 -name clk_port -waveform {0.000 4.000} -add [get_ports clk_port]

# This is essential to prevent interface changes that prevent RMs being stitched into the static image later
set_property KEEP_HIERARCHY true [get_cells {reconfig_rp}]

set_false_path -to [get_cells {retime_*/reg_retime_reg[*]}]
# These off chip sources and destinations are not synchronous, but we want a clean timing report.
# Time in ns
set_input_delay  -clock [get_clocks clk_port] -max  0.200 [get_ports {{btn[*]} {sw[*]}}]
set_input_delay  -clock [get_clocks clk_port] -min  0.100 [get_ports {{btn[*]} {sw[*]}}]
set_output_delay -clock [get_clocks clk_port] -max  0.100 [get_ports {{led[*]} disp_sel {sevseg[*]}}]
set_output_delay -clock [get_clocks clk_port] -min -0.100 [get_ports {{led[*]} disp_sel {sevseg[*]}}]

# Pack the final register into the IOB? Keep this auto to avoid hold time violations
set_property IOB AUTO [get_ports {{led[*]} disp_sel {sevseg[*]}}]
