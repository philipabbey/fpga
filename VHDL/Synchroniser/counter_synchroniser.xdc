####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# This code implements a synchroniser solution gleaned from a Doulos training video
# on clock domain crossings available at
# https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
#
# P A Abbey, 1 September 2024
#
#####################################################################################

set_false_path -from [get_cells {gray_reg[*]}] -to [get_cells {gray_sync_reg[0][*]}]
