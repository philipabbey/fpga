####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# SCOPED_TO_REF constraints file for 'bus_data_valid_synch'.
#
# When inclusing this constraints file, be sure to set the following property in TCL.
#
#   set_property SCOPED_TO_REF bus_data_valid_synch [get_files constraints.xdc]
#
# References:
#  * Dynamic Timing Check For A Standard Clock Domain Crossing Solution
#    https://blog.abbey1.org.uk/index.php/technology/dynamic-timing-check-for-a-standard-clock-domain
#
# P A Abbey, 4 November 2023
#
#####################################################################################

set max_delay \
    [get_property PERIOD \
        [get_clocks -of_objects \
            [get_cells {data_out_reg[*]}]]]

set_max_delay -datapath_only \
    -from [get_cells {capture.di_reg[*]}] \
    -to   [get_cells {data_out_reg[*]}] \
    $max_delay

set_max_delay -datapath_only \
    -from [get_cells {capture.dv_in_reg}] \
    -to   [get_cells {dv_reg[0]}] \
    $max_delay

# The paths between 'di' and 'data_out' still come up as 'warnings' even though they are also marked as 'safe' with a set_max_delay exception.
create_waiver -type CDC -id CDC-15 \
  -from [get_pins {capture.di_reg[*]/C}] \
  -to   [get_pins {data_out_reg[*]/D}] \
  -user Author \
  -description {Controlled clock domain crossing of a data bus} \
  -tags {Data Valid CDC}
