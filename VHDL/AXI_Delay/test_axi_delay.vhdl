-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the two AXI Delay implementations to demonstrate and compare their
-- behaviours. Two configurations are provided for switching between them without
-- altering VHDL code.
--
-- P A Abbey, 26 March 2022
--
-------------------------------------------------------------------------------------

entity test_axi_delay is
end entity;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library local;
use local.testbench_pkg.all;

architecture test of test_axi_delay is

  component axi_delay is
    generic(
      delay_g      : positive;
      data_width_g : positive
    );
    port(
      clk         : in  std_logic;
      s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
      s_axi_valid : in  std_logic;
      s_axi_ready : out std_logic;
      m_axi_data  : out std_logic_vector(data_width_g-1 downto 0);
      m_axi_valid : out std_logic;
      m_axi_ready : in  std_logic
    );
  end component;

  constant delay_c      : positive := 5;
  constant data_width_c : positive := 8;

  signal clk          : std_logic;
  signal s_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal s_axi_valid  : std_logic                                 := '0';
  signal s_axi_ready  : std_logic                                 := '0';
  signal m_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid  : std_logic                                 := '0';
  signal m_axi_ready  : std_logic                                 := '0';

begin

  clkgen : clock(clk, 10 ns);


  axi_delay_i : axi_delay 
    generic map (
      delay_g      => delay_c,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => s_axi_data,
      s_axi_valid => s_axi_valid,
      s_axi_ready => s_axi_ready,
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_ready => m_axi_ready
    );


  source : process
    variable i : natural := 1;
  begin
    s_axi_data  <= (others => '0');
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    while i <= 128 loop
      s_axi_valid <= '0';
      wait_rndr_ticks(clk, 0.25);
      s_axi_valid <= '1';
      s_axi_data  <= std_logic_vector(to_unsigned(i, s_axi_data'length));
      wait_nf_ticks(clk, 1);
      wait_until(s_axi_ready, '1');
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    wait;
  end process;


  sink : process
    variable i            : natural := 1;
    variable meas_delay   : natural;
    variable max_delay    : natural := 0;
    variable tests_passed : boolean := true;
  begin
    m_axi_ready <= '0';
--    wait_nr_ticks(clk, 10);

    while i <= 128 loop
      m_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      wait_until(m_axi_valid, '1');
      if to_integer(unsigned(m_axi_data)) /= i then
        report "Incorrect data read, expected: " & integer'image(i) & " got: " & integer'image(to_integer(unsigned(m_axi_data)));
        tests_passed := false;
      end if;
      meas_delay := to_integer(unsigned(s_axi_data)) - i;
      if (now > 0.2 us) and (meas_delay > max_delay) then
        max_delay := meas_delay;
      end if;
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 1);

    -- Works in the expectation that there will be a run of consecutive valid and ready shifts
    -- so that the maximum difference equals the delay.
    if max_delay /= delay_c then
      report "Delay measured to be " & integer'image(max_delay) & " expected " & integer'image(delay_c);
      tests_passed := false;
    end if;

    if tests_passed then
      report "All tests PASSED";
    else
      report "At least one test FAILED";
    end if;

    stop_clocks;
    wait;
  end process;

end architecture;


configuration simple of test_axi_delay is
  for test
    for axi_delay_i : axi_delay
      use entity work.axi_delay(simple);
    end for;
  end for;
end configuration;


configuration itdev of test_axi_delay is
  for test
    for axi_delay_i : axi_delay
      use entity work.axi_delay(itdev);
    end for;
  end for;
end configuration;
