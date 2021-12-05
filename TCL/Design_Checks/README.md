# Design Policy Checks in Vivado

TCL `proc`s to search a Vivado design for:
* Transparent Latches
* Asynchronous Resets
* Registers Without Resets
* Critical Clock Domain Crossing Issues

Please read the blog post [Automating Code Review Design Checks in Vivado](http://blog.abbey1.org.uk/index.php/technology/automating-code-review-design-checks-in-vivado) for an explanation of how the code works in detail.

## Execution

1. Open a design in Vivado source
2. Source the [design_policy_checks.tcl](design_policy_checks.tcl) TCL script in the Vivado TCL shell

```tcl
source {design_policy_checks.tcl}
```

3. `design_policy_checks` will be run by the sourced TCL script, but you can always run it again.

```tcl
design_policy_checks
```
