-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the join mechanism for an AXI Data Stream.
--
-- P A Abbey, 30 August 2024
--
-------------------------------------------------------------------------------------

entity test_axi_join is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_join is

  constant data_width_c : positive := 16;
  constant max_loops_c  : positive := 128;

  signal clk            : std_logic;
  signal s1_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal s1_axi_valid   : std_logic                                   := '0';
  signal s_axi_ready    : std_logic                                   := '0';
  signal s2_axi_data    : std_logic_vector(data_width_c-1 downto 0)   := (others => '0');
  signal s2_axi_valid   : std_logic                                   := '0';
  signal m_axi_data     : std_logic_vector(2*data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid    : std_logic                                   := '0';
  signal m_axi_ready    : std_logic                                   := '0';

begin

  clkgen : clock(clk, 10 ns);


  axi_join_i : entity work.axi_join
    generic map (
      data_width_g => data_width_c
    )
    port map (
      clk          => clk,
      s1_axi_data  => s1_axi_data,
      s1_axi_valid => s1_axi_valid,
      s_axi_ready  => s_axi_ready,
      s2_axi_data  => s2_axi_data,
      s2_axi_valid => s2_axi_valid,
      m_axi_data   => m_axi_data,
      m_axi_valid  => m_axi_valid,
      m_axi_ready  => m_axi_ready
    );


  source1 : process
    variable i : natural := 1;
  begin
    s1_axi_data  <= (others => '0');
    s1_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    while i <= max_loops_c loop
      s1_axi_valid <= '0';
      wait_rndr_ticks(clk, 0.25);
      s1_axi_valid <= '1';
      s1_axi_data  <= std_logic_vector(to_unsigned(i, s1_axi_data'length));
      wait_nf_ticks(clk, 1);
      wait_until(s_axi_ready, '1');
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    s1_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    wait;
  end process;


  source2 : process
    variable i : natural := 1;
  begin
    s2_axi_data  <= (others => '0');
    s2_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    while i <= max_loops_c loop
      s2_axi_valid <= '0';
      wait_rndr_ticks(clk, 0.25);
      s2_axi_valid <= '1';
      s2_axi_data  <= std_logic_vector(to_unsigned(i, s2_axi_data'length));
      wait_nf_ticks(clk, 1);
      wait_until(s_axi_ready, '1');
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    s2_axi_valid <= '0';
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
