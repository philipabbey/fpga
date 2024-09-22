####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# SCOPED_TO_REF constraints file for 'bus_data_valid_synch'.
#
# When inclusing this constraints file, be sure to set the following property in TCL.
#
#   set_property SCOPED_TO_REF bus_data_valid_synch [get_files constraints.xdc]
#
# References:
#  * Determining A Device's Maximum Clock Speed
#    https://blog.abbey1.org.uk/index.php/technology/determining-a-device-s-maximum-clock-speed
#
# P A Abbey, 22 September 2024
#
#####################################################################################

# Hold on input
set_input_delay  -clock [get_clocks {clk_ext}] -min  0.0 [get_ports {input}]
# Setup on input
set_input_delay  -clock [get_clocks {clk_ext}] -max  0.0 [get_ports {input}]
# Hold on output
set_output_delay -clock [get_clocks {clk_ext}] -min  0.0 [get_ports {output}]
# Setup on output
set_output_delay -clock [get_clocks {clk_ext}] -max -0.0 [get_ports {output}]

set_false_path -to [get_cells {input_r_reg}]
set_false_path -from [get_cells {output_reg}]
