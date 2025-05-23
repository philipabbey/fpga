-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- RTL code for a FIR filter with constant coefficients. There are three different
-- architectures for three different constructions:
--  * Traditional adder tree
--  * Transpose
--  * Systolic
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.adder_tree_pkg.all;
library local;
  use local.rtl_pkg.signed_arr_t;

entity fir_filter_const_coeffs is
  generic (
    -- Quartus Prime
    -- Error (10802): VHDL Unconstrained Array error at fir_filter_const_coeffs.vhdl(6): formal "coeffs_g" must be constrained
    -- Error (12153): Can't elaborate top-level user hierarchy
    coeffs_g      : signed_arr_t;
    input_width_g : positive
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    data_in  : in  signed(input_width_g-1 downto 0);
    -- data_in'length can't be accessed at this point, so use an extra generic 'input_width_g'.
    -- ** Error: A:\Philip\Work\VHDL\Adder_Tree\fir_filter_const_coeffs.vhdl(15): (vcom-1396) Object "data_in" cannot appear within the same interface list in which it is declared.
    data_out : out signed(output_bits(input_width_g + coeffs_g(0)'length, coeffs_g'length)-1 downto 0)
  );
end entity;


architecture traditional of fir_filter_const_coeffs is

  -- Re-map the array ranges to something we can guarantee.
  constant coeffs_c : signed_arr_t(coeffs_g'length-1 downto 0)(coeffs_g(0)'length-1 downto 0) := coeffs_g;

  signal data_reg : signed_arr_t(coeffs_c'range)(data_in'range);
  signal mult_arr : signed_arr_t(coeffs_c'range)(input_width_g + coeffs_c(0)'length - 1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_reg <= (others => (others => '0'));
        mult_arr <= (others => (others => '0'));
      else
        data_reg <= data_in & data_reg(data_reg'high downto 1);
        for i in coeffs_c'range loop
          mult_arr(i) <= data_reg(i) * coeffs_c(i);
        end loop;
      end if;
    end if;
  end process;

  adder_tree_pipe_i : entity work.adder_tree_pipe
    generic map (
      depth_g        => local.math_pkg.ceil_log(coeffs_c'length, 2), -- Best attempt at a binary tree with single adder between register stages
      num_operands_g => coeffs_c'length,
      input_width_g  => mult_arr(0)'length
    )
    port map (
      clk   => clk,
      reset => reset,
      i     => mult_arr,
      o     => data_out -- 10 + 3 = 13 bits
    );

end architecture;


architecture transpose of fir_filter_const_coeffs is

  -- Re-map the array ranges to something we can guarantee.
  constant coeffs_c    : signed_arr_t(coeffs_g'length-1 downto 0)(coeffs_g(0)'length-1 downto 0) := reverse(coeffs_g);
  constant sum_width_c : integer_vector(coeffs_c'range)                                          := calc_sum_width(coeffs_c, input_width_g);

  signal mult_arr : signed_arr_t(coeffs_c'range)(input_width_g + coeffs_c(0)'length - 1 downto 0);
  signal sum      : signed_arr_t(coeffs_c'range)(output_bits(input_width_g + coeffs_c(0)'length, coeffs_c'length)-1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        mult_arr <= (others => (others => '0'));
        -- Ensure some bits are sum are never touched and not just evapourate, but provably never get used in the filter logic.
        for i in coeffs_c'range loop
          sum(i)(sum_width_c(i)-1 downto 0) <= (others => '0');
        end loop;
      else
        for i in coeffs_c'range loop
          mult_arr(i) <= data_in * coeffs_c(i);

          if i = coeffs_c'high then
            sum(i)(sum_width_c(i)-1 downto 0) <= resize(mult_arr(i), sum_width_c(i)); -- Add zero sum in
          else
            sum(i)(sum_width_c(i)-1 downto 0) <= resize(mult_arr(i), sum_width_c(i)) + resize(sum(i+1)(sum_width_c(i+1)-1 downto 0), sum_width_c(i));
          end if;
        end loop;
      end if;
    end if;
  end process;

  data_out <= sum(0);

end architecture;



architecture systolic of fir_filter_const_coeffs is

  -- Re-map the array ranges to something we can guarantee.
  constant coeffs_c    : signed_arr_t(coeffs_g'length-1 downto 0)(coeffs_g(0)'length-1 downto 0) := coeffs_g;
  constant sum_width_c : integer_vector(coeffs_c'range)                                         := calc_sum_width(coeffs_c, input_width_g);

  signal data_reg  : signed_arr_t(coeffs_c'range)(data_in'range);
  signal data_pipe : signed_arr_t(coeffs_c'length-2 downto 0)(data_in'range);
  signal mult_arr  : signed_arr_t(coeffs_c'range)(input_width_g + coeffs_c(0)'length - 1 downto 0);
  signal sum       : signed_arr_t(coeffs_c'range)(output_bits(input_width_g + coeffs_c(0)'length, coeffs_c'length)-1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_reg  <= (others => (others => '0'));
        data_pipe <= (others => (others => '0'));
        mult_arr  <= (others => (others => '0'));
        -- Ensure some bits are sum are never touched and not just evapourate, but provably never get used in the filter logic.
        for i in coeffs_c'range loop
          sum(i)(sum_width_c(i)-1 downto 0) <= (others => '0');
        end loop;
      else
        data_reg  <= data_in & data_pipe;
        data_pipe <= data_reg(data_reg'high downto 1);
        for i in coeffs_c'range loop
          mult_arr(i) <= data_reg(i) * coeffs_c(i);

          if i = coeffs_c'high then
            sum(i)(sum_width_c(i)-1 downto 0) <= resize(mult_arr(i), sum_width_c(i)); -- Add zero sum in
          else
            sum(i)(sum_width_c(i)-1 downto 0) <= resize(mult_arr(i), sum_width_c(i)) + resize(sum(i+1)(sum_width_c(i+1)-1 downto 0), sum_width_c(i));
          end if;
        end loop;
      end if;
    end if;
  end process;

  data_out <= sum(0);

end architecture;
