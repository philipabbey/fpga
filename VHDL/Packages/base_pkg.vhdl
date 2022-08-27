-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Experiments on packages post VHDL-2008.
--
-- P A Abbey, 27 August 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package base_pkg is

  -- Vector width
  constant width_c : positive := 8;

  subtype slv_vector_t is std_logic_vector(width_c-1 downto 0);

  -- Bitwise reverse a std_logic_vector
  function reverse (v : slv_vector_t) return slv_vector_t;
end package;


package body base_pkg is

  function reverse (v : slv_vector_t) return slv_vector_t is
    variable ret : slv_vector_t;
  begin
    for i in v'range loop
      ret(i) := v(v'high-i);
    end loop;
    return ret;
  end function;

end package body;
