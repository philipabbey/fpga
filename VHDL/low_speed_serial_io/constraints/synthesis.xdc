#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# Constraints file required for synthesis of the full LSSIO test design.
#
# P A Abbey, 18 December 2024
#
#####################################################################################

# Clock are actually set by the MMCM IP in their individual XDC files.

# Keep the mapping from hierarchy to code clear.
set_property keep_hierarchy true [get_cells retime_*]
# Pack the final register into the IOB? Keep this auto to avoid hold time violations
set_property IOB AUTO [get_ports {{btn[*]} {sw[*]} {rx[*]} {led[*]} {tx[*]}}]
set_false_path -to [get_cells {retime_*/reg_retime_reg[*]}]

# Time in ns
# The switch sources and destinations are not synchronous, but we want a clean timing report.
set_input_delay -clock [get_clocks clk_port] -max 0.100 [get_ports {{btn[*]} {sw[*]}}]
set_input_delay -clock [get_clocks clk_port] -min -0.100 [get_ports {{btn[*]} {sw[*]}}]

# Source synchronous clock applied to 'clk_rx' from 'clk_tx'
# These need the clock after the system PLL
set_output_delay -clock [get_clocks clk_out_pll] -max 0.100 [get_ports {{led[*]} {tx[*]} clk_tx}]
set_output_delay -clock [get_clocks clk_out_pll] -min -0.100 [get_ports {{led[*]} {tx[*]} clk_tx}]
# Input delay: +ve for data behind of clock edge, as here.
# Affects setup time
#set_input_delay -clock [get_clocks clk_rx] -max 8.767 [get_ports {rx[*]}]
set_input_delay -clock [get_clocks clk_rx] -max 0.6 [get_ports {rx[*]}]
# Affects hold time
#set_input_delay -clock [get_clocks clk_rx] -min 2.648 [get_ports {rx[*]}]
set_input_delay -clock [get_clocks clk_rx] -min -2.0 [get_ports {rx[*]}]

# Xilinx FIFOs seem to show up in report_cdc too often
create_waiver -type CDC -id CDC-15 \
  -from [get_pins {fifo_rx_i/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gdm.dm_gen.dm/RAM_reg_0_15_0_2/RAM*/CLK}] \
  -to   [get_pins {fifo_rx_i/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gdm.dm_gen.dm/gpr1.dout_i_reg[*]/D}] \
  -description {Xilinx FIFO IP}
