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

package rtl_pkg is

  -- Reverse a vector of bits.
  --
  -- Usage:
  --   reverse("1011") => "1101"
  --
  -- Only needs to be defined for std_ulogic_vector due to the way VHDL-2008 sub-typing works.
--  function reverse(i : std_logic_vector) return std_logic_vector;
  function reverse(i : std_ulogic_vector) return std_ulogic_vector;

end package;


package body rtl_pkg is

--  function reverse(i : std_logic_vector) return std_logic_vector is
--    variable ret : std_logic_vector(i'reverse_range);
--  begin
--    for j in i'range loop
--      ret(j) := i(j);
--    end loop;
--  end function;


  function reverse(i : std_ulogic_vector) return std_ulogic_vector is
    variable ret : std_ulogic_vector(i'reverse_range);
  begin
    for j in i'range loop
      ret(j) := i(j);
    end loop;
    return ret;
  end function;

end package body;
