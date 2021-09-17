entity test_testbench is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library local;
use local.testbench.all;

architecture behav of test_testbench is

  -- Signal declarations
  signal clk         : std_ulogic := '0';
  signal clk2        : std_ulogic := '0';
  signal reset       : std_ulogic := '0';
  signal enable      : std_ulogic := '0';
  signal data_random : std_ulogic_vector(31 downto 0) := (others => '0');

  type test_cnt_t is array (0 to 2) of natural;
  type test_ratio_t is array (test_cnt_t'range) of real;
  signal test_sig : std_ulogic_vector(test_cnt_t'range);
  constant exp_ratio : test_ratio_t := (0.333, 0.5, 0.75);
  signal test_cnt_low  : test_cnt_t := (others => 0);
  signal test_cnt_high : test_cnt_t := (others => 0);
  signal test_ratio : test_ratio_t := (others => 0.0);
  constant ratio_tolerance : real := 0.05;

begin

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
  
  process
    variable res : line;
  begin
    -- Expect to see 'X's from before the reset
    wait until rising_edge(clk);
    -- Initialise the inputs
    enable <= '0';
    data_random <= (others => '0');
    wait until rising_edge(clk);
    toggle_r(reset, clk, 2);

    wait until rising_edge(clk);
    enable <= '1';
    data_random <= random_vector(data_random'length);
    wait until rising_edge(clk);
    data_random <= random_vector(data_random'length);
    wait until rising_edge(clk);
    data_random <= random_vector(data_random'length);
    
    wait for 70 us;
    swrite(res, "End of simulation at ");
    write(res, now, right, 0, us);
    writeline(OUTPUT, res);
    
    for i in test_ratio'range loop
      swrite(res, "test_sig(");
      write(res, i);
      swrite(res, ") ratio is ");
      write(res, test_ratio(i), right, 0, 2);
      swrite(res, ", expected: ");
      write(res, exp_ratio(i), right, 0, 3);
      if (test_ratio(i) < (exp_ratio(i) * (1.0 + ratio_tolerance))) and
         (test_ratio(i) > (exp_ratio(i) * (1.0 - ratio_tolerance))) then
        swrite(res, " - PASS");
      else
        swrite(res, " - FAIL");
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

    stop_clocks;
    wait;
  end process;
  
end architecture;
