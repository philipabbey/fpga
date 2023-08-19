####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Synthesis & Implementation:
# Ensure that reset and chip enable pins are directly connected to their registers.
#
# P A Abbey, 8 August 2023
#
#####################################################################################

set_property DIRECT_RESET  true [get_nets -of_objects [get_ports {reset}]]
set_property DIRECT_ENABLE true [get_nets -of_objects [get_ports {ces[*]}]]
