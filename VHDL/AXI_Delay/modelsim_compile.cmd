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
set DEST=%SIM%\projects\axi_delay

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
  vlib work
)

rem Convert back slashes to forward slashes
vmap others %SIM:\=/%/libraries/modelsim.ini
vcom -quiet -2008 ^
  %SRC%\axi_delay.vhdl ^
  %SRC%\test_axi_delay.vhdl ^
  %SRC%\axi_delay_stage.vhdl ^
  %SRC%\axi_delay_mixed.vhdl ^
  %SRC%\test_axi_delay_mixed.vhdl ^
  %SRC%\axi_pause.vhdl ^
  %SRC%\test_axi_pause.vhdl ^
  %SRC%\axi_width_conv_pause.vhdl ^
  %SRC%\test_axi_width_conv_pause.vhdl ^
  %SRC%\axi_width_conv_pause_filter.vhdl ^
  %SRC%\test_axi_width_conv_pause_filter.vhdl ^
  %SRC%\axi_edit.vhdl ^
  %SRC%\test_axi_edit.vhdl
set ec=%ERRORLEVEL%

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
