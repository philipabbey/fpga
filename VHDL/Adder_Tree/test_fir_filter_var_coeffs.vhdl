-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the FIR filter with variable coefficients.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

entity test_fir_filter_var_coeffs is
end entity;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library local;
use local.testbench_pkg.all;
use work.adder_tree_pkg.all;

architecture rtl of test_fir_filter_var_coeffs is

  signal clk     : std_logic;
  signal reset   : std_logic;
  signal data_in : signed(13 downto 0);

  constant coeffs_c : integer_vector := (1, 2, -2, 2, -2, -1);
--  constant coeffs_c : integer_vector := (
--       -659,
--      -1915,
--      -2005,
--       -358,
--       1679,
--       1089,
--      -1853,
--      -2807,
--       2077,
--      10186,
--      14235,
--      10186,
--       2077,
--      -2807,
--      -1853,
--       1089,
--       1679,
--       -358,
--      -2005,
--      -1915,
--       -659
--    );

  constant data_in_c : integer_vector := (
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8,
    -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8
  );

  signal data_out_trad  : signed(output_bits(2 * data_in'length, coeffs_c'length)-1 downto 0);
  signal data_out_trans : signed(output_bits(2 * data_in'length, coeffs_c'length)-1 downto 0);
  signal data_out_syst  : signed(output_bits(2 * data_in'length, coeffs_c'length)-1 downto 0);
  signal coeffs         : input_arr_t(coeffs_c'range)(data_in'range);

begin

  clkgen : clock(clk, 10 ns);
  
  coeffs <= to_input_arr_t(coeffs_c, data_in'length);

  dut_trad : entity work.fir_filter_var_coeffs(traditional)
    generic map (
      input_width_g => data_in'length,
      num_coeffs_g  => coeffs_c'length
    )
    port map (
      clk      => clk,
      reset    => reset,
      coeffs   => coeffs,
      data_in  => data_in,
      data_out => data_out_trad
    );

  dut_trans : entity work.fir_filter_var_coeffs(transpose)
    generic map (
      input_width_g => data_in'length,
      num_coeffs_g  => coeffs_c'length
    )
    port map (
      clk      => clk,
      reset    => reset,
      coeffs   => coeffs,
      data_in  => data_in,
      data_out => data_out_trans
    );

  dut_syst : entity work.fir_filter_var_coeffs(systolic)
    generic map (
      input_width_g => data_in'length,
      num_coeffs_g  => coeffs_c'length
    )
    port map (
      clk      => clk,
      reset    => reset,
      coeffs   => coeffs,
      data_in  => data_in,
      data_out => data_out_syst
    );

  process
  begin
    reset   <= '1';
    data_in <= (others => '0');
    wait_nr_ticks(clk, 2);
    reset   <= '0';

    for i in data_in_c'range loop
      data_in <= to_signed(data_in_c(i), data_in'length);
      wait_nr_ticks(clk, 1);
    end loop;
    wait_nr_ticks(clk, 10);

    stop_clocks;
    wait;
  end process;

end architecture;
