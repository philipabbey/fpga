#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to find concerning aspects of your design by searching synthesis results.
#
# To run this code, keep your synthesised design open in Vivado and run:
#
#   source {path\to\design_policy_checks.tcl}
#
# Attempt to automate local design policy checks, much of which is subjective.
#
# Reference:
#   http://blog.abbey1.org.uk/index.php/technology/automating-code-review-design-checks-in-vivado
#
#####################################################################################

# NB. PRIMITIVE_TYPE is the concatenation of PRIMITIVE_GROUP, PRIMITIVE_SUBGROUP and REF_NAME.
# E.g. If:
#   PRIMITIVE_GROUP    = REGISTER
#   PRIMITIVE_SUBGROUP = SDR
#   REF_NAME           = FDPE
# Then
#   PRIMITIVE_GROUP    = REGISTER.SDR.FDPE
#
# Use these to try and keep the functions device independent.


# Asynchronous resets (Xilinx FPGAs like synchronous...)
# Ref: https://forums.xilinx.com/t5/PLD-Blog-Archived/That-Dangerous-Asynchronous-Reset/ba-p/12856
# FDCE Primitive: D Flip-Flop with Asynchronous Clear
# FDPE Primitive: D Flip-Flop with Asynchronous Preset
proc get_async_reset_registers {{verbose 0}} {
    set ret {}
    foreach r [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ "REGISTER.SDR.FDC*" || PRIMITIVE_TYPE =~ "REGISTER.SDR.FDP*"}] {
        lappend ret $r
        if {$verbose} {
            puts "Warning - $r has an asynchronous reset."
        }
    }
    return $ret
}

# Paired with 'get_no_reset_registers'.
proc has_tied_reset {cell} {
    set pin [get_pins -quiet -filter {IS_CLEAR || IS_PRESET || IS_RESET || IS_SET || IS_SETRESET} -of_objects [get_cells $cell]]
    if {[llength $pin] > 0} {
        # get_property IS_CONNECTED $pin is true for resets tied to GND/VCC
        return [get_property IS_TIED $pin]
    } else {
        if {[llength $cell] > 0} {
            # $cell has no set, reset, clear, or preset pin
            return 2
        } else {
            error "No cell parameter specified."
        }
    }
}


# Registers with no reset (policy?). Means no reset signal just tied high or low permanently.
proc get_no_reset_registers {{verbose 0}} {
    set ret {}
    foreach r [all_registers] {
        if {[has_tied_reset $r] == 0} {
            lappend ret $r
            if {$verbose} {
                puts "Warning - $r has tied reset, not reset by a signal. Indicates a missing reset clause in a clocked process."
            }
        }
    }
    return $ret
}


# Transparent latches - Worthy of ritual embarrassment
# ILD* Macro: Transparent Input Data Latch [with *]
# LDCE/LDPE Macros for Ultrascale
proc get_transparent_latches {{verbose 0}} {
    set ret {}
    foreach r [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE =~ "REGISTER.LATCH*"}] {
        lappend ret $r
        if {$verbose} {
            puts "Warning - $r is a transparent latch."
        }
    }
    return $ret
}


# Find all critical clock domain crossing issues
#
# Usage: get_problem_cdc_issues 1
#
# Understanding ASYNC_REG attribute
# https://forums.xilinx.com/t5/Timing-Analysis/Understanding-ASYNC-REG-attribute/td-p/774023
# Verify "unsafe" column in report_cdc
#
proc get_problem_cdc_issues {{verbose 0}} {
    report_cdc -quiet
    set ret [get_cdc_violations -filter {SEVERITY == Critical}]
    if {$verbose} {
        foreach cdc $ret {
            if {![get_property IS_WAIVED $cdc] && ([get_property EXCEPTION $cdc] == "None")} {
                puts "[format "#%03d:           " [get_property ID $cdc]]  [get_property DESCRIPTION $cdc]"
                puts "  Severity:       [get_property SEVERITY $cdc]"
                puts "  Clock Crossing: [get_property STARTPOINT_CLOCK $cdc] -> [get_property ENDPOINT_CLOCK $cdc]"
                puts "  Start Pin:      [get_property STARTPOINT_PIN $cdc]"
                puts "  End Pin:        [get_property ENDPOINT_PIN $cdc]"
                puts "  Check:          [get_property CHECK $cdc]"
                puts "  Exception:      [get_property EXCEPTION $cdc]"
            }
        }
    }
    return $ret
}


# Display a summary of the identified design issues we care about chastising designer for.
#
# Usage: design_policy_checks
#
proc design_policy_checks {} {
    set arr [get_async_reset_registers]
    if {$arr > 0} {
        puts "Warning - [llength $arr] with asynchronous reset. Run 'get_async_reset_registers 1' for details."
    }
    set tl [get_transparent_latches]
    if {$tl > 0} {
        puts "Warning - [llength $tl] transparent latches. Run 'get_transparent_latches 1' for details. Sack the code author."
    }
    set cdc [get_problem_cdc_issues]
    if {$cdc > 0} {
        puts "Warning - [llength $cdc] Critical clock domain crossing (CDC) issues. Run 'get_problem_cdc_issues 1' or 'report_cdc' for details."
    }
}

design_policy_checks
