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

set_property CONFIG_VOLTAGE        3.3      [current_design]

set_property IOSTANDARD            LVCMOS18 [get_ports {input}]

set_property IOSTANDARD            LVCMOS18 [get_ports {output}]
set_property SLEW                  FAST     [get_ports {output}]
set_property DRIVE                 12       [get_ports {output}]

set_property IOSTANDARD            LVCMOS18 [get_ports {clk_ext}]
