# Mean Time Between Failure (MTBF) Analysis in Vivado

TCL to automate the generation of MTBF reports for a simple _n_-stage CDC synchroniser in order to understand how the calculation is applied to a simple design.

Please read the blog post [Managing Mean Time Between Failure in Xilinx Devices](https://blog.abbey1.org.uk/index.php/technology/managing-mean-time-between-failure-in-xilinx-devices) for an explanation of how the code works in detail.

## Execution

Requires the [TCL library file](../auto_constrain/out_of_context_synth_lib.tcl) for out of context synthesis.

1. Open a new project in Vivado
2. Add the Two VHDL sources and synthesise and the XDC constraints files
3. Amend the clock frequencies to use in [ooc.tcl](ooc.tcl)
4. Source the [results.tcl](results.tcl) TCL script in the Vivado TCL shell

```tcl
source -notrace {results.tcl}
```

5. Locate the `results.log` file for analysis
