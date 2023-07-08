# Recursive Fast Fourier Transform (FFT)

This blog is not intended to describe the FFT itself but an implementation in VHDL that scales using generics and without software tools that generate IP cores. It is assumed that you already understand the FFT algorithm in principle or at least have access to decent educational resources. Here I will write a working simulatable and hopefully synthesisable VHDL Core configured through generics for the popular Cooley-Tukey algorithm using decimation in time (DIT). The desire is to explore how different radices are implemented, and even generalise the VHDL implementation to a multi-radix 'Radix-*n*' *p*-Point FFT where '*n*' and '*p*' are positive integer generics to the entity. As the FFT is defined recursively, a recursive VHDL implementation felt like a natural fit.

### Radix-4 Fourier Matrix
<img width="203" alt="Radix-4 Fourier Matrix" src="./media/Radix-4_Fourier_Matrix.png?raw=true">

Twiddle Factors given by:

<img width="106" alt="Twiddle Factor Fourmula" src="./media/Twiddle_Factors.png?raw=true">

Please read the blog post [Large Comparators Pipelined Efficiently by Recursion](https://blog.abbey1.org.uk/index.php/technology/radix-n-fast-fourier-transforms) for an explanation of how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Compile VHDL library [sfixed](../sfixed) if you have not already done so.
3. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
