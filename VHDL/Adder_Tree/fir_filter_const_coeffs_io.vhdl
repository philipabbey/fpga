library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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

  -- Slow 1100mV 85C Model Only
  -- FAMILY "Cyclone V"
  -- DEVICE 5CGXFC7C7F23C8 (156 DSP Blocks)
  --
  -- Coefficients:  6 defined in (1, 2, -2, 2, -2, -1)
  -- input_width_g: 8
  -- Constraint:    275 MHz
  --
  -- Fmax Results:
  --
  -- Traditional: 312.60 MHz
  -- Transpose:   300.39 MHz
  -- Systolic:    269.25 MHz
  --
  --
  -- Coefficients:  21 defined in (-659, -1915, -2005, -358, 1679, 1089, -1853, -2807, 2077, 10186, 14235,
  --                 10186, 2077, -2807, -1853, 1089, 1679, -358, -2005, -1915, -659)
  -- input_width_g: 14
  -- Constraint:    275 MHz
  --
  -- Fmax Results:
  --
  -- Traditional: 155.16 MHz
  -- Transpose:   155.76 MHz
  -- Systolic:    154.70 MHz
  --
  --
  -- Coefficients:  41 defined in (29, -136, -397, -422, -15, 379, 160, -423, -405, 382, 727, -183, -1091, -257, 1452, 1089, -1757, -2827, 1962, 10205, 14350,
  --                 10205, 1962, -2827, -1757, 1089, 1452, -257, -1091, -183, 727, 382, -405, -423, 160, 379, -15, -422, -397, -136, 29)
  -- input_width_g: 14
  -- Constraint:    275 MHz
  --
  -- Fmax Results:
  --
  -- Traditional: 151.08 MHz
  -- Transpose:   150.88 MHz
  -- Systolic:    151.19 MHz
  --
  --
  -- "Cyclone V"
  -- 5CEFA2U19C6 (25 DSP Blocks) - Too small a device on purpose.
  --
  -- Coefficients:  41 defined in (29, -136, -397, -422, -15, 379, 160, -423, -405, 382, 727, -183, -1091, -257, 1452, 1089, -1757, -2827, 1962, 10205, 14350,
  --                 10205, 1962, -2827, -1757, 1089, 1452, -257, -1091, -183, 727, 382, -405, -423, 160, 379, -15, -422, -397, -136, 29)
  -- input_width_g: 14
  -- Constraint:    275 MHz
  --
  -- Fmax Results:
  --
  --             | Clock (MHz) | Registers | ALMs | DSP Blocks
  -- ------------+-------------+-----------+------+------------
  -- Traditional |    174.40   |           |      |     25
  -- Transpose   |    206.36   |           |      |     17 (Symmetric coefficients lead to an immediate optimisation of multiplers)
  -- Systolic    |    172.95   |           |      |     25
  --
  --
  -- "Cyclone V"
  -- XxXxXxXxXxXxX (66 DSP Blocks) - Lost the device name
  --
  -- Coefficients:  41 defined in (29, -136, -397, -422, -15, 379, 160, -423, -405, 382, 727, -183, -1091, -257, 1452, 1089, -1757, -2827, 1962, 10205, 14350,
  --                 10205, 1962, -2827, -1757, 1089, 1452, -257, -1091, -183, 727, 382, -405, -423, 160, 379, -15, -422, -397, -136, 29)
  -- input_width_g: 14
  -- Constraint:    275 MHz
  --
  -- Fmax Results:
  --             | Clock (MHz) | Registers | ALMs | DSP Blocks
  -- ------------+-------------+-----------+------+------------
  -- Traditional |             |           |      |       
  -- Transpose   |             |           |      |        (Symmetric coefficients lead to an immediate optimisation of multiplers)
  -- Systolic    |             |           |      |       
  --
  fir_filter_i : entity work.fir_filter_const_coeffs(Systolic)
    generic map (
      coeffs_g      => to_input_arr_t(coeffs_g, input_width_g), -- Assume same range of values for both data_in and coefficient values.
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
