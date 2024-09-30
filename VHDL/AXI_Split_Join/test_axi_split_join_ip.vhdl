-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the split and join mechanisms for two parallel AXI Data Stream loads.
--
-- P A Abbey, 30 August 2024
--
-------------------------------------------------------------------------------------

entity test_axi_split_join_ip is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_split_join_ip is

  constant data_width_c : positive := 16;
  constant max_loops_c  : positive := 128;

  signal clk               : std_logic;
  signal resetn            : std_logic := '1';
  signal s_axi_data        : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal s_axi_valid       : std_logic                                   := '0';
  signal s_axi_ready       : std_logic                                   := '0';
  signal m_axi_data        : std_logic_vector(2*data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid       : std_logic                                   := '0';
  signal m_axi_ready       : std_logic                                   := '0';
  signal backpressure_src  : std_logic;
  signal backpressure_sink : std_logic;

begin

  clkgen : clock(clk, 10 ns);

  backpressure_src <= s_axi_valid and not s_axi_ready after 1 ps;

  dut : entity work.axi_split_join_ip
    port map (
      clk         => clk,
      resetn      => resetn,
      s_axi_data  => s_axi_data,
      s_axi_valid => s_axi_valid,
      s_axi_ready => s_axi_ready,
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_ready => m_axi_ready
    );

  backpressure_sink <= m_axi_valid and not m_axi_ready after 1 ps;

  source : process
    variable i : natural := 1;
  begin
    resetn <= '1';
    wait_nr_ticks(clk, 4);
    resetn <= '1';
    wait_nr_ticks(clk, 4);
    s_axi_data  <= (others => '0');
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    while i <= max_loops_c loop
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
    variable tests_passed : boolean := true;
  begin
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 10);

    while i <= max_loops_c loop
      m_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      while m_axi_valid /= '1' loop
        wait_nf_ticks(clk, 1);
      end loop;
      if unsigned(m_axi_data) /= to_unsigned(i, data_width_c) & to_unsigned(i, data_width_c) then
        report "Incorrect data read, expected: " & to_hstring(to_unsigned(i, data_width_c) & to_unsigned(i, data_width_c)) & " got: " & to_hstring(m_axi_data);
        tests_passed := false;
      end if;
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 1);

    if tests_passed then
      report "All tests PASSED";
    else
      report "At least one test FAILED";
    end if;

    stop_clocks;

    wait;
  end process;

end architecture;
