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

set_property EXTRACT_ENABLE true [get_ports {ces[*]}]
