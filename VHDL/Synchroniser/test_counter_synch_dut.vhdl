-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- This code tests a demonstration of a counter synchroniser solution gleaned from a
-- Doulos training video on clock domain crossings available at
-- https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
--
-- P A Abbey, 1 September 2024
--
-------------------------------------------------------------------------------------

entity test_counter_synch_dut is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_counter_synch_dut is

  constant width_c     : positive := 8;
  constant len_c       : positive := 3;
  -- Prevent runaway while loops
  constant max_loops_c : positive := 7 + len_c;

  signal clk1      : std_logic := '0';
  signal reset1    : std_logic := '1';
  signal clk2      : std_logic := '0';
  signal reset2    : std_logic := '1';
  signal incr_cnt1 : std_logic := '0';
  signal incr_cnt2 : std_logic := '0';
  signal gt12_1    : std_logic;
  signal gt12_2    : std_logic;

  signal cnt1_finished : boolean := false;
  signal cnt2_finished : boolean := false;
  signal tests_passed1 : boolean := true;
  signal tests_passed2 : boolean := true;

begin

  clkgen1 : clock(clk1, 8 ns);
  clkgen2 : clock(clk2, 5 ns, offset => 1 ns);

  counter_synch_dut_i : entity work.counter_synch_dut
    generic map (
      width_g => width_c,
      len_g   => len_c
    )
    port map (
      clk1      => clk1,
      reset1    => reset1,
      clk2      => clk2,
      reset2    => reset2,
      incr_cnt1 => incr_cnt1,
      incr_cnt2 => incr_cnt2,
      gt12_1    => gt12_1,
      gt12_2    => gt12_2
    );


  cd1 : process
    variable num_loops : natural := 0;
  begin
    incr_cnt1 <= '0';
    wait_nr_ticks(clk1, 4);
    reset1 <= '0';
    wait_nr_ticks(clk1, 1);

    incr_cnt1 <= '1';
    num_loops := 0;
    while gt12_1 = '0' loop
      wait_nr_ticks(clk1, 1);
      num_loops := num_loops + 1;
      if num_loops > max_loops_c then
        tests_passed1 <= false;
        exit;
      end if;
    end loop;
    incr_cnt1 <= '0';

    wait_until(gt12_1, '0');
    wait_nr_ticks(clk1, 1);

    incr_cnt1 <= '1';
    num_loops := 0;
    while gt12_1 = '0' loop
      wait_nr_ticks(clk1, 1);
      if num_loops > max_loops_c then
        tests_passed1 <= false;
        exit;
      end if;
    end loop;
    incr_cnt1 <= '0';

    wait_nr_ticks(clk1, 10);
    cnt1_finished <= true;

    wait;
  end process;


  cd2 : process
    variable num_loops : natural := 0;
  begin
    incr_cnt2 <= '0';
    wait_nr_ticks(clk2, 6);
    reset2 <= '0';
    wait_until(gt12_2, '1');
    wait_nr_ticks(clk1, 1);

    incr_cnt2 <= '1';
    num_loops := 0;
    while gt12_2 = '1' loop
      wait_nr_ticks(clk2, 1);
      if num_loops > max_loops_c then
        tests_passed2 <= false;
        exit;
      end if;
    end loop;
    incr_cnt2 <= '0';

    wait_until(gt12_2, '1');
    wait_nr_ticks(clk2, 1);

    incr_cnt2 <= '1';
    num_loops := 0;
    while gt12_2 = '1' loop
      wait_nr_ticks(clk2, 1);
      if num_loops > max_loops_c then
        tests_passed2 <= false;
        exit;
      end if;
    end loop;
    incr_cnt2 <= '0';

    wait_nr_ticks(clk2, 10);
    cnt2_finished <= true;

    wait;
  end process;


  check : process
  begin

    wait until cnt1_finished and cnt2_finished;

    if tests_passed1 and tests_passed2 then
      report "All tests PASSED";
    else
      report "At least one test FAILED";
    end if;

    stop_clocks;
    wait;
  end process;

end architecture;
