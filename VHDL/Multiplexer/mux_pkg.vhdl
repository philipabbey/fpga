-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- The package required for efficient construction of the recursive multiplexer.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.rtl_pkg.natural_vector;

package mux_pkg is

  -- Create an array of length 'num_clks' providing the lower indexes of the selection ('sel') vector
  -- such that sel'high downto this index should be delayed by a clock cycle.
  --
  -- Usage:
  --   register_stages(3, 3) => (2, 1)
  -- If num_clks > sel_len we must not delay 'sel' any more than 'sel_len'.
  --   register_stages(3, 4) => (2, 1)
  --
  -- "(2, 1)" means for sel(2 downto 0) (of length 3):
  --  * delay sel(2 downto 2) (1 bit), then
  --  * delay sel(2 downto 1) (2 bits)
  --
  -- The aim is to construct a triangular delay chain like this:
  --
  --             +---+     +---+
  --  sel_in(2)--|D Q|-----|D Q|--sel_out(2)
  --             |>  |     |>  |
  --             +---+     +---+
  --
  --                       +---+
  --  sel_in(1)------------|D Q|--sel_out(1)
  --                       |>  |
  --                       +---+
  --
  --  sel_in(0)-------------------sel_out(0)
  --
  function register_stages(
    sel_len  : positive;
    num_clks : positive
  ) return natural_vector;


  -- The number of selection bits to consume in the next clock cycle stage.
  --
  function num_bits(
    sel_len  : natural;
    num_clks : positive
  ) return natural;

end package;


library ieee;
  use ieee.math_real.all;
library local;
  use local.math_pkg.int_ceil_div;
  -- This is for the benefit of Quartus Prime and its limited VHDL-2008 support.
  use local.math_pkg.maximum;
  use local.math_pkg.minimum;

package body mux_pkg is

  function register_stages(
    sel_len  : positive;
    num_clks : positive
  ) return natural_vector is
    -- If num_clks > sel_len we must not delay 'sel' any more than 'sel_len'.
    variable ret    : natural_vector(minimum(sel_len, num_clks)-1 downto 1) := (others => 0);
    variable remain : natural;
  begin
    remain := sel_len;
    for i in ret'range loop
        remain := maximum(0, remain - num_bits(remain, i+1));
        ret(i) := remain;
    end loop;
    return ret;
  end function;


  function num_bits(
    sel_len  : natural;
    num_clks : positive
  ) return natural is
  begin
    if num_clks > sel_len then
      return 0;
    else
      return local.math_pkg.int_ceil_div(sel_len, num_clks);
    end if;
  end function;

end package body;
