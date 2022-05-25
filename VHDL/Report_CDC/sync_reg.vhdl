-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Just provide 2 synchronising registers. Additional ASYNC_REG properties
-- deliberately omitted.
--
-- P A Abbey, 22 May 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity sync_reg is
  generic (
    num_bits_g : positive := 1
  );
  port (
    clk_dest   : in  std_logic;
    reset_dest : in  std_logic;
    flags_in   : in  std_logic_vector(num_bits_g-1 downto 0);
    flags_out  : out std_logic_vector(num_bits_g-1 downto 0)
  );
end entity;


architecture rtl of sync_reg is

  -- ASYNC_REG properties deliberately omitted.
  signal reg_retime : std_logic_vector(num_bits_g-1 downto 0) := (others => '0');

begin

  process(clk_dest)
  begin
    if rising_edge(clk_dest) then
      if reset_dest = '1' then
        reg_retime <= (others => '0');
        flags_out  <= (others => '0');
      else
        reg_retime <= flags_in;
        flags_out  <= reg_retime;
      end if;
    end if;
  end process;

end architecture;
