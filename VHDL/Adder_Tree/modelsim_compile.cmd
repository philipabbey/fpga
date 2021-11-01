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
set DEST=%SIM%\projects\Adder_Tree

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

vmap local %SIM%\libraries\local
vlib work
vcom -quiet -2008 ^
  %SRC%\adder_tree_pkg.vhdl ^
  %SRC%\adder_tree.vhdl ^
  %SRC%\adder_tree_pipe.vhdl ^
  %SRC%\test_adder_tree.vhdl ^
  %SRC%\test_adder_tree_pipe.vhdl ^
  %SRC%\fir_filter_const_coeffs.vhdl ^
  %SRC%\fir_filter_var_coeffs.vhdl ^
  %SRC%\test_fir_filter_const_coeffs.vhdl ^
  %SRC%\test_fir_filter_var_coeffs.vhdl ^
  %SRC%\fir_filter_const_coeffs_io.vhdl ^
  %SRC%\fir_filter_var_coeffs_io.vhdl
set ec=%ERRORLEVEL%

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
