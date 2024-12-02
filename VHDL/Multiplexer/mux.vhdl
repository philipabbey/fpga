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
-- P A Abbey, 22 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library local;

entity mux is
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


architecture rtl of mux is

  signal sel_i : std_logic_vector(sel'range);

  constant indexes_c : local.rtl_pkg.natural_vector := work.mux_pkg.register_stages(
    sel_len  => sel_bits_g,
    num_clks => num_clks_g
  );

begin

  mux_sel_g : if indexes_c'length > 0 generate

   mux_sel_i : entity work.mux_sel
     generic map (
       sel_bits_g => sel_bits_g,
       indexes_g  => indexes_c
     )
     port map (
       clk     => clk,
       reset   => reset,
       sel_in  => sel,
       sel_out => sel_i
     );

   else generate

      -- Pipeline length is 1, so 'sel' does not need any registering
      sel_i <= sel;

   end generate;

  mux_tree_i : entity work.mux_tree
    generic map (
      sel_bits_g   => sel_bits_g,
      data_width_g => data_width_g,
      num_clks_g   => num_clks_g
    )
    port map (
      clk      => clk,
      reset    => reset,
      sel      => sel_i,
      data_in  => data_in,
      data_out => data_out
    );

end architecture;
