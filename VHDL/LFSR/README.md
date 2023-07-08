# LFSR Counters

![Swapping Synchronous and LFSR Counters](./media/LFSR.svg?raw=true "Swapping Synchronous and LFSR Counters")

The plan here is to simulate your design with synchronous counters which show an easy to read incrementing integer, then swap out the synchronous counter for a faster equivalent Linear Feedback Shift Register (LFSR). The VHDL must be able to automatically select the correct polynomial for the maximum count value required without intervention or assistance. This is perhaps a moot point with modern FPGAs being so capable of arithmetic with DSP slices that carry chain propagation delays do not get noticed, but remains relevant in the ASIC world.

Please read the blog post [Swapping Synchronous and LFSR Counters](https://blog.abbey1.org.uk/index.php/technology/swapping-synchronous-and-lfsr-counters) for an explanation of how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
