@echo off
rem ---------------------------------------------------------------------------------
rem 
rem  Distributed under MIT Licence
rem    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
rem 
rem ---------------------------------------------------------------------------------

set SIM=%USERPROFILE%\ModelSim
rem Batch file's directory where the source code is
set SRC=%~dp0
rem drop last character '\'
set SRC=%SRC:~0,-1%
set SRC=%SRC:\=/%
set DEST=%SIM%\projects\XPM
set OTHERS=%SIM%\libraries\modelsim.ini

echo Compile Source:   %SRC%\*
echo Into Destination: %DEST%
echo.

if not exist %DEST% (
  md %DEST%
)
rem vlib needs to be execute from the local directory, limited command line switches.
cd /d %DEST%
if exist work (
  echo Deleting old work directory
  vdel -modelsimini .\modelsim.ini -all
)

vmap others %OTHERS:\=/%
vlib work
vmap work ./work
vlog -quiet -work work "C:\Xilinx\Vivado\2023.2\data\verilog\src\glbl.v"
rem ** Warning: .../XPM/dpram_err.vhdl(xx): (vcom-1246) Range -1 downto 0 is null.
rem The source of these is guarded by conditional tests for generated blocks, hence the error is suppressed below.

vcom -quiet -2008 -work work -suppress 1246 ^
  %SRC%/dpram_1clk.vhdl ^
  %SRC%/test_dpram_1clk.vhdl ^
  %SRC%/dpram_2clk.vhdl ^
  %SRC%/test_dpram_2clk.vhdl ^
  %SRC%/dpram_err.vhdl ^
  %SRC%/test_dpram_err.vhdl ^
  %SRC%/dpram_1clk_init.vhdl ^
  %SRC%/test_dpram_1clk_init.vhdl
set ec=%ERRORLEVEL%

copy %SRC:/=\%\init.mem %DEST%

if %ec% equ 0 (
  echo =================================================================
  echo Run the simulation with:
  echo.
  echo   cd {%DEST%}
  echo   vsim -t 1ps work.test_dpram_1clk       or
  echo   vsim -t 1ps work.test_dpram_2clk       or
  echo   vsim -t 1ps work.test_dpram_err        or
  echo   vsim -t 1ps work.test_dpram_1clk_init
  echo =================================================================
)

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
