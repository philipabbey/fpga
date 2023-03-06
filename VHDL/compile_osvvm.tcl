# ---------------------------------------------------------------------------------
# 
#  Distributed under MIT Licence
#    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
# 
# ---------------------------------------------------------------------------------

if {$::env(SRC) eq "" || $::env(DEST) eq ""} {
  error "Both environment variables 'SRC' and 'DEST' must be set prior to this script." "Missing environment variables." 1
} else {
  source [string cat $::env(SRC) {/OsvvmLibraries/Scripts/StartUp.tcl}]
  SetLibraryDirectory $::env(DEST)/osvvm
  build [string cat $::env(SRC) {/OsvvmLibraries/OsvvmLibraries.pro}]
  # These take ages, but worth doing initially.
  # build [string cat $::env(SRC) {/OsvvmLibraries/RunAllTests.pro}]
}
quit
