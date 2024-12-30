-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Testbench for the Low Speed Serial IO Interface testing
--
-- References:
--  * https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
--  * https://digilent.com/reference/programmable-logic/zybo-z7/start
--  * https://www.01signal.com/electronics/source-synchronous-inputs/
--
-- P A Abbey, 18 December 2024
--
-------------------------------------------------------------------------------------

entity test_zybo_z7_10 is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library std;
library local;
  use local.testbench_pkg.all;

architecture test_rtl of test_zybo_z7_10 is

  signal clk              : std_logic                    := '0';
  signal dut_clk          : std_logic                    := '0';
  signal sw               : std_logic_vector(3 downto 0) := "0000";
  signal btn              : std_logic_vector(3 downto 0) := "0000";
  signal leds             : std_logic_vector(3 downto 0) := "0000";
  signal clk_data         : std_logic                    := '0';
  signal clk_data_delayed : std_logic                    := '0';
  signal data             : std_logic_vector(2 downto 0) := "000";
  signal data_delayed     : std_logic_vector(2 downto 0) := "000";
  signal all_test_pass    : boolean                      := true;

begin

  clkgen : clock(clk, 8 ns);
  dut_clk <= << signal dut.clk : std_logic >>;

  dut : entity work.zybo_z7_10
    port map (
      clk_port => clk,
      sw       => sw,
      btn      => btn,
      led      => leds,
      clk_tx   => clk_data,         -- Transmission
      tx       => data,             -- Transmission
      clk_rx   => clk_data_delayed, -- Transmission
      rx       => data_delayed      -- Transmission
    );

  clk_data_delayed <= transport clk_data after 2 ns;
  data_delayed     <= transport data     after 6 ns;


  process
  begin
    sw  <= "0000";
    btn <= "0000";
    wait_nr_ticks(clk, 10);

    wait until << signal dut.reset_rx : std_logic >> = '0';
    wait_nr_ticks(clk, 100);
    btn <= "1000";
    wait_nr_ticks(clk, 400);
    btn <= "1100";
    wait_nr_ticks(clk, 400);
    btn <= "1010";
    wait_nr_ticks(clk, 400);
    btn <= "1001";
    wait_nr_ticks(clk, 400);
    btn <= "1111";
    wait_nr_ticks(clk, 400);
    btn <= "1000";
    wait_nr_ticks(clk, 400);
    btn <= "0000";
    wait_nr_ticks(clk, 400);
    btn <= "1000";
    wait_nr_ticks(clk, 100);
    btn <= "0000";

    wait_nr_ticks(clk, 100);
    --stop_clocks;
    -- PLL IP Core won't stop creating events, must use 'stop' instead of 'stop_clocks'.
    if all_test_pass then
      report "All tests PASSED" severity note;
    else
      report "Some tests FAILED" severity error;
    end if;
    std.env.stop;
    wait;
  end process;

  process(dut_clk)
  begin
    if falling_edge(dut_clk) then
      if leds(2) = '1' and leds(0) = '0' then
        report "PRBS Check error" severity error;
        all_test_pass <= false;
      end if;
    end if;
  end process;

end architecture;


library ieee;
  use ieee.std_logic_1164.all;
library std;
library local;
  use local.testbench_pkg.all;

architecture test_idelay of test_zybo_z7_10 is

  signal clk              : std_logic                    := '0';
  signal sw               : std_logic_vector(3 downto 0) := "0000";
  signal btn              : std_logic_vector(3 downto 0) := "0000";
  signal leds             : std_logic_vector(3 downto 0) := "0000";
  signal clk_data         : std_logic                    := '0';
  signal clk_data_delayed : std_logic                    := '0';
  signal dut_clk          : std_logic                    := '0';
  signal data             : std_logic_vector(2 downto 0) := "000";
  signal data_delayed     : std_logic_vector(2 downto 0) := "000";
  signal all_test_pass    : boolean                      := true;
  signal rx_shifted       : std_logic_vector(2 downto 0);
  signal cnt_reg          : std_logic_vector(0 to 7)     := (others => '0');

begin

  clkgen : clock(clk, 8 ns);
  dut_clk <= << signal dut.clk : std_logic >>;

  dut : entity work.zybo_z7_10
    port map (
      clk_port => clk,
      sw       => sw,
      btn      => btn,
      led      => leds,
      clk_tx   => clk_data,         -- Transmission
      tx       => data,             -- Transmission
      clk_rx   => clk_data_delayed, -- Transmission
      rx       => data_delayed      -- Transmission
    );

  clk_data_delayed <= transport clk_data after 4.0 ns;
  data_delayed(0)  <= transport data(0)  after 4.0 ns + 2.0 ns + random_integer(0, 2) * 0.5 ns;
  data_delayed(1)  <= transport data(1)  after 4.0 ns + 3.0 ns + random_integer(0, 1) * 0.5 ns;
  data_delayed(2)  <= transport data(2)  after 4.0 ns + 3.5 ns + random_integer(0, 2) * 0.5 ns;


  process
  begin
    sw  <= "0000";
    btn <= "0000";
    wait_nr_ticks(clk, 10);

    wait until << signal dut.reset_rx : std_logic >> = '0';
    wait_nr_ticks(clk, 100);
    btn <= "1000";
    wait_nr_ticks(clk, 16000);
    btn <= "0000";

    wait_nr_ticks(clk, 100);
    --stop_clocks;
    -- PLL IP Core won't stop creating events, must use 'stop' instead of 'stop_clocks'.
    if all_test_pass then
      report "All tests PASSED" severity note;
    else
      report "Some tests FAILED" severity error;
    end if;
    std.env.stop;
    wait;
  end process;

  process(dut_clk)
  begin
    if rising_edge(dut_clk) then
      cnt_reg <= << signal dut.counting_d : std_logic >> & cnt_reg(0 to cnt_reg'high-1);
    end if;
  end process;

  -- Delay the checking until after the training period, then wait a few clock cycles for data
  -- on the chosen to idelay to filter through the FIFO.
  process(dut_clk)
  begin
    if falling_edge(dut_clk) then
      if cnt_reg(cnt_reg'high) = '0' and leds(2) = '1' and leds(0) = '0' then
        report "PRBS Check error" severity error;
        all_test_pass <= false;
      end if;
    end if;
  end process;

  rx_shifted <= << signal dut.rx : std_logic_vector(2 downto 0) >> XOR << signal dut.rx_f1 : std_logic_vector(2 downto 0) >>;

end architecture;
