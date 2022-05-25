## Report CDC

Even if you are aware of all the rules about how to mitigate metastability from passing signals from one clock domain to another, i.e. clock domain crossings, it is all too easy to miss a clock domain crossing (CDC) by inspection using *Mark 1 Eye Ball*, or to forget some of the constraints, or to foul up the cell name in XDC, or to overlook some finer aspect of risk mitigation because the delivery of the design is divided amongst a team, who may be working to different standards. Vivado includes a TCL function <tt>report_cdc</tt> to aid the designer, and it has proven effective in locating issues that need addressing. Here are some examples of the finer points that the function identifies.

Please read the blog post [Verification of Clock Domain Crossing Topologies](https://blog.abbey1.org.uk/index.php/technology/verification-of-clock-domain-crossing-topologies) for an explanation of how the code replicates common clock domain crossing issues reported by Vivado.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
