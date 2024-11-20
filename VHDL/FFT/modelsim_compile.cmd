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
set DEST=%SIM%\projects\FFT

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
  vdel -modelsimini .\modelsim.ini -all || rmdir /s /q work
)
if exist modelsim.ini del /q modelsim.ini
if not exist modelsim.ini vmap -c

rem Convert back slashes to forward slashes
vmap others %SIM:\=/%/modelsim.ini
vcom -quiet -2008 ^
  %SRC%\fft_real_pkg.vhdl ^
  %SRC%\fft_sfixed_pkg.vhdl ^
  %SRC%\..\Adder_Tree\adder_tree_pkg.vhdl ^
  %SRC%\test_fft_pkg.vhdl ^
  %SRC%\test_data_fft_pkg.vhdl ^
  %SRC%\adder_tree_complex.vhdl ^
  %SRC%\adder_tree_complex_pipe.vhdl ^
  %SRC%\fft_real.vhdl ^
  %SRC%\fft_sfixed.vhdl ^
  %SRC%\dft_multi_radix_real.vhdl ^
  %SRC%\dft_multi_radix_sfixed.vhdl ^
  %SRC%\test_adder_tree_complex.vhdl ^
  %SRC%\test_adder_tree_complex_pipe.vhdl ^
  %SRC%\test_fft_real.vhdl ^
  %SRC%\test_fft_sfixed.vhdl ^
  %SRC%\test_dft_multi_radix_real.vhdl ^
  %SRC%\test_dft_multi_radix_sfixed.vhdl
set ec=%ERRORLEVEL%

echo.
echo ========================================================
echo To run the simulation in ModelSim:
echo.
echo   cd {%DEST%}
echo   vsim work.test_adder_tree_complex      -voptargs="+acc" -t ps
echo   vsim work.test_adder_tree_complex_pipe -voptargs="+acc" -t ps
echo   vsim work.test_fft_real                -voptargs="+acc" -t ps
echo   vsim work.test_fft_sfixed              -voptargs="+acc" -t ps
echo   vsim work.test_dft_multi_radix_real    -voptargs="+acc" -t ps
echo   vsim work.test_dft_multi_radix_sfixed  -voptargs="+acc" -t ps
echo.
echo ========================================================
echo.

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
