-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench to drive the time display.
--
-- P A Abbey, 18 September 2020
--
-------------------------------------------------------------------------------------

entity test_time_display is
end entity;

library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture rtl of test_time_display is

  signal clk   : std_logic := '0';
  signal digit : work.sevseg_pkg.digits_t;
  signal disp  : work.sevseg_pkg.time_disp_t;
  signal am    : std_logic := '0';
  signal pm    : std_logic := '0';
  signal alarm : std_logic := '0';

begin

  clkgen : clock(clk, 10 ns);

  comp_time_display : entity work.time_display
    port map (
      digit => digit,
      disp  => disp
    );

  process
  begin
    digit           <= (0, 1, 2, 3);
    (am, alarm, pm) <= std_logic_vector'("100");
    wait_nr_ticks(clk, 1);

    for i in 0 to 15 loop
      digit <= (
        (digit(0)+1) mod 16,
        (digit(1)+1) mod 16,
        (digit(2)+1) mod 16,
        (digit(3)+1) mod 16
      );
      (am, alarm, pm) <= std_logic_vector'(pm, am, alarm);
      wait_nr_ticks(clk, 1);
    end loop;

    stop_clocks;
    wait;
  end process;

end architecture;
