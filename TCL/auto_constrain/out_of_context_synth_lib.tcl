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
# Verification:
#
# It is possible to verify the hold and setup times used by OOC synthesis by querying
# the synthesised design. 'check_setup_hold_times' provides this verification by finding
# the pins fed by or driving the ports and pulling timing data out of the "timing arcs".
# This requires a synthesised design to be open. A reliable way to run these checks is
# via the 'synth_check_setup_hold_times' command which ensures the synthesied design is
# open (and performs synthesis if required). The parameters 'ths' & 'tsus' are taken
# from the standard ooc.tcl template.
#
# Usage: synth_check_setup_hold_times $ths $tsus
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
        if {[llength [get_cells -quiet $c -filter {IS_SEQUENTIAL}]] > 0} {
            set pins [get_pins -quiet -of_objects $c -filter {IS_CLOCK}]
            if {[llength $pins] > 0} {
                set clksrc [get_clocks -quiet -of_objects $pins]
                # This might not return a value, but the pin is connected to a clock port, so trace it back to the origins.
                if {[llength $clksrc] == 0} {
                    set clksrc [get_clocks -of_objects [all_fanin -flat -startpoints_only $pins]]
                }
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
            if {[llength $fo] > 0} {
                set reglist {}
                foreach f $fo {
                    # Filter out anything that is not a cell, need to cope with both RTL from elaboration and device primitives from synthesis
                    # See Ref [1] for filter criteria
                    set c [get_cells -quiet -of_objects $f -filter {IS_SEQUENTIAL}]
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
        set fi [filter [all_fanin -quiet -flat $p] -filter {IS_CLOCK}]
        if {[llength $fi] > 0} {
            set reglist {}
            foreach f $fi {
                set c [get_cells -of_objects $f -quiet]
                if {[llength $c]} {
                    lappend reglist {*}[get_clock_port_of_registers $c]
                }
            }
            dict set clklist $p $reglist
        }
    }
    return $clklist
}

# Process the port data dictionary returned by 'get_clock_for_input_port' and
# 'get_clock_for_output_ports' and list the distinct clock names and source pins per port. The hope is
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
#   # Port        Clock name and pin list
#   {flags_in[0]} {clk_src_nm clk_pin}
#   {flags_in[1]} {{clk_src_nm clk_pin} {clk_dest_nm clk_pin}}
#   {flags_in[2]} {clk_src_nm clk_pin}
#   {flags_in[3]} {clk_src_nm clk_pin}
#   reset_dest    {clk_dest_nm clk_pin}
#   reset_src     {clk_src_nm clk_pin}
#
proc unique_clock_domains {port_data} {
    set clklist [dict create]
    dict for {port data} $port_data {
        set clks {}
        foreach d $data {
            if {![string equal [lindex $d 3] "ASYNC"]} {
                set clkgrp [lindex $d 1]
                set clkpin [lindex $d 2]
                set item [list $clkgrp $clkpin]
                if {[lsearch -exact $clks $item] < 0} {
                    lappend clks $item
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

# When 'is_single_clock_domain_per_port' says there are multiple clock domains per port,
# this function will list the offending port and the clocks for debugging.
#
# Usage:
#   find_multiple_clock_domain_ports [get_clock_for_input_ports  [all_inputs]]
#   find_multiple_clock_domain_ports [get_clock_for_output_ports [all_outputs]]
#
# Return:
#   {port} {{clock_name clock_port}}
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
        puts "--- Start automatically derived constraints by auto_constrain_lib.tcl ---"
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
        puts "---- End automatically derived constraints by auto_constrain_lib.tcl ----"
    }
    puts "INFO Out of Context Synthesis: Call 'synth_check_setup_hold_times \$ths \$tsus' to check hold and setup time values."
}

# For an input list of pairs: {{delay1 primitive1} {delay2 primitive2} {delay3 primitive3}}
# Return the pair with the largest 'delay' value.
#
# Usage: max_delay {{1 a} {3 c} {2 b}} => {3 c}
#
proc max_delay {delay_list} {    
    # TCL floating point number range: https://www.tcl.tk/man/tcl8.5/tutorial/Tcl6a.html
    set mv -1.0e+300
    set ret {}
    # {d p} = {delay primitive_type}
    foreach pair $delay_list {
        set d [lindex $pair 0]
        set p [lindex $pair 1]
        if {$d > $mv} {
            set mv $d
            set ret [list $d $p]
        }
    }
    return $ret
}

# For input ports only, fetch the maximum hold time of a pin in the fanout of each port. Also
# provide the primitive as that might explain any surprises.
#
# Usage: get_hold_times [all_inputs]
#
# Returns: A list of pairs {input_port details}, where 'details' is a list of the form {hold_time primitive_type}.
#   {
#     # input_port {hold_time primitive_type}
#     m_axis_ready {0.108 REGISTER.SDR.FDCE}
#     {m_node_vector[0][major_type][0]} {0.108 REGISTER.SDR.FDRE}
#     {m_node_vector[0][major_type][10]} {0.108 REGISTER.SDR.FDRE}
#   }
#
proc get_hold_times {ports} {
    set portdelays [dict create]
    foreach p $ports {
        # Exclude aysynchronous resets pins
        set fo [filter [all_fanout -quiet -endpoints_only -flat $p] -filter {!IS_CLOCK && !IS_CLEAR && !IS_PRESET}]
        if {[llength $fo] > 0} {
            set dl {}
            foreach f $fo {
                # Hold_FDRE_C_D
                lappend dl [list \
                    [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -to $f -filter {TYPE == "hold"}]] \
                    [get_property PRIMITIVE_TYPE [get_cells -of_objects $f]] \
                ]
            }
            # All values in the list tend to be the same
            dict set portdelays $p [max_delay $dl]
        }
    }
    return $portdelays
}

# For output ports only, fetch the maximum setup time of a pin in the fanin of each port. Also
# provide the primitive as that might explain any surprises.
#
# Usage: get_setup_times [all_outputs]
#
# Returns: A list of pairs {output_port details}, where 'details' is a list of the form {setup_time primitive_type}.
#   {
#     # output_port {setup_time primitive_type}
#     irq {0.000 REGISTER.SDR.FDRE}
#     {m_axis_data[tdata][0]} {0.047 REGISTER.SDR.FDRE}
#     {m_axis_data[tdata][10]} {0.047 REGISTER.SDR.FDRE}
#     {m_axis_data[tdata][11]} {0.047 REGISTER.SDR.FDRE}
#   }
#
proc get_setup_times {ports} {
    set portdelays [dict create]
    foreach p $ports {
        set dl {}
        set fi [filter [all_fanin -quiet -flat $p] -filter {(DIRECTION == OUT) && (CLASS == pin)}]
        foreach f $fi {
            set c [get_cells -of_objects $f]
            set l [dict create]
            foreach a [get_timing_arcs -quiet -to [get_pins -of_objects $c -filter {
                DIRECTION == IN &&
                !IS_CLOCK &&
                !IS_CLEAR && !IS_PRESET &&
                !IS_RESET && !IS_SET
            }] -filter {TYPE == "setup"}] {
                dict set l [get_property TO_PIN $a] [list \
                    [get_property DELAY_SLOW_MAX_RISE $a] \
                    [get_property PRIMITIVE_TYPE $c] \
                ]
            }
            if {[llength $l] > 0} {
                lappend dl [max_delay [dict values $l]]
            }
        }
        if {[llength $fi] > 0} {
            # All values in the list tend to be the same
            dict set portdelays $p [max_delay $dl]
        }
    }
    return $portdelays
}

# Verify the hold and setup times supplied at parameters match the synthesised design's expected hold
# and setup times. Note this check can only be done *after* synthesis when the timing arcs are
# available, hence this is a check after the fact rather than a value extraction for constraints before
# synthesis.
#
# NB. Requires a synthesised design to be open. Call 'synth_check_setup_hold_times' instead if not.
#
# Usage: check_setup_hold_times $ths $tsus 1
#
proc check_setup_hold_times {hold_time setup_time {verbose 0} {design synth_1}} {
    set hold_design  [max_delay [dict values [get_hold_times [all_inputs]]]]
    # Delay
    set hdd [lindex $hold_design 0]
    # Primitive
    set hdp [lindex $hold_design 1]
    set setup_design [max_delay [dict values [get_setup_times [all_outputs]]]]
    # Delay
    set sdd [lindex $setup_design 0]
    # Primitive
    set sdp [lindex $setup_design 1]
    if {$hdd != $hold_time} {
        puts "WARNING in '[lindex [info level 0] 0]': Specified hold time '$hold_time ns' does not match input ports' maximum hold time of '$hdd ns' on a '$hdp' primtive."
    } else {
        if {$verbose} {
            puts "INFO in '[lindex [info level 0] 0]': Specified hold time matches input ports' maximum hold time of '$hdd ns' on a '$hdp' primtive."
        }
    }
    if {$sdd != $setup_time} {
        puts "WARNING in '[lindex [info level 0] 0]': Specified hold time '$setup_time ns' does not match output ports' maximum hold time of '$sdd ns' on a '$sdp' primtive."
    } else {
        if {$verbose} {
            puts "INFO in '[lindex [info level 0] 0]': Specified hold time matches output ports' maximum hold time of '$sdd ns' on a '$sdp' primtive."
        }
    }
}

# Check we have the sythesised design open, or perform synthesis. Then extract the timing for the
# input and output ports against which the supplied parameters used in the constraints file will
# be checked.
#
# Usage: synth_check_setup_hold_times $ths $tsus
#
proc synth_check_setup_hold_times {ths tsus {synth synth_1} {jobs 6}} {
    set d [current_design -quiet]
    set synth_run [get_runs $synth]
    set must_refesh [get_property NEEDS_REFRESH $synth_run]
    if {[llength $d] > 0} {
        if {![string equal [lindex $d 0] $synth]} {
            puts "Closing design [lindex $d 0] as it is not a synthesis run."
            close_design
        } elseif {$must_refesh} {
            puts "Closing design [lindex $d 0] at it is out of date."
            close_design
        }
    }
    if {$must_refesh || [string equal [get_property PROGRESS $synth_run] "0%"]} {
        reset_run $synth
        launch_runs $synth -jobs $jobs
        wait_on_run $synth
    }
    set d [current_design -quiet]
    if {[llength $d] == 0} {
        open_run $synth -name $synth
    }
    # Open a schematic of the basic design - The created window distracts from the TCL console where the result is printed.
    #report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_synth
    # Check the TCL console for the printed results.
    check_setup_hold_times $ths $tsus 1
}

# Each of these results drives a clock at a sequential primitive and hence must have a constraint to set up a
# clock, e.g. 'create_clock'. This function provides a simple design check.
#
# Usage: design_clock_pins => { user_clks[user_clk_375] sys_ctrl_clk }
#
proc design_clock_pins {} {
    return [all_fanin -startpoints_only -flat [get_pins -of_objects [get_cells -hier -filter {IS_SEQUENTIAL}] -filter {IS_CLOCK}]]
}

# Perform a simple check that all clocks have been defined for this design.
# Requires a design to be open, elaborated at least.
#
# Usage: check_design_clocks
#
proc check_design_clocks {} {
    set clkports [design_clock_pins]
    foreach clk $clkports {
        set clk_name [get_clocks -quiet -of_objects $clk]
        if {[llength $clk_name] > 0} {
            puts "INFO in '[lindex [info level 0] 0]': Clock port '[get_property SOURCE_PINS $clk_name]' has clock name '$clk_name' with period '[get_property PERIOD $clk_name] ns'."
        } else {
            puts "WARNING in '[lindex [info level 0] 0]': '$clk' is used to drive a clock without a clock definition."
        }
    }
}
