library ieee;
use ieee.numeric_std.all;

package adder_tree_pkg is

  -- Defaults to "to" range
  type input_arr_t is array (natural range <>) of signed;

  function minimum(a, b : positive) return positive;

  -- Made public as it can be used to configure the pipelined adder tree depth.
  -- E.g.
  --   adder_tree_pipe_i : entity work.adder_tree_pipe
  --     generic map (
  --       depth_g       => ceil_log(coeffs'length, 2),
  --       num_coeffs_g  => coeffs'length,
  --       input_width_g => mult_arr(0)'length
  --     )...
  --
  -- log to base b of v
  --
  -- Example results:
  --
  --   v  b   log_b(v) Return(r)  b^r
  -- ---------------------------------
  --   4  2     2.00      2         4
  --   7  2     2.81      3         8
  --  13  2     3.70      4        16
  --   8  3     1.89      2         9
  --   9  3     2.00      2         9
  --  26  3     2.97      3        27
  --  27  3     3.00      3        27
  --  28  3     3.03      4        81
  --  16  4     2.00      2        16
  --  17  4     2.04      3        64
  --
  function ceil_log(
    constant v : positive;
    constant b : positive
  ) return natural;

  -- Made public as it can be used to verify construction in the test bench.
  --
  -- bth root of v
  --
  -- Example results:
  --
  --   v  b   root  Return(r)  r^b
  -- ------------------------------
  --   4  2   2.00     2         4
  --   8  3   2.00     2         8
  --  26  3   2.96     3        27
  --  27  3   3.00     3        27
  --  28  3   3.04     4        64
  --  40  3   3.42     4        64
  --  40  4   2.51     3        81
  --  40  5   2.09     3       243
  --  40  6   1.85     2        64
  --  80  5   2.40     3       243
  --
  function ceil_root(
    constant v : positive;
    constant b : positive
  ) return positive;

  -- The amount to divide and recurse on now for a minimum depth of logic between registers.
  --
  -- Parameters:
  --  * num_coeffs - The number of coefficients left to service.
  --  * depth      - The pipeline depth left in which to service the ocefficients.
  --
  -- The basic calculation provides a macro value for the remaining amount of work over all depths.
  -- Then a test is done to see if doing less work now does not increase the adder depth later. If
  -- not, do less now and ensure the tree is bottom heavy for the purposes of minimising logic
  -- utilisation.
  function recurse_divide(
    constant num_coeffs : positive;
    constant depth      : positive
  ) return positive;

  function first_adder_coeffs(
    constant num_coeffs : positive
  ) return positive;

  function output_bits(
    constant input_width : positive;
    constant num_coeffs  : positive
  ) return positive;

  function to_input_arr_t (
    i : integer_vector;
    w : positive
  ) return input_arr_t;

  function reverse(i : input_arr_t) return input_arr_t;

  function calc_sum_width(
    c           : input_arr_t;
    input_width : positive
  ) return integer_vector;

end package;


library ieee;
use ieee.math_real.all;

package body adder_tree_pkg is

  -- Not been implemented for 'positive' in some tools! Where it has been implemented, the function's
  -- presence causes ambiguity. Helpful...
  --
  -- Quartus Prime:
  -- Error (10482): VHDL error at comparator.vhdl(85): object "minimum" is used but not declared
  -- Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
  --
  -- ModelSim: ** Error: A:/Philip/Work/VHDL/Comparator/comparator.vhdl(89): Subprogram "minimum" is ambiguous.
  --
  function minimum(a, b : positive) return positive is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;

  function ceil_log(
    constant v : positive;
    constant b : positive
  ) return natural is
  begin
    return natural(ceil(log(real(v), real(b))));
  end function;

  function ceil_root(
    constant v : positive;
    constant b : positive
  ) return positive is
    variable ret : positive := 1;
  begin
    while ret**b < v loop
      ret := ret + 1;
    end loop;
    return ret; -- ceil(v**(1/b))
  end function;

  function recurse_divide(
    constant num_coeffs : positive;
    constant depth      : positive
  ) return positive is
    -- Warning (10542): VHDL Variable Declaration warning at adder_tree_pkg.vhdl(145): used initial value expression
    -- for variable "divide" because variable was never assigned a value
    -- Variable assignment moved below to solve this Quartus Prime warning.
    variable divide : positive; -- := ceil_root(num_coeffs, depth);
    variable ncl    : positive;
  begin
    divide := ceil_root(num_coeffs, depth);
    if depth > 1 then
      -- Try to divide by less the 'divide'
      for i in 1 to divide-1 loop
        -- Divide by 'i' now and do the remainder 'ncl' in 'depth-1' levels.
        ncl := positive(ceil(real(num_coeffs) / real(i)));
        if ceil_root(ncl, depth-1) = divide then
          -- Trial division found a better answer
          return i;
        end if;
      end loop;
      -- No better answer
      return divide;
    else
      -- No depth left to play with, must divide.
      return divide;
    end if;
  end function;

  -- Use ceil not floor otherwise not all bits will get used
  function first_adder_coeffs(
    constant num_coeffs : positive
  ) return positive is
  begin
    return positive(ceil(real(num_coeffs) / 2.0));
  end function;

  function output_bits(
    constant input_width : positive;
    constant num_coeffs  : positive
  ) return positive is
  begin
    return input_width + ceil_log(num_coeffs, 2);
  end function;

  function to_input_arr_t (
    i : integer_vector;
    w : positive
  ) return input_arr_t is
    variable ret : input_arr_t(i'range)(w-1 downto 0);
  begin
    for j in i'range loop
      ret(j) := to_signed(i(j), w);
    end loop;
    return ret;
  end function;

  function reverse(i : input_arr_t) return input_arr_t is
    variable ret : input_arr_t(i'range)(i(0)'range);
  begin
    for j in i'range loop
      ret(j) := i(i'high - j);
    end loop;
    return ret;
  end reverse;

  function calc_sum_width(
    c           : input_arr_t;
    input_width : positive
  ) return integer_vector is
    variable ret : integer_vector(c'range);
  begin
    for i in c'range loop
      ret(i) := output_bits(input_width + c(0)'length, c'length-i);
    end loop;
    return ret;
  end function;

end package body;
