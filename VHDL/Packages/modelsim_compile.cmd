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
set DEST=%SIM%\projects\Packages

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
rem not required when using vmap later. Without this "vdel -modelsimini .\modelsim.ini" fails.
if not exist modelsim.ini (
  echo Initialising modelsim.ini
  vmap -c
)

vlib work
vcom -quiet -2008 ^
  %SRC%\prot_type_pkg.vhdl ^
  %SRC%\base_pkg.vhdl ^
  %SRC%\inherit_pkg1.vhdl ^
  %SRC%\inherit_pkg2.vhdl ^
  %SRC%\base_gpkg.vhdl ^
  %SRC%\inherit_gpkg2.vhdl ^
  %SRC%\test_prot_type_pkg.vhdl ^
  %SRC%\test_inherit_pkg.vhdl
set ec=%ERRORLEVEL%

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
