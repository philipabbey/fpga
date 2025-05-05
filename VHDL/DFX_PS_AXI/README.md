# Dynamic Function eXchange with ICAP Driven by Software

A minimal design to demonstrate DFX on a Zybo (Z7 or legacy) development board. This includes:
* a code structure,
* TCL compilation scripts, and 
* C software for the PS to demonstrate the available interactions.

Please read the blog post [Dynamic Function eXchange with ICAP Driven by Software](https://blog.abbey1.org.uk/index.php/technology/dynamic-function-exchange-with-icap-driven-by-software) for an explanation of how the code works in detail.

## Compilation

This project must be simulated in Vivado's xsim.

1. Build the Xilinx Project by [`source dfx_ps_legacy.tcl`](./tcl/dfx_ps_legacy.tcl).
2. Build the FPGA artifacts with [`source build.tcl`](./tcl/build.tcl).
3. Amend the Vivado project memory file reference from `src/rm_all_comp.mem` to `project/rm_all_comp.mem`.
4. (Optionally skip) Run the Vivado's xsim.
5. Create the Vitis Platform from `/Drive/path/.../Vivado/dfx_test/dfx_ps_legacy.xsa`.
6. Create the Vitis Standlone Application from [`ps/*.c`](./ps/) and the platform from step 5.
7. Ensure that the application run settings references the correct bitstream file, preferrably the one from the project build results, `project/initial_rom.bit` from step 2. Then run the application on a Zybo board.

The Windows batch file [modelsim_compile.cmd](modelsim_compile.cmd) is provided as it can be used to check compilability, but does not work in QuestaSim due to vsim errors within protected IP when loading. These cannot be investigated due to the protection. The script assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
