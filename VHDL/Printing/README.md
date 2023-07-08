## Printing

VHDL solutions I keep searching the Internet for, so I've created a crib.

There's no `printf()` equivalent in VHDL that works with all types, and I think it would be quite hard to create as it is a strongly typed language. Here are some examples of what can be done in VHDL 2008, and a couple of extensions.

Please read the blog post [A Crib For Formatting Strings in VHDL](https://blog.abbey1.org.uk/index.php/technology/a-crib-for-formatting-strings-in-vhdl) for an explanation.

## Compilation

1. Compile VHDL library [ieee_proposed](../sfixed) if you have not already done so.
2. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```
