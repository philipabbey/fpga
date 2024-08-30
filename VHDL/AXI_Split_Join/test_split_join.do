onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_axi_split_join/data_width_c
add wave -noupdate /test_axi_split_join/clk
add wave -noupdate /test_axi_split_join/s_axi_data
add wave -noupdate /test_axi_split_join/s_axi_ready
add wave -noupdate /test_axi_split_join/s_axi_valid
add wave -noupdate -expand -group {Split to Delay 1} /test_axi_split_join/asad1_axi_data
add wave -noupdate -expand -group {Split to Delay 1} /test_axi_split_join/asad1_axi_valid
add wave -noupdate -expand -group {Split to Delay 1} /test_axi_split_join/asad1_axi_ready
add wave -noupdate -expand -group {Delay 1 to Join} /test_axi_split_join/adaj1_axi_data
add wave -noupdate -expand -group {Delay 1 to Join} /test_axi_split_join/adaj1_axi_valid
add wave -noupdate -expand -group {Delay 1 to Join} /test_axi_split_join/adaj_axi_ready
add wave -noupdate -expand -group {Split to Delay 2} /test_axi_split_join/asad2_axi_data
add wave -noupdate -expand -group {Split to Delay 2} /test_axi_split_join/asad2_axi_valid
add wave -noupdate -expand -group {Split to Delay 2} /test_axi_split_join/asad2_axi_ready
add wave -noupdate -expand -group {Delay 2 to Join} /test_axi_split_join/adaj2_axi_data
add wave -noupdate -expand -group {Delay 2 to Join} /test_axi_split_join/adaj2_axi_valid
add wave -noupdate -expand -group {Delay 2 to Join} /test_axi_split_join/adaj_axi_ready
add wave -noupdate /test_axi_split_join/m_axi_data
add wave -noupdate /test_axi_split_join/m_axi_ready
add wave -noupdate /test_axi_split_join/m_axi_valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {170101 ps} 0}
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
WaveRestoreZoom {0 ps} {2194500 ps}
