#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# Internal Logic Analyser (ILA) setup.
#
# P A Abbey, 1 August 2025
#
#####################################################################################

# Unlock the file we want to delete
close_hw_manager
reset_run synth_1
launch_runs synth_1 -jobs 14
wait_on_runs synth_1
open_run synth_1 -name synth_1

# Set these per installation
set vivado_dir {C:/Users/philip/Vivado}
set probes_file "$vivado_dir/lssio/lssio.runs/impl_1/zybo_z7_10.ltx"

# Re-create this as there seems to be a hang-over warning.
if {[file exists $probes_file]} {
  file delete $probes_file
}

set dbc [get_debug_cores {u_ila_0}]
if {[llength $dbc] > 0} {
  delete_debug_core [get_debug_cores {u_ila_0 }]
}
create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list pll_i/inst/clk_out]]
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {check_gated[0]} {check_gated[1]} {check_gated[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe1]
set_property port_width 4 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {led_OBUF[0]} {led_OBUF[1]} {led_OBUF[2]} {led_OBUF[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe2]
set_property port_width 5 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {idelay_mux[1][0]} {idelay_mux[1][1]} {idelay_mux[1][2]} {idelay_mux[1][3]} {idelay_mux[1][4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe3]
set_property port_width 5 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {idelay_mux[2][0]} {idelay_mux[2][1]} {idelay_mux[2][2]} {idelay_mux[2][3]} {idelay_mux[2][4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe4]
set_property port_width 3 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {rx_r[0]} {rx_r[1]} {rx_r[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe5]
set_property port_width 5 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {idelay_mux[0][0]} {idelay_mux[0][1]} {idelay_mux[0][2]} {idelay_mux[0][3]} {idelay_mux[0][4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe6]
set_property port_width 5 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {idelay[0]} {idelay[1]} {idelay[2]} {idelay[3]} {idelay[4]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe7]
set_property port_width 7 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {prbs_cnt[0]} {prbs_cnt[1]} {prbs_cnt[2]} {prbs_cnt[3]} {prbs_cnt[4]} {prbs_cnt[5]} {prbs_cnt[6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe8]
set_property port_width 3 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {check[0]} {check[1]} {check[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe9]
set_property port_width 4 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {buttons[0]} {buttons[1]} {buttons[2]} {buttons[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe10]
set_property port_width 7 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {wrong[2][0]} {wrong[2][1]} {wrong[2][2]} {wrong[2][3]} {wrong[2][4]} {wrong[2][5]} {wrong[2][6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe11]
set_property port_width 8 [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {total_idelay[0][0]} {total_idelay[0][1]} {total_idelay[0][2]} {total_idelay[0][3]} {total_idelay[0][4]} {total_idelay[0][5]} {total_idelay[0][6]} {total_idelay[0][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
set_property port_width 2 [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {state[0]} {state[1]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe13]
set_property port_width 3 [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {w_g[0].state_qty[0]} {w_g[0].state_qty[1]} {w_g[0].state_qty[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe14]
set_property port_width 7 [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {wrong[0][0]} {wrong[0][1]} {wrong[0][2]} {wrong[0][3]} {wrong[0][4]} {wrong[0][5]} {wrong[0][6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe15]
set_property port_width 3 [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {w_g[1].state_qty[0]} {w_g[1].state_qty[1]} {w_g[1].state_qty[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe16]
set_property port_width 8 [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {total_idelay[1][0]} {total_idelay[1][1]} {total_idelay[1][2]} {total_idelay[1][3]} {total_idelay[1][4]} {total_idelay[1][5]} {total_idelay[1][6]} {total_idelay[1][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe17]
set_property port_width 8 [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list {total_idelay[2][0]} {total_idelay[2][1]} {total_idelay[2][2]} {total_idelay[2][3]} {total_idelay[2][4]} {total_idelay[2][5]} {total_idelay[2][6]} {total_idelay[2][7]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe18]
set_property port_width 3 [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list {tx_OBUF[0]} {tx_OBUF[1]} {tx_OBUF[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe19]
set_property port_width 3 [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list {w_g[2].state_qty[0]} {w_g[2].state_qty[1]} {w_g[2].state_qty[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe20]
set_property port_width 7 [get_debug_ports u_ila_0/probe20]
connect_debug_port u_ila_0/probe20 [get_nets [list {wrong[1][0]} {wrong[1][1]} {wrong[1][2]} {wrong[1][3]} {wrong[1][4]} {wrong[1][5]} {wrong[1][6]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe21]
set_property port_width 1 [get_debug_ports u_ila_0/probe21]
connect_debug_port u_ila_0/probe21 [get_nets [list counting]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe22]
set_property port_width 1 [get_debug_ports u_ila_0/probe22]
connect_debug_port u_ila_0/probe22 [get_nets [list idelay_ld]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA [get_debug_ports u_ila_0/probe23]
set_property port_width 1 [get_debug_ports u_ila_0/probe23]
connect_debug_port u_ila_0/probe23 [get_nets [list idelay_ldd]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_tx_OBUF]

save_constraints
close_design
launch_runs impl_1 -to_step write_bitstream -jobs 14
wait_on_runs impl_1

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target
set hwdev [get_hw_devices xc7z010_1]
current_hw_device $hwdev
refresh_hw_device [lindex $hwdev 0]
set_property PROBES.FILE      $probes_file $hwdev
set_property FULL_PROBES.FILE $probes_file $hwdev
set_property PROGRAM.FILE     "$vivado_dir/lssio/lssio.runs/impl_1/zybo_z7_10.bit" $hwdev
program_hw_devices $hwdev
refresh_hw_device [lindex $hwdev 0]
display_hw_ila_data [get_hw_ila_data hw_ila_data_1 -of_objects [get_hw_ilas -of_objects $hwdev -filter {CELL_NAME=~"u_ila_0"}]]
save_wave_config "$vivado_dir/lssio/lssio.hw/hw_1/wave/hw_ila_data_1/hw_ila_data_1.wcfg"
