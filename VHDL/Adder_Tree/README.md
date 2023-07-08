# Adder Tree

![Adder Trees Pipelined Efficiently by Recursion](./media/Pipeline_Adder_Tree.png?raw=true "Adder Trees Pipelined Efficiently by Recursion")

I wanted to solve the problem of how to construct a size efficient pipelined adder tree in VHDL so that a FIR filter's products could be summed with a decent clock speed.

Please read the blog post [Adder Trees Pipelined Efficiently by Recursion](https://blog.abbey1.org.uk/index.php/technology/adder-trees-pipelined-efficiently-by-recursion) for an explanation of how the code works in detail.

# FIR Filter Comparison

The whole point of creating the automatically self-constructing pipelined adder tree component was to instantiate FIR filters by just specifying VHDL generic parameters. In order to decide if the component has merit, it is necessary to compare it with other implementations. I compare three different implementations of a FIR filter, the "traditional" with the adder tree, the "transpose" and "systolic" variants that are simple iterative pipelined arrays.

Please read the blog post [FIR Filter Implementation Comparisons](https://blog.abbey1.org.uk/index.php/technology/fir-filter-implementation-comparisons) for an explanation of how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
