#####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
#####################################################################################
#
# TCL script to display a the time in a quadruple seven segment display created out
# of TCL/TK graphics linked to a trigger set by ModelSim VHDL simulator.
#
# To run this code, keep your synthesised design open in Vivado and run:
#
#   source {path\to\sevseg_display.tcl}
#
# Reference:
#   https://blog.abbey1.org.uk/index.php/technology/tcl-tk-graphical-display-driven-by-a-vhdl
#
#####################################################################################

proc hseg {{can .} {w 40} {h 20} {col #f00} {ox 0} {oy 0}} {
  $can create polygon \
    [expr      $h/2 + $ox]                   $oy  \
    [expr $w - $h/2 + $ox]                   $oy  \
    [expr $w        + $ox] [expr      $h/2 + $oy] \
    [expr $w - $h/2 + $ox] [expr $h        + $oy] \
    [expr      $h/2 + $ox] [expr $h        + $oy] \
                      $ox  [expr      $h/2 + $oy] \
    -outline $col -fill $col
}

proc vseg {{can .} {w 20} {h 40} {col #f00} {ox 0} {oy 0}} {
  $can create polygon \
                      $ox  [expr      $w/2 + $oy] \
                      $ox  [expr $h - $w/2 + $oy] \
    [expr      $w/2 + $ox] [expr $h        + $oy] \
    [expr $w        + $ox] [expr $h - $w/2 + $oy] \
    [expr $w        + $ox] [expr      $w/2 + $oy] \
    [expr      $w/2 + $ox]                   $oy  \
    -outline $col -fill $col
}

#
#      a
#    #####
#   #     #
# f #     # b
#   #  g  #
#    #####
#   #     #
# e #     # c
#   #  d  #
#    #####
#
#                        0123456
#                        abcdefg
proc sevseg {{can .} {b "0000000"} {ox 0} {oy 0}} {
  global on
  global off
  if {[string length $b] != 7} {
    error "Seven segment displays need precisely 7 bits."
  }
  # a
  if {[expr [string index $b 0] == "1"]} {
    hseg $can 60 20 $on  [expr 12+$ox] [expr 0+$oy]
  } {
    hseg $can 60 20 $off [expr 12+$ox] [expr 0+$oy]
  }
  # g
  if {[expr [string index $b 6] == "1"]} {
    hseg $can 60 20 $on  [expr 12+$ox] [expr 64+$oy]
  } {
    hseg $can 60 20 $off [expr 12+$ox] [expr 64+$oy]
  }
  # d
  if {[expr [string index $b 3] == "1"]} {
    hseg $can 60 20 $on  [expr 12+$ox] [expr 128+$oy]
  } {
    hseg $can 60 20 $off [expr 12+$ox] [expr 128+$oy]
  }
  # f
  if {[expr [string index $b 5] == "1"]} {
    vseg $can 20 60 $on  [expr 0+$ox] [expr 12+$oy]
  } {
    vseg $can 20 60 $off [expr 0+$ox] [expr 12+$oy]
  }
  # b
  if {[expr [string index $b 1] == "1"]} {
    vseg $can 20 60 $on  [expr 64+$ox] [expr 12+$oy]
  } {
    vseg $can 20 60 $off [expr 64+$ox] [expr 12+$oy]
  }
  # e
  if {[expr [string index $b 4] == "1"]} {
    vseg $can 20 60 $on  [expr 0+$ox] [expr 76+$oy]
  } {
    vseg $can 20 60 $off [expr 0+$ox] [expr 76+$oy]
  }
  # c
  if {[expr [string index $b 2] == "1"]} {
    vseg $can 20 60 $on  [expr 64+$ox] [expr 76+$oy]
  } {
    vseg $can 20 60 $off [expr 64+$ox] [expr 76+$oy]
  }
}

proc display {can s0 s1 s2 s3} {
  global winheight
  global winwidth
  destroy $can
  canvas $can -width $winwidth -height $winheight
  sevseg $can $s0 0
  sevseg $can $s1 100
  $can create oval 200 34 220  54 -outline #f00 -fill #f00
  $can create oval 200 94 220 114 -outline #f00 -fill #f00
  sevseg $can $s2 240
  sevseg $can $s3 340
  pack $can
}

# Global variables
set on #f00
set off #aaa
set winwidth 425
set winheight 149
set monitor {/test_time_display/disp }

destroy .sevseg
toplevel .sevseg
# Four seven segment displays for the time
display .sevseg.time "0000000" "0000000" "0000000" "0000000"
wm title .sevseg "Time Display"
wm geometry .sevseg ${winwidth}x${winheight}+100+0

# Setup the trigger to update the display
when -label updateTime "${monitor}'event" {
  display .sevseg.time [examine -radix bin "sim:${monitor}(0)"] [examine "sim:${monitor}(1)"] [examine "sim:${monitor}(2)"] [examine "sim:${monitor}(3)"]
  # Don't let the sim run away, we won't see the display update
  stop
}
