# Dynamic Function eXchange (DFX)

A minimal design to demonstrate DFX on a Zybo Z7 development board. This includes:
* a code structure,
* TCL compilation scripts, and 
* a TCL demonstration script to show the partial reconfiguration of the FPGA.

Please read the blog post [Dynamic Function eXchange](https://blog.abbey1.org.uk/index.php/technology/dynamic-function-exchange) for an explanation of how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
