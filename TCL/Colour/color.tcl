# Remove all highlighted colourings and marks for a blank canvas.
#
proc uncolor_registers {} {
    set allcells [get_cells -hier *]
    unhighlight_objects $allcells
    unmark_objects $allcells
}
 
# Colourise just the currently selected objects, must faster than the above.
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
  set nextcol 3
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
      foreach p $clkpins {
        # Some arithmetic primitives have a CLK pin but it can be tied to '0'.
        if {[get_property IS_TIED $p] == 0} {
          # Take the top level name.
          set clksrc [lindex [all_fanin -flat $p] end]
          if {![info exists clksrcarr($clksrc)]} {
            # Add a new clock & color
            set clksrcarr($clksrc) $nextcol
            puts "Clock = $clksrc, Color Index = $clksrcarr($clksrc)"
            highlight_objects -color_index $nextcol $clksrc
            if {[get_property CLASS $clksrc] == "port"} {
              highlight_objects -color_index $nextcol [get_nets -of_objects $clksrc]
            }
            incr nextcol
            if {$nextcol >=  21} {
              error "Run out of colours"
            }
          }
          if {[llength $clkpins] == 1} {
            highlight_objects -color_index $clksrcarr($clksrc) $c
          } else {
            lappend unhighlightable $c
          }
        }
      }
    }
  }
  return $unhighlightable
}

