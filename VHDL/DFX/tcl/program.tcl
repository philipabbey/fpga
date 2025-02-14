####################################################################################
#
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
#
####################################################################################
#
# TCL script to execute partial reconfiguration demonstration.
#
# P A Abbey, 12 February 2025
#
####################################################################################
#
# Run this from a Vivado TCL Shell. Do not use the normal GUI as 'gets stdin' causes a lock-up.
# i.e. C:\Xilinx\Vivado\2023.2\bin\vivado.bat -mode tcl -source {A:/Philip/Work/VHDL/Public/VHDL/DFX/tcl/program.tcl}

set prods {<path>/DFX/products}

# Suppress "INFO: [Labtools 27-1434] Device xc7z010 (JTAG device index = 1) is programmed with a design that has no supported debug core(s) in it."
set_msg_config -suppress -id {Labtools 27-1434}
# Suppress: "INFO: [Labtools 27-3164] End of startup status: HIGH"
set_msg_config -suppress -id {Labtools 27-3164}

# https://stackoverflow.com/questions/18993122/tcl-pause-waiting-for-key-pressed-to-continue
proc pause {{message "Enter to continue"}} {
    puts -nonewline $message
    flush stdout
    gets stdin
}

proc program {f} {
  set hwd [get_hw_devices xc7z010_1]
  set_property PROBES.FILE {} $hwd
  set_property FULL_PROBES.FILE {} $hwd
  set_property PROGRAM.FILE $f $hwd
  program_hw_devices $hwd
  refresh_hw_device [lindex $hwd 0]
}

open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7z010_1]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7z010_1] 0]

# Full / Initial
program "$prods/initial.bit"
pause "Initial BIT file loaded, Enter to continue"

foreach rm {2 3 4} {
  # Partial Reconfigure
  program "$prods/rm${rm}.bit"
  pause "Partial BIT file RM${rm} loaded, Enter to continue"
}

foreach rm {1 2 3 4} {
  # Partial Reconfigure
  program "$prods/rm${rm}.bit"
  pause "Partial BIT file RM${rm} loaded, Enter to continue"
}

# Static Revert gives "F" hex, nets must float high
program "$prods/static.bit"
puts "Static BIT file with black box"
pause "THE END, Enter to exit"

close_hw_manager
exit

# # Seems to be an RM1 equivalent - Same file size
# program "$prods/initial_pblock_rp_partial.bit"
# # Gives "3", no idea what this is supposed to be from or for.
# program "$prods/static_pblock_rp_partial.bit"
