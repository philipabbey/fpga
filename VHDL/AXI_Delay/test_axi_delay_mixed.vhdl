-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the A pause mechanism for an AXI Data Stream.
--
-- References:
--  * Explanation here: https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 1 April 2022
--
-------------------------------------------------------------------------------------

entity test_axi_delay_mixed is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_delay_mixed is

  constant delay_vector_c : std_logic_vector := "101010101"; -- "000" Gives a well bahaved FIXED delay. Start pipelining with some '1's and the fixed delay fails.
  constant delay_c        : positive         := delay_vector_c'length;
  constant data_width_c   : positive         := 16;
  constant max_cnt_c      : positive         := 256;

  signal clk          : std_logic;
  signal s_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal s_axi_valid  : std_logic := '0';
  signal s_axi_ready  : std_logic := '0';
  signal m_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid  : std_logic := '0';
  signal m_axi_ready  : std_logic := '0';

begin

  clkgen : clock(clk, 10 ns);


  axi_delay_i : entity work.axi_delay_mixed
    generic map (
      delay_vector_g => delay_vector_c,
      data_width_g   => data_width_c
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

    while i <= max_cnt_c loop
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
    wait_nr_ticks(clk, 8+delay_c);

    report "Constantly valid" severity note;
    i := 1;

    while i <= 2 * delay_c loop
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
    wait_nr_ticks(clk, 10);

    while i <= max_cnt_c loop
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
    wait_nr_ticks(clk, delay_c);

    report "Constantly ready" severity note;
    i := 1;

    while i <= 2 * delay_c loop
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
    if max_delay > delay_c then
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
