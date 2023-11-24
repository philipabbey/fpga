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
set DEST=%SIM%\projects\synchroniser

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
  %SRC%\bus_data_valid_synch.vhdl ^
  %SRC%\sent_pkg.vhdl ^
  %SRC%\test_bus_data_valid_synch.vhdl
set ec=%ERRORLEVEL%

echo.
echo =======================================================
echo.
echo   cd {%DEST%}
echo   vsim -t ns work.test_bus_data_valid_synch
echo.
echo =======================================================

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
