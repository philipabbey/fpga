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
  function minimum(constant a, b : positive) return positive;

  -- Return the maximum of 'a' and 'b'.
  --
  -- This function has not been implemented for Quartus Prime.
  --
  -- Quartus Prime:
  -- Error (10482): VHDL error at file.vhdl(xx): object "maximum" is used but not declared
  -- Error: Quartus Prime Analysis & Elaboration was unsuccessful. 1 error, 2 warnings
  function maximum(constant a, b : integer) return integer;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 1.23
  --
  function trunc(
    constant r : real;
    constant d : natural
  ) return real;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 2.0
  --
  function trunc_ceil(
    constant r : real;
    constant d : natural
  ) return real;


  -- Truncate real value, r, to d decimal places. A simple extention to the IEEE
  -- 'trunc' function:
  --   Truncate X towards 0.0 and returns truncated value.
  --   trunc(X : in real) return real;
  --
  -- Usage:
  --   trunc(1.2345, 2) => 2
  --
  function trunc_ceil(
    constant r : real;
    constant d : natural
  ) return integer;


  -- Integer ceil(x/y), perform ceil() without using a conversion to real.
  -- Ref: https://stackoverflow.com/questions/2745074/fast-ceiling-of-an-integer-division-in-c-c
  --
  -- Usage:
  --   int_ceil_div(16, 10) => 2
  --
  -- Equivalent to int_ceil_div(x, y, 1)
  --
--  function int_ceil_div(
--    constant x : natural;
--    constant y : positive -- Must not divide by zero
--  ) return integer;

  -- Integer round a division up to the nearest integer multiple
  --
  -- Usage:
  --   int_ceil_div(11, 3, 3) => 6 (3.667 rounded up to 6)
  --
  function int_ceil_div(
    constant x : natural;
    constant y : positive;     -- Must not divide by zero
    constant m : positive := 1 -- Must not divide by zero
  ) return integer;

  -- Integer ceil(x/y), perform ceil() without using a conversion to real.
  -- Ref: https://stackoverflow.com/questions/2745074/fast-ceiling-of-an-integer-division-in-c-c
  --
  -- Usage:
  --   int_ceil_div(16 ns, 10 ns) => 2
  --
  -- This is for the benefit of Quartus Prime and its limited VHDL-2008 support
  -- altera translate_off
  function int_ceil_div(constant x, y : time) return integer;
  -- altera translate_on


  -- Return the ceil(log(n, base)), i.e. round up the result of log(n, base).
  --
  -- Example results:
  --
  --   v  base   log_b(v) Return(r)  b^r
  -- ------------------------------------
  --   4  2        2.00      2         4
  --   7  2        2.81      3         8
  --  13  2        3.70      4        16
  --   8  3        1.89      2         9
  --   9  3        2.00      2         9
  --  26  3        2.97      3        27
  --  27  3        3.00      3        27
  --  28  3        3.03      4        81
  --  16  4        2.00      2        16
  --  17  4        2.04      3        64
  --
  function ceil_log(
    constant n    : positive;
    constant base : positive := 2
  ) return positive;


  -- Return the floor(log(n, base)), i.e. round down the result of log(n, base).
  --
  function floor_log(
    constant n    : positive;
    constant base : positive := 2
  ) return natural;


  -- Return the ceil(root'th root of n), i.e. round up the result of taking the root.
  -- This overloaded version only allows positive integer roots.
  --
  --   n  root  ans  Return(r)  r^b
  -- ------------------------------
  --   4    2  2.00      2        4
  --   8    3  2.00      2        8
  --  26    3  2.96      3       27
  --  27    3  3.00      3       27
  --  28    3  3.04      4       64
  --  40    3  3.42      4       64
  --  40    4  2.51      3       81
  --  40    5  2.09      3      243
  --  40    6  1.85      2       64
  --  80    5  2.40      3      243
  --
  function ceil_root(
    constant n    : positive;
    constant root : positive := 2
  ) return positive;


  -- Return the ceil(root'th root of n), i.e. round up the result of taking the root.
  -- This overloaded version allows for real roots.
  --
  function ceil_root(
    constant n    : positive;
    constant root : real := 2.0
  ) return positive;

end package;


library ieee;
  use ieee.math_real.all;

package body math_pkg is

  function minimum(constant a, b : positive) return positive is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;


  function maximum(constant a, b : integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;


  function trunc(
    constant r : real;
    constant d : natural
  ) return real is
    constant exp : real := (1.0 * 10.0**d);
  begin
--    report "trunc(" & real'image(r) & ", " & integer'image(d) & ") = " & real'image(trunc(r * exp));
    return trunc(r * exp) / exp;
  end function;


  -- Truncate real value, r, to d decimal places then round up to nearest integer.
  function trunc_ceil(
    constant r : real;
    constant d : natural
  ) return real is
    constant exp : real := (1.0 * 10.0**d);
  begin
    return ceil(trunc(r * exp) / exp);
  end function;


  -- Truncate real value, r, to d decimal places then round up to nearest integer.
  function trunc_ceil(
    constant r : real;
    constant d : natural
  ) return integer is
    constant exp : real := (1.0 * 10.0**d);
  begin
    return integer(ceil(trunc(r * exp) / exp));
  end function;


  -- Integer ceil(x/y)
  -- Equivalent to int_ceil_div(x, y, 1)
--  function int_ceil_div(
--    constant x : natural;
--    constant y : positive -- Must not divide by zero
--  ) return integer is
--  begin
--    -- (x + y - 1) / y, but to avoid overflow in x+y use:
--    return 1 + ((x - 1) / y);
--  end function;

  function int_ceil_div(
    constant x : natural;
    constant y : positive;     -- Must not divide by zero
    constant m : positive := 1 -- Must not divide by zero
  ) return integer is
  begin
    -- 
    return m + (((x - 1) / (y * m)) * m);
  end function;

  -- altera translate_off
  function int_ceil_div(constant x, y : time) return integer is
  begin
    -- (x + y - 1 fs) / y, but to avoid overflow in x+y use:
    return 1 + ((x - std.env.resolution_limit) / y);
  end function;
  -- altera translate_on

  -- https://stackoverflow.com/questions/44717034/function-clogb2-generated-by-vivado-cant-synthesize-with-loop-limit-error
  function ceil_log(
    constant n    : positive;
    constant base : positive := 2
  ) return natural is
  begin
    return natural(ceil(log(real(n), real(base))));
  end function;


  function floor_log(
    constant n    : positive;
    constant base : positive := 2
  ) return natural is
  begin
    return natural(floor(log(real(n), real(base))));
  end function;


  function ceil_root(
    constant n    : positive;
    constant root : positive := 2
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/real(root))));
  end function;

  function ceil_root(
    constant n    : positive;
    constant root : real := 2.0
  ) return positive is
  begin
    return positive(ceil(n ** (1.0/root)));
  end function;

end package body;
