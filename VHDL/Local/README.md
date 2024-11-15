# Local Library

A library of testing functions with which to build test benches for VHDL projects. This is required to be compiled before using any other VHDL sources in this repository.

## lfsr_pkg.vhdl

Functions required for automatically selecting LFSR polynomials and determining their terminal value for a given maximal count.

## math_pkg.vhdl

Functions typically used for initialising constants, e.g. from generics, in RTL code when constructing data types and structures.

## rtl_pkg.vhdl

Functions typically re-used for RTL code, e.g. common vector manipulations.

## testbench_pkg.vhdl

Function include:

* Setting up clocks
* Stopping clocks without std.env.stop causing the source window to cover the wave window in ModelSim.
* Clock alignment
* Random 'wiggle' for 'data valid' lines to check logic has no dependency on any mark space ratio.

## Compilation

Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file. Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
