-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the A pause mechanism for an AXI Data Stream.
--
-- P A Abbey, 1 April 2022
--
-------------------------------------------------------------------------------------

entity test_axi_pause is
end entity;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library local;
use local.testbench_pkg.all;

architecture test of test_axi_pause is

  constant data_width_c : positive := 16;

  signal clk          : std_logic;
  signal s_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal s_axi_valid  : std_logic                                 := '0';
  signal s_axi_ready  : std_logic                                 := '0';
  signal enable       : std_logic                                 := '1';
  signal m_axi_data   : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid  : std_logic                                 := '0';
  signal m_axi_ready  : std_logic                                 := '0';

begin

  clkgen : clock(clk, 10 ns);


  axi_delay_i : entity work.axi_pause 
    generic map (
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => s_axi_data,
      s_axi_valid => s_axi_valid,
      s_axi_ready => s_axi_ready,
      enable      => enable,
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_ready => m_axi_ready
    );


  pause : process
    constant interval_c : time := 200 ns;
  begin
    enable <= '1';

    while true loop
      wait for interval_c;
      wait_nr_ticks(clk, 1);
      enable <= not enable;
    end loop;

    wait;
  end process;

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
    variable tests_passed : boolean := true;
  begin
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 10);

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
