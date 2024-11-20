-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Functions frequently used in RTL and test benches.
--
-- P A Abbey, 10 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_complex.all;

package rtl_pkg is

  -- Defaults to "to" range
  type slv_arr_t       is array (integer range <>) of std_logic_vector;
  type unsigned_arr_t  is array (integer range <>) of unsigned;
  type signed_arr_t    is array (integer range <>) of signed;
  -- Choice of names is to suit the official VHDL-2008 integer_vector type
  type natural_vector  is array (integer range <>) of natural;
  type positive_vector is array (integer range <>) of positive;

  -- Reverse a vector of bits.
  --
  -- Usage:
  --   reverse("1011") => "1101"
  --
  -- Only needs to be defined for std_ulogic_vector due to the way VHDL-2008 sub-typing works.
  function reverse(i : std_ulogic_vector) return std_ulogic_vector;

end package;


package body rtl_pkg is

  function reverse(i : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(i'reverse_range);
  begin
    for j in i'range loop
      ret(j) := i(j);
    end loop;
    return ret;
  end function;

end package body;
