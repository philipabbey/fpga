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
set DEST=%SIM%\projects\Signal_Spies

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
vmap others %SIM:\=/%/libraries/modelsim.ini
vcom -quiet -2008 ^
  %SRC%\dut_register.vhdl ^
  %SRC%\external_signals_pkg.vhdl ^
  %SRC%\test_external_signals_process.vhdl ^
  %SRC%\test_external_signals_procedure.vhdl ^
  %SRC%\util_commands_pkg.vhdl ^
  %SRC%\test_force.vhdl ^
  %SRC%\test_util_comands.vhdl ^
  %SRC%\signal_spies_pkg.vhdl ^
  %SRC%\test_signal_spies.vhdl
set ec=%ERRORLEVEL%

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
