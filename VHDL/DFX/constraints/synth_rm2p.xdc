#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# Constraints file for out of context synthesis of subsequent RMs (2+).
#
# P A Abbey, 12 February 2025
#
#####################################################################################

create_clock -period 8.000 -name clk_port -waveform {0.000 4.000} -add [get_ports clk]

# These off chip sources and destinations are not synchronous, but we want a clean timing report.
# Time in ns
set_input_delay  -clock [get_clocks clk_port] -max  0.200 [get_ports {{reset} {buttons[*]} {incr}}]
set_input_delay  -clock [get_clocks clk_port] -min  0.100 [get_ports {{reset} {buttons[*]} {incr}}]
set_output_delay -clock [get_clocks clk_port] -max  0.100 [get_ports {{led[*]} {display[*]}}]
set_output_delay -clock [get_clocks clk_port] -min -0.100 [get_ports {{led[*]} {display[*]}}]
