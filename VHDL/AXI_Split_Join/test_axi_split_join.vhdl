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

entity test_axi_split_join is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_split_join is

  constant data_width_c  : positive := 16;
  constant max_loops_c   : positive := 128;

  signal clk               : std_logic;
  signal s_axi_data        : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal s_axi_valid       : std_logic                                   := '0';
  signal s_axi_ready       : std_logic                                   := '0';
  signal asad1_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal asad1_axi_valid   : std_logic                                   := '0';
  signal asad1_axi_ready   : std_logic                                   := '0';
  signal asad2_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal asad2_axi_valid   : std_logic                                   := '0';
  signal asad2_axi_ready   : std_logic                                   := '0';
  signal adaj1_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal adaj1_axi_valid   : std_logic                                   := '0';
  signal adaj_axi_ready    : std_logic                                   := '0';
  signal adaj2_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal adaj2_axi_valid   : std_logic                                   := '0';
  signal m_axi_data        : std_logic_vector(2*data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid       : std_logic                                   := '0';
  signal m_axi_ready       : std_logic                                   := '0';
  signal backpressure_src  : std_logic;
  signal backpressure_sink : std_logic;

begin

  clkgen : clock(clk, 10 ns);

  backpressure_src <= s_axi_valid and not s_axi_ready after 1 ps;

  axi_split_i : entity work.axi_split
    generic map (
      data_width_g => data_width_c
    )
    port map (
      s_axi_data   => s_axi_data,
      s_axi_valid  => s_axi_valid,
      s_axi_ready  => s_axi_ready,
      m1_axi_data  => asad1_axi_data,
      m1_axi_valid => asad1_axi_valid,
      m1_axi_ready => asad1_axi_ready,
      m2_axi_data  => asad2_axi_data,
      m2_axi_valid => asad2_axi_valid,
      m2_axi_ready => asad2_axi_ready
    );


  axi_delay1 : entity work.axi_delay(simple)
    generic map (
      delay_g      => 20,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => asad1_axi_data,
      s_axi_valid => asad1_axi_valid,
      s_axi_ready => asad1_axi_ready,
      m_axi_data  => adaj1_axi_data,
      m_axi_valid => adaj1_axi_valid,
      m_axi_ready => adaj_axi_ready
    );


  axi_delay2 : entity work.axi_delay(itdev)
    generic map (
      delay_g      => 19,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => asad2_axi_data,
      s_axi_valid => asad2_axi_valid,
      s_axi_ready => asad2_axi_ready,
      m_axi_data  => adaj2_axi_data,
      m_axi_valid => adaj2_axi_valid,
      m_axi_ready => adaj_axi_ready
    );


  axi_join_i : entity work.axi_join
    generic map (
      data_width_g => data_width_c
    )
    port map (
      clk          => clk,
      s1_axi_data  => adaj1_axi_data,
      s1_axi_valid => adaj1_axi_valid,
      s_axi_ready  => adaj_axi_ready,
      s2_axi_data  => adaj2_axi_data,
      s2_axi_valid => adaj2_axi_valid,
      m_axi_data   => m_axi_data,
      m_axi_valid  => m_axi_valid,
      m_axi_ready  => m_axi_ready
    );

  backpressure_sink <= m_axi_valid and not m_axi_ready after 1 ps;

  source : process
    variable i : natural := 1;
  begin
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
      wait_until(m_axi_valid, '1');
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
