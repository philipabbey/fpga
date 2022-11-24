# Determining Port Clock Domains for Automating Input and Output Constraints

One of the annoyances with the method of [Specifying Boundary Timing Constraints](https://blog.abbey1.org.uk/index.php/technology/specifying-boundary-timing-constraints-in-vivado) in Vivado is that each input and output (albeit in bus-based blocks) needs to be treated with a clock domain and a delay. For designs with multiple clocks and many ports this becomes cumbersome, and the information to automate this is present in the elaborated design. This code extracts the clock domains in an automatic way, and then apply the constraints to a design, removing a tedious step in the process.

Please read the blog post [Determining Port Clock Domains for Automating Input and Output Constraints](https://blog.abbey1.org.uk/index.php/technology/determining-port-clock-domains-for-automating-input-and#extraction) to explain how the code works in detail.

## Execution

Customise these command, e.g. to include the full path to the filenames, and execute in Vivado with the desired project open.

```tcl
read_xdc -unmanaged -mode out_of_context out_of_context_synth_lib.tcl
read_xdc -unmanaged -mode ooc.tcl
reorder_files -fileset constrs_1 -front [get_files ooc.tcl]
reorder_files -fileset constrs_1 -front [out_of_context_synth_lib.tcl]
```
