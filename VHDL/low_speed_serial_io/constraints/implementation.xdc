#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# Constraints file required for implementation of the full LSSIO test design.
#
# P A Abbey, 19 December 2024
#
#####################################################################################

# [Place 30-172] Sub-optimal placement for a clock-capable IO pin and PLL pair. If this sub optimal
# condition is acceptable for this design, you may use the CLOCK_DEDICATED_ROUTE constraint in the
# .xdc file to demote this message to a WARNING. However, the use of this override is highly
# discouraged. These examples can be used directly in the .xdc file to override this clock rule.
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {pll_rx/inst/clk_in_pll_lssio}]
