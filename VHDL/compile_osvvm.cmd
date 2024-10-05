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
set DEST=%SIM%\libraries

echo Compile Source:   %SRC%\*
echo Into Destination: %DEST%
echo.

if not exist %DEST% (
  md %DEST%
)

cd /d %DEST%
rem convert back slashes to forward slashes
vsim -batch -do %SRC:\=/%/compile_osvvm.tcl

if not exist %SIM%\modelsim.ini (
  rem Must change to the directory rather than specify a -modelsimini command line argument
  pushd %SIM%
  vmap -c
  popd
)

rem Create a single modelsim.ini file for all "others"
rem Extract OSVVM mappings from its own modelsim.ini and collect them into a single common INI file
rem
rem 1     2 3 <= Tokens
rem v     v v
rem osvvm = C:/Users/philip/ModelSim/libraries/osvvm/VHDL_LIBS/QuestaSim-2023.07/osvvm
rem ^       ^
rem %%a     %%b
for /f "tokens=1,3" %%a in ('findstr "osvvm" %SIM%\libraries\modelsim.ini') do (
  vmap -modelsimini %SIM%\modelsim.ini %%a %%b
)

pause
