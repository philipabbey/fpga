-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the simple fixed point multipler.
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

entity test_float_mult is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library ieee_proposed;
  use ieee_proposed.float_pkg.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_float_mult is

  signal clk   : std_logic;
  signal reset : std_logic;
  signal a, b  : float(7 downto -8);
  signal o     : float(7 downto -8);

begin

  clock(clk, 10 ns);

  test_sfixed_mult_i : entity work.float_mult
    port map (
      clk   => clk,
      reset => reset,
      a     => a,
      b     => b,
      o     => o
    );

  process
  begin
    reset <= '1';
    a <= to_float(0.0, a);
    b <= to_float(0.0, b'high, -b'low);
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    a <= to_float( 5.1, a'high, -a'low);
    b <= to_float(-2.2, b);
    wait_nr_ticks(clk, 10);
    stop_clocks;

    wait;
  end process;

end architecture;
