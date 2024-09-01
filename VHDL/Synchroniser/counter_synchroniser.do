onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /test_counter_synchroniser/width_c
add wave -noupdate -radix unsigned /test_counter_synchroniser/len_c
add wave -noupdate /test_counter_synchroniser/reset_f
add wave -noupdate /test_counter_synchroniser/reset_s
add wave -noupdate -expand -group {Slow Count (1)} -expand -group Write /test_counter_synchroniser/clk_s
add wave -noupdate -expand -group {Slow Count (1)} -expand -group Write -radix unsigned /test_counter_synchroniser/cnt1_s
add wave -noupdate -expand -group {Slow Count (1)} -radix binary /test_counter_synchroniser/counter_synchroniser_sf/gray
add wave -noupdate -expand -group {Slow Count (1)} -radix binary -childformat {{/test_counter_synchroniser/counter_synchroniser_sf/gray_sync(0) -radix binary} {/test_counter_synchroniser/counter_synchroniser_sf/gray_sync(1) -radix binary} {/test_counter_synchroniser/counter_synchroniser_sf/gray_sync(2) -radix binary}} -subitemconfig {/test_counter_synchroniser/counter_synchroniser_sf/gray_sync(0) {-height 15 -radix binary} /test_counter_synchroniser/counter_synchroniser_sf/gray_sync(1) {-height 15 -radix binary} /test_counter_synchroniser/counter_synchroniser_sf/gray_sync(2) {-height 15 -radix binary}} /test_counter_synchroniser/counter_synchroniser_sf/gray_sync
add wave -noupdate -expand -group {Slow Count (1)} -expand -group Read /test_counter_synchroniser/clk_f
add wave -noupdate -expand -group {Slow Count (1)} -expand -group Read -radix unsigned /test_counter_synchroniser/cnt1_f
add wave -noupdate -expand -group {Fast Count (2)} -expand -group Write /test_counter_synchroniser/clk_f
add wave -noupdate -expand -group {Fast Count (2)} -expand -group Write -radix unsigned /test_counter_synchroniser/cnt2_f
add wave -noupdate -expand -group {Fast Count (2)} -radix binary /test_counter_synchroniser/counter_synchroniser_fs/gray
add wave -noupdate -expand -group {Fast Count (2)} -radix binary -childformat {{/test_counter_synchroniser/counter_synchroniser_fs/gray_sync(0) -radix binary} {/test_counter_synchroniser/counter_synchroniser_fs/gray_sync(1) -radix binary} {/test_counter_synchroniser/counter_synchroniser_fs/gray_sync(2) -radix binary}} -subitemconfig {/test_counter_synchroniser/counter_synchroniser_fs/gray_sync(0) {-height 15 -radix binary} /test_counter_synchroniser/counter_synchroniser_fs/gray_sync(1) {-height 15 -radix binary} /test_counter_synchroniser/counter_synchroniser_fs/gray_sync(2) {-height 15 -radix binary}} /test_counter_synchroniser/counter_synchroniser_fs/gray_sync
add wave -noupdate -expand -group {Fast Count (2)} -expand -group Read /test_counter_synchroniser/clk_s
add wave -noupdate -expand -group {Fast Count (2)} -expand -group Read -radix unsigned /test_counter_synchroniser/cnt2_s
add wave -noupdate -expand -group {Count 1 > 2 Slow} -radix unsigned /test_counter_synchroniser/cnt1_s
add wave -noupdate -expand -group {Count 1 > 2 Slow} -radix unsigned /test_counter_synchroniser/cnt2_s
add wave -noupdate -expand -group {Count 1 > 2 Slow} /test_counter_synchroniser/gt12_s
add wave -noupdate -expand -group {Count 1 > 2 Fast} -radix unsigned /test_counter_synchroniser/cnt1_f
add wave -noupdate -expand -group {Count 1 > 2 Fast} -radix unsigned /test_counter_synchroniser/cnt2_f
add wave -noupdate -expand -group {Count 1 > 2 Fast} /test_counter_synchroniser/gt12_f
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {19309401 ps} 0}
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
WaveRestoreZoom {16981758 ps} {19469928 ps}
