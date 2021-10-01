# VHDL Projects

The source code for various investigations.

## Adder Tree

### Themes:
 * Automatic scaling
 * Recursive structures in hardware description languages

### Description
Build an adder tree structure for any number of operands to be summed. But does the recursive adder tree provide any advantage? Verified by comparing with two other FIR Filter implementations.

### References:
 * [Adder Trees Pipelined Efficiently by Recursion](http://blog.abbey1.org.uk/index.php/technology/adder-trees-pipelined-efficiently-by-recursion)
 * [FIR Filter Implementation Comparisons](http://blog.abbey1.org.uk/index.php/technology/fir-filter-implementation-comparisons)

## BRAM

### Description
Testing Vivado's large BlockRAM inferrencing and how and when it uses cascading.

### References:
 * [Cascade Block RAMs for Larger Memories](http://blog.abbey1.org.uk/index.php/technology/cascade-block-rams-for-larger-memories)

## Comparator

### Themes:
 * Automatic scaling
 * Recursive structures in hardware description languages

### Description
Produce both fast and efficient very large comparators of _n_-bit vectors.

### References:
 * [Large Comparators Pipelined Efficiently by Recursion](http://blog.abbey1.org.uk/index.php/technology/large-comparator-pipelined-efficiently-by-recursion)

## Fixed Point Arithmetic Libraries

### Themes:
 * Libraries

### Description
VHDL-2008 has added types `sfixed` and `ufixed` for fixed point arithmetic, but you may struggle to use them with older tools. Here's how to fix that.

### References:
 * [Compiling VHDL For The Missing Fixed Point Libraries](http://blog.abbey1.org.uk/index.php/technology/compiling-vhdl-for-the-missing-fixed-point-libraries)

## LFSR

### Themes:
 * Automatic scaling

### Description
Substituting _Linear Feedback Shift Register_ (LFSR) counters for synchronous counter equivalents to avoid the carry chain delay. The polynomial used for the LFSR is automatically selected based on the required maximum count value.

### References:
 * [Swapping Synchronous and LFSR Counters](http://blog.abbey1.org.uk/index.php/technology/swapping-synchronous-and-lfsr-counters)

## Local

### Themes:
 * Testing
 * Libraries

### Description
A library of testing functions with which to build test benches for VHDL projects. This is required to be compiled before using any other VHDL sources in this repository.

## Polynomial

### Themes:
 * Automatic scaling

### Description
Polynomial division for any polynomial for any number of bits work per clock cycle. Useful for calculating (for example) CRCs on byte-wide data.

### References:
 * [Bus-width Polynomial Division Logic](http://blog.abbey1.org.uk/index.php/technology/bus-width-polynomial-division-logic)

## Signal Spies

### Themes:
 * Testing

### Description
Familiarisation with VHDL-2008 "_External Signals_" and ModelSim "_Signal Spies_". Trying to understand some superficial explanations.

### References:
 * [Comparison of ModelSim 'Signal Spies' and VHDL 'External Signals'](http://blog.abbey1.org.uk/index.php/technology/comparison-of-modelsim-signal-spies-and-vhdl-external)
