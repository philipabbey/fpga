onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/dut/clk_tx
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk_data
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk_data_delayed
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/dut/clk_rx
add wave -noupdate -expand -group {Test Bench} -expand /test_zybo_z7_10/leds
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/dut_clk
add wave -noupdate -expand -group {Test Bench} -expand /test_zybo_z7_10/cnt_reg
add wave -noupdate /test_zybo_z7_10/dut/clk
add wave -noupdate /test_zybo_z7_10/dut/reset
add wave -noupdate /test_zybo_z7_10/dut/rst_reg
add wave -noupdate /test_zybo_z7_10/dut/locked
add wave -noupdate /test_zybo_z7_10/dut/locked_clk
add wave -noupdate /test_zybo_z7_10/dut/reset_rx
add wave -noupdate /test_zybo_z7_10/dut/rst_reg_rx
add wave -noupdate /test_zybo_z7_10/dut/rx_locked
add wave -noupdate /test_zybo_z7_10/dut/rx_locked_rx
add wave -noupdate /test_zybo_z7_10/dut/btn
add wave -noupdate /test_zybo_z7_10/dut/btn_r
add wave -noupdate /test_zybo_z7_10/dut/rx_enable_rx
add wave -noupdate /test_zybo_z7_10/dut/sw
add wave -noupdate /test_zybo_z7_10/dut/sw_r
add wave -noupdate /test_zybo_z7_10/dut/buttons
add wave -noupdate /test_zybo_z7_10/dut/clk_tx
add wave -noupdate -expand /test_zybo_z7_10/dut/led
add wave -noupdate /test_zybo_z7_10/dut/clk_tx
add wave -noupdate -group {IDELAY delay} /test_zybo_z7_10/dut/idelayctrl_i/RST
add wave -noupdate -group {IDELAY delay} /test_zybo_z7_10/dut/idelayctrl_i/RDY
add wave -noupdate -group {IDELAY delay} /test_zybo_z7_10/dut/rx_g(0)/idelaye2_i/LD
add wave -noupdate -group {IDELAY delay} -radix unsigned /test_zybo_z7_10/dut/rx_g(0)/idelaye2_i/CNTVALUEOUT
add wave -noupdate -group {IDELAY delay} -radix unsigned /test_zybo_z7_10/dut/rx_g(1)/idelaye2_i/CNTVALUEOUT
add wave -noupdate -group {IDELAY delay} -radix unsigned /test_zybo_z7_10/dut/rx_g(2)/idelaye2_i/CNTVALUEOUT
add wave -noupdate /test_zybo_z7_10/dut/tx
add wave -noupdate /test_zybo_z7_10/dut/clk_rx
add wave -noupdate /test_zybo_z7_10/dut/rx
add wave -noupdate /test_zybo_z7_10/dut/rx_f1
add wave -noupdate /test_zybo_z7_10/dut/rx_f2
add wave -noupdate /test_zybo_z7_10/dut/clk_rx_pll
add wave -noupdate -expand /test_zybo_z7_10/rx_shifted
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rst
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/wr_clk
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/wr_en
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/din
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rd_clk
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rd_en
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/dout
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/empty
add wave -noupdate -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/full
add wave -noupdate /test_zybo_z7_10/dut/empty
add wave -noupdate -expand /test_zybo_z7_10/dut/rx_r
add wave -noupdate /test_zybo_z7_10/dut/check
add wave -noupdate -expand /test_zybo_z7_10/dut/rx_gated
add wave -noupdate -expand /test_zybo_z7_10/dut/check_gated
add wave -noupdate /test_zybo_z7_10/dut/state
add wave -noupdate -radix unsigned /test_zybo_z7_10/dut/prbs_cnt
add wave -noupdate -radix unsigned /test_zybo_z7_10/dut/prbs_cnt_max_c
add wave -noupdate -radix unsigned -childformat {{/test_zybo_z7_10/dut/idelay(4) -radix unsigned} {/test_zybo_z7_10/dut/idelay(3) -radix unsigned} {/test_zybo_z7_10/dut/idelay(2) -radix unsigned} {/test_zybo_z7_10/dut/idelay(1) -radix unsigned} {/test_zybo_z7_10/dut/idelay(0) -radix unsigned}} -subitemconfig {/test_zybo_z7_10/dut/idelay(4) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay(3) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay(2) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay(1) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay(0) {-height 15 -radix unsigned}} /test_zybo_z7_10/dut/idelay
add wave -noupdate -radix unsigned /test_zybo_z7_10/dut/idelay_d
add wave -noupdate /test_zybo_z7_10/dut/idelay_ld
add wave -noupdate /test_zybo_z7_10/dut/idelay_ldd
add wave -noupdate /test_zybo_z7_10/dut/save_cnt
add wave -noupdate /test_zybo_z7_10/dut/save_cnt_d
add wave -noupdate -radix unsigned -childformat {{/test_zybo_z7_10/dut/idelay_mux(2) -radix unsigned} {/test_zybo_z7_10/dut/idelay_mux(1) -radix unsigned} {/test_zybo_z7_10/dut/idelay_mux(0) -radix unsigned}} -expand -subitemconfig {/test_zybo_z7_10/dut/idelay_mux(2) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay_mux(1) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/idelay_mux(0) {-height 15 -radix unsigned}} /test_zybo_z7_10/dut/idelay_mux
add wave -noupdate /test_zybo_z7_10/dut/counting
add wave -noupdate /test_zybo_z7_10/dut/counting_d
add wave -noupdate -radix unsigned -childformat {{/test_zybo_z7_10/dut/wrong(2) -radix unsigned} {/test_zybo_z7_10/dut/wrong(1) -radix unsigned} {/test_zybo_z7_10/dut/wrong(0) -radix unsigned}} -expand -subitemconfig {/test_zybo_z7_10/dut/wrong(2) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/wrong(1) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/wrong(0) {-height 15 -radix unsigned}} /test_zybo_z7_10/dut/wrong
add wave -noupdate -radix unsigned -childformat {{/test_zybo_z7_10/dut/wrong_r(2) -radix unsigned} {/test_zybo_z7_10/dut/wrong_r(1) -radix unsigned} {/test_zybo_z7_10/dut/wrong_r(0) -radix unsigned}} -expand -subitemconfig {/test_zybo_z7_10/dut/wrong_r(2) {-format Analog-Step -height 74 -max 58.0 -radix unsigned} /test_zybo_z7_10/dut/wrong_r(1) {-format Analog-Step -height 74 -max 59.999999999999993 -radix unsigned} /test_zybo_z7_10/dut/wrong_r(0) {-format Analog-Step -height 74 -max 58.0 -radix unsigned}} /test_zybo_z7_10/dut/wrong_r
add wave -noupdate /test_zybo_z7_10/dut/w_g(2)/state_qty
add wave -noupdate /test_zybo_z7_10/dut/w_g(1)/state_qty
add wave -noupdate /test_zybo_z7_10/dut/w_g(0)/state_qty
add wave -noupdate -radix unsigned -childformat {{/test_zybo_z7_10/dut/total_idelay(2) -radix unsigned} {/test_zybo_z7_10/dut/total_idelay(1) -radix unsigned} {/test_zybo_z7_10/dut/total_idelay(0) -radix unsigned}} -expand -subitemconfig {/test_zybo_z7_10/dut/total_idelay(2) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/total_idelay(1) {-height 15 -radix unsigned} /test_zybo_z7_10/dut/total_idelay(0) {-height 15 -radix unsigned}} /test_zybo_z7_10/dut/total_idelay
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {50337975 ps} 0} {{Cursor 2} {130312578 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {132601366 ps} {133105192 ps}
