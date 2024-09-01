onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_toggle_synchroniser/all_tests_pass
add wave -noupdate /test_toggle_synchroniser/width_c
add wave -noupdate /test_toggle_synchroniser/len_c
add wave -noupdate -expand -group Write /test_toggle_synchroniser/clk_wr
add wave -noupdate -expand -group Write /test_toggle_synchroniser/reset_wr
add wave -noupdate -expand -group Write -radix unsigned /test_toggle_synchroniser/data_wr
add wave -noupdate -expand -group Write /test_toggle_synchroniser/wr_rdy
add wave -noupdate -expand -group Write /test_toggle_synchroniser/wr_tgl
add wave -noupdate -expand -group Write /test_toggle_synchroniser/wr_finished
add wave -noupdate -expand -group Read /test_toggle_synchroniser/clk_rd
add wave -noupdate -expand -group Read /test_toggle_synchroniser/reset_rd
add wave -noupdate -expand -group Read -radix unsigned /test_toggle_synchroniser/data_rd
add wave -noupdate -expand -group Read /test_toggle_synchroniser/rd_rdy
add wave -noupdate -expand -group Read /test_toggle_synchroniser/rd_tgl
add wave -noupdate -expand -group Read /test_toggle_synchroniser/rd_finished
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 80
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
WaveRestoreZoom {0 ps} {1092376 ps}
