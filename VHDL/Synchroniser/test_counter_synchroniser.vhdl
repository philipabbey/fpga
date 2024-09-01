-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for 'counter_synchroniser' synchroniser solution gleaned from a Doulos
-- training video on clock domain crossings available at
-- https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
--
-- P A Abbey, 31 August 2024
--
-------------------------------------------------------------------------------------

entity test_counter_synchroniser is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_counter_synchroniser is

  constant width_c : positive := 8;
  constant len_c   : positive := 3;

  signal clk_s     : std_logic := '0';
  signal reset_s   : std_logic := '1';
  signal clk_f     : std_logic := '0';
  signal reset_f   : std_logic := '1';
  signal cnt1_s    : std_logic_vector(width_c-1 downto 0);
  signal cnt1_f    : std_logic_vector(width_c-1 downto 0);
  signal cnt2_f    : std_logic_vector(width_c-1 downto 0);
  signal cnt2_s    : std_logic_vector(width_c-1 downto 0);
--  signal all_tests_pass : boolean := true;
  signal finished1 : boolean   := false;
  signal finished2 : boolean   := false;
  signal gt12_s    : boolean;
  signal gt12_f    : boolean;

begin

  clkgen_s : clock(clk_s, 8 ns);
  clkgen_f : clock(clk_f, 5 ns, offset => 1 ns);

  -- Slow to fast
  counter_synchroniser_sf : entity work.counter_synchroniser
    generic map (
      width_g => width_c,
      len_g   => len_c
    )
    port map (
      clk_wr   => clk_s,
      reset_wr => reset_s,
      clk_rd   => clk_f,
      reset_rd => reset_f,
      cnt_wr   => cnt1_s,
      cnt_rd   => cnt1_f
    );

  -- Fast to slow
  counter_synchroniser_fs : entity work.counter_synchroniser
    generic map (
      width_g => width_c,
      len_g   => len_c
    )
    port map (
      clk_wr   => clk_f,
      reset_wr => reset_f,
      clk_rd   => clk_s,
      reset_rd => reset_s,
      cnt_wr   => cnt2_f,
      cnt_rd   => cnt2_s
    );

  -- Slow clock
  cnt_s : process
  begin
    cnt1_s <= (others => '0');
    wait_nr_ticks(clk_s, 6);
    reset_s <= '0';
    wait_nr_ticks(clk_s, 1);

    for i in 0 to 2**width_c-1 loop
      cnt1_s <= to_slv(i, width_c);
      if gt12_s then
        wait_rndr_ticks(clk_s, 1, 49);
      else
        wait_rndr_ticks(clk_s, 1, 46);
      end if;
    end loop;
    wait_nr_ticks(clk_s, 2);
    finished1 <= true;

    wait;
  end process;


  -- Fast clock
  cnt_f : process
  begin
    cnt2_f <= (others => '0');
    wait_nr_ticks(clk_f, 4);
    reset_f <= '0';
    wait_nr_ticks(clk_f, 1);

    for i in 0 to 2**width_c-1 loop
      cnt2_f <= to_slv(i, width_c);
      wait_rndr_ticks(clk_f, 1, 80);
    end loop;
    wait_nr_ticks(clk_f, 2);
    finished2 <= true;

    wait;
  end process;


  -- Is counter 1 greater than counter 2 in each clock domain?
  gt12_s <= (cnt1_s > cnt2_s);
  gt12_f <= (cnt1_f > cnt2_f);


  check : process
  begin

    wait until finished1 and finished2;
    report "All tests completed (not self-checking)";
    stop_clocks;

    wait;
  end process;

end architecture;
