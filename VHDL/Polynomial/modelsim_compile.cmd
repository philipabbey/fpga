@echo off

set SIM=%USERPROFILE%/ModelSim
rem Batch file's directory where the source code is
set SRC=%~dp0
rem drop last character '\'
set SRC=%SRC:~0,-1%
set DEST=%SIM%\projects\Polynomial

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

vmap local D:/Users/Philip/ModelSim/libraries/local
vlib work
vcom -2008 %SRC%/polybitdiv.vhdl %SRC%/polydiv.vhdl %SRC%/polydiv_wrapper.vhdl %SRC%/test_polybitdiv.vhdl %SRC%/test_polydiv.vhdl

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
