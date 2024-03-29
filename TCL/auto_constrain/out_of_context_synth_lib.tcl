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
# To debug the use of this script:
#   1.  Open an elaborated design (synth_design -rtl -name rtl_1 -mode out_of_context)
#   2.  source -notrace {path\to\auto_constrain_lib.tcl}
#
# References:
#  * Specifying Boundary Timing Constraints in Vivado
#    https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado
#  * Determining port clock domains for automating input and output constraints
#    https://blog.abbey1.org.uk/index.php/technology/determining-port-clock-domains-for-automating-input-and
#
# P A Abbey, 20 November 2022
#
####################################################################################

# References:
#  1. Cell Primitives Table, https://docs.xilinx.com/r/2022.1-English/ug912-vivado-properties/CELL
#
# Known issues:
#  * BlockRAMs, PRIMITIVE_TYPE  =~ "BLOCKRAM.BRAM.*", how to extract clock domain
#    given there could be two different ones?
#    We detect the presence of multiple clock primitives and extract both. Later this
#    is found and managed. Constraints for such input ports must be set manually.
#
# If this TCL library simply does not work for your OOC synthesis, revert to manual
# specification of input and output constraints.
#
#   set_input_delay  -clock [get_clocks {...}] $input_delay  [get_ports <input port>]
#   set_output_delay -clock [get_clocks {...}] $output_delay [get_ports <output port>]
#
# Any manual set_false_path and set_max_delay constraints must go in the SCOPED_TO_REF
# constraints file, NOT HERE, for use in both OOC and the full image synthesis.
#
# Verification:
#
# It is possible to verify the hold and setup times, clock setup and input and output
# delay application used by OOC synthesis by querying the synthesised design.
# 'check_setup_hold_times' provides these verifications by finding the pins fed by or driving
# the ports and pulling timing data out of the "timing arcs" and 'check_port_constraints'
# checks the input and output delays from each port's "timing paths" to ensure every port has
# been constrained. This requires a synthesised design to be open. A reliable way to run
# these checks is via the 'check_ooc_setup' command which ensures the synthesied design is
# open (and performs synthesis if required). The parameters 'tsus' & 'ths' are taken
# from the standard ooc.tcl template.
#
# Usage: check_ooc_setup $ths $tsus
#


# Get the clock source of each cell in the supplied 'cells' list
#
# Usage: get_clock_port_of_registers [get_selected_objects]
#
# Returns: Each cell listed with its clock name and clock source port
#          E.g. {{cell clock_name clock_port} {cell clock_name clock_port} ...}
#
# An exception is made here for primitives with no clocks, where the return format will
# include a list element of the format:
#          {cell NOTSET clock_port}
#
proc get_clock_port_of_registers {cells} {
    set clklist {}
    foreach c $cells {
        # Filter out anything that is not a cell, need to cope with both RTL from elaboration and device primitives from synthesis
        # See Ref [1] for filter criteria
        if {[llength [get_cells -quiet $c -filter {IS_SEQUENTIAL}]] > 0} {
            set pins [get_pins -quiet -of_objects $c -filter {IS_CLOCK}]
            if {[llength $pins] < 1} {
                # E.g. LUTRAM have a CLK pin that do not have their IS_CLOCK property set to 1.
                set clksrc [get_clocks -quiet -of_objects $c]
                if {[llength $clksrc] > 0} {
                    lappend clklist [list $c $clksrc [get_property SOURCE_PINS $clksrc]]
                } else {
#                    puts "WARNING in '[lindex [info level 0] 0]': No clock constraint found for cell '$c' of primitive type '[get_property PRIMITIVE_TYPE $c]'."
                    lappend clklist [list $c NOTSET NOTFOUND]
                }
            } else {
                foreach p $pins {
                    set clksrc [get_clocks -quiet -of_objects $p]
                    # This might not return a value, but the pin is connected to a clock port, so trace it back to the origins.
                    if {[llength $clksrc] > 0} {
                        set pinsrc [get_property SOURCE_PINS $clksrc]
                    } else {
                        set pinsrc [all_fanin -flat -startpoints_only $p]
                        set clksrc [get_clocks -quiet -of_objects $pinsrc]
                    }
                    if {[llength $clksrc] > 0} {
                        lappend clklist [list $c $clksrc $pinsrc]
                    } else {
#                        puts "WARNING in '[lindex [info level 0] 0]': No clock constraint found for pin '$p' of primitive type '[get_property PRIMITIVE_TYPE $c]'."
                        lappend clklist [list $c NOTSET $pinsrc]
                    }
                }
            }
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
#   get_clock_for_input_ports [get_ports {port1 port2} -filter {DIRECTION == "IN"}]
#   get_clock_for_input_ports [all_inputs]
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
                        # Can return multiple clocks for a single primitive
                        set regs [get_clock_port_of_registers $c]
                        foreach r $regs {
                            if {[llength $r] == 0} {
                                error "ERROR in '[lindex [info level 0] 0]': 'get_clock_port_of_registers $c' returned no registers for port '$p'."
                            } else {
                                set l $r
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
                                #      error "ERROR in '[lindex [info level 0] 0]': 'IS_SETRESET' property used on an input pin of '$c', the script cannot handle these."
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


# For a single port's list of connections, check return a list of unique clock domains.
#
# Parameters:
#   port_data - A list of tuples in the format:
#   {
#     {{flags_out_reg[0]} clk_dest_nm1 clk_pin1}
#     {{flags_out_reg[1]} clk_dest_nm1 clk_pin1}
#     {{flags_out_reg[2]} clk_dest_nm2 clk_pin2}
#   }
#
# Returns: A list of the unique clock names and clock pins, e.g.
#   {
#     {clk_dest_nm1 clk_pin1}
#     {clk_dest_nm2 clk_pin2}
#   }
#
# Usage: single_port_unique_clock_domains [dict get [get_clock_for_input_ports [get_ports {m_axi4_com[arready]}]] {m_axi4_com[arready]}]
#           => {sys_data_clk sys_data_clk}
#
proc single_port_unique_clock_domains {port_data} {
    set clks {}
    foreach d $port_data {
        if {![string equal [lindex $d 3] "ASYNC"]} {
            set clkgrp [lindex $d 1]
            set clkpin [lindex $d 2]
            set item [list $clkgrp $clkpin]
            if {[lsearch -exact $clks $item] < 0} {
                lappend clks $item
            }
        }
    }
    return $clks
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
    # Cannot be a global as it does not exist as the time this function is called.
    set script_name "auto_constrain_lib.tcl"

    if {$verbose} {
        puts "--- Start automatically derived constraints by $script_name ---"
    }

    dict for {port data} [get_clock_for_input_ports [all_inputs]] {
        # 'data' is the list of destination sequential primitives
        # Cannot extract any existing input or output delay from a port without 'get_timing_paths',
        # which requires a synthesied design, not just elaboration.
        #  * get_property INPUT_DELAY [get_timing_paths -from $port]
        #  * get_property OUTPUT_DELAY [get_timing_paths -to $port]
        set setopd 0
        set ucd [single_port_unique_clock_domains $data]
        if {[llength $ucd] == 1} {
            foreach d $data {
                # d = {register clock_name clock_port ?ASYNC?}
                if {[string equal [lindex $d 3] "ASYNC"]} {
                    # Set up false paths from any ports to each ASYNC pin.
                    if {$verbose} {
                        puts "set_false_path -from $port -to [lindex $d 0]"
                    }
                    # Don't false path the reset though, that must be timed to the register's clock.
                    set_false_path -from $port -to [lindex $d 0]
                    # Alternative is: set_max_delay -datapath_only -from [get_ports $port] -to [lindex $d 0] [get_property PERIOD [get_clocks [lindex $d 1]]]
                    # See observation above.
                } elseif {[string equal [lindex $d 1] "NOTSET"]} {
                    puts "WARNING in '[lindex [info level 0] 0]': Input port '$port' has unknown clock constraint on pin '[lindex $d 2]'."
                } elseif {! $setopd} {
                    # Only need to set up this constraint the first time
                    set setopd 1
                    if {$verbose} {
                        puts "set_input_delay -clock [get_clocks [lindex $d 1]] $input_delay $port"
                    }
                    set_input_delay -clock [get_clocks [lindex $d 1]] $input_delay $port
                }
            }
        } elseif {[llength $data] > 1} {
            # if $data contains more then one clock... Provide evidence and call for manual setting
            puts "WARNING in '[lindex [info level 0] 0]': Input port '$port' has multiple clocks. Clock list: ${ucd}."
            if {$verbose} {
                puts "# Select the best constraint and add manually in OOC constraints, before call to '[lindex [info level 0] 0]'"
                foreach c $ucd {
                    if {![string equal [lindex $c 0] "NOTSET"]} {
                        puts "# set_input_delay -clock \[get_clocks {[lindex $c 0]}\] $input_delay \[get_port {$port}\]"
                    }
                    puts "# set_input_delay -clock \[get_clocks -of_objects \[get_ports {[lindex $c 1]}\]\] $input_delay \[get_port {$port}\]"
                }
            }
        } else {
            # ([llength $data] == 0) || ($except == "NONE")
            puts "WARNING in '[lindex [info level 0] 0]': Input port '$port' has no clocks."
        }
    }

    dict for {port data} [get_clock_for_output_ports [all_outputs]] {
        # 'data' is the list of destination sequential primitives
        set setopd 0
        set ucd [single_port_unique_clock_domains $data]
        if {[llength $ucd] == 1} {
            foreach d $data {
                # d = {register clock_name clock_port ?ASYNC?}
                if {[string equal [lindex $d 1] "NOTSET"]} {
                    puts "WARNING in '[lindex [info level 0] 0]': Output port '$port' has unknown clock constraint on pin '[lindex $d 2]'."
                } elseif {! $setopd} {
                    # Only need to set up this constraint the first time
                    set setopd 1
                    if {$verbose} {
                        puts "set_output_delay -clock [get_clocks [lindex $d 1]] $output_delay $port"
                    }
                    set_output_delay -clock [get_clocks [lindex $d 1]] $output_delay $port
                }
            }
        } elseif {[llength $data] > 1} {
            # if $data contains more then one clock... Provide evidence and call for manual setting
            puts "WARNING in '[lindex [info level 0] 0]': Output port '$port' has multiple clocks. Clock list: ${ucd}."
            if {$verbose} {
                puts "# Select the best constraint and add manually in OOC constraints, before call to '[lindex [info level 0] 0]'"
                foreach c $ucd {
                    if {![string equal [lindex $c 0] "NOTSET"]} {
                        puts "# set_output_delay -clock \[get_clocks {[lindex $c 0]}\] $output_delay \[get_port {$port}\]"
                    }
                    puts "# set_output_delay -clock \[get_clocks -of_objects \[get_ports {[lindex $c 1]}\]\] $output_delay \[get_port {$port}\]"
                }
            }
        } else {
            # ([llength $data] == 0) || ($except == "NONE")
            puts "WARNING in '[lindex [info level 0] 0]': Output port '$port' has no clocks."
        }
    }

    if {$verbose} {
        puts "---- End automatically derived constraints by $script_name ----"
    }
    puts "INFO Out of Context Synthesis: Call TCL 'check_ooc_setup \$tsus \$ths' to check the OOC setup."
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


# For input ports only, fetch the maximum both the setup and hold times of a pin in the fanout
# of each port. Also provide the primitive as that might explain any surprises.
#
# Usage: get_setup_hold_times [all_inputs]
#
# Returns: A dictionary keyed on 'setup' or 'hold', of dictionary of pairs
#          {input_port {details}, input_port {details}...}
#   where 'details' is a list of the form
#          {hold_time primitive_type}.
#
# For example:
#
#   setup {
#     # input_port {hold_time primitive_type}
#     m_axis_ready {0.108 REGISTER.SDR.FDCE}
#     {m_node_vector[0][major_type][0]} {0.108 REGISTER.SDR.FDRE}
#     {m_node_vector[0][major_type][10]} {0.108 REGISTER.SDR.FDRE}
#   }
#   hold {
#     # input_port {hold_time primitive_type}
#     m_axis_ready {0.108 REGISTER.SDR.FDCE}
#     {m_node_vector[0][major_type][0]} {0.108 REGISTER.SDR.FDRE}
#     {m_node_vector[0][major_type][10]} {0.108 REGISTER.SDR.FDRE}
#   }
#
proc get_setup_hold_times {ports} {
    set setupdelays [dict create]
    set holddelays  [dict create]
    foreach p $ports {
        # Exclude asynchronous resets pins and any that are tied to GND or VCC
        set fo [filter [all_fanout -quiet -endpoints_only -flat $p] -filter {!IS_CLOCK && !IS_CLEAR && !IS_PRESET && !IS_TIED}]
        if {[llength $fo] > 0} {
            set sdl {}
            set hdl {}
            foreach f $fo {
                set c [get_cells -of_objects $f]
                if {[get_property IS_SEQUENTIAL $c]} {
                    lappend sdl [list \
                        [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -to $f -filter {TYPE == "setup"}]] \
                        [get_property PRIMITIVE_TYPE $c] \
                    ]
                    lappend hdl [list \
                        [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -to $f -filter {TYPE == "hold"}]] \
                        [get_property PRIMITIVE_TYPE $c] \
                    ]
# Highlights an issue with 'all_fanout -endpoints_only' above
#                } else {
#                    puts "WARNING in '[lindex [info level 0] 0]': '$f' given as a timing endpoint when it is not sequential."
                }
            }
            # All values in the list tend to be the same
            dict set setupdelays $p [max_delay $sdl]
            dict set holddelays  $p [max_delay $hdl]
        }
    }
    set portdelays [dict create]
    dict set portdelays setup $setupdelays
    dict set portdelays hold  $holddelays
    return $portdelays
}


# Verify the hold and setup times supplied at parameters match the synthesised design's expected hold
# and setup times. Note this check can only be done *after* synthesis when the timing arcs are
# available, hence this is a check after the fact rather than a value extraction for constraints before
# synthesis.
#
# NB. Requires a synthesised design to be open. Call 'check_ooc_setup' instead if not.
#
# Usage: check_setup_hold_times $tsus $ths 1
#
# Return: the number of warnings
#
proc check_setup_hold_times {setup_time hold_time {verbose 0} {design synth_1}} {
    set warn 0
    set times        [get_setup_hold_times [all_inputs]]
    set setup_design [max_delay [dict values [dict get $times setup]]]
    set hold_design  [max_delay [dict values [dict get $times hold]]]
    # Delay
    set sdd [lindex $setup_design 0]
    # Primitive
    set sdp [lindex $setup_design 1]
    # Delay
    set hdd [lindex $hold_design 0]
    # Primitive
    set hdp [lindex $hold_design 1]
    if {$sdd != $setup_time} {
        puts "WARNING in '[lindex [info level 0] 0]': Specified setup time '$setup_time ns' does not match output ports' maximum setup time of '$sdd ns' on a '$sdp' primtive."
        incr warn
    } else {
        if {$verbose} {
            puts "INFO in '[lindex [info level 0] 0]': Specified setup time matches output ports' maximum setup time of '$sdd ns' on a '$sdp' primtive."
        }
    }
    if {$hdd != $hold_time} {
        puts "WARNING in '[lindex [info level 0] 0]': Specified hold time '$hold_time ns' does not match input ports' maximum hold time of '$hdd ns' on a '$hdp' primtive."
        incr warn
    } else {
        if {$verbose} {
            puts "INFO in '[lindex [info level 0] 0]': Specified hold time matches input ports' maximum hold time of '$hdd ns' on a '$hdp' primtive."
        }
    }
    return $warn
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
# Usage: check_design_clocks 1
#
# Return: the number of warnings
#
proc check_design_clocks {{verbose 0}} {
    set warn 0
    set clkports [design_clock_pins]
    foreach clk $clkports {
        set clk_name [get_clocks -quiet -of_objects $clk]
        if {[llength $clk_name] > 0} {
            if {$verbose} {
                puts "INFO in '[lindex [info level 0] 0]': Clock port '[get_property SOURCE_PINS $clk_name]' has clock name '$clk_name' with period '[get_property PERIOD $clk_name] ns'."
            }
        } else {
            puts "WARNING in '[lindex [info level 0] 0]': '$clk' is used to drive a clock without a clock constraint."
            incr warn
        }
    }
    return $warn
}


# Verify the input and output constraints for each port in the design. This must be run post
# synthesis, i.e. not on an elaborated design.
#
# Usage: check_port_constraints 1
#
# Return: the number of warnings
#
# Sample output to the console:
#
# INFO in 'check_port_constraints': Input port 'sys_ctrl_aresetn' has delay set to 0.152 ns.
# INFO in 'check_port_constraints': Input port 'sys_data_aresetn' has delay set to 0.152 ns.
# INFO in 'check_port_constraints': Output port 'irq' has delay set to 0.439 ns.
# INFO in 'check_port_constraints': Output port 'm_axi4_req[araddr][0]' has delay set to 0.439 ns.
# INFO in 'check_port_constraints': Output port 'm_axi4_req[araddr][10]' has delay set to 0.439 ns.
#
proc check_port_constraints {{verbose 0}} {
    set warn 0
    # Cannot be a global as it does not exist as the time this function is called.
    set script_name "auto_constrain_lib.tcl"

    puts "--- Start port constraints verification by $script_name ---"
    set input_ports [get_clock_for_input_ports [all_inputs]]
    dict for {port data} $input_ports {
        set dset [get_property INPUT_DELAY [get_timing_paths -from $port]]
        if {$dset != ""} {
            if {$verbose} {
                puts "INFO in '[lindex [info level 0] 0]': Input port '$port' has delay set to [get_property INPUT_DELAY [get_timing_paths -from $port]] ns."
            }
        } else {
            puts "WARNING in '[lindex [info level 0] 0]': Input port '$port' has no delay set."
            incr warn
        }
    }

    set output_ports [get_clock_for_output_ports [all_outputs]]
    dict for {port data} $output_ports {
        set dset [get_property OUTPUT_DELAY [get_timing_paths -to $port]]
        if {$dset != ""} {
            if {$verbose} {
                puts "INFO in '[lindex [info level 0] 0]': Output port '$port' has delay set to [get_property OUTPUT_DELAY [get_timing_paths -to $port]] ns."
            }
        } else {
            puts "WARNING in '[lindex [info level 0] 0]': Output port '$port' has no delay set."
            incr warn
        }
    }

    if {$warn == 0} {
        puts "INFO in '[lindex [info level 0] 0]': No missing constraints found."
    }

    puts "---- End port constraints verification by $script_name ----"
    return $warn
}


# Check we have the sythesised design open, or perform synthesis. Only then is it
# possible to perform post synthesis checks for OOC setup.
#
# Usage: open_synth_design
#
# Return: the number of warnings
#
proc open_synth_design {{synth synth_1} {jobs 6}} {
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
}


# Perform OOC synthesis setup checks. This will open a synthesised design if not already open.
#
# Usage: check_ooc_setup $tsus $ths 1
#
proc check_ooc_setup {tsus ths {verbose 0}} {
    set warn 0
    open_synth_design
    # Open a schematic of the basic design - The created window distracts from the TCL console where the result is printed.
    #report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -routable_nets -name timing_synth
    # Check the TCL console for the printed results.
    incr warn [check_setup_hold_times $tsus $ths $verbose]
    incr warn [check_design_clocks $verbose]
    incr warn [check_port_constraints $verbose]
    puts "INFO in '[lindex [info level 0] 0]': Number of warnings to address: $warn."
    return $warn
}
