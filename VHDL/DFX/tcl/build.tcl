####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Build script for static plus 4 reconfigurable partitions.
#
# P A Abbey, 12 February 2025
#
####################################################################################
#
# source -notrace {<path>/DFX/tcl/build.tcl}

set src_dir {<path>/DFX/products}

# Delete all previous products
set fs [glob -nocomplain $src_dir/*]
if {[llength $fs] > 0} {
  file delete {*}$fs
}

set_property top zybo_z7_10 [current_fileset]
set_property generic rm_num_g=1 [current_fileset]
reset_run synth_1
launch_runs synth_1 -jobs 14
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 14
wait_on_run impl_1

# After implementation
open_run impl_1
# Static + RM1
write_bitstream -force "$src_dir/initial.bit"

# RM1 only
set crp [get_cells {reconfig_rp}]
write_bitstream -force -cell $crp "$src_dir/rm1.bit"
update_design -cell $crp -black_box
lock_design -level routing
# Static only
write_checkpoint -force "$src_dir/static.dcp"
write_bitstream -force "$src_dir/static.bit"

foreach rm {2 3 4} {
  set_property generic rm_num_g=$rm [current_fileset]
  reset_run synth_1
  launch_runs synth_1 -jobs 14
  wait_on_run synth_1
  open_run synth_1
  write_checkpoint -force -cell $crp "$src_dir/synth_rm${rm}.dcp"
  # Create a new Vivado instance briefly for RM
  create_project -part xc7z010clg400-1 -in_memory "Stitch RM${rm}"
  add_files "$src_dir/static.dcp"
  add_files "$src_dir/synth_rm${rm}.dcp"
  set_property SCOPED_TO_CELLS {reconfig_rp} [get_files "$src_dir/synth_rm${rm}.dcp"]
  link_design -top {zybo_z7_10} -part xc7z010clg400-1 -reconfig_partitions {reconfig_rm}
  opt_design
  place_design
  route_design
  write_bitstream -force -cell $crp "$src_dir/rm${rm}.bit"
  close_project
}

# 
# # PLL woes
# reset_target all [get_files  <path>/DFX/ip/pll/pll.xci]
# config_ip_cache -clear_output_repo
