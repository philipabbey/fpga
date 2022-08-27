## VHDL-2008 Packages

Simple examples of working with VHDL-2008 packages. How close to inheritance-like properties do the new VHDL features get us? Protected types are class-like but how close?

I have felt that the VHDL implementation of packages was perhaps clumsy, and unnatural by the standards and expectations of modern languages. This does of course overlook that purpose of VHDL is to describe the implementation of logic (a "hardware description language") rather than programme software. More recent developments in the language have been to "improve" the behavioural parts for verification rather than for synthesis. So what have we now got?

Please read the blog post [VHDL-2008 Packages](https://blog.abbey1.org.uk/index.php/technology/vhdl-2008-packages) for an explanation of how the code works in detail.

## Compilation

1. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
