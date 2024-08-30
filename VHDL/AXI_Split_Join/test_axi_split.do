onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /test_axi_split/data_width_c
add wave -noupdate /test_axi_split/clk
add wave -noupdate -color Red /test_axi_split/axi_split_i/backpressure
add wave -noupdate /test_axi_split/s_axi_data
add wave -noupdate /test_axi_split/s_axi_ready
add wave -noupdate /test_axi_split/s_axi_valid
add wave -noupdate /test_axi_split/m1_axi_data
add wave -noupdate /test_axi_split/m1_axi_ready
add wave -noupdate /test_axi_split/m1_axi_valid
add wave -noupdate /test_axi_split/m2_axi_data
add wave -noupdate /test_axi_split/m2_axi_ready
add wave -noupdate /test_axi_split/m2_axi_valid
add wave -noupdate -expand -group Ready /test_axi_split/s_axi_ready
add wave -noupdate -expand -group Ready /test_axi_split/m1_axi_ready
add wave -noupdate -expand -group Ready /test_axi_split/m2_axi_ready
add wave -noupdate -expand -group Valid /test_axi_split/s_axi_valid
add wave -noupdate -expand -group Valid /test_axi_split/m1_axi_valid
add wave -noupdate -expand -group Valid /test_axi_split/m2_axi_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {260383 ps} 0}
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
WaveRestoreZoom {0 ps} {2037 ns}
