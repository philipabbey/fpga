####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Synthesis & Implementation:
# Ensure that reset and chip enable pins are extracted from their registers and
# driven through a LUT.
#
# P A Abbey, 8 August 2023
#
#####################################################################################

# Not working on its own, needs -control_set_opt_threshold setting to be changed.
#set_property EXTRACT_RESET  true [get_nets -of_objects [get_ports {reset}]]
#set_property EXTRACT_ENABLE true [get_nets -of_objects [get_ports {ces[*]}]]
set_property CONTROL_SET_REMAP ENABLE [get_cells shift_g.* -filter {IS_SEQUENTIAL}]
