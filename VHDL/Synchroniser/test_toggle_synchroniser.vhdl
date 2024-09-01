-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for 'toggle_synchroniser' synchroniser solution gleaned from a Doulos
-- training video on clock domain crossings available at
-- https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
--
-- P A Abbey, 31 August 2024
--
-------------------------------------------------------------------------------------

entity test_toggle_synchroniser is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_toggle_synchroniser is

  constant width_c          : positive := 4;
  constant len_c            : positive := 3;
  constant num_data_items_c : positive := 10;

  signal clk_wr   : std_logic := '0';
  signal reset_wr : std_logic := '1';
  signal clk_rd   : std_logic := '0';
  signal reset_rd : std_logic := '1';
  signal data_wr  : std_logic_vector(width_c-1 downto 0);
  signal wr_rdy   : std_logic;
  signal wr_tgl   : std_logic;
  signal data_rd  : std_logic_vector(width_c-1 downto 0);
  signal rd_rdy   : std_logic;
  signal rd_tgl   : std_logic;

  signal all_tests_pass : boolean := true;
  signal wr_finished    : boolean := false;
  signal rd_finished    : boolean := false;

begin

  clkgen_wr : clock(clk_wr, 5 ns);
  clkgen_rd : clock(clk_rd, 8 ns, offset => 1 ns);


  toggle_synchroniser_i : entity work.toggle_synchroniser
    generic map (
      width_g => width_c,
      len_g   => len_c
    )
    port map (
      clk_wr   => clk_wr,
      reset_wr => reset_wr,
      clk_rd   => clk_rd,
      reset_rd => reset_rd,
      data_wr  => data_wr,
      wr_rdy   => wr_rdy,
      wr_tgl   => wr_tgl,
      data_rd  => data_rd,
      rd_rdy   => rd_rdy,
      rd_tgl   => rd_tgl
    );


  write : process
  begin
    wr_tgl  <= '0';
    data_wr <= (others => '0');
    wait_nr_ticks(clk_wr, 4);
    reset_wr <= '0';
    wait_nr_ticks(clk_wr, 1);

    for i in 1 to num_data_items_c loop
      wait_until(wr_rdy, '1');
      data_wr <= to_slv(i, width_c);
      wait_nr_ticks(clk_wr, 1);
      wr_tgl  <= not wr_tgl;
      wait_nr_ticks(clk_wr, 1);
    end loop;
    wr_finished <= true;

    wait;
  end process;


  read : process
    variable data_exp : std_logic_vector(width_c-1 downto 0);
  begin
    rd_tgl <= '0';
    wait_nr_ticks(clk_rd, 4);
    reset_rd <= '0';
    wait_nr_ticks(clk_rd, 1);

    for i in 1 to num_data_items_c loop
      wait_until(rd_rdy, '1');
      data_exp := to_slv(i, width_c);
      if data_rd /= data_exp then
        report "Expected: 0x" & to_hstring(data_exp) & " Read : 0x" & to_hstring(data_rd) severity error;
        all_tests_pass <= false;
      end if;
      wait_nr_ticks(clk_rd, 1);
      rd_tgl <= not rd_tgl;
      wait_nr_ticks(clk_rd, 1);
    end loop;
    rd_finished <= true;

    wait;
  end process;


  check : process
  begin

    wait until wr_finished and rd_finished;

    if all_tests_pass then
      report "All tests PASSED";
    else
      report "At least one test FAILED";
    end if;

    stop_clocks;
    wait;
  end process;

end architecture;
