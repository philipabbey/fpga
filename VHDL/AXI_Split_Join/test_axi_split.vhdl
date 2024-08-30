-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the split mechanism for an AXI Data Stream.
--
-- P A Abbey, 30 August 2024
--
-------------------------------------------------------------------------------------

entity test_axi_split is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_axi_split is

  constant data_width_c : positive := 16;
  constant max_loops_c  : positive := 128;

  signal clk            : std_logic;
  signal s_axi_data     : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal s_axi_valid    : std_logic                                 := '0';
  signal s_axi_ready    : std_logic                                 := '0';
  signal m1_axi_data    : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m1_axi_valid   : std_logic                                 := '0';
  signal m1_axi_ready   : std_logic                                 := '0';
  signal m2_axi_data    : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m2_axi_valid   : std_logic                                 := '0';
  signal m2_axi_ready   : std_logic                                 := '0';

  signal tests_passed1  : boolean := true;
  signal tests_passed2  : boolean := true;
  signal test1_finished : boolean := false;
  signal test2_finished : boolean := false;

begin

  clkgen : clock(clk, 10 ns);


  axi_split_i : entity work.axi_split
    generic map (
      data_width_g => data_width_c
    )
    port map (
      s_axi_data   => s_axi_data,
      s_axi_valid  => s_axi_valid,
      s_axi_ready  => s_axi_ready,
      m1_axi_data  => m1_axi_data,
      m1_axi_valid => m1_axi_valid,
      m1_axi_ready => m1_axi_ready,
      m2_axi_data  => m2_axi_data,
      m2_axi_valid => m2_axi_valid,
      m2_axi_ready => m2_axi_ready
    );


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


  sink1 : process
    variable i : natural := 1;
  begin
    m1_axi_ready <= '0';
    wait_nr_ticks(clk, 10);

    while i <= max_loops_c loop
      m1_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m1_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      wait_until(m1_axi_valid, '1');
      if to_integer(unsigned(m1_axi_data)) /= i then
        report "Incorrect data read, expected: " & integer'image(i) & " got: " & integer'image(to_integer(unsigned(m1_axi_data)));
        tests_passed1 <= false;
      end if;
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    m1_axi_ready <= '0';
    wait_nr_ticks(clk, 1);
    test1_finished <= true;

    wait;
  end process;


  sink2 : process
    variable i : natural := 1;
  begin
    m2_axi_ready <= '0';
    wait_nr_ticks(clk, 10);

    while i <= max_loops_c loop
      m2_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m2_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      wait_until(m2_axi_valid, '1');
      if to_integer(unsigned(m2_axi_data)) /= i then
        report "Incorrect data read, expected: " & integer'image(i) & " got: " & integer'image(to_integer(unsigned(m2_axi_data)));
        tests_passed2 <= false;
      end if;
      wait_nr_ticks(clk, 1);
      i := i + 1;
    end loop;
    m2_axi_ready <= '0';
    wait_nr_ticks(clk, 1);
    test2_finished <= true;

    wait;
  end process;


  check : process
  begin

    wait until test1_finished and test2_finished;

    if tests_passed1 and tests_passed2 then
      report "All tests PASSED";
    else
      report "At least one test FAILED";
    end if;

    stop_clocks;
    wait;
  end process;

end architecture;
