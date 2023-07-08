# Visualising Clock Domain Crossings in Vivado

![Using colour to show signal clock domain](./media/Dual_Transfer.png?raw=true "Using colour to show signal clock domain")

This is not the place for being an authority on clock domain crossing techniques as a web search will throw up many authoritative and meritorious articles very quickly on the subject. Here are some at the top of the list:

* [Some Simple Clock-Domain Crossing Solutions](https://zipcpu.com/blog/2017/10/20/cdc.html) by The ZipCPU
* [Introduction to Clock Domain Crossing: Double Flopping](https://www.allaboutcircuits.com/technical-articles/introduction-to-clock-domain-crossing-double-flopping/) by Steve Arar
* [Clock Domain Crossing (CDC) Design & Verification Techniques Using SystemVerilog](http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf) by Clifford E. Cummings
* [Understanding Clock Domain Crossing Issues](https://www.eetimes.com/understanding-clock-domain-crossing-issues/) by Saurabh Verma, Ashima S. Dabare

Instead here I'm concerned with making it easy to get familiar with someone else's HDL code, perhaps where there is some doubt over the safety of some of the cross clock domain signals. To do this I wanted a better way to visualise which clock domain each register was in based on the clock name on the clock pin. So I decided to try using a facility in Vivado where gates can be either or both 'highlighted' or 'marked'. Highlighted seemed to give the best results, here are a few to see if you are convinced about this sort of visualisation technique.

Please read the blog post [Visualising Clock Domain Crossings in Vivado](https://blog.abbey1.org.uk/index.php/technology/visualising-clock-domain-crossings-in-vivado) to explain how the code works in detail.

## Execution

1. Open a design in Vivado and view a schematic
2. Source the [colour.tcl](colour.tcl) TCL script in the Vivado TCL shell

```tcl
source {colour.tcl}
```

3. Use either of these two methods to perform colouration:
   * Select a group of clocked gates to be coloured and run `colour_selected_primitives_by_clock_source`, OR
   * Execute some TCL to list all the required cells to be coloured.

```tcl
colour_selected_primitives_by_clock_source [get_cells ...]
```

The routine is slow, so selecting all gates in a large design will take a long time. Each new invocation of the TCL proc will uncolour the previously coloured gates.


# Verification of Cross Clock Domain Timing Constraints and Exceptions

Intended to be part of a tutorial for those new to FPGA design, this blog is specific to Xilinx's Synthesis tool "Vivado", and a refresher as someone returning to FPGA design having used different tools (Synplify Pro) over a decade ago. The principles are the same, but the method of application has changed for the better so that it is simpler to get right.

## Execution

Requires the [TCL library file](../auto_constrain/out_of_context_synth_lib.tcl) for out of context synthesis.

You will need to create a Vivado project with both:
* [transfer.vhdl](transfer.vhdl)
* [ooc.tcl](ooc.tcl)

Please read the blog post [Verification of Cross Clock Domain Timing Constraints and Exceptions](https://blog.abbey1.org.uk/index.php/technology/verification-of-clock-domain-crossing-timing-constraints-and-exceptions) for an explanation of how to amend the commented constraints in [ooc.xdc](ooc.xdc) to trial the methods proposed, and enter the TCL commands in Vivado to test their effect.
