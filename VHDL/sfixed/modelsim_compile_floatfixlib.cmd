@echo off
rem ---------------------------------------------------------------------------------
rem 
rem  Distributed under MIT Licence
rem    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
rem 
rem ---------------------------------------------------------------------------------
rem 
rem  Method to compile the fixed_pkg for 'sfixed' and 'ufixed' types for older tools.
rem 
rem  P A Abbey, 1 Sep 2021
rem 
rem ---------------------------------------------------------------------------------

set SIM=%USERPROFILE%\ModelSim
rem Batch file's directory where the source code is
rem set SRC=D:\intelFPGA_lite\18.1\modelsim_ase\vhdl_src\floatfixlib
set SRC=C:\intelFPGA_lite\23.1std\questa_fse\vhdl_src\floatfixlib
set DEST=%SIM%\libraries

echo Compile Source:   %SRC%\*
echo Into Destination: %DEST%
echo.

if not exist %DEST% (
  md %DEST%
)

rem vlib needs to be execute from the local directory, limited command line switches.
cd /d %DEST%
if exist ieee_proposed (
  echo Deleting old ieee_proposed directory
  vdel -lib ieee_proposed -modelsimini ./modelsim.ini -all || rmdir /s /q ieee_proposed
)
if exist modelsim.ini del /q modelsim.ini
if not exist modelsim.ini vmap -c

rem $ verror 1907
rem 
rem vcom-vlog Message # 1907:
rem Following -nowarn, an additional argument, representing which category
rem of warning message to suppress, must be specified.
rem   1 = Unbound component (VHDL)
rem   2 = Process without a WAIT statement (VHDL)
rem   3 = Null range (VHDL)
rem   4 = No space in physical (e.g. TIME) literal (VHDL)
rem   5 = Multiple drivers on unresolved signal (VHDL)
rem   6 = VITAL compliance checks ("-nowarn VitalChecks" also accepted) (VHDL)
rem   7 = VITAL optimization messages (VHDL)
rem   8 = Lint warnings (VHDL and Verilog)
rem   9 = Signal value dependency at elaboration (VHDL)
rem  10 = VHDL-1993 constructs in VHDL-1987 code (VHDL)
rem  11 = PSL warnings (VHDL and Verilog)
rem  12 = Non-LRM compliance to match Cadence behavior (Verilog)
rem  13 = Constructs that coverage can't handle (VHDL and Verilog)
rem  14 = Locally static error deferred until run time (VHDL)
rem  15 = SystemVerilog assertions using local variable (Verilog)

rem Turn off the warning about null ranges as this is expected.
vlib ieee_proposed
vmap floatfixlib %DEST:\=/%/ieee_proposed
vmap ieee_proposed %DEST:\=/%/ieee_proposed
rem Must use VHDL-1993 not VHDL-2008
vcom -quiet -93 -nowarn 3 -work ieee_proposed ^
  %SRC%\fixed_float_types_c.vhd ^
  %SRC%\fixed_pkg_c.vhd ^
  %SRC%\float_pkg_c.vhd
set ec=%ERRORLEVEL%

if not exist %SIM%\modelsim.ini (
  rem Must change to the directory rather than specify a -modelsimini command line argument
  pushd %SIM%
  vmap -c
  popd
)

rem Create a single modelsim.ini file for all "others"
vmap -modelsimini %SIM%\modelsim.ini floatfixlib %DEST:\=/%/ieee_proposed
vmap -modelsimini %SIM%\modelsim.ini ieee_proposed %DEST:\=/%/ieee_proposed

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
