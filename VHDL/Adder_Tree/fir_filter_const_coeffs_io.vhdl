-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- RTL code for a FIR filter with constant coefficients instantiated with registered
-- I/O for use in synthesis to extract timing information of the inner FIR filter
-- instantiation.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work; -- Implicit anyway, but acts to group.
  use work.adder_tree_pkg.all;

entity fir_filter_const_coeffs_io is
  generic (
    coeffs_g : integer_vector := (
      29, -136, -397, -422, -15, 379, 160, -423, -405, 382, 727, -183, -1091, -257, 1452, 1089, -1757, -2827, 1962, 10205, 14350,
      10205, 1962, -2827, -1757, 1089, 1452, -257, -1091, -183, 727, 382, -405, -423, 160, 379, -15, -422, -397, -136, 29
    );
    input_width_g : positive := 14
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    data_in  : in  signed(input_width_g-1 downto 0);
    data_out : out signed(output_bits(2*input_width_g, coeffs_g'length)-1 downto 0)
  );
end entity;


architecture rtl of fir_filter_const_coeffs_io is

  signal reset_reg  : std_ulogic_vector(1 downto 0);
  signal data_in_i  : signed(data_in'range);
  signal data_out_i : signed(data_out'range);

begin

  fir_filter_i : entity work.fir_filter_const_coeffs(Systolic)
    generic map (
      coeffs_g      => to_signed_arr_t(coeffs_g, input_width_g), -- Assume same range of values for both data_in and coefficient values.
      input_width_g => input_width_g
    )
    port map (
      clk      => clk,
      reset    => reset_reg(1),
      data_in  => data_in_i,
      data_out => data_out_i
    );

  process(clk, reset)
  begin
    -- Asynchronous reset for synchronising the reset
    -- See articles at:
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-other-Design/bc-p/931744
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-and-other-Design/ba-p/887366
    if reset = '1' then
      reset_reg  <= "11";
    elsif rising_edge(clk) then
      reset_reg  <= reset_reg(0) & '0';
    end if;
  end process;

  -- Inputs
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        data_in_i <= (others => '0');
      else
        -- double retime data
        data_in_i <= data_in;
      end if;
    end if;
  end process;

  -- Outputs
  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        data_out <= (others => '0');
      else
        data_out <= data_out_i;
      end if;
    end if;
  end process;

end architecture;
