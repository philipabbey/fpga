## Generic Pseudorandom Binary Sequence (PRBS) Sequence Generator

Digital Test Patterns For Performance Measurements On Digital Transmission Equipment

The [ITU-T O.150 standard](https://www.itu.int/rec/T-REC-O.150-199210-S) defines several methods of generating pseudorandom binary sequence meeting maximum sequences of zeros or ones. These are used for testing digital transmission equipment. I found a messy Xilinx implementation (v1.0) in [XAPP1240](https://docs.amd.com/r/en-US/xapp1240-k7-us-clk-data-recovery) and I felt there was a more general and succinct implementation with no need for a checker, so I've reinvented it. Subsequently, I found a significantly cleaned up [v1.1](https://raw.githubusercontent.com/palbicoc/AUX_Bus/refs/heads/master/AUX_bus.srcs/sources_1/new/prbs_any.vhd). It is essentially a [linear feedback shift register](../LFSR), but producing multiple bits of PRBS per clock cycle in a similar way to the [Polynomial](../Polynomial) divisions used for CRC checking.

The `itu_prbs_generator` component instantiates the more general LFSR-based PRBS generator, but customises it with one of the ITU-T polynomials. Just select which row number from the table below, or array constant index in [`itu_t_o150_c`](../Local/lfsr_pkg.vhdl#L84), to use for the `itu_prbs_generator`, and the rest is done for you. This saves misconfiguring the parameters. Or you can re-use the more general `prbs_generator` with your own desired polynomial.

Parameters values for the ITU-T compliant PRBS polynomials:

| Poly length | Poly tap | Inv pattern? | Number of |   Bit seq. |  Max 0   |
|             |          |              |   stages  |    length  | sequence |
|-------------|----------|--------------|-----------|------------|----------|
|       7     |     6    |     false    |      7    |        127 |     6    |
|       9     |     5    |     false    |      9    |        511 |     8    |
|      11     |     9    |     false    |     11    |       2047 |    10    |
|      15     |    14    |     true     |     15    |      32767 |    15    |
|      20     |     3    |     false    |     20    |    1048575 |    19    |
|      23     |    18    |     true     |     23    |    8388607 |    23    |
|      29     |    27    |     true     |     29    |  536870911 |    29    |
|      31     |    28    |     true     |     31    | 2147483647 |    31    |

Xilinx provide a checker version of this component, which I have removed as it is redundant. Simple employ a second generator and compare the received PRBS after transmision with the localy generated PRBS. An XOR of the pair of vectors will provide the bit location of each error. No separate checker is actually required, and the way it is used in XAPP1240 relies on users knowing how to set up the component and provide a constant `data_in` driven to "0..0", which requires additional study and reverse engineering. This version is minimal and simpler.


## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```


## References

1. [Pseudorandom binary sequence](https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence)
2. [TX Pattern Generator](https://docs.amd.com/r/en-US/am017-versal-gtm-transceivers/TX-Pattern-Generator)
