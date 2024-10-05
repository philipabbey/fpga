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

rem vlib needs to be execute from the local directory, limited command line switches.
cd /d %DEST%
if exist local (
  vdel -lib local -modelsimini ./modelsim.ini -all
)

vlib local
vmap local %DEST:\=/%/local
vcom -quiet -2008 -work local ^
  %SRC%\math_pkg.vhdl ^
  %SRC%\lfsr_pkg.vhdl ^
  %SRC%\testbench_pkg.vhdl ^
  %SRC%\test_testbench.vhdl
set ec=%ERRORLEVEL%

if not exist %SIM%\modelsim.ini (
  rem Must change to the directory rather than specify a -modelsimini command line argument
  pushd %SIM%
  vmap -c
  popd
)
rem Create a single modelsim.ini file for all "others"
vmap -modelsimini %SIM%\modelsim.ini local %DEST:\=/%/local

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
