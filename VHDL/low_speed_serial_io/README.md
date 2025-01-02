## Low Speed Serial I/O

High speed serial I/O has been made simple to set up. It does however have a lower limit of clock speed, e.g. 300 MHz. Whilst the data rate can be lower than 300 Mb/s by using a chip select pin to negate the validity of some bits over time, that does not offer a reduce power solution from a lower clock speed. This code implements advice from a blog on [Source-synchronous inputs](https://www.01signal.com/electronics/source-synchronous-inputs/) by Eli Billauer.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Generate the IP from Vivado using one of:
   * `ip_gen.tcl` - Basic 180&deg; phase shift
   * `ip_gen_idelay.tcl` - Fine IDELAY phase shift
   * `ip_gen_01.tcl` - 01-signal sampling
3. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file. Any errors due to the IP generation can be solved by removing files not actually needed for compilation.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```

## Files required for Vivado project

### Phase Shifting

Basic 180&deg; phase shift
* `retime.vhdl`
* `zybo_z7_10.vhdl`
* `test_zybo_z7_10.vhdl`
* `constraints\Zybo-Z7-Master.xdc`
* `constraints\synthesis.xdc`
* `constraints\implementation.xdc`

Fine IDELAY phase shift
 * `retime.vhdl`
 * `zybo_z7_10_idelay.vhdl`
 * `test_zybo_z7_10.vhdl`
 * `constraints\Zybo-Z7-Master.xdc`
 * `constraints\synthesis.xdc`
 * `constraints\implementation.xdc`


### 01-Signal Sampling

* `retime.vhdl`
* `zybo_z7_10_01sampling.vhdl`
* `test_zybo_z7_10.vhdl`
* `constraints\Zybo-Z7-Master.xdc`
* `constraints\synthesis_01.xdc`


## References

1. [Low Speed Serial I/O](https://blog.abbey1.org.uk/index.php/technology/low-speed-serial-i-o)
2. [Source-synchronous inputs](https://www.01signal.com/electronics/source-synchronous-inputs/) by Eli Billauer
3. [Using 01-signal sampling with source-synchronous inputs](https://www.01signal.com/electronics/01-signal-sampling/) by Eli Billauer
