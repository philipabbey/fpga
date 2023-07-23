onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /test_dpram_err/addr_bits_c
add wave -noupdate /test_dpram_err/data_bits_c
add wave -noupdate /test_dpram_err/blockram_c
add wave -noupdate /test_dpram_err/clk_period_c
add wave -noupdate /test_dpram_err/clk
add wave -noupdate /test_dpram_err/reset
add wave -noupdate /test_dpram_err/ena
add wave -noupdate /test_dpram_err/wea
add wave -noupdate -radix unsigned /test_dpram_err/addra
add wave -noupdate -radix unsigned /test_dpram_err/dina
add wave -noupdate /test_dpram_err/dut/regceb
add wave -noupdate /test_dpram_err/enb
add wave -noupdate -radix unsigned /test_dpram_err/addrb
add wave -noupdate -radix unsigned /test_dpram_err/doutb
add wave -noupdate /test_dpram_err/dut/ram_i/injectsbiterra
add wave -noupdate /test_dpram_err/dut/ram_i/injectdbiterra
add wave -noupdate /test_dpram_err/dut/ram_i/sbiterrb
add wave -noupdate /test_dpram_err/dut/ram_i/dbiterrb
add wave -noupdate /test_dpram_err/written
add wave -noupdate /test_dpram_err/finished
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/MEMORY_SIZE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/MEMORY_PRIMITIVE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/CLOCKING_MODE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/ECC_MODE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/ECC_TYPE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/ECC_BIT_RANGE
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/MEMORY_INIT_FILE
add wave -noupdate -group Generics -radix symbolic /test_dpram_err/dut/ram_i/MEMORY_INIT_PARAM
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/USE_MEM_INIT
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/USE_MEM_INIT_MMI
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/WAKEUP_TIME
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/AUTO_SLEEP_TIME
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/MESSAGE_CONTROL
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/USE_EMBEDDED_CONSTRAINT
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/MEMORY_OPTIMIZATION
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/CASCADE_HEIGHT
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/SIM_ASSERT_CHK
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/WRITE_PROTECT
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/IGNORE_INIT_SYNTH
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/WRITE_DATA_WIDTH_A
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/BYTE_WRITE_WIDTH_A
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/ADDR_WIDTH_A
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/RST_MODE_A
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/READ_DATA_WIDTH_B
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/ADDR_WIDTH_B
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/READ_RESET_VALUE_B
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/READ_LATENCY_B
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/WRITE_MODE_B
add wave -noupdate -group Generics -radix ascii /test_dpram_err/dut/ram_i/RST_MODE_B
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_MEMORY_PRIMITIVE
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_CLOCKING_MODE
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_ECC_MODE
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_WAKEUP_TIME
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_WRITE_MODE_B
add wave -noupdate -group Generics /test_dpram_err/dut/ram_i/P_MEMORY_OPTIMIZATION
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15213888 ps} 0}
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
WaveRestoreZoom {0 ps} {15177750 ps}
