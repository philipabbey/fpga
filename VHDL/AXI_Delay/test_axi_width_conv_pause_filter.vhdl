-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the data width conversion with pause and filter mechanism for an AXI Data
-- Stream.
--
-- P A Abbey, 25 February 2023
--
-------------------------------------------------------------------------------------

entity test_axi_width_conv_pause_filter is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_width_conv_pause_filter is

  constant max_loops_c : positive := 512;

  signal clk           : std_logic;
  signal s_axi_data    : std_logic_vector(15 downto 0) := (others => '0');
  signal s_axi_byte_en : std_logic_vector( 1 downto 0) := "00";
  signal s_axi_valid   : std_logic                     := '0';
  signal s_axi_ready   : std_logic                     := '0';
  signal enable        : std_logic                     := '1';
  signal m_axi_data    : std_logic_vector( 7 downto 0) := (others => '0');
  signal m_axi_valid   : std_logic                     := '0';
  signal m_axi_ready   : std_logic                     := '0';

begin

  clkgen : clock(clk, 10 ns);


  axi_delay_i : entity work.axi_width_conv_pause_filter
    port map (
      clk           => clk,
      s_axi_data    => s_axi_data,
      s_axi_byte_en => s_axi_byte_en,
      s_axi_valid   => s_axi_valid,
      s_axi_ready   => s_axi_ready,
      enable        => enable,
      m_axi_data    => m_axi_data,
      m_axi_valid   => m_axi_valid,
      m_axi_ready   => m_axi_ready
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
    variable i  : natural := 1;
    variable be : std_logic_vector(1 downto 0);
  begin
    s_axi_data  <= (others => '0');
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    while i <= max_loops_c loop
      s_axi_valid <= '0';
      wait_rndr_ticks(clk, 0.25);
      s_axi_valid <= '1';
      be := random_vector(s_axi_byte_en'length);

      case to_bitvector(be) is

        when "00" =>
          s_axi_data <= x"0000";

        when "01" =>
          s_axi_data <= x"00" & std_logic_vector(to_unsigned(i mod 256, m_axi_data'length));
          i := i + 1;

        when "10" =>
          s_axi_data <= std_logic_vector(to_unsigned(i mod 256, m_axi_data'length)) & x"00";
          i := i + 1;

        when "11" =>
          s_axi_data <= std_logic_vector(to_unsigned((i+1) mod 256, m_axi_data'length) & to_unsigned(i mod 256, m_axi_data'length));
          i := i + 2;

      end case;

      s_axi_byte_en <= be;
      wait_nf_ticks(clk, 1);
--      wait_until(s_axi_ready, '1');
      loop
        if s_axi_ready = '1' then
          exit;
        end if;
        wait_nf_ticks(clk, 1);
      end loop;
      wait_nr_ticks(clk, 1);

    end loop;
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);

    wait;
  end process;


  sink : process
    variable i            : natural := 1;
    variable tests_passed : boolean := true;
    variable od           : natural;
  begin
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 10);

    while i <= max_loops_c loop
      m_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      wait_until(m_axi_valid, '1');
      od := to_integer(unsigned(m_axi_data));
      if od /= (i mod 256) then
        report "Incorrect data read, expected: 0x" & to_hstring(to_unsigned(i mod 256, 8)) &
               " (" & to_string(i mod 256) & ") got: 0x" &
               to_hstring(unsigned(m_axi_data)) &
               " (" & to_string(od) & ")";
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
