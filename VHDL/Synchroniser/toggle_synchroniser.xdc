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
# P A Abbey, 31 August 2024
#
#####################################################################################

# This all ought to be a 'set_max_delay -datapath_only -from <objects>', except this
# design does not have knowledge of the source registers. Therefore note it for now
# and substitute a false path constraint. Maximum delays are preferable because we
# want to ensure net delay prior to the registers does not subtract from the settling
# time after the registers.
set_false_path -to [get_cells {data_rd_reg[*]}]
set_false_path -from [get_port {rd_tgl}] -to [get_cells {wr_tgl_sync_reg[0]}]
set_false_path -from [get_port {wr_tgl}] -to [get_cells {rd_tgl_sync_reg[0]}]
