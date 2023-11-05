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
set DEST=%SIM%\projects\Report_CDC

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

vmap xpm %SIM%/libraries/xpm
vlib work
vmap work ./work
vcom -quiet -2008 -work work ^
  %SRC%/sync_reg.vhdl ^
  %SRC%/sync_reg_bad.vhdl ^
  %SRC%/cdc_validated_data_slow_fast.vhdl ^
  %SRC%/cdc_invalid_data_slow_fast.vhdl ^
  %SRC%/report_cdc.vhdl
set ec=%ERRORLEVEL%

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
