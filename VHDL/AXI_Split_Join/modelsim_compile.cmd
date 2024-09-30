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
set DEST=%SIM%\projects\axi_split_join

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

vlib work
vmap work ./work
rem Convert back slashes to forward slashes
vmap others %SIM:\=/%/vivado_23.1std/modelsim.ini

vlog -quiet -work work ^
  %SRC%\ip\axis_broadcaster\gen\axis_broadcaster_sim_netlist.v ^
  %SRC%\ip\axis_combiner\gen\axis_combiner_sim_netlist.v

vcom -quiet -2008 -work work ^
  %SRC%\ip\axis_broadcaster\gen\axis_broadcaster_sim_netlist.vhdl ^
  %SRC%\ip\axis_combiner\gen\axis_combiner_sim_netlist.vhdl ^
  %SRC%\axi_split.vhdl ^
  %SRC%\axi_join.vhdl ^
  %SRC%\..\AXI_Delay\axi_delay.vhdl ^
  %SRC%\axi_split_join.vhdl ^
  %SRC%\axi_split_join_ip.vhdl ^
  %SRC%\test_axi_split.vhdl ^
  %SRC%\test_axi_join.vhdl ^
  %SRC%\test_axi_split_join.vhdl ^
  %SRC%\test_axi_split_join_ip.vhdl
set ec=%ERRORLEVEL%

echo.
echo ========================================================
echo To run the simulation in ModelSim:
echo.
echo   cd {%DEST%}
echo   vsim work.test_axi_split         -voptargs="+acc" -t ps
echo   vsim work.test_axi_join          -voptargs="+acc" -t ps
echo   vsim work.test_axi_split_join    -voptargs="+acc" -t ps
echo   vsim work.test_axi_split_join_ip -voptargs="+acc" -t ps
echo.
echo ========================================================
echo.

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
