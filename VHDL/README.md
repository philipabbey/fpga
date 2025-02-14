# VHDL Projects

The source code for various investigations.

## AXI-S Delay
 * Working with AXI data streams, buffering and pausing.

### References:
 * [Working With AXI Streaming Data](https://blog.abbey1.org.uk/index.php/technology/working-with-axi-streaming-data)


## AXI-S Delay RAM
 * Working with AXI data streams, interfacing XPM RAM as an AXI-S source with pipeling.

### References:
 * [Implementing an AXI-Streaming delay pipeline when reading data from XPM RAM](https://blog.abbey1.org.uk/index.php/technology/implementing-an-axi-streaming-delay-pipeline-when-reading)


## AXI-S Split & Join
 * Working examples of how to split and join a pair of AXI Streams.

### References:
* [AXI-Stream Split & Join Components](https://blog.abbey1.org.uk/index.php/technology/axi-stream-split-join-components)


## Adder Tree

### Themes:
 * Automatic scaling
 * Recursive structures in hardware description languages

### Description
Build an adder tree structure for any number of operands to be summed. But does the recursive adder tree provide any advantage? Verified by comparing with two other FIR Filter implementations.

### References:
 * [Adder Trees Pipelined Efficiently by Recursion](https://blog.abbey1.org.uk/index.php/technology/adder-trees-pipelined-efficiently-by-recursion)
 * [FIR Filter Implementation Comparisons](https://blog.abbey1.org.uk/index.php/technology/fir-filter-implementation-comparisons)


## BRAM

### Description
Testing Vivado's large BlockRAM inferrencing and how and when it uses cascading.

### References:
 * [Cascade Block RAMs for Larger Memories](https://blog.abbey1.org.uk/index.php/technology/cascade-block-rams-for-larger-memories)


## Comparator

### Themes:
 * Automatic scaling
 * Recursive structures in hardware description languages

### Description
Produce both fast and efficient very large comparators of _n_-bit vectors.

### References:
 * [Large Comparators Pipelined Efficiently by Recursion](https://blog.abbey1.org.uk/index.php/technology/large-comparator-pipelined-efficiently-by-recursion)


## Control Sets

### Description
Testing Vivado's control set remapping ability in order to increase packing density and reduce routing congestion.

### References:
 * [Practical Control Set Reduction](https://blog.abbey1.org.uk/index.php/technology/practical-control-set-reduction)


## Dynamic Function eXchange (DFX)

### Description
A minimal design to demonstrate DFX on a Zybo Z7 development board.

### References:
 * [Dynamic Function eXchange](https://blog.abbey1.org.uk/index.php/technology/dynamic-function-exchange)


## Fast Fourier Transform (FFT)

### Themes:
 * Automatic scaling
 * Recursive structures in hardware description languages

### Description
Generalise the VHDL implementation to a multi-radix 'Radix-*n*' *p*-Point FFT where '*n*' and '*p*' are positive integer generics to the entity.

### References:
 * [Large Comparators Pipelined Efficiently by Recursion](https://blog.abbey1.org.uk/index.php/technology/radix-n-fast-fourier-transforms)


## Fixed Point Arithmetic Libraries (`sfixed`)

### Themes:
 * Libraries

### Description
VHDL-2008 has added types `sfixed` and `ufixed` for fixed point arithmetic, but you may struggle to use them with older tools. Here's how to fix that.

### References:
 * [Compiling VHDL For The Missing Fixed And Floating Point Libraries](https://blog.abbey1.org.uk/index.php/technology/compiling-vhdl-for-the-missing-fixed-and-floating)


## Large Barrel Shift Pipelined by Iteration or Recursion

### Themes:
 * Automatic scaling

### Description
Creating an excessively large barrel shift component that is arbitraily pipelined.

### References:
 * [Large Barrel Shift Pipelined by Iteration or Recursion](https://blog.abbey1.org.uk/index.php/technology/large-barrel-shift-pipelined-by-iteration-or-recursion)


## LFSR

### Themes:
 * Automatic scaling

### Description
Substituting _Linear Feedback Shift Register_ (LFSR) counters for synchronous counter equivalents to avoid the carry chain delay. The polynomial used for the LFSR is automatically selected based on the required maximum count value.

### References:
 * [Swapping Synchronous and LFSR Counters](https://blog.abbey1.org.uk/index.php/technology/swapping-synchronous-and-lfsr-counters)


## Local

### Themes:
 * Testing
 * Libraries

### Description
A library of testing functions with which to build test benches for VHDL projects. This is required to be compiled before using any other VHDL sources in this repository.


## Low Speed Serial I/O

### Themes:
 * I/O

### Description
Code to implement and test an implementation of Low Speed Serial I/O.


## Multiplexer

### Themes:
 * Automatic scaling

### Description
Creating an excessively large multiplexer component that is arbitraily pipelined.

### References:
 * [Large Multiplexer Pipelined by Recursion](https://blog.abbey1.org.uk/index.php/technology/large-multiplexer-pipelined-by-recursion)


## Packages

### Themes:
 * Libraries

### Description
Simple examples of working with VHDL-2008 packages. How close to inheritance-lie properties do  the new VHDL features get us? Protected types are class-like but how close?


## PRBS

### Themes:
 * Automatic scaling

### Description
Generic Pseudorandom Binary Sequence (PRBS) Sequence Generator any polynomial or [ITU-T O.150 standard](https://www.itu.int/rec/T-REC-O.150-199210-S) generators for any number of bits per clock cycle. Useful for testing.

### References:
 * [Multiple Bit Pseudorandom Binary Sequence](https://blog.abbey1.org.uk/index.php/technology/multiple-bit-pseudorandom-binary-sequence)


## Polynomial

### Themes:
 * Automatic scaling

### Description
Polynomial division for any polynomial for any number of bits work per clock cycle. Useful for calculating (for example) CRCs on byte-wide data.

### References:
 * [Bus-width Polynomial Division Logic](https://blog.abbey1.org.uk/index.php/technology/bus-width-polynomial-division-logic)


## Printing

### Themes:
 * Testing

### Description
VHDL solutions I keep searching the Internet for, so I've created a crib.

### References:
 * [A Crib For Formatting Strings in VHDL](https://blog.abbey1.org.uk/index.php/technology/a-crib-for-formatting-strings-in-vhdl)


## Report CDC

### Themes:
 * Design verification

### Description
VHDL code to illustrate a number of incorrect clock domain crossing topologies identified by Vivado's TCL command <tt>report_cdc</tt>.

### References:
 * [Verification of Clock Domain Crossing Topologies](https://blog.abbey1.org.uk/index.php/technology/verification-of-clock-domain-crossing-topologies)


## Signal Spies

### Themes:
 * Testing
 
### Description
Familiarisation with VHDL-2008 "_External Signals_" and ModelSim "_Signal Spies_". Trying to understand some superficial explanations.

### References:
 * [Comparison of ModelSim 'Signal Spies' and VHDL 'External Signals'](https://blog.abbey1.org.uk/index.php/technology/comparison-of-modelsim-signal-spies-and-vhdl-external)


## Speed Test

### Description
A proposed method for checking attainable clock speeds comparatively and ability to achieve timing closure on different devices.

### References:
 * [Determining A Device's Maximum Clock Speed](https://blog.abbey1.org.uk/index.php/technology/determining-a-device-s-maximum-clock-speed)


## Sychroniser

### Themes:
 * Testing

### Description

1. Implementing dynamic timing checks for a standard clock domain crossing solution.
2. Two synchronisers taught by Doulos coded and examined.

### References:
 * [Dynamic Timing Check For A Standard Clock Domain Crossing Solution](https://blog.abbey1.org.uk/index.php/technology/dynamic-timing-check-for-a-standard-clock-domain)
 * [Doulos Clock Domain Crossing Material](https://blog.abbey1.org.uk/index.php/technology/doulos-clock-domain-crossing-material)


## XPM

### Themes:
 * Testing

### Description
Testing Xilinx Parameterized Macros (XPM).

### References:
 * [Exploring Xilinx XPM Memory](https://blog.abbey1.org.uk/index.php/technology/exploring-xilinx-xpm-memory)
