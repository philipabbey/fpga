onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/dut/clk_tx
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk_data
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/clk_data_delayed
add wave -noupdate -expand -group {Test Bench} /test_zybo_z7_10/dut/clk_rx
add wave -noupdate /test_zybo_z7_10/dut/clk
add wave -noupdate /test_zybo_z7_10/dut/reset
add wave -noupdate /test_zybo_z7_10/dut/rst_reg
add wave -noupdate /test_zybo_z7_10/dut/locked
add wave -noupdate /test_zybo_z7_10/dut/locked_clk
add wave -noupdate /test_zybo_z7_10/dut/reset_rx
add wave -noupdate /test_zybo_z7_10/dut/rst_reg_rx
add wave -noupdate /test_zybo_z7_10/dut/rx_locked
add wave -noupdate /test_zybo_z7_10/dut/rx_locked_rx
add wave -noupdate /test_zybo_z7_10/dut/clk_rx_pll
add wave -noupdate /test_zybo_z7_10/dut/btn
add wave -noupdate -expand /test_zybo_z7_10/dut/btn_r
add wave -noupdate /test_zybo_z7_10/dut/rx_enable_rx
add wave -noupdate /test_zybo_z7_10/dut/sw
add wave -noupdate /test_zybo_z7_10/dut/sw_r
add wave -noupdate /test_zybo_z7_10/dut/buttons
add wave -noupdate /test_zybo_z7_10/dut/clk_tx
add wave -noupdate /test_zybo_z7_10/dut/clk_rx
add wave -noupdate -expand /test_zybo_z7_10/dut/led
add wave -noupdate /test_zybo_z7_10/dut/tx
add wave -noupdate /test_zybo_z7_10/dut/rx
add wave -noupdate /test_zybo_z7_10/dut/rx_f
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rst
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/wr_clk
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/wr_en
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/din
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rd_clk
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/rd_en
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/dout
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/empty
add wave -noupdate -expand -group FIFO /test_zybo_z7_10/dut/fifo_rx_i/full
add wave -noupdate -expand /test_zybo_z7_10/dut/empty
add wave -noupdate /test_zybo_z7_10/dut/rx_r
add wave -noupdate /test_zybo_z7_10/dut/check
add wave -noupdate /test_zybo_z7_10/dut/rx_gated
add wave -noupdate /test_zybo_z7_10/dut/check_gated
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9669382 ps} 0}
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
WaveRestoreZoom {27651615 ps} {29449915 ps}
