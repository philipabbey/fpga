####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Implementation only:
# Hand placement of control_set_array component for maximum packing density when
# reset and chip enable pins are "extracted" (as opposed to "direct").
#
# P A Abbey, 8 August 2023
#
#####################################################################################

# # PBlock placement - has sufficient capacity but still scatters logic outside the requested area
# create_pblock pblock_1
# add_cells_to_pblock -clear_locs [get_pblocks pblock_1] [get_cells {{shift_g.dd_reg[*][0]} {shift_g.q_reg[*]}}]
# # width=4
# #resize_pblock [get_pblocks pblock_1] -replace -add {SLICE_X36Y99:SLICE_X37Y100}
# # width=128, way bigger than should be required
# resize_pblock [get_pblocks pblock_1] -replace -add {SLICE_X36Y96:SLICE_X43Y99}

# Manual placement into a single SliceL for width=4
set_property BEL D5LUT [get_cells {shift_g.q[0]_i_1}]
set_property BEL D6LUT [get_cells {shift_g.dd[0][0]_i_1}]
set_property BEL DFF [get_cells {shift_g.dd_reg[0][0]}]
set_property BEL D5FF [get_cells {shift_g.q_reg[0]}]

set_property BEL C5LUT [get_cells {shift_g.q[1]_i_1}]
set_property BEL C6LUT [get_cells {shift_g.dd[1][0]_i_1}]
set_property BEL CFF [get_cells {shift_g.dd_reg[1][0]}]
set_property BEL C5FF [get_cells {shift_g.q_reg[1]}]

set_property BEL B5LUT [get_cells {shift_g.q[2]_i_1}]
set_property BEL B6LUT [get_cells {shift_g.dd[2][0]_i_1}]
set_property BEL BFF [get_cells {shift_g.dd_reg[2][0]}]
set_property BEL B5FF [get_cells {shift_g.q_reg[2]}]

set_property BEL A5LUT [get_cells {shift_g.q[3]_i_1}]
set_property BEL A6LUT [get_cells {shift_g.dd[3][0]_i_1}]
set_property BEL AFF [get_cells {shift_g.dd_reg[3][0]}]
set_property BEL A5FF [get_cells {shift_g.q_reg[3]}]

# This must come after the BEL property settings
set_property LOC SLICE_X36Y97 [get_cells * -filter {PRIMITIVE_GROUP == FLOP_LATCH || PRIMITIVE_GROUP == LUT}]
