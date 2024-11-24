-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the generic pipelined barrel shift enabling arbitraily large vector rotations
-- over a user specified number of clock cycles in order to manage timing closure.
--
-- P A Abbey, 15 November 2024
--
-------------------------------------------------------------------------------------

entity test_barrel_shift is
  generic (
    -- Iterative or recursive component?
    recursive_g : boolean := false
  );
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
library local;
  use local.testbench_pkg.all;
  use local.rtl_pkg.natural_vector;

architecture rtl of test_barrel_shift is

  -- Test one of each with different data widths
  type test_t is record
    shift_bits : positive;
    shift_left : boolean;
    num_clks   : positive;
  end record;

  type test_arr_t is array (natural range <>) of test_t;

  constant test_c : test_arr_t := (
  -- shift_bits, shift_left, num_clks
    (     1,        true,       1),
    (     1,        false,      2), -- Longer than required
    (     3,        true,       2),
    (     7,        true,       2),
    (     7,        true,       4),
    (     9,        false,      2),
    (     9,        false,      3),
    (     9,        true,       4),
    (     9,        false,     10)  -- Longer than required
  );

  signal clk          : std_logic;
  signal reset        : std_logic                       := '0';
  signal finished     : std_ulogic_vector(test_c'range) := (others => '0');
  signal finished_all : std_ulogic                      := '0';

  shared variable success : bool_t;

begin

  clock(clk, 5 ns, 5 ns);

  duts : for i in test_c'range generate

    constant shift_bits_c : positive := test_c(i).shift_bits;
    constant shift_left_c : boolean  := test_c(i).shift_left;
    constant num_clks_c   : positive := test_c(i).num_clks;

    signal run_test     : std_logic;
    signal shift        : std_logic_vector(   shift_bits_c-1 downto 0);
    signal data_in      : std_logic_vector(2**shift_bits_c-1 downto 0);
    signal data_out     : std_logic_vector(2**shift_bits_c-1 downto 0);
    signal shift_reg    : local.rtl_pkg.slv_arr_t(0 to num_clks_c-1)(2**shift_bits_c-1 downto 0);
    signal check_data   : std_logic_vector(2**shift_bits_c-1 downto 0);
    signal tests_passed : boolean                           := true;
    signal answer_valid : std_logic                         := '0';
    signal av_reg       : std_logic_vector(shift_reg'range) := (others => '0');

  begin

    choose : if recursive_g generate

      --dut : entity work.barrel_shift_recursive(recursive)
      dut : entity work.barrel_shift_recursive(recursive2)
        generic map (
          shift_bits_g => shift_bits_c,
          shift_left_g => shift_left_c,
          num_clks_g   => num_clks_c
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift,
          data_in  => data_in,
          data_out => data_out
        );

    else generate

      --dut : entity work.barrel_shift_iterative(iterative)
      dut : entity work.barrel_shift_iterative(iterative2)
        generic map (
          shift_bits_g => shift_bits_c,
          shift_left_g => shift_left_c,
          num_clks_g   => num_clks_c
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift,
          data_in  => data_in,
          data_out => data_out
        );

    end generate;

    stimulus : process
    begin
      shift        <= (others => '1');
      data_in      <= (others => '0');
      run_test     <= '0';
      answer_valid <= '0';
      wait until falling_edge(reset);
      wait_nr_ticks(clk, 2);
      answer_valid <= '1';
      data_in(0)   <= '1';
--      if data_in'high >= 3 then
--        data_in(3) <= '1';
--      end if;
      run_test <= '1';
      for i in 0 to 2**shift_bits_c-1 loop
        shift <= to_slv(i, shift'length);
        wait_nr_ticks(clk, 1);
      end loop;
      shift        <= (others => '1');
      answer_valid <= '0';
      wait_nr_ticks(clk, num_clks_c);
      run_test <= '0';
      wait_nr_ticks(clk, 1);
      data_in  <= (others => '0');

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

    check_data <= (data_in rol to_integer(shift)) when shift_left_c else (data_in ror to_integer(shift));

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
          shift_reg <= (others => (others => '0'));
          av_reg    <= (others => '0');
        else
          if run_test = '1' then
            shift_reg <= check_data & shift_reg(0 to shift_reg'high-1);
            av_reg    <= answer_valid & av_reg(0 to av_reg'high-1);
          end if;
        end if;
      end if;
    end process;

    check : process(clk)
    begin
      if falling_edge(clk) then
        if av_reg(av_reg'high) = '1' and shift_reg(shift_reg'high) /= data_out then
          report "Test " & to_string(i) & ": Expected: " & to_hstring(shift_reg(shift_reg'high)) & ", Data out: " & to_hstring(data_out) severity error;
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
    if recursive_g then
      report "Exercising recursive components";
    else
      report "Exercising iterative components";
    end if;
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
