# AXI Stream Split & Join

Working examples of how to split and join a pair of AXI Streams. Both the splitter and joiner are tested individually, and then a final test using a pair of different parallel AXI-S loads shows the pair working together.

Please read the following blog posts for an explanation:

* [AXI-Stream Split & Join Components](https://blog.abbey1.org.uk/index.php/technology/axi-stream-split-join-components)


## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
