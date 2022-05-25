-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Bad example clock domain crossing to demonstrate Vivado 'report_cdc' TCL command.
-- Create the topologies listed at [1] in order to purposely create errors for
-- 'report_cdc' to find.
--
-- References:
--  [1] https://docs.xilinx.com/r/en-US/ug906-vivado-design-analysis/Simplified-Schematics-of-the-CDC-Topologies
--
-- P A Abbey, 22 May 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity cdc_invalid_data_slow_fast is
  generic(
    width_g : positive -- Data width must match on input and output ports
  );
  port(
    clk_in         : in  std_logic;
    reset_in       : in  std_logic;
    data_in        : in  std_logic_vector(width_g-1 downto 0);
    data_valid_in  : in  std_logic;
    clk_out        : in  std_logic;
    reset_out      : in  std_logic;
    data_out       : out std_logic_vector(width_g-1 downto 0) := (others => '0');
    data_valid_out : out std_logic                            := '0'
  );
end entity;


architecture rtl of cdc_invalid_data_slow_fast is

  signal data_i : std_logic_vector(width_g-1 downto 0) := (others => '0');
  signal dv_i   : std_logic                            := '0';

begin

  -- Catch the valid signal in the slower clock domain
  capture : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if reset_in = '1' then
        data_i <= (others => '0');
        dv_i   <= '0';
      else
        if data_valid_in = '1' then
          data_i <= data_in;
        end if;
        dv_i <= data_valid_in;
      end if;
    end if;
  end process;

  process(clk_out)
  begin
    if rising_edge(clk_out) then
      if reset_out = '1' then
        data_valid_out <= '0';
        data_out       <= (others => '0');
      else
        if dv_i = '1' then
          data_out <= data_i;
        end if;
        data_valid_out <= dv_i;
      end if;
    end if;
  end process;

end architecture;

