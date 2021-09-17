@echo off

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
vmap local ./local
vcom -2008 -work local %SRC%/math.vhdl %SRC%/lfsr.vhdl %SRC%/testbench.vhdl %SRC%/test_testbench.vhdl

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
