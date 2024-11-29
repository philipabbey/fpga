-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the generic pipelined multiplexer enabling selection of one of a large number
-- of inputs over auser specified number of clock cycles in order to manage timing
-- closure.
--
-- P A Abbey, 22 November 2024
--
-------------------------------------------------------------------------------------

entity test_mux is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
library local;
  use local.testbench_pkg.all;
  use local.rtl_pkg.natural_vector;

architecture rtl of test_mux is

  -- Test one of each with different data widths
  type test_t is record
    sel_bits   : positive;
    num_clks   : positive;
    data_width : positive;
  end record;

  type test_arr_t is array (natural range <>) of test_t;

  constant test_c : test_arr_t := (
  -- sel_bits, num_clks, data_width
    (    1,       1,        16     ),
    (    1,       2,         8     ), -- Longer than required
    (    3,       2,         8     ),
    (    7,       2,         4     ),
    (    7,       4,         8     ),
    (    9,       2,         8     ),
    (    9,       3,         8     ),
    (    9,       4,         8     ),
    (    9,      10,         8     )  -- Longer than required
  );

  signal clk          : std_logic;
  signal reset        : std_logic                       := '0';
  signal finished     : std_ulogic_vector(test_c'range) := (others => '0');
  signal finished_all : std_ulogic                      := '0';

  shared variable success : bool_t;

begin

  clock(clk, 5 ns, 5 ns);

  duts : for i in test_c'range generate

    constant sel_bits_c   : positive := test_c(i).sel_bits;
    constant num_clks_c   : positive := test_c(i).num_clks;
    constant data_width_c : positive := test_c(i).data_width;

    signal run_test     : std_logic;
    signal sel          : std_logic_vector(sel_bits_c-1 downto 0);
    signal data_in      : local.rtl_pkg.slv_arr_t(2**sel_bits_c-1 downto 0)(data_width_c-1 downto 0);
    signal data_out     : std_logic_vector(data_width_c-1 downto 0);
    signal sel_reg      : local.rtl_pkg.slv_arr_t(0 to num_clks_c-1)(data_width_c-1 downto 0);
    signal tests_passed : boolean                         := true;
    signal answer_valid : std_logic                       := '0';
    signal av_reg       : std_logic_vector(sel_reg'range) := (others => '0');

  begin

    dut : entity work.mux
      generic map (
        sel_bits_g   => sel_bits_c,
        data_width_g => data_width_c,
        num_clks_g   => num_clks_c
      )
      port map (
        clk      => clk,
        reset    => reset,
        sel      => sel,
        data_in  => data_in,
        data_out => data_out
      );

    stimulus : process
    begin
      sel          <= (others => '1');
      data_in      <= (others => (others => '1'));
      run_test     <= '0';
      answer_valid <= '0';
      wait until reset'event and reset = '0';
      wait_nr_ticks(clk, 2);
      answer_valid <= '1';
      for i in data_in'range loop
        data_in(i) <= to_slv(i, data_width_c);
      end loop;
      run_test <= '1';
      for i in 0 to 2**sel_bits_c-1 loop
        sel <= to_slv(i, sel'length);
        wait_nr_ticks(clk, 1);
      end loop;
      sel          <= to_slv(0, sel'length);
      answer_valid <= '0';
      wait_nr_ticks(clk, num_clks_c);
      run_test <= '0';
      wait_nr_ticks(clk, 1);
      data_in  <= (others => (others => '1'));

      wait_nr_ticks(clk, 2);
      if tests_passed then
        report "Test " & to_string(i) & " PASSED" severity note;
      else
        report "Test " & to_string(i) & " FAILED" severity error;
      end if;

      finished(i) <= '1';
      -- Prevent the process repeating after the simulation time has been manually extended.
      wait;
    end process;

    shft : process(clk)

      function "&" (l : std_logic_vector; r : local.rtl_pkg.slv_arr_t) return local.rtl_pkg.slv_arr_t is
        variable ret : local.rtl_pkg.slv_arr_t(0 to r'length)(l'range);
      begin
        ret(0)             := l;
        ret(1 to r'length) := r;
        return ret;
      end function;

    begin
      if rising_edge(clk) then
        if reset = '1' then
          sel_reg <= (others => (others => '0'));
          av_reg  <= (others => '0');
        else
          if run_test = '1' then
            sel_reg <= std_logic_vector'(data_in(to_integer(sel))) & local.rtl_pkg.slv_arr_t'(sel_reg(0 to sel_reg'high-1));
            av_reg  <= answer_valid & av_reg(0 to av_reg'high-1);
          end if;
        end if;
      end if;
    end process;

    check : process(clk)
    begin
      if falling_edge(clk) then
        if av_reg(av_reg'high) = '1' and sel_reg(sel_reg'high) /= data_out then
          report "Test " & to_string(i) & ": Expected: " & to_hstring(sel_reg(sel_reg'high)) & ", Data out: " & to_hstring(data_out) severity error;
          tests_passed <= false;
          success.set(false);
        end if;
      end if;
    end process;

  end generate;

  finished_check : process(finished)
    constant all_ones : std_ulogic_vector(test_c'range) := (others => '1');
  begin
    for i in finished'range loop
      if finished = all_ones then
        finished_all <= '1';
      end if;
    end loop;
  end process;

  control : process
  begin
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);
    wait until finished_all = '1';
    if success.get then
      report "SUCCESS - All tests passed" severity note;
    else
      report "FAILED - Some tests failed" severity error;
    end if;
   stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;

end architecture;
