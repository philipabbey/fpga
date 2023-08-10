####################################################################################
#
# Distributed under MIT Licence
#   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# Implementation only:
# Hand placement of control_set_array component for maximum packing density when
# reset and chip enable pins are "extracted" (as opposed to "direct").
#
# P A Abbey, 10 August 2023
#
#####################################################################################

set rows 4
set offset_row 96
set offset_col 36

# Manual placement into a single SliceL for width=128
for {set i 0} {$i < 128} {incr i} {
  switch [expr $i % 4] {
    0 {
      set_property BEL A5LUT [get_cells "shift_g.q[$i]_i_1"]
      set_property BEL A6LUT [get_cells "shift_g.dd[$i][0]_i_1"]
      set_property BEL AFF   [get_cells "shift_g.dd_reg[$i][0]"]
      set_property BEL A5FF  [get_cells "shift_g.q_reg[$i]"]
    }
    1 {
      set_property BEL B5LUT [get_cells "shift_g.q[$i]_i_1"]
      set_property BEL B6LUT [get_cells "shift_g.dd[$i][0]_i_1"]
      set_property BEL BFF   [get_cells "shift_g.dd_reg[$i][0]"]
      set_property BEL B5FF  [get_cells "shift_g.q_reg[$i]"]
    }
    2 {
      set_property BEL C5LUT [get_cells "shift_g.q[$i]_i_1"]
      set_property BEL C6LUT [get_cells "shift_g.dd[$i][0]_i_1"]
      set_property BEL CFF   [get_cells "shift_g.dd_reg[$i][0]"]
      set_property BEL C5FF  [get_cells "shift_g.q_reg[$i]"]
    }
    3 {
      set_property BEL D5LUT [get_cells "shift_g.q[$i]_i_1"]
      set_property BEL D6LUT [get_cells "shift_g.dd[$i][0]_i_1"]
      set_property BEL DFF   [get_cells "shift_g.dd_reg[$i][0]"]
      set_property BEL D5FF  [get_cells "shift_g.q_reg[$i]"]
    }
  }
  # Integer division
  set div4 [expr $i / 4]
  set row [expr ($div4 % $rows) + $offset_row]
  set col [expr ($div4 / $rows) + $offset_col]
  set loc_string "SLICE_X${col}Y${row}"
  puts "i=$i, mod 4 = [expr $i % 4], ${loc_string}"
  # This must come after the BEL property settings
  set_property LOC $loc_string [get_cells "shift_g.q[$i]_i_1"]
  set_property LOC $loc_string [get_cells "shift_g.dd[$i][0]_i_1"]
  set_property LOC $loc_string [get_cells "shift_g.dd_reg[$i][0]"]
  set_property LOC $loc_string [get_cells "shift_g.q_reg[$i]"]
}
