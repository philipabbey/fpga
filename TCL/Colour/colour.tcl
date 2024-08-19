#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to colour clocked primitives by clock source for visualisation.
#
# Usage:
#   source -notrace {colour.tcl}
#
# Reference:
#   http://blog.abbey1.org.uk/index.php/technology/visualising-clock-domain-crossings-in-vivado
#
#####################################################################################

# Remove all highlighted colourings and marks for a blank canvas.
#
proc uncolor_registers {} {
    unhighlight_objects -quiet [get_highlighted_objects]
    unmark_objects -quiet [get_marked_objects]
}
 
# Colourise just the currently selected objects, and mark the ASYNC_REG registers.
#
# Returns a list of primitive instance names with multiple clocks that could
# not be highlighted multiple times.
#
proc colour_selected_primitives_by_clock_source {{cells {}}} {
  if {[llength $cells] == 0} {
    set cells [get_selected_objects]
  }
  if {[llength $cells] == 0} {
    error "No cells selected or passed as a parameter."
  }
  uncolor_registers
  set nextcol 1
  set unhighlightable {}
  foreach c $cells {
    set cond [get_property -quiet IS_SEQUENTIAL $c]
    if {[llength $cond] == 0} {
      set cond 0
    }
    if {$cond} {
      set clkpins [get_pins -of_objects $c -filter {IS_CLOCK}]
      #
      # BlockRAM: $clkpins => <inst>/CLKARDCLK <inst>/CLKBWRCLK
      # i.e. clkpins will be a list
      #
      foreach cp $clkpins {
        # Some arithmetic primitives have a CLK pin but it can be tied to '0'.
        if {[get_property IS_TIED $cp] == 0} {
          # Take the top level name.
          set clksrc [lindex [all_fanin -flat $cp] end]
          if {![info exists clksrcarr($clksrc)]} {
            if {$nextcol >=  21} {
              error "Run out of colours"
            }
            # Add a new clock & color
            set clksrcarr($clksrc) $nextcol
            puts "Clock = $clksrc, Color Index = $clksrcarr($clksrc)"
            incr nextcol
            if {$nextcol == 2 || $nextcol == 5} {
              # Skip these colours (yellow and blue)
              incr nextcol
            }
          }
          # Colour Nets
          foreach f [all_fanin $cp] {
            foreach p [get_pins $f -quiet] {
              # First item is a pin, second and subsequent are nets, often elsewhere in the design
              set n [lindex [get_nets -of_objects $p -quiet] 0]
              if {[llength $n] > 0} {
                highlight_objects -color_index $clksrcarr($clksrc) $n
              }
            }
          }
          # Colour Cells
          if {[llength $clkpins] == 1} {
            highlight_objects -color_index $clksrcarr($clksrc) $c
          } else {
            lappend unhighlightable $c
          }
          if {[get_property ASYNC_REG $c] == 1} {
            # RGB for Black
            mark_objects -color red $c
          }
        }
      }
    }
  }
  return $unhighlightable
}

