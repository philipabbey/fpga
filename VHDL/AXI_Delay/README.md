# AXI Delay

A few solutions and options to manipulating AXI data streams.

Please read the following blog posts for an explanation:

* [Working With AXI Streaming Data](http://blog.abbey1.org.uk/index.php/technology/working-with-axi-streaming-data)
* [AXI Data Stream Width Conversion](https://blog.abbey1.org.uk/index.php/technology/axi-data-stream-width-conversion)
* [AXI Stream General Edit](https://blog.abbey1.org.uk/index.php/technology/axi-stream-general-edit)


## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. For `axi_edit` compile [OSVVM](../compile_osvvm.cmd).
3. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
