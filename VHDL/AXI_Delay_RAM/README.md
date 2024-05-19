# AXI Delay RAM

An effective solution to interface an XPM RAM as a source of data feeding an AXI Stream.

Please read the following blog posts for an explanation:

* [Implementing an AXI-Streaming delay pipeline when reading data from XPM RAM](https://blog.abbey1.org.uk/index.php/technology/implementing-an-axi-streaming-delay-pipeline-when-reading)


## Compilation

2. Compile [OSVVM](../compile_osvvm.cmd).
3. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
