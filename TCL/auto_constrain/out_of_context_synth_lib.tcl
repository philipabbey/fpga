####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# TCL library functions for automating the discovery of the correct clock domain to
# use for each input and output when when setting up out of context synthesis
# constraints. The plan is to find the register fed by or driven by an input or
# output port respectively. That is our first guess as to the correct clock domain,
# but is not an infallible method due to designer error. Hopefully designer errors
# will be detected by using 'report_cdc'. Care is also taken with inputs feeding an
# asychronous pin. By using this code, there is no longer any need to manually
# specify input and output constraints for each port, significantly reducing the
# effort required to set up OOC synthesis.
#
# References:
#  * Specifying Boundary Timing Constraints in Vivado
#    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
#  * Determining port clock domains for automating input and output constraints
#    https://blog.abbey1.org.uk/index.php/technology/...
#
# P A Abbey, 20 November 2022
#
####################################################################################

# References:
#  1. Cell Primitives Table, https://docs.xilinx.com/r/2022.1-English/ug912-vivado-properties/CELL
#
# Known issues:
#  * BlockRAMs, PRIMITIVE_TYPE  =~ "BLOCKRAM.BRAM.*", how to extract clock domain
#    given there could be two?
#    * Inputs directly feeding BlockRAMs
#    * Outputs directly driven by BlockRAMs
#    We would need to determine if knowledge of the net/pin could then be associated
#    precisely with just one of the two clocks through the list of cell properties,
#    e.g. name suffix matching? Then modify get_clock_port_of_registers, passing it
#    a second parameter that is the net attached (from fan-in/out in caller). This
#    would then be used to select which of the two clocks is returned. Primitives of
#    type "BLOCKRAM.BRAM.*" would then be a special case in the body of the procedure
#    to be handled separately to the single clocked primitives.
#
# If this TCL library simply does not work for your OOC synthesis, revert to manual
# specification of input and output constraints.
#
#   set_input_delay  -clock [get_clocks {...}] $input_delay  <input port>
#   set_output_delay -clock [get_clocks {...}] $output_delay <output port>
#
# Any manual set_false_path and set_max_delay constraints must go in the SCOPED_TO_REF
# constraints file, NOT HERE, for use in both OOC and the full image synthesis.
#


# Get the clock source of each cell in the supplied 'cells' list
#
# Usage: get_clock_port [get_selected_objects]
#
# Returns: Each cell listed with its clock name and clock source port
#          E.g. {{cell clock_name clock_port} {cell clock_name clock_port} ...}
#
# NB. Zynq devices have changed from using a PRIMITIVE_GROUP of "REGISTER", as
# used by Kintex devices, to "FLOP_LATCH" post synthesis.
#
proc get_clock_port_of_registers {cells} {
    set clklist {}
    foreach c $cells {
        # Filter out anything that is not a cell, need to cope with both RTL from elaboration and device primitives from synthesis
        # See Ref [1] for filter criteria
        if {[llength [get_cells -quiet $c -filter {
                PRIMITIVE_GROUP == "REGISTER"     ||
                PRIMITIVE_GROUP == "RTL_REGISTER" ||
                PRIMITIVE_GROUP == "FLOP_LATCH"   ||
                PRIMITIVE_TYPE  =~ "CLB.LUTRAM.*" ||
                PRIMITIVE_TYPE  =~ "CLB.SRL.*"
            }]] > 0} {
            set pins [get_pins -quiet -of_objects $c -filter {IS_CLOCK}]
            if {[llength $pins] > 0} {
                set clksrc [get_clocks -of_objects $pins]
            } else {
                # LUTRAM have a CLK pin that do not have their IS_CLOCK property set to 1.
                set clksrc [get_clocks -of_objects $c]
            }
            lappend clklist [list $c $clksrc [get_property SOURCE_PINS $clksrc]]
        }
    }
    return $clklist
}

# Returns a dictionary of lists such that each input port is associated with a list
# of destination registers each associated with its clock name and clock input port.
# If the input is asynchronous, then the string ASYNC is appended to the inner list
# after the clock domain and clock pin. This provides warning that the destination
# register's clock domain is not an indicator of the input port's originating clock
# domain.
#
# Usage:
#   get_clock_for_input_port [get_ports {port1 port2} -filter {DIRECTION == "IN"}]
#   get_clock_for_input_port [all_inputs]
#
# Returns:
#   {flags_in[0]} {{{flags_in_i_reg[0]} clk_src_nm clk_src}}
#   {flags_in[1]} {{{flags_in_i_reg[1]} clk_src_nm clk_src}}
#   {flags_in[2]} {{{flags_in_i_reg[2]} clk_src_nm clk_src}}
#   {flags_in[3]} {{{flags_in_i_reg[3]} clk_src_nm clk_src}}
#   reset_dest {
#     {{retime_i/reg_retime_reg[4][3]} clk_dest_nm clk_dest ASYNC}
#     :
#     {{retime_i/reg_retime_reg[0][0]} clk_dest_nm clk_dest ASYNC}
#     {{flags_out_reg[3]} clk_dest_nm clk_dest}
#     :
#     {{flags_out_reg[0]} clk_dest_nm clk_dest}
#   }
#   reset_src {
#     {{retime_i/reg_capture_reg[3]} clk_src_nm clk_src}
#     :
#     {{retime_i/reg_capture_reg[0]} clk_src_nm clk_src}
#     {{flags_in_i_reg[3]} clk_src_nm clk_src}
#     :
#     {{flags_in_i_reg[0]} clk_src_nm clk_src}
#   }
#
# NB. Zynq devices have changed from using a PRIMITIVE_GROUP of "REGISTER", as
# used by Kintex devices, to "FLOP_LATCH" post synthesis.
#
proc get_clock_for_input_ports {ports} {
    set clklist [dict create]
    foreach p $ports {
        if {[llength [get_clocks -of_objects $p -quiet]] == 0} {
            set fo [filter [all_fanout -flat $p] -filter {!IS_CLOCK}]
            set reglist {}
            foreach f $fo {
                # Filter out anything that is not a cell, need to cope with both RTL from elaboration and device primitives from synthesis
                # See Ref [1] for filter criteria
                set c [get_cells -quiet -of_objects $f -filter {
                    PRIMITIVE_GROUP == "REGISTER"     ||
                    PRIMITIVE_GROUP == "RTL_REGISTER" ||
                    PRIMITIVE_GROUP == "FLOP_LATCH"   ||
                    PRIMITIVE_TYPE  =~ "CLB.LUTRAM.*" ||
                    PRIMITIVE_TYPE  =~ "CLB.SRL.*"
                }]
                if {[llength $c]} {
                    set r [get_clock_port_of_registers $c]
                    if {[llength $r] == 0} {
                        error "ERROR: get_clock_for_input_ports - 'get_clock_port_of_registers $c' returned no registers."
                    }
                    set l {*}$r
                    # Is $f the reset pin to $c or a data pin?
                    #
                    #  * Data pin to a register with property ASYNC_REG - Mark input ASYNC for false path (later)
                    #  * Cell with XPM_CDC property ASYNC_RST           - Mark input ASYNC for false path (later), UltraScale specific,
                    #                                                     no pin properties IS_CLEAR || IS_PRESET yet (argh!)
                    #  * Asynchronous reset pin                         - Mark input ASYNC for false path (later), e.g. cell name
                    #                                                     RTL_REG_ASYNC, pin properties IS_CLEAR || IS_PRESET
                    #  * Synchronous reset pin                          - No ASYNC_REG to ensure it remains a timed path, e.g. pin
                    #                                                     properties IS_RESET || IS_SET
                    #
                    # Another strategy for cells with XPM_CDC properties (any value) is to mark them (e.g. with an optional "XPM") for
                    # absolutely no treatment later and allow XPMs to sort themselves out with their own constraints. However the XPM
                    # constraints are not marking them up themselves. Watch and learn here.
                    #
                    # NB. Need to cater for a synchronous reset feeding an ASYNC_REG register, hence the check for both sorts of reset pins.
                    #
                    # NB. pins with IS_SETRESET give us problems: Programmable synchronous or asynchronous set/reset. The pin's behavior is
                    # controlled by an attribute on the block. E.g. The RSTRAMB pin on a RAMB36E2. Ignore for now, as IS_SETRESET is set
                    # when IS_RESET is also set, so the documentation is not sufficiently complete on this attribute.
                    #
                    #  if {[llength [get_pins -quiet -of_objects $c -filter {IS_SETRESET}]] > 0} {
                    #      error "ERROR: get_clock_for_input_ports - 'IS_SETRESET' property used on an input pin of '$c', the script cannot handle these."
                    #  }
                    #
                    set asyncrsts [get_pins -quiet -of_objects $c -filter {IS_CLEAR || IS_PRESET}]
                    set syncrsts [get_pins -quiet -of_objects $c -filter {IS_RESET || IS_SET}]
                    if {(([get_property ASYNC_REG $c] == 1) ||
                         (([string equal [get_property XPM_CDC $c] "ASYNC_RST"]) && ([string match "*/CLR" $f])) ||
                         (([llength $asyncrsts] > 0) && ([lsearch -exact $asyncrsts $f] >= 0))) &&
                        !(([llength $syncrsts] > 0) && ([lsearch -exact $syncrsts $f] >= 0))} {
                        lappend l {ASYNC}
                    }
                    lappend reglist $l
                }
            }
            if {[llength $fo] > 0} {
                dict set clklist $p $reglist
            }
        }
    }
    return $clklist
}

# Returns a dictionary of lists such that each output port is associated with a list
# of source registers paired with its clock name and clock input port. NB. There can
# be more than one source register if the output port is not directly registered but
# instead includes combinatorial logic.
#
# Usage:
#   get_clock_for_output_ports [get_ports {port1 port2} -filter {DIRECTION == "OUT"}]
#   get_clock_for_output_ports [all_outputs]
#
# Returns:
#   {flags_out[0]} {{{flags_out_reg[0]} clk_dest_nm clk_dest}}
#   {flags_out[1]} {{{flags_out_reg[1]} clk_dest_nm clk_dest}}
#   {flags_out[2]} {{{flags_out_reg[2]} clk_dest_nm clk_dest}}
#   {flags_out[3]} {{{flags_out_reg[3]} clk_dest_nm clk_dest}}
#
proc get_clock_for_output_ports {ports} {
    set clklist [dict create]
    foreach p $ports {
        set fi [filter [all_fanin -flat $p] -filter {IS_CLOCK}]
        set reglist {}
        foreach f $fi {
            set c [get_cells -of_objects $f -quiet]
            if {[llength $c]} {
                lappend reglist {*}[get_clock_port_of_registers $c]
            }
        }
        if {[llength $fi] > 0} {
            dict set clklist $p $reglist
        }
    }
    return $clklist
}

# Process the port data dictionary returned by 'get_clock_for_input_port' and
# 'get_clock_for_output_ports' and list the distinct clock names per port. The hope is
# that the value for each key is a list of length one. If not then a port is feeding or
# being fed by mutliple clock domains. Any clock domain marked as terminating at an
# asynchronous input is omitted.
#
# Parameters:
#   port_data - A dictionary produced by either 'get_clock_for_input_port' or
#               'get_clock_for_output_ports'.
#
# Usage:
#   unique_clock_domains [get_clock_for_input_ports  [all_inputs]]
#   unique_clock_domains [get_clock_for_output_ports [all_outputs]]
#
# Return:
#   # Port        Clock name list
#   {flags_in[0]} clk_src_nm
#   {flags_in[1]} {clk_src_nm clk_dest_nm}
#   {flags_in[2]} clk_src_nm
#   {flags_in[3]} clk_src_nm
#   reset_dest    clk_dest_nm
#   reset_src     clk_src_nm
#
proc unique_clock_domains {port_data} {
    set clklist [dict create]
    dict for {port data} $port_data {
        set clks {}
        foreach d $data {
            if {![string equal [lindex $d 3] "ASYNC"]} {
                set clkgrp [lindex $d 1]
                if {[lsearch $clks $clkgrp] < 0} {
                    lappend clks $clkgrp
                }
            }
        }
        dict set clklist $port $clks
    }
    return $clklist
}

# Process the port data dictionary returned by 'get_clock_for_input_port' and
# 'get_clock_for_output_ports' and count the distinct clock names per port. Return
# the maximum number of unique clock names per port. The hope is this value is 1,
# i.e. no port in the port_data has more then a single clock domain. Any clock
# domain marked as terminating in an input marked as ASYNC is omitted.
#
# Usage:
#   is_single_clock_domain_per_port [get_clock_for_input_ports  [all_inputs]]
#   is_single_clock_domain_per_port [get_clock_for_output_ports [all_outputs]]
#
# Return:
#   0 - All ports feed ASYNC inputs                           - GOOD
#   1 - All ports feed or are driven by a single clock domain - GOOD
#  >1 - Some ports feed or are fed by multiple clock domains  - BAD
#
proc is_single_clock_domain_per_port {port_data} {
    set clklist [unique_clock_domains $port_data]
    set min 0
    dict for {port data} $clklist {
        set l [llength $data]
        if {$l > $min} {
            set min $l
        }
    }
    return $min
}

# find_multiple_clock_domain_ports [get_clock_for_input_ports  [all_inputs]]
# find_multiple_clock_domain_ports [get_clock_for_output_ports [all_outputs]]
#
proc find_multiple_clock_domain_ports {port_data} {
    set clklist [unique_clock_domains $port_data]
    set ret {}
    dict for {port data} $clklist {
        set l [llength $data]
        if {$l > 1} {
            puts "$port $l '$data'"
            lappend ret [list $port $data]
        }
    }
    return $ret
}

# Automatically apply input and output timing constraints for OOC synthesis.
#
# Parameters:
#   input_delay  - The input delay to use with 'set_input_delay' in ns
#   output_delay - The output delay to use with 'set_output_delay' in ns
#   verbose      - 0 or 1, control echo'ing of constraints to the transcript for
#                  visibility of execution.
#
# Usage: setup_port_constraints $input_delay $output_delay
#
# Observation: Using 'set_max_delay' instead of 'set_false_path' means that the
# corresponding input port is reported by static timing analysis to be partially
# constrained. To correct this, both a '-min' and a '-max' input delay must be
# set. Except we want them set to the same value for OOC synthesis, and the tool
# collapses the two separate min/max constraints into one constraint and
# continues to warn about the partially constrained input. XPM use false paths.
#
proc setup_port_constraints {input_delay output_delay {verbose 0}} {
    set inputs_ports [get_clock_for_input_ports [all_inputs]]
    if {$verbose} {
        puts "--- Start automatically derived constraints by out_of_context_synth_lib.tcl ---"
    }
    if {[is_single_clock_domain_per_port $inputs_ports] <= 1} {
        dict for {port data} $inputs_ports {
            # We've checked there's only a single clock domain in the list to worry about, but
            # we might want to set up false paths from any ports to each ASYNC input.
            set setopd 0
            foreach d $data {
                # d = {register clock_name clock_port ?ASYNC?}
                if {[string equal [lindex $d 3] "ASYNC"]} {
                    if {$verbose} {
                        puts "set_false_path -from $port -to [lindex $d 0]"
                    }
                    # Don't false path the reset though, that must be timed to the register's clock.
                    set_false_path -from $port -to [lindex $d 0]
                    # Alternative is: set_max_delay -datapath_only -from [get_ports $port] -to [lindex $d 0] [get_property PERIOD [get_clocks [lindex $d 1]]]
                    # See observation above.
                } elseif {! $setopd} {
                    # Only need to set up this constraint the first time
                    set setopd 1
                    if {$verbose} {
                        puts "set_input_delay -clock [get_clocks [lindex $d 1]] $input_delay $port"
                    }
                    set_input_delay -clock [get_clocks [lindex $d 1]] $input_delay $port
                }
            }
        }
    } else {
        error "ERROR: Multiple clock domains detected on at least one input port."
        puts [find_multiple_clock_domain_ports $inputs_ports]
    }

    set output_ports [get_clock_for_output_ports [all_outputs]]
    if {[is_single_clock_domain_per_port $output_ports] == 1} {
        dict for {port data} $output_ports {
            # We've checked there's only a single clock domain in the list to worry about.
            set d [lindex $data 0]
            # d = {register clock_name clock_port}
            if {$verbose} {
                puts "set_output_delay -clock [get_clocks [lindex $d 1]] $output_delay $port"
            }
            set_output_delay -clock [get_clocks [lindex $d 1]] $output_delay $port
        }
    } else {
        error "ERROR: Multiple clock domains detected on at least one output port."
        puts [find_multiple_clock_domain_ports $output_ports]
    }
    if {$verbose} {
        puts "---- End automatically derived constraints by out_of_context_synth_lib.tcl ----"
    }
}
