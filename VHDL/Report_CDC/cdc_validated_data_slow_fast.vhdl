-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado 'report_cdc' TCL command.
-- Create the topologies listed at [1] in order to purposely create warnings for
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

entity cdc_validated_data_slow_fast is
  generic(
    width_g      : positive;                              -- Data width must match on input and output ports
    sync_chain_g : positive range 2 to positive'high := 2 -- Synchronising register chain length
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


architecture rtl of cdc_validated_data_slow_fast is

  signal data_i : std_logic_vector(width_g-1 downto 0)      := (others => '0');
  signal dv_i   : std_logic                                 := '0';
  signal dv     : std_logic_vector(sync_chain_g-1 downto 0) := (others => '0');
  -- This bit for pulse generation is not to be included as part of the synchroniser
  -- register chain with an ASYNC_REG attribute.
  signal pg     : std_logic                                 := '0';

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

  -- Retime the data from a slower to a faster clock domain
  -- Double retime the valid signal, then resample the data in the new clock domain
  cdc : process(clk_out)
  begin
    if rising_edge(clk_out) then
      if reset_out = '1' then
        dv             <= (others => '0');
        pg             <= '0';
        data_valid_out <= '0';
        data_out       <= (others => '0');
      else
        -- Double retime the enable signal
        dv <= dv(dv'high-1 downto 0) & dv_i;
        -- Can't use LHS concatenation in synthesis with Vivado:
        --    (pg, dv) <= dv & dv_i;
        -- ERROR: [Synth 8-2778] type error near dv ; expected type std_ulogic [.../cdc_validated_data_slow_fast.vhd:nn]
        pg <= dv(dv'high);
        -- Pulse generator
        data_valid_out <= dv(dv'high) and not pg;
        if dv(dv'high) = '1' then
          -- Sample the data bus in the new clock domain
          -- Should be in sync with data_valid_out
          -- NB. Need set_max_delay constraint from data_i to data_out
          data_out <= data_i;
        end if;
      end if;
    end if;
  end process;

end architecture;

