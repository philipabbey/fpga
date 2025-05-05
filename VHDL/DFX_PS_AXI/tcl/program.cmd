@echo off
rem ---------------------------------------------------------------------------------
rem 
rem  Distributed under MIT Licence
rem    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
rem 
rem ---------------------------------------------------------------------------------

C:\Xilinx\Vivado\2023.2\bin\vivado.bat ^
  -mode tcl ^
  -notrace ^
  -nojournal ^
  -nolog ^
  -source {./program.tcl}
