## Low Speed Serial I/O

High speed serial I/O has been made simple to set up. It does however have a lower limit of clock speed, e.g. 300 MHz. Whilst the data rate can be lower than 300 Mb/s by using a chip select pin to negate the validity of some bits over time, that does not offer a reduce power solution from a lower clock speed. This code implements advice from a blog on [Source-synchronous inputs](https://www.01signal.com/electronics/source-synchronous-inputs/) by Eli Billauer.


## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```


## References

1. [Large Multiplexer Pipelined by Recursion](https://blog.abbey1.org.uk/index.php/technology/large-multiplexer-pipelined-by-recursion)
2. [Source-synchronous inputs](https://www.01signal.com/electronics/source-synchronous-inputs/) by Eli Billauer
