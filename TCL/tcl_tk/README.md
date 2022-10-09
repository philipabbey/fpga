# Driving a graphical display using VHDL

An example TCK/TK graphical display driven by VHDL such that as signals change, the display reflects the new values.

Please read the blog post [TCL/TK Graphical Display Driven By A VHDL Test Bench](https://blog.abbey1.org.uk/index.php/technology/tcl-tk-graphical-display-driven-by-a-vhdl) for an explanation of how the code works in detail.

## Execution

1. Compile VHDL library [local](../../VHDL/Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.
3. Open the simulation in ModelSim.
4. Source the [sevseg_display.tcl](sevseg_display.tcl) TCL script in the ModelSim TCL shell. This should open up the graphical display in a separate window and set up the update trigger.

```tcl
source {sevseg_display.tcl}
```

5. `run -all` multiple times until completion.

![TCL/TK Graphical Display driven by VHDL in ModelSim](./media/time_display.png?raw=true "Example TCL/TK Graphical Display")

## Acknowledgements

Jointly code with @josephabbey.
