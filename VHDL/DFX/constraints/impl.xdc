#####################################################################################
##
## Distributed under MIT Licence
##   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
##
#####################################################################################
##
## Implementation constraints for experimental design for partial reconfiguration.
##
## P A Abbey, 12 February 2025
##
#####################################################################################

# Define the reconfigurable region of the device.
create_pblock pblock_rp
set crp [get_cells reconfig_rp]
set prp [get_pblocks pblock_rp]
add_cells_to_pblock $prp $crp
resize_pblock $prp -add {SLICE_X36Y50:SLICE_X43Y74}
#resize_pblock $prp -add {RAMB18_X2Y29:RAMB18_X2Y20}
#resize_pblock $prp -add {RAMB36_X2Y14:RAMB36_X2Y10}

# The above is pretty much ignored without turning off the IS_SOFT property.
# The PBLOCK is "soft" by default which is unhelpful.
# Partial Reconfiguration changes a load of properties: IS_SOFT, EXCLUDE_PLACEMENT, CONTAIN_ROUTING
# Sets DONT_TOUCH on the specified cell and its interface nets. This prevents optimization across the
# boundary of the module.
#
# In order to implement a DFX design, it is required to specify each RM as such. To do this you must
# set a property on the top level of each hierarchical cell that is going to be reconfigurable.
# https://docs.amd.com/r/en-US/ug909-vivado-partial-reconfiguration/Define-a-Module-as-Reconfigurable
set_property HD.RECONFIGURABLE true $crp

# If the design uses the DRP interface of the 7 series XADC component, the interface is blocked (held
# in reset) during partial reconfiguration when RESET_AFTER_RECONFIG is enabled. The interface is
# non-responsive (busy), and there is no access during the length of the reconfiguration period. The
# interface becomes accessible again after partial reconfiguration is complete.
# https://docs.amd.com/r/en-US/ug909-vivado-partial-reconfiguration/Apply-Reset-After-Reconfiguration
#set_property -dict [list RESET_AFTER_RECONFIG {true}] $prp

# SNAPPING MODE property is applied on Pblocks to automatically adjust the size and shape. The property
# can be applied to Reconfigurable Partition Pblocks, to have them automatically adjusted to meet DFX
# floorplan requirements.
# https://docs.amd.com/r/en-US/ug912-vivado-properties/SNAPPING_MODE
set_property SNAPPING_MODE {ON} $prp
# report_property [get_pblocks {pblock_rp}]
