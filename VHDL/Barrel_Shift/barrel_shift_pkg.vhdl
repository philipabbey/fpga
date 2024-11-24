-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- The package required for efficient construction of the iterative and recursive
-- barrel shift component.
--
-- P A Abbey, 15 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.rtl_pkg.natural_vector;

package barrel_shift_pkg is

  -- For iterative case.
  -- Create an array of length 'num_clks' providing the indexes of the rotation stage
  -- numbers at which to register an intermediate rotation.
  --
  -- Usage:
  --   register_stages(9,  4) => (6, 4, 2, 0)
  --   register_stages(9, 10) => (9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 0)
  --
  -- "(6, 4, 2, 0)" means for shift(8 downto 0) (of length 9):
  --  * Use shift(8 downto 6) (3 bits) to rotate the input vector and register the-
  --    output from bit 6.
  --  * Then use shift(5 downto 4) (2 bits) for the next clock cycle's rotation.
  --  * Then use shift(3 downto 2) and register.
  --  * Lastly shift(1 downto 0) and register.
  --
  -- Extra trailing '0' indexes means there are no shift bit left to use and the
  -- output is just delay for another clock cycle without further rotation. It
  -- means more clock cycles have been requested than can be made use of.
  --
  function register_stages(
    shift_len : positive;
    num_clks  : positive
  ) return natural_vector;


  -- For recursive case.
  -- The number of shift bits to consume in the next clock cycle stage.
  --
  function num_bits(
    shift_len : natural;
    num_clks  : positive
  ) return natural;


  -- The data bit at which to split and rotate the vector. This is the high numbered
  -- bit of the lower half, i.e. 'n' in (n downto 0).
  --
  function split_high_fn(
    data_len   : positive;
    idx        : natural;
    shift_left : boolean
  ) return natural;


  -- Generate a mask for which bits of the shift input to use in this pipeline stage.
  --
  function mask_gen(shift_bits, top, bot : natural) return std_logic_vector;

end package;


library ieee;
  use ieee.math_real.all;
library local;
  use local.math_pkg.int_ceil_div;

package body barrel_shift_pkg is

  function register_stages(
    shift_len : positive;
    num_clks  : positive
  ) return natural_vector is
    variable ret    : natural_vector(num_clks downto 0) := (others => 0);
    variable remain : natural;
  begin
    -- Required as a way to provide the initial upper bound to a generate loop
    ret(num_clks) := shift_len;
    remain        := shift_len;
    for i in num_clks-1 downto 0 loop
      remain := maximum(0, remain - int_ceil_div(remain, i+1));
      ret(i) := remain;
    end loop;
    return ret;
  end function;


  function num_bits(
    shift_len : natural;
    num_clks  : positive
  ) return natural is
  begin
    if shift_len = 0 then
      -- No more work, just shift
      return 0;
    elsif num_clks >= shift_len then
      return 1;
    else
      return int_ceil_div(shift_len, num_clks);
    end if;
  end function;


  function split_high_fn(
    data_len   : positive;
    idx        : natural;
    shift_left : boolean
  ) return natural is
  begin
    if shift_left then
      return data_len-1-2**idx;
    else
      return 2**idx-1;
    end if;
  end function;


  function mask_gen(shift_bits, top, bot : natural) return std_logic_vector is
    variable ret : std_logic_vector(shift_bits-1 downto 0) := (others => '0');
  begin
    for i in top downto bot loop
      ret(i) := '1';
    end loop;
    return ret;
  end function;

end package body;
