onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_dpram_2clk/clk_perioda_c
add wave -noupdate /test_dpram_2clk/clka
add wave -noupdate /test_dpram_2clk/clk_periodb_c
add wave -noupdate /test_dpram_2clk/clkb
add wave -noupdate /test_dpram_2clk/rstb

add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/addr_bits_g
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/data_bits_g
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/primitive_g
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/read_latency_g
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/sleep
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/ena
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/wea
add wave -noupdate -expand -group DUT0 -radix hexadecimal /test_dpram_2clk/t(0)/dut/addra
add wave -noupdate -expand -group DUT0 -radix hexadecimal /test_dpram_2clk/t(0)/dut/dina
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/enb
add wave -noupdate -expand -group DUT0 -radix hexadecimal /test_dpram_2clk/t(0)/dut/addrb
add wave -noupdate -expand -group DUT0 -radix hexadecimal /test_dpram_2clk/t(0)/dut/doutb
add wave -noupdate -expand -group DUT0 /test_dpram_2clk/t(0)/dut/doutv

add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/addr_bits_g
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/data_bits_g
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/primitive_g
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/read_latency_g
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/sleep
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/ena
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/wea
add wave -noupdate -expand -group DUT1 -radix hexadecimal /test_dpram_2clk/t(1)/dut/addra
add wave -noupdate -expand -group DUT1 -radix hexadecimal /test_dpram_2clk/t(1)/dut/dina
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/enb
add wave -noupdate -expand -group DUT1 -radix hexadecimal /test_dpram_2clk/t(1)/dut/addrb
add wave -noupdate -expand -group DUT1 -radix hexadecimal /test_dpram_2clk/t(1)/dut/doutb
add wave -noupdate -expand -group DUT1 /test_dpram_2clk/t(1)/dut/doutv

add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/addr_bits_g
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/data_bits_g
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/primitive_g
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/read_latency_g
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/sleep
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/ena
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/wea
add wave -noupdate -expand -group DUT2 -radix hexadecimal /test_dpram_2clk/t(2)/dut/addra
add wave -noupdate -expand -group DUT2 -radix hexadecimal /test_dpram_2clk/t(2)/dut/dina
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/enb
add wave -noupdate -expand -group DUT2 -radix hexadecimal /test_dpram_2clk/t(2)/dut/addrb
add wave -noupdate -expand -group DUT2 -radix hexadecimal /test_dpram_2clk/t(2)/dut/doutb
add wave -noupdate -expand -group DUT2 /test_dpram_2clk/t(2)/dut/doutv

add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/addr_bits_g
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/data_bits_g
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/primitive_g
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/read_latency_g
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/sleep
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/ena
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/wea
add wave -noupdate -expand -group DUT3 -radix hexadecimal /test_dpram_2clk/t(3)/dut/addra
add wave -noupdate -expand -group DUT3 -radix hexadecimal /test_dpram_2clk/t(3)/dut/dina
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/enb
add wave -noupdate -expand -group DUT3 -radix hexadecimal /test_dpram_2clk/t(3)/dut/addrb
add wave -noupdate -expand -group DUT3 -radix hexadecimal /test_dpram_2clk/t(3)/dut/doutb
add wave -noupdate -expand -group DUT3 /test_dpram_2clk/t(3)/dut/doutv

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {21620000 ps} 0}
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
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {22785 ns}
