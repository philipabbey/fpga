onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /test_axi_join/data_width_c
add wave -noupdate -radix unsigned /test_axi_join/max_loops_c
add wave -noupdate /test_axi_join/clk
add wave -noupdate -color Red /test_axi_join/axi_join_i/backpressure1
add wave -noupdate /test_axi_join/s1_axi_data
add wave -noupdate /test_axi_join/s1_axi_valid
add wave -noupdate /test_axi_join/s_axi_ready
add wave -noupdate /test_axi_join/s2_axi_data
add wave -noupdate /test_axi_join/s2_axi_valid
add wave -noupdate -color Red /test_axi_join/axi_join_i/backpressure2
add wave -noupdate /test_axi_join/m_axi_data
add wave -noupdate /test_axi_join/m_axi_ready
add wave -noupdate /test_axi_join/m_axi_valid
add wave -noupdate -expand -group Valid /test_axi_join/s1_axi_valid
add wave -noupdate -expand -group Valid /test_axi_join/s2_axi_valid
add wave -noupdate -expand -group Valid /test_axi_join/m_axi_valid
add wave -noupdate -expand -group Ready /test_axi_join/s_axi_ready
add wave -noupdate -expand -group Ready /test_axi_join/m_axi_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {246302 ps} 0}
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
WaveRestoreZoom {0 ps} {2089500 ps}
