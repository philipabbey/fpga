-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench to exercise the test bench package 'testbench_pkg'.
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

entity test_testbench is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library std;
  use std.textio.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_testbench is

  type test_cnt_t   is array (0 to 2) of natural;
  type test_ratio_t is array (test_cnt_t'range) of real;

  constant exp_ratio     : test_ratio_t := (0.333, 0.5, 0.75);
  constant r1            : real         := local.math_pkg.trunc_ceil(1.2345, 1);
  constant r2            : integer      := local.math_pkg.trunc_ceil(1.2345, 2);
  constant r3            : real         := local.math_pkg.trunc(1.2345, 3);
  constant terminal_time : time         := 140 us;

  signal clk           : std_ulogic                     := '0';
  signal clk2          : std_ulogic                     := '0';
  signal reset         : std_ulogic                     := '0';
  signal enable        : std_ulogic                     := '0';
  signal data_random   : std_ulogic_vector(31 downto 0) := (others => '0');
  signal int_random    : integer                        := 0;
  signal test_sig      : std_ulogic_vector(test_cnt_t'range);
  signal test_cnt_low  : test_cnt_t                     := (others => 0);
  signal test_cnt_high : test_cnt_t                     := (others => 0);
  signal test_ratio    : test_ratio_t                   := (others => 0.0);
  signal wiggle        : std_ulogic                     := '0';

  shared variable success : bool_t;

begin

  assert r1 = 2.0
    report "r1 is incorrect"
    severity warning;

  assert r2 = 2
    report "r2 is incorrect"
    severity warning;

  assert r3 = 1.234
    report "r3 is incorrect"
    severity warning;

  test : for i in test_ratio_t'range generate
    test_ratio(i) <= real(test_cnt_high(i)) / real(test_cnt_high(i) + test_cnt_low(i)) when (test_cnt_high(i) + test_cnt_low(i)) > 0;
  end generate;

  clock(clk, 5 ns, 5 ns, 70 us);
  clock(clk2, 12 ns, 0.6);

  -- run to 70 us to see test_ratio(i) tend towards these ratios:
  w : for i in test_sig'range generate
    wiggle_r(test_sig(i), clk, exp_ratio(i));
  end generate;

  process(clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        test_cnt_low  <= (others => 0);
        test_cnt_high <= (others => 0);
      else
        for i in test_sig'range loop
          if test_sig(i) = '1' then
            test_cnt_high(i) <= test_cnt_high(i) + 1;
          else
            test_cnt_low(i) <= test_cnt_low(i) + 1;
          end if;
        end loop;
      end if;
    end if;
  end process;


  test1 : process
    constant ratio_tolerance : real := 0.02;
    variable res             : line;
  begin
    -- Expect to see 'X's from before the reset
    wait_nr_ticks(clk, 1);
    -- Initialise the inputs
    enable      <= '0';
    data_random <= (others => '0');
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);

    wait_nr_ticks(clk, 1);
    enable      <= '1';
    data_random <= random_vector(data_random'length);
    wait_nr_ticks(clk, 1);
    data_random <= random_vector(data_random'length);
    wait_nr_ticks(clk, 1);
    data_random <= random_vector(data_random'length);
    wait_nr_ticks(clk, 1);

    int_random <= random_integer(5, 10);
    wait_nr_ticks(clk, 1);
    int_random <= random_integer(-5, 0);
    wait_nr_ticks(clk, 1);
    int_random <= random_integer(-2, 2);
    wait_nr_ticks(clk, 1);

    wait_absolute_time(terminal_time);
    if (now = terminal_time) then
      swrite(res, "Wait until simulation time ");
      write(res, now, right, 0, us);
      swrite(res, " - PASS");
      writeline(OUTPUT, res);
    else
      swrite(res, "Wait until simulation time ");
      write(res, terminal_time, right, 0, us);
      swrite(res, " - FAIL, time is ");
      write(res, now, right, 0, us);
      writeline(OUTPUT, res);
      success.set(false);
    end if;

    for i in test_ratio'range loop
      swrite(res, "Test 1: test_sig(");
      write(res, i);
      swrite(res, ") ratio is ");
      write(res, test_ratio(i), right, 0, 2);
      swrite(res, ", expected: ");
      write(res, exp_ratio(i), right, 0, 2);
      swrite(res, " - ");
      if (test_ratio(i) < (exp_ratio(i) * (1.0 + ratio_tolerance))) and
         (test_ratio(i) > (exp_ratio(i) * (1.0 - ratio_tolerance))) then
        swrite(res, "PASS");
      else
        swrite(res, "FAIL");
        success.set(false);
      end if;
      swrite(res, " (within ");
      write(res, ratio_tolerance * 100.0, right, 0, 1);
      swrite(res, "% tolerance, range: ");
      write(res, (exp_ratio(i) * (1.0 - ratio_tolerance)), right, 0, 3);
      swrite(res, " - ");
      write(res, (exp_ratio(i) * (1.0 + ratio_tolerance)), right, 0, 3);
      swrite(res, ")");
      writeline(OUTPUT, res);
    end loop;

    if success.get then
      swrite(res, "All tests PASSED");
      writeline(OUTPUT, res);
    else
      swrite(res, "At least one test FAILED");
      writeline(OUTPUT, res);
    end if;
    
    stop_clocks;
    wait;
  end process;


  test2 : process
    -- Configure Test
    constant num_loops : positive := 200;
    constant min_wait  : natural  := 2;
    constant max_wait  : natural  := 8;
    constant exp_mean  : real     := ((real(max_wait - min_wait)) / 2.0) + real(min_wait);
    constant tolerance : real     := 0.01;

    variable start     : time;
    variable wt        : natural;
    variable min       : natural := integer'high;
    variable max       : natural := 0;
    variable sum       : natural := 0;
    variable mean      : real;
    variable res       : line;
  begin
    wait_nr_ticks(clk, 10);
    for i in 1 to num_loops loop
      start := now;
      wait_rndr_ticks(clk, min_wait, max_wait);
      wt := (now - start) / 10 ns; -- clk period
      if wt > max then
        max := wt;
      end if;
      if wt < min then
        min := wt;
      end if;
      sum := sum + wt;
    end loop;

    swrite(res, "Test 2: Maximum clock cycles is ");
    write(res, max);
    swrite(res, ", expected: ");
    write(res, max_wait);
    swrite(res, " - ");
    if max = max_wait then
      swrite(res, "PASS");
    else
      swrite(res, "FAIL");
      success.set(false);
    end if;
    writeline(OUTPUT, res);

    swrite(res, "Test 2: Minimum clock cycles is ");
    write(res, min);
    swrite(res, ", expected: ");
    write(res, min_wait);
    swrite(res, " - ");
    if min = min_wait then
      swrite(res, "PASS");
    else
      swrite(res, "FAIL");
      success.set(false);
    end if;
    writeline(OUTPUT, res);

    mean := real(sum) / real(num_loops);
    swrite(res, "Test 2: Average clock cycles is ");
    write(res, mean, right, 0, 2);
    swrite(res, ", expected: ");
    write(res, exp_mean, right, 0, 2);
    swrite(res, " - ");
    if (mean > exp_mean * (1.0 - tolerance)) and
       (mean < exp_mean * (1.0 + tolerance)) then
      swrite(res, "PASS");
    else
      swrite(res, "FAIL");
    end if;
    swrite(res, " (within ");
    write(res, tolerance * 100.0, right, 0, 1);
    swrite(res, "% tolerance, range: ");
    write(res, exp_mean * (1.0 - tolerance), right, 0, 3);
    swrite(res, " - ");
    write(res, exp_mean * (1.0 + tolerance), right, 0, 3);
    swrite(res, ")");
    writeline(OUTPUT, res);

    wait;
  end process;


  test3 : process
    -- Configure Test
    constant num_loops : positive := 2000;
    constant exp_mean  : real     := 0.1;
    constant tolerance : real     := 0.05;

    variable start     : time;
    variable wt        : natural;
    variable sum       : natural := 0;
    variable mean      : real;
    variable res       : line;
  begin
    wiggle <= '1';
    wait_nr_ticks(clk, 10);
    wiggle <= '0';
    for i in 1 to num_loops loop
      start := now;
      wiggle <= '1';
      wait_rndr_ticks(clk, exp_mean);
      wt := (now - start) / 10 ns; -- clk period
      sum := sum + wt;
      wiggle <= '0';
      wait_nr_ticks(clk, 1);
    end loop;

    mean := real(sum) / real(num_loops);
    swrite(res, "Test 3: Average clock cycles is ");
    write(res, mean, right, 0, 2);
    swrite(res, ", expected: ");
    write(res, exp_mean, right, 0, 2);
    swrite(res, " - ");
    if (mean > exp_mean * (1.0 - tolerance)) and
       (mean < exp_mean * (1.0 + tolerance)) then
      swrite(res, "PASS");
    else
      swrite(res, "FAIL");
      success.set(false);
    end if;
    swrite(res, " (within ");
    write(res, tolerance * 100.0, right, 0, 1);
    swrite(res, "% tolerance, range: ");
    write(res, exp_mean * (1.0 - tolerance), right, 0, 3);
    swrite(res, " - ");
    write(res, exp_mean * (1.0 + tolerance), right, 0, 3);
    swrite(res, ")");
    writeline(OUTPUT, res);

    wait;
  end process;

end architecture;
