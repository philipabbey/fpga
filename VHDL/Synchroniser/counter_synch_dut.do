onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_counter_synch_dut/len_c
add wave -noupdate /test_counter_synch_dut/width_c
add wave -noupdate /test_counter_synch_dut/clk1
add wave -noupdate /test_counter_synch_dut/reset1
add wave -noupdate /test_counter_synch_dut/clk2
add wave -noupdate /test_counter_synch_dut/reset2
add wave -noupdate -expand -group {Clock Domain 1} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt11
add wave -noupdate -expand -group {Clock Domain 1} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt12
add wave -noupdate -expand -group {Clock Domain 1} /test_counter_synch_dut/incr_cnt1
add wave -noupdate -expand -group {Clock Domain 1} /test_counter_synch_dut/gt12_1
add wave -noupdate -expand -group {Clock Domain 2} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt22
add wave -noupdate -expand -group {Clock Domain 2} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt21
add wave -noupdate -expand -group {Clock Domain 2} /test_counter_synch_dut/incr_cnt2
add wave -noupdate -expand -group {Clock Domain 2} /test_counter_synch_dut/gt12_2
add wave -noupdate -expand -group {Compare 1} /test_counter_synch_dut/cnt1_finished
add wave -noupdate -expand -group {Compare 1} /test_counter_synch_dut/tests_passed1
add wave -noupdate -expand -group {Compare 1} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt11
add wave -noupdate -expand -group {Compare 1} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt21
add wave -noupdate -expand -group {Compare 1} /test_counter_synch_dut/gt12_1
add wave -noupdate -expand -group {Compare 2} /test_counter_synch_dut/cnt2_finished
add wave -noupdate -expand -group {Compare 2} /test_counter_synch_dut/tests_passed2
add wave -noupdate -expand -group {Compare 2} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt12
add wave -noupdate -expand -group {Compare 2} -radix unsigned /test_counter_synch_dut/counter_synch_dut_i/cnt22
add wave -noupdate -expand -group {Compare 2} /test_counter_synch_dut/gt12_2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {62187 ps} 0}
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
WaveRestoreZoom {0 ps} {285600 ps}
