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
set DEST=%SIM%\projects\axi_delay

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
  -pslfile %SRC%\axi_delay.psl ^
  %SRC%\axi_delay.vhdl ^
  %SRC%\test_axi_delay.vhdl ^
  %SRC%\axi_delay_stage.vhdl ^
  %SRC%\axi_delay_mixed.vhdl ^
  %SRC%\test_axi_delay_mixed.vhdl ^
  %SRC%\axi_pause.vhdl ^
  %SRC%\test_axi_pause.vhdl ^
  %SRC%\axi_width_conv_pause.vhdl ^
  %SRC%\test_axi_width_conv_pause.vhdl ^
  %SRC%\axi_width_conv_pause_filter.vhdl ^
  %SRC%\test_axi_width_conv_pause_filter.vhdl ^
  %SRC%\axi_edit.vhdl ^
  %SRC%\test_axi_edit.vhdl ^
  %SRC%\char_utils_pkg.vhdl ^
  %SRC%\protocol_edit.vhdl ^
  %SRC%\ScoreboardPkg_char.vhdl ^
  %SRC%\test_protocol_edit.vhdl
set ec=%ERRORLEVEL%

echo.
echo ========================================================
echo To run the simulation in ModelSim:
echo.
echo   cd {%DEST%}
echo   vsim work.test_axi_delay_simple            -voptargs="+acc" -t ps
echo   vsim work.test_axi_delay_itdev             -voptargs="+acc" -t ps
echo   vsim work.test_axi_delay_mixed             -voptargs="+acc" -t ps
echo   vsim work.test_axi_pause                   -voptargs="+acc" -t ps
echo   vsim work.test_axi_width_conv_pause        -voptargs="+acc" -t ps
echo   vsim work.test_axi_width_conv_pause_filter -voptargs="+acc" -t ps
echo   vsim work.test_axi_edit                    -voptargs="+acc" -t ps
echo   vsim work.test_protocol_edit               -voptargs="+acc" -t ps
echo.
echo ========================================================
echo.

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
