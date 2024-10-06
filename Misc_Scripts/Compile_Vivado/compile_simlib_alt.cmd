@echo off
rem ---------------------------------------------------------------------------------
rem
rem  Distributed under MIT Licence
rem    See https://github.com/philipabbey/fpga/blob/main/LICENCE.
rem
rem Alternative to Vivado's TCL compile_simlib command for Intel's free QuestaSim
rem simulator.
rem
rem ---------------------------------------------------------------------------------

set SIM=%USERPROFILE%\ModelSim
rem Batch file's directory where the source code is
rem set SRC=%~dp0
rem drop last character '\'
rem set SRC=%SRC:~0,-1%
set DEST=%SIM%\vivado_23.2
set VIVADO_INSTALL=C:\Xilinx\Vivado\2023.2\data

echo Compile Xilinx primitives : %VIVADO_INSTALL%
echo Into Destination          : %DEST%
echo Started                   : %date% %time%
echo.

if not exist %DEST% (
  md %DEST%
)

rem vlib needs to be execute from the local directory, limited command line switches.
pushd %DEST%
if exist unisim (
  echo Deleting old unisim directory
  vdel -modelsimini .\modelsim.ini -lib unisim -all
)
if exist secureip (
  echo Deleting old secureip directory
  vdel -modelsimini .\modelsim.ini -lib secureip -all
)
if exist unifast (
  echo Deleting old unifast directory
  vdel -modelsimini .\modelsim.ini -lib unifast -all
)
if exist unimacro (
  echo Deleting old unimacro directory
  vdel -modelsimini .\modelsim.ini -lib unimacro -all
)
if exist xpm (
  echo Deleting old xpm directory
  vdel -modelsimini .\modelsim.ini -lib xpm -all
)

vlib unisim
vmap unisim %DEST:\=/%/unisim
echo ** Compiling unisims

set unisims=%VIVADO_INSTALL%\vhdl\src\unisims

rem If you look into the unisim folder of your Common Libraries, you’ll see the following files:
rem 
rem unisim_VCOMP.vhd (7-series and newer primitives)
rem retarget_VCOMP.vhd (support for old architecture primitives that are retargeted to their equivalent)
rem unisim_retarget_VCOMP.vhd (combines both of the previous files)
rem
rem https://insights.sigasi.com/tech/vivado-unisim/

vcom -work unisim -93 -quiet ^
  "%unisims%\unisim_VPKG.vhd" ^
  "%unisims%\unisim_retarget_VCOMP.vhdp"

set filelist=%unisims%\primitive\vhdl_analyze_order
for %%F in (%filelist%) do set srcdir=%%~dpF
rem drop last character '\'
set srcdir=%srcdir:~0,-1%

for /f "delims=" %%a in (%filelist%) do (
  vcom -work unisim -93 -quiet %srcdir%\%%a
  if %ERRORLEVEL% NEQ 0 (
    echo FAILED %srcdir%\%%a
  ) else (
    echo PASSED %srcdir%\%%a
  )
)

set filelist=%unisims%\retarget\vhdl_analyze_order
for %%F in (%filelist%) do set srcdir=%%~dpF
rem drop last character '\'
set srcdir=%srcdir:~0,-1%

for /f "delims=" %%a in (%filelist%) do (
  vcom -work unisim -93 -quiet %srcdir%\%%a
  if %ERRORLEVEL% NEQ 0 (
    echo FAILED %srcdir%\%%a
  ) else (
    echo PASSED %srcdir%\%%a
  )
)
echo ** Compilation of unisims complete

echo ** Compiling secureip
set expanded_list=
for /f "tokens=*" %%F in ('dir /b /a:-d "%unisims%\secureip\*.vhd"') do call set expanded_list=%%expanded_list%% "%unisims%\secureip\%%F"
vcom -work secureip -93 -quiet %expanded_list%
echo ** Compilation of secureip complete

vlib unifast
vmap unifast %DEST:\=/%/unifast
echo ** Compiling unifast

set unifast=%VIVADO_INSTALL%\vhdl\src\unifast

set filelist=%unifast%\primitive\vhdl_analyze_order
for %%F in (%filelist%) do set srcdir=%%~dpF
rem drop last character '\'
set srcdir=%srcdir:~0,-1%

for /f "delims=" %%a in (%filelist%) do (
  vcom -work unifast -93 -quiet %srcdir%\%%a
  if %ERRORLEVEL% NEQ 0 (
    echo FAILED %srcdir%\%%a
  ) else (
    echo PASSED %srcdir%\%%a
  )
)
echo ** Compilation of unifast complete

vlib unimacro
vmap unimacro %DEST:\=/%/unimacro
echo ** Compiling unimacro

set unimacro=%VIVADO_INSTALL%\vhdl\src\unimacro

set filelist=%unimacro%\vhdl_analyze_order
for %%F in (%filelist%) do set srcdir=%%~dpF
rem drop last character '\'
set srcdir=%srcdir:~0,-1%

for /f "delims=" %%a in (%filelist%) do (
  vcom -work unimacro -93 -quiet %srcdir%\%%a
  if %ERRORLEVEL% NEQ 0 (
    echo FAILED %srcdir%\%%a
  ) else (
    echo PASSED %srcdir%\%%a
  )
)
echo ** Compilation of unimacro complete

vlib xpm
vmap xpm %DEST:\=/%/xpm
echo ** Compiling XPM

set xpm=%VIVADO_INSTALL%\ip\xpm
vcom -work xpm -93 -quiet "%xpm%\xpm_VCOMP.vhd"
vlog -quiet -work xpm ^
  "%xpm%\xpm_cdc\hdl\xpm_cdc.sv" ^
  "%xpm%\xpm_fifo\simulation\xpm_fifo_tb.sv" ^
  "%xpm%\xpm_memory\hdl\xpm_memory.sv"

rem These two are encrypted
rem Turn off warnings as best we can, "NOC" indicates "Network On Chip" for Versal devices
vlog -quiet -work xpm -note 13361 -note 2263 -note 2240 ^
  "%xpm%\xpm_noc\hdl\xpm_nmu_mm.sv" ^
  "%xpm%\xpm_noc\hdl\xpm_nsu_mm.sv"

echo ** Compilation of XPM complete

if not exist %SIM%\modelsim.ini (
  rem Must change to the directory rather than specify a -modelsimini command line argument
  pushd %SIM%
  vmap -c
  popd
)

rem Create a single modelsim.ini file for all "others"
vmap -modelsimini %SIM%\modelsim.ini unisim   %DEST:\=/%/unisim
vmap -modelsimini %SIM%\modelsim.ini unifast  %DEST:\=/%/unifast
vmap -modelsimini %SIM%\modelsim.ini unimacro %DEST:\=/%/unimacro
vmap -modelsimini %SIM%\modelsim.ini xpm      %DEST:\=/%/xpm

popd
echo Ended: %date% %time%
pause
