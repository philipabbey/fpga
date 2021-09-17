-- Refer to "IEEE Standard VHDL Mathematical Packages" for standard definitions. There are some rogue
-- and incorrect package definitions on the Internet!
-- https://perso.telecom-paristech.fr/guilley/ENS/20171205/TP/tp_syn/doc/IEEE_VHDL_1076.2-1996.pdf

package math is

  function minimum(a, b : positive) return positive;
  
  function trunc(r : real; d : natural) return real;

  function trunc_ceil(r : real; d : natural) return real;

  function trunc_ceil(r : real; d : natural) return integer;

  function log_ceil(
    n    : positive;
    base : positive := 2
  ) return natural;

  function log_floor(
    n    : positive;
    base : positive := 2
  ) return natural;

  function root_ceil(
    n    : positive;
    root : positive := 2
  ) return positive;

  function root_ceil(
    n    : positive;
    root : real := 2.0
  ) return positive;

end package;

library ieee;
use ieee.math_real.all;

package body math is

  -- Not been implemented for 'positive' in some tools! Where it has been implemented, the function's
  -- presence causes ambiguity. Helpful...
  --
  -- Quartus Prime:
  -- Error (10482): VHDL error at comparator.vhdl(85): object "minimum" is used but not declared
  -- Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
  --
  -- ModelSim: ** Error: A:/Philip/Work/VHDL/Comparator/comparator.vhdl(89): Subprogram "minimum" is ambiguous.
  function minimum(a, b : positive) return positive is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;

  -- Truncate real value, r, to d decimal places. A simple extention to the IEE 'trunc' function.
  function trunc(r : real; d : natural) return real is
    constant exp : real := (1.0 * 10.0**d);
  begin
    return trunc(r * exp) / exp;
  end function;

  -- Truncate real value, r, to d decimal places then round up to nearest integer.
  function trunc_ceil(r : real; d : natural) return real is
    constant exp : real := (1.0 * 10.0**d);
  begin
    return ceil(trunc(r * exp) / exp);
  end function;

  -- Truncate real value, r, to d decimal places then round up to nearest integer.
  function trunc_ceil(r : real; d : natural) return integer is
    constant exp : real := (1.0 * 10.0**d);
  begin
    return integer(ceil(trunc(r * exp) / exp));
  end function;

  -- https://stackoverflow.com/questions/44717034/function-clogb2-generated-by-vivado-cant-synthesize-with-loop-limit-error
  function log_ceil(
    n    : positive;
    base : positive := 2
  ) return natural is
  begin
    return natural(ceil(log(real(n), real(base))));
  end function;

--  function log_ceil(
--    n    : natural;
--    base : positive := 2
--  ) return natural is
--    variable ans : positive := 1;
--  begin
--    while base**ans <= n loop
--      ans := ans + 1;
--    end loop;
--    return ans;
--  end function;

  function log_floor(
    n    : positive;
    base : positive := 2
  ) return natural is
  begin
    return natural(floor(log(real(n), real(base))));
  end function;

  function root_ceil(
    n    : positive;
    root : positive := 2
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/real(root))));
  end function;

  function root_ceil(
    n    : positive;
    root : real := 2.0
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/root)));
  end function;

end package body;
