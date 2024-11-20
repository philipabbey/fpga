-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- The package required for efficient construction of the recursive adder tree.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.numeric_std.all;
library local;
  use local.rtl_pkg.signed_arr_t;

package adder_tree_pkg is

  -- The amount to divide and recurse on now for a minimum depth of logic between registers.
  --
  -- Parameters:
  --  * num_operands - The number of coefficients left to service.
  --  * depth      - The pipeline depth left in which to service the ocefficients.
  --
  -- The basic calculation provides a macro value for the remaining amount of work over all depths.
  -- Then a test is done to see if doing less work now does not increase the adder depth later. If
  -- not, do less now and ensure the tree is bottom heavy for the purposes of minimising logic
  -- utilisation.
  --
  function recurse_divide(
    constant num_operands : positive;
    constant depth        : positive
  ) return positive;


  -- Given an adder with a pair of input operands, calculate the number of coefficients to recurse
  -- with on the first input, with the remainder recurse on for the second input. The first half
  -- will be the larger half for an odd number of coefficients.
  function first_adder_operands(
    constant num_operands : positive
  ) return positive;


  function output_bits(
    constant input_width  : positive;
    constant num_operands : positive
  ) return positive;


  function to_signed_arr_t (
    i : integer_vector;
    w : positive
  ) return signed_arr_t;


  function reverse(i : signed_arr_t) return signed_arr_t;


  function calc_sum_width(
    c           : signed_arr_t;
    input_width : positive
  ) return integer_vector;

end package;


library ieee;
  use ieee.math_real.all;

package body adder_tree_pkg is

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
    constant num_operands : positive;
    constant depth        : positive
  ) return positive is
    -- Warning (10542): VHDL Variable Declaration warning at adder_tree_pkg.vhdl(145): used initial value expression
    -- for variable "divide" because variable was never assigned a value
    -- Variable assignment moved below to solve this Quartus Prime warning.
    variable divide : positive; -- := ceil_root(num_operands, depth);
    variable ncl    : positive;
  begin
    divide := ceil_root(num_operands, depth);
    if depth > 1 then
      -- Try to divide by less the 'divide'
      for i in 1 to divide-1 loop
        -- Divide by 'i' now and do the remainder 'ncl' in 'depth-1' levels.
        ncl := positive(ceil(real(num_operands) / real(i)));
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
  function first_adder_operands(
    constant num_operands : positive
  ) return positive is
  begin
    return positive(ceil(real(num_operands) / 2.0));
  end function;


  function output_bits(
    constant input_width  : positive;
    constant num_operands : positive
  ) return positive is
  begin
    return input_width + local.math_pkg.ceil_log(num_operands, 2);
  end function;


  function to_signed_arr_t (
    i : integer_vector;
    w : positive
  ) return signed_arr_t is
    variable ret : signed_arr_t(i'range)(w-1 downto 0);
  begin
    for j in i'range loop
      ret(j) := to_signed(i(j), w);
    end loop;
    return ret;
  end function;


  function reverse(i : signed_arr_t) return signed_arr_t is
    variable ret : signed_arr_t(i'range)(i(0)'range);
  begin
    for j in i'range loop
      ret(j) := i(i'high - j);
    end loop;
    return ret;
  end reverse;


  function calc_sum_width(
    c           : signed_arr_t;
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
