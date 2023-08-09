####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Useful TCL commands for manual invocation in Vivado when experimenting.
#
# P A Abbey, 9 August 2023
#
#####################################################################################

# Set top level generics
set_property generic [list \
  width=4100 \
  depth=2 \
] [current_fileset]

# Set top level generics
set_property generic [list \
  width=128 \
  depth=2 \
] [current_fileset]

set_property generic [list \
  width=4 \
  depth=2 \
] [current_fileset]

# List top level generics
get_property generic [current_fileset]

# Set the Xilinx Vivado generated file as "target" again
set_property target_constrs_file [get_files {xilinx_managed.xdc}] [get_filesets {constrs_xilinx}]
# The following returns the current target constraints file for a constraints set
# get_property target_constrs_file [get_filesets {constrs_xilinx}]
