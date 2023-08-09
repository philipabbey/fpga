####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Implementation only:
# 'pblock' guided placement of control_set_array component when reset and chip
# enable pins are "direct" (as opposed to "extracted").
#
# P A Abbey, 8 August 2023
#
#####################################################################################

create_pblock pblock_1
add_cells_to_pblock -clear_locs [get_pblocks pblock_1] [get_cells {{shift_g.dd_reg[*][0]} {shift_g.q_reg[*]}}]
resize_pblock [get_pblocks pblock_1] -replace -add {SLICE_X36Y99:SLICE_X37Y100}
