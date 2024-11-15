-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Pseudorandom binary sequence (PRBS) compliant with ITU-T Recommendation O.150
-- Section 5, Digital Test Patterns for Performance Measurements On Digital
-- Transmission Equipment.
--
-- Reference: https://www.itu.int/rec/T-REC-O.150-199210-S
--
-- P A Abbey, 10 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity itu_prbs_generator is
  generic (
    index_g      : natural range 1 to 8 := 4;
    data_width_g : natural              := 4
  );
  port (
    clk      : in  std_logic;                                -- System clock
    reset    : in  std_logic;                                -- Sync reset active high
    enable   : in  std_logic;                                -- Enable pattern generation
    data_out : out std_logic_vector(data_width_g-1 downto 0) -- Generated PRBS pattern
  );
end entity;


library local;

architecture rtl of itu_prbs_generator is
begin

  prbs_generator_i : entity work.prbs_generator
    generic map (
      inv_pattern_g => local.lfsr_pkg.itu_t_o150_c(index_g).invert,
      poly_g        => local.lfsr_pkg.itu_t_poly_gen(index_g),
      data_width_g  => data_width_g
    )
    port map (
      clk      => clk,
      reset    => reset,
      enable   => enable,
      data_out => data_out
    );

end architecture;
