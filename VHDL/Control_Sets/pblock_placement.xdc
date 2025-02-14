####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Implementation only:
# 'pblock' guided placement of control_set_array component for maximum packing
# density when reset and chip enable pins are "extracted" (as opposed to "direct").
#
# P A Abbey, 8 August 2023
#
#####################################################################################

create_pblock pblock_1
add_cells_to_pblock -clear_locs [get_pblocks pblock_1] [get_cells {{shift_g.dd_reg[*][*]} {shift_g.q_reg[*]}}]
resize_pblock [get_pblocks pblock_1] -replace -add {SLICE_X36Y96:SLICE_X43Y99}
set_property IS_SOFT false [get_pblocks pblock_1]
