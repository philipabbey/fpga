onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_delay_ram/clk
add wave -noupdate /test_delay_ram/reset
add wave -noupdate /test_delay_ram/resetn
add wave -noupdate /test_delay_ram/run
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/clk_period_c
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/default_delay_c
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/seed_g
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/timeout
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/num_iterations_c
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/ready_cov
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/TestStart
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/TestDone
add wave -noupdate -expand -group {Test Bench} /test_delay_ram/complete
add wave -noupdate -expand -group {RAM Port A} -radix unsigned /test_delay_ram/ram_addr
add wave -noupdate -expand -group {RAM Port A} -radix hexadecimal /test_delay_ram/ram_wr_data
add wave -noupdate -expand -group {RAM Port A} /test_delay_ram/ram_wr_en
add wave -noupdate -expand -group {RAM Port A} /test_delay_ram/ram_rd_en
add wave -noupdate -expand -group {RAM Port A} -radix hexadecimal /test_delay_ram/ram_rd_data
add wave -noupdate -expand -group {RAM Port A} /test_delay_ram/ram_rd_valid
add wave -noupdate -expand -group {Ram Port B} -radix unsigned /test_delay_ram/axi_delay_ram_i/item_next_addr
add wave -noupdate -expand -group {Ram Port B} -radix hexadecimal /test_delay_ram/axi_delay_ram_i/item_next_data
add wave -noupdate -expand -group {Ram Port B} /test_delay_ram/axi_delay_ram_i/item_next_valid
add wave -noupdate -expand -group {Ram Port B} /test_delay_ram/axi_delay_ram_i/item_next_rdy
add wave -noupdate -expand -group {Ram Port B} /test_delay_ram/axi_delay_ram_i/ram_int_dv
add wave -noupdate -expand -group {Ram Port B} /test_delay_ram/axi_delay_ram_i/ram_int_rdy
add wave -noupdate /test_delay_ram/axi_delay_ram_i/item_tready
add wave -noupdate -radix hexadecimal /test_delay_ram/axi_delay_ram_i/item_tdata
add wave -noupdate /test_delay_ram/axi_delay_ram_i/item_tvalid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3412903 ps} 0}
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3785250 ps}
