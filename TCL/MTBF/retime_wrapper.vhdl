-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado's MTBF calculation.
--
-- P A Abbey, 24 September 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity retime_wrapper is
  generic (
    num_bits_g  : positive := 2;
    reg_depth_g : positive := 2 -- Deliberately does not start at 2 in order to measure the MTBF of a 1-logn resync chain.
  );
  port (
    clk_src    : in  std_logic;
    reset_src  : in  std_logic;
    clk_dest   : in  std_logic;
    reset_dest : in  std_logic;
    flags_in   : in  std_logic_vector(num_bits_g-1 downto 0);
    flags_out  : out std_logic_vector(num_bits_g-1 downto 0)
  );
end entity;

architecture rtl of retime_wrapper is

  signal flags_in_i  : std_logic_vector(num_bits_g-1 downto 0);
  signal flags_out_i : std_logic_vector(num_bits_g-1 downto 0);

begin

  process(clk_src)
  begin
    if rising_edge(clk_src) then
      if reset_src = '1' then
        flags_in_i <= (others => '0');
      else
        flags_in_i <= flags_in;
      end if;
    end if;
  end process;

  retime_i : entity work.retime
    generic map (
      num_bits_g  => num_bits_g,
      reg_depth_g => reg_depth_g
    )
    port map (
      clk_src    => clk_src,
      reset_src  => reset_src,
      clk_dest   => clk_dest,
      reset_dest => reset_dest,
      flags_in   => flags_in_i,
      flags_out  => flags_out_i
    );

  process(clk_dest)
  begin
    if rising_edge(clk_dest) then
      if reset_dest = '1' then
        flags_out <= (others => '0');
      else
        flags_out <= flags_out_i;
      end if;
    end if;
  end process;

end architecture;
