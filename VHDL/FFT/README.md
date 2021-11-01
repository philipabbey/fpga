# Recursive Fast Fourier Transform (FFT)

\[
\omega^n_N=e^{\frac{-2\pi ni}{N}}
\]

\[
F_4=\begin{pmatrix}
\omega_4^0 &amp; \omega_4^0 &amp; \omega_4^0 &amp; \omega_4^0 \\
\omega_4^0 &amp; \omega_4^2 &amp; \omega_4^1 &amp; \omega_4^3 \\
\omega_4^0 &amp; \omega_4^4 &amp; \omega_4^2 &amp; \omega_4^6 \\
\omega_4^0 &amp; \omega_4^6 &amp; \omega_4^3 &amp; \omega_4^9
\end{pmatrix}
\]

This blog is not intended to describe the FFT itself but an implementation in VHDL that scales using generics and without software tools that generate IP cores. It is assumed that you already understand the FFT algorithm in principle or at least have access to decent educational resources. Here I will write a working simulatable and hopefully synthesisable VHDL Core configured through generics for the popular Cooley-Tukey algorithm using decimation in time (DIT). The desire is to explore how different radices are implemented, and even generalise the VHDL implementation to a multi-radix 'Radix-*n*' *p*-Point FFT where '*n*' and '*p*' are positive integer generics to the entity. As the FFT is defined recursively, a recursive VHDL implementation felt like a natural fit.

Please read the blog post [Large Comparators Pipelined Efficiently by Recursion](http://blog.abbey1.org.uk/index.php/technology/radix-n-fast-fourier-transforms) to explain how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```

<script defer src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js">
