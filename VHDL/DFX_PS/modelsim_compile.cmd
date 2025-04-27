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
set DEST=%SIM%\projects\dfx_ps

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

if exist %SRC%\products\rm*_comp.mem (
  copy /A %SRC%\products\rm*_comp.mem %DEST%
) else (
  echo.
  echo WARNING - Not created removable module memory files yet.
  echo.
)

rem verror 1907
rem
rem vcom-vlog Message # 1907:
rem Following -nowarn, an additional argument, representing which category
rem of warning message to suppress, must be specified.
rem   1 = Unbound component (VHDL)
rem   2 = Process without a WAIT statement (VHDL)
rem   3 = Null range (VHDL)
rem   4 = No space in physical (e.g. TIME) literal (VHDL)
rem   5 = Multiple drivers on unresolved signal (VHDL)
rem   6 = VITAL compliance checks ("-nowarn VitalChecks" also accepted) (VHDL)
rem   7 = VITAL optimization messages (VHDL)
rem   8 = Lint warnings (VHDL and Verilog)
rem   9 = Signal value dependency at elaboration (VHDL)
rem  10 = VHDL-1993 constructs in VHDL-1987 code (VHDL)
rem  11 = PSL warnings (VHDL and Verilog)
rem  12 = Non-LRM compliance to match Cadence behavior (Verilog)
rem  13 = Constructs that coverage can't handle (VHDL and Verilog)
rem  14 = Locally static error deferred until run time (VHDL)
rem  15 = SystemVerilog assertions using local variable (Verilog)
rem [DOC: QuestaSim Command Reference - vcom command]
rem [DOC: QuestaSim Command Reference - vlog command]
rem [DOC: QuestaSim Command Reference - vopt command]

rem Convert back slashes to forward slashes
vmap others %SIM:\=/%/modelsim.ini

rem AXI BRAM IP
rem
rem Ignore warnings about possible multiple drivers on signals in generate statements in official Xilinx code
rem See "verror 1907" for -nowarn switch categories.
vcom -quiet -2008 ^
  -nowarn 5 ^
  -work axi_bram_ctrl_v4_1_9 %SRC%\ip\axi_bram\hdl\axi_bram_ctrl_v4_1_rfs.vhd
vmap axi_bram_ctrl_v4_1_9 %DEST%\axi_bram_ctrl_v4_1_9

rem DFX Controller IP
rem
rem The library mappings can be discovered by attempting to compile code and seeing which libraries are missing.
vcom -quiet -2008 ^
  -work xbip_utils_v3_0_12 %SRC%\ip\dfx_controller\hdl\xbip_utils_v3_0_vh_rfs.vhd
vmap xbip_utils_v3_0_12 %DEST%\xbip_utils_v3_0_12

vcom -quiet -2008 ^
  -work xbip_pipe_v3_0_8 %SRC%\ip\dfx_controller\hdl\xbip_pipe_v3_0_vh_rfs.vhd
vmap xbip_pipe_v3_0_8 %DEST%\xbip_pipe_v3_0_8

vcom -quiet -2008 ^
  -work c_reg_fd_v12_0_8 %SRC%\ip\dfx_controller\hdl\c_reg_fd_v12_0_vh_rfs.vhd
vmap c_reg_fd_v12_0_8 %DEST%\c_reg_fd_v12_0_8

vcom -quiet -2008 ^
  -work xbip_dsp48_wrapper_v3_0_5 %SRC%\ip\dfx_controller\hdl\xbip_dsp48_wrapper_v3_0_vh_rfs.vhd
vmap xbip_dsp48_wrapper_v3_0_5 %DEST%\xbip_dsp48_wrapper_v3_0_5

vcom -quiet -2008 ^
  -work xbip_dsp48_addsub_v3_0_8 %SRC%\ip\dfx_controller\hdl\xbip_dsp48_addsub_v3_0_vh_rfs.vhd
vmap xbip_dsp48_addsub_v3_0_8 %DEST%\xbip_dsp48_addsub_v3_0_8

vcom -quiet -2008 ^
  -work xbip_addsub_v3_0_8 %SRC%\ip\dfx_controller\hdl\xbip_addsub_v3_0_vh_rfs.vhd
vmap xbip_addsub_v3_0_8 %DEST%\xbip_addsub_v3_0_8

vcom -quiet -2008 ^
  -work c_addsub_v12_0_17 %SRC%\ip\dfx_controller\hdl\c_addsub_v12_0_vh_rfs.vhd
vmap c_addsub_v12_0_17 %DEST%\c_addsub_v12_0_17

vcom -quiet -2008 ^
  -work c_gate_bit_v12_0_8 %SRC%\ip\dfx_controller\hdl\c_gate_bit_v12_0_vh_rfs.vhd
vmap c_gate_bit_v12_0_8 %DEST%\c_gate_bit_v12_0_8

vcom -quiet -2008 ^
  -work xbip_counter_v3_0_8 %SRC%\ip\dfx_controller\hdl\xbip_counter_v3_0_vh_rfs.vhd
vmap xbip_counter_v3_0_8 %DEST%\xbip_counter_v3_0_8

vcom -quiet -2008 ^
  -work c_counter_binary_v12_0_18 %SRC%\ip\dfx_controller\hdl\c_counter_binary_v12_0_vh_rfs.vhd
vmap c_counter_binary_v12_0_18 %DEST%\c_counter_binary_v12_0_18

vcom -quiet -2008 ^
  -work axi_utils_v2_0_8 %SRC%\ip\dfx_controller\hdl\axi_utils_v2_0_vh_rfs.vhd
vmap axi_utils_v2_0_8 %DEST%\axi_utils_v2_0_8

vcom -quiet -2008 ^
  -work lib_cdc_v1_0_2 %SRC%\ip\dfx_controller\hdl\lib_cdc_v1_0_rfs.vhd
vmap lib_cdc_v1_0_2 %DEST%\lib_cdc_v1_0_2

vcom -quiet -2008 ^
  -work lib_pkg_v1_0_3 %SRC%\ip\dfx_controller\hdl\lib_pkg_v1_0_rfs.vhd
vmap lib_pkg_v1_0_3 %DEST%\lib_pkg_v1_0_3

vcom -quiet -2008 ^
  -work lib_srl_fifo_v1_0_3 %SRC%\ip\dfx_controller\hdl\lib_srl_fifo_v1_0_rfs.vhd
vmap lib_srl_fifo_v1_0_3 %DEST%\lib_srl_fifo_v1_0_3

vcom -quiet -2008 ^
  -work dfx_controller_v1_0_6 %SRC%\ip\dfx_controller\hdl\dfx_controller_v1_0_rfs.vhd
vmap dfx_controller_v1_0_6 %DEST%\dfx_controller_v1_0_6

vlog -quiet C:\Xilinx\Vivado\2023.2\data\verilog\src\glbl.v

vcom -quiet -2008 ^
  -work xil_defaultlib ^
  %SRC%\ip\pll\pll_sim_netlist.vhdl ^
  %SRC%\ip\dfx_controller\dfx_controller_dfx_controller_table_pkg.vhd ^
  %SRC%\ip\dfx_controller\dfx_controller_dfx_controller_vsm_VS_0.vhd ^
  %SRC%\ip\dfx_controller\dfx_controller_dfx_controller_fetch.vhd ^
  %SRC%\ip\dfx_controller\dfx_controller_dfx_controller_icap_if_0.vhd ^
  %SRC%\ip\dfx_controller\dfx_controller_dfx_controller.vhd ^
  %SRC%\ip\dfx_controller\sim\dfx_controller.vhd ^
  %SRC%\ip\axi_bram\sim\axi_bram.vhd
vmap xil_defaultlib %DEST%\xil_defaultlib

vcom -quiet -2008 ^
  %SRC%\src\retime.vhdl ^
  %SRC%\src\reconfig_fn.vhdl ^
  %SRC%\src\dual_seven_seg_display.vhdl ^
  %SRC%\src\reconfig_action.vhdl ^
  %SRC%\src\pl.vhdl ^
  %SRC%\sim\test_pl.vhdl
set ec=%ERRORLEVEL%

echo.
echo =====================================================================
echo.
echo The sumulation does not work in QuestaSim, use Vivado's vsim instead.
echo.
echo =====================================================================
echo.

rem echo.
rem echo ========================================================
rem echo To run the simulation in ModelSim:
rem echo.
rem echo   cd {%DEST%}
rem echo   vsim work.test_pl -voptargs="+acc" -t ps
rem echo.
rem echo ========================================================
rem echo.

rem Do not pause inside MS Visual Studio Code, it has its own prompt on completion.
if not "%TERM_PROGRAM%"=="vscode" pause
exit /b %ec%
