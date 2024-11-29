-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Generic pipelined multiplexer enabling selection of one of a large number of
-- inputs over auser specified number of clock cycles in order to manage timing
-- closure.
--
-- Use to gain design clock speed data from Quartus Prime. Putting a ring of
-- registers around the DUT and false paths on all the external edges. 
--
-- P A Abbey, 24 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library local;

entity synth_mux is
  generic (
    sel_bits_g   : positive;
    data_width_g : positive;
    -- Pipeline stages
    num_clks_g   : positive
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    sel      : in  std_logic_vector(sel_bits_g-1 downto 0);
    data_in  : in  local.rtl_pkg.slv_arr_t(2**sel_bits_g-1 downto 0)(data_width_g-1 downto 0);
    data_out : out std_logic_vector(data_width_g-1 downto 0)
  );
end entity;


architecture rtl of synth_mux is

  signal reset_i    : std_logic;
  signal sel_i      : std_logic_vector(sel_bits_g-1 downto 0);
  signal data_in_i  : local.rtl_pkg.slv_arr_t(2**sel_bits_g-1 downto 0)(data_width_g-1 downto 0);
  signal data_out_i : std_logic_vector(data_width_g-1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      reset_i <= reset;

      if reset_i = '1' then
        sel_i     <= (others => '0');
        data_in_i <= (others => (others => '0'));
        data_out  <= (others => '0');
      else
        sel_i     <= sel;
        data_in_i <= data_in;
        data_out  <= data_out_i;
      end if;
    end if;
  end process;


  mux_i : entity work.mux
    generic map (
      sel_bits_g   => sel_bits_g,
      data_width_g => data_width_g,
      num_clks_g   => num_clks_g
    )
    port map (
      clk      => clk,
      reset    => reset_i,
      sel      => sel_i,
      data_in  => data_in_i,
      data_out => data_out_i
    );

end architecture;
