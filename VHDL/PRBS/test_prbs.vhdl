-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the PRBS generator component.
--
-- P A Abbey, 10 November 2024
--
-------------------------------------------------------------------------------------

entity test_prbs is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_prbs is

  -- Test one of each with different data widths
  type test_t is record
    itu_index  : integer range 1 to 8;
    data_width : positive;
  end record;

  type test_arr_t is array (natural range <>) of test_t;

  constant test_c : test_arr_t := (
  -- itu_index, data_width
    (   1,  1),
    (   2,  2),
    (   3,  3), -- Non power of 2
    (   4,  4),
    (   5,  5), -- Non power of 2
    (   6,  8),
    (   7, 16),
    (   8, 32),
    (   1, 12)  -- Data width > polynomial
  );

  signal clk    : std_logic;
  signal reset  : std_logic;
  signal enable : std_logic := '1';

begin

  clock(clk, 5 ns, 5 ns);

  dut : for i in test_c'range generate

    constant itu_index_c  : integer range 1 to 8 := test_c(i).itu_index;
    constant data_width_c : positive             := test_c(i).data_width;
    constant invert_c     : boolean              := local.lfsr_pkg.itu_t_o150_c(itu_index_c).invert;

    signal data_in    : std_logic_vector(data_width_c-1 downto 0);
    signal data_out_x : std_logic_vector(data_width_c-1 downto 0);
    signal data_out   : std_logic_vector(data_width_c-1 downto 0);
    signal err_vec    : std_logic_vector(data_width_c-1 downto 0) := (others => '0'); -- := (1 => '1', others => '0');

  begin

    data_in <= (others => '0');

    prbs_any_i : entity work.prbs_any
      generic map (
        inv_pattern => invert_c,
        poly_length => local.lfsr_pkg.itu_t_o150_c(itu_index_c).length,
        poly_tap    => local.lfsr_pkg.itu_t_o150_c(itu_index_c).tap,
        nbits       => data_width_c
      )
      port map (
        chk_mode => '0',
        rst      => reset,
        clk      => clk,
        data_in  => data_in,
        en       => enable,
        data_out => data_out_x
      );


    prbs_generator_i : entity work.itu_prbs_generator
      generic map (
        index_g      => itu_index_c,
        data_width_g => data_width_c
      )
      port map (
        clk      => clk,
        reset    => reset,
        enable   => enable,
        data_out => data_out
      );

    -- Ignore differences before reset
    assert (now < 1 ns) or (data_out = data_out_x)
      report "FAILURE Expected: " & to_hstring(data_out_x) & " Read: " & to_string(data_out)
      severity error;

  end generate;


  stimulus : process
  begin
    reset  <= '0';
    enable <= '0';
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);
    wait_nr_ticks(clk, 2);

    -- Random wiggle on 'enable' input
    for i in 1 to 40 loop
      enable <= '1';
      wait_rndr_ticks(clk, 1, 3);
      enable <= '0';
      wait_rndr_ticks(clk, 0, 3);
    end loop;

    wait_nr_ticks(clk, 1);
    stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;

end architecture;
