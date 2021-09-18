# Cascade Block RAMs for Larger Memories

Xilinx has clear advice on how to create large performant memories in FPGA. This work checks the reality of their claims given a project where timing closure was critical in this implementation.

Please read the blog post [Cascade Block RAMs for Larger Memories](http://blog.abbey1.org.uk/index.php/technology/cascade-block-rams-for-larger-memories)

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
