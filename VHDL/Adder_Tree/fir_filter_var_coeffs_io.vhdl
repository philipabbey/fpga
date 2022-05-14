-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- RTL code for a FIR filter with variable coefficients instantiated with registered
-- I/O for use in synthesis to extract timing information of the inner FIR filter
-- instantiation.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------
--
-- Sample Results from Synthesis
-- =============================
--
-- Slow 1100mV 85C Model Only
-- FAMILY "Cyclone V"
-- DEVICE 5CGXFC7C7F23C8 (156 DSP Blocks)
--
-- Coefficients:  6
-- input_width_g: 8
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   124.89   |   87 |     249   |   129 |   6 |
-- Transpose   |   124.72   |   69 |     203   |    91 |   6 |
-- Systolic    |   126.39   |   90 |     275   |   131 |   6 |
--
--
-- Slow 1100mV 85C Model Only
-- FAMILY "Cyclone V"
--
-- Coefficients:  6
-- input_width_g: 9
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   122.93   |   89 |     279   |   144 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 10
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   156.79   |  105 |     309   |   159 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 11
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   157.68   |  111 |     339   |   174 |   6 |
-- Transpose   |   150.51   |  100 |     275   |   121 |   6 |
-- Systolic    |   154.80   |  127 |     374   |   176 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 12
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   156.72   |  122 |     369   |   189 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 13
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   155.64   |  134 |     399   |   204 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 14
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   153.66   |  145 |     429   |   219 |   6 |
-- Transpose   |   150.92   |  126 |     347   |   151 |   6 |
-- Systolic    |   153.73   |  159 |     473   |   221 |   6 |
--
--
-- Coefficients:  6
-- input_width_g: 15
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   152.95   |  157 |     459   |   234 |   6 |
--
--
-- Coefficients:  21
-- input_width_g: 8
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   125.28   |  332 |     982   |   523 |  21 |
-- Transpose   |   123.35   |  278 |     746   |   394 |  21 |
-- Systolic    |   124.49   |  354 |    1058   |   554 |  21 |
--
--
-- Coefficients:  21
-- input_width_g: 11
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   151.93   |  445 |    1333   |   703 |  21 |
-- Transpose   |   153.63   |  382 |     998   |   514 |  21 |
-- Systolic    |   150.33   |  489 |    1427   |   734 |  21 |
--
--
-- Coefficients:  21
-- input_width_g: 14
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   150.31   |  561 |    1684   |   883 |  21 |
-- Transpose   |   154.25   |  459 |    1250   |   634 |  21 |
-- Systolic    |   154.87   |  595 |    1796   |   914 |  21 |
--
--
-- Coefficients:  41
-- input_width_g: 8
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   124.05   |  666 |    1961   |  1050 |  41 |
--
--
-- Coefficients:  41
-- input_width_g: 11
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   151.54   |  902 |    2660   |  1410 |  41 |
--
--
-- Coefficients:  41
-- input_width_g: 14
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   150.51   | 1131 |    3359   |  1770 |  41 |
-- Transpose   |   148.48   |  934 |    2479   |  1303 |  41 |
-- Systolic    |   150.69   | 1209 |    3585   |  1863 |  41 |
--
--
-- "Cyclone V"
-- 5CEFA2U19C6 (25 DSP Blocks) - Too small a device on purpose.
--
-- Coefficients:  41
-- input_width_g: 14
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   172.50   | 1131 |    3359   |  1770 |  25 |
-- Transpose   |   172.62   |  934 |    2479   |  1303 |  25 |
-- Systolic    |   171.64   | 1209 |    3585   |  1863 |  25 |
--
--
-- "Cyclone V"
-- 5CEBA4F17A7 (66 DSP Blocks)
--
-- Coefficients:  41
-- input_width_g: 14
-- Constraint:    275 MHz
--
-- Fmax Results:
--
--             | Fmax (MHz) | ALMs | Registers | ALUTs | DSP |
-- ------------+------------+------+-----------+-------+-----+
-- Traditional |   168.95   | 1131 |    3359   |  1770 |  41 |
-- Transpose   |   171.73   |  934 |    2479   |  1303 |  41 |
-- Systolic    |   172.06   | 1209 |    3585   |  1863 |  41 |
--

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library work; -- Implicit anyway, but acts to group.
  use work.adder_tree_pkg.all;

entity fir_filter_var_coeffs_io is
  generic (
    num_coeffs_g  : positive := 6;
    input_width_g : positive := 8
  );
  port(
    clk         : in  std_ulogic;
    reset       : in  std_ulogic;
    coeffs      : in  signed(input_width_g-1 downto 0);
    coeffs_load : in  std_ulogic;
    data_in     : in  signed(input_width_g-1 downto 0);
    data_out    : out signed(output_bits(2*input_width_g, num_coeffs_g)-1 downto 0)
  );
end entity;


architecture rtl of fir_filter_var_coeffs_io is

  subtype coeffs_arr_t is input_arr_t(num_coeffs_g-1 downto 0)(input_width_g-1 downto 0);

  signal reset_reg  : std_ulogic_vector(1 downto 0);
  signal coeffs_i   : coeffs_arr_t;
  signal data_in_i  : signed(input_width_g-1 downto 0);
  signal data_out_i : signed(data_out'range);

begin

  fir_filter_i : entity work.fir_filter_var_coeffs(Traditional)
    generic map (
      num_coeffs_g  => num_coeffs_g,
      input_width_g => input_width_g
    )
    port map (
      clk      => clk,
      reset    => reset_reg(1),
      coeffs   => coeffs_i,
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
        coeffs_i <= (others => (others => '0'));
      else
        if coeffs_load = '1' then
          coeffs_i <= coeffs_i(num_coeffs_g-2 downto 0) & coeffs;
        end if;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        data_in_i <= (others => '0');
      else
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
