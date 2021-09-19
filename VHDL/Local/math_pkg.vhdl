-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Refer to "IEEE Standard VHDL Mathematical Packages" for standard definitions. There are some rogue
-- and incorrect package definitions on the Internet!
-- https://perso.telecom-paristech.fr/guilley/ENS/20171205/TP/tp_syn/doc/IEEE_VHDL_1076.2-1996.pdf
--
-- P A Abbey, 23 August 2019
--
-------------------------------------------------------------------------------------

package math_pkg is

  -- Return the minimum of 'a' and 'b'.
  --
  -- This function has not been implemented for 'positive' in some tools! Where it
  -- has been implemented, the function's presence causes ambiguity. Helpful...
  --
  -- Quartus Prime:
  -- Error (10482): VHDL error at file.vhdl(xx): object "minimum" is used but not declared
  -- Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
  --
  -- ModelSim: ** Error: file.vhdl(xx): Subprogram "minimum" is ambiguous.
  --
  -- Therefore qualification by full path name might be required,
  --   e.g. 'local.math_pkg.minimum(..)'.
  --
  -- Usage:
  --   constant min : positive := minimum(4, width_g);
  --
  function minimum(a, b : positive) return positive;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 1.23
  --
  function trunc(r : real; d : natural) return real;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 2.0
  --
  function trunc_ceil(r : real; d : natural) return real;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 2
  --
  function trunc_ceil(r : real; d : natural) return integer;


  -- Return the ceil(log(n, base)), i.e. round up the result of log(n, base).
  --
  function ceil_log(
    n    : positive;
    base : positive := 2
  ) return positive;


  -- Return the floor(log(n, base)), i.e. round down the result of log(n, base).
  --
  function floor_log(
    n    : positive;
    base : positive := 2
  ) return natural;


  -- Return the ceil(root'th root of n), i.e. round up the result of taking the root.
  -- This overloaded version only allows positive integer roots.
  --
  function ceil_root(
    n    : positive;
    root : positive := 2
  ) return positive;


  -- Return the ceil(root'th root of n), i.e. round up the result of taking the root.
  -- This overloaded version allows for real roots.
  --
  function ceil_root(
    n    : positive;
    root : real := 2.0
  ) return positive;

end package;


library ieee;
use ieee.math_real.all;

package body math_pkg is

  function minimum(a, b : positive) return positive is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;


  function trunc(r : real; d : natural) return real is
    constant exp : real := (1.0 * 10.0**d);
  begin
--    report "trunc(" & real'image(r) & ", " & integer'image(d) & ") = " & real'image(trunc(r * exp));
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
  function ceil_log(
    n    : positive;
    base : positive := 2
  ) return positive is
  begin
    return positive(ceil(log(real(n), real(base))));
  end function;


  function floor_log(
    n    : positive;
    base : positive := 2
  ) return natural is
  begin
    return natural(floor(log(real(n), real(base))));
  end function;


  function ceil_root(
    n    : positive;
    root : positive := 2
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/real(root))));
  end function;

  function ceil_root(
    n    : positive;
    root : real := 2.0
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/root)));
  end function;

end package body;
