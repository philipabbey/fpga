-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Bad example clock domain crossing to demonstrate Vivado 'report_cdc' TCL command.
-- Create the topologies listed at [1] in order to purposely create errors for
-- 'report_cdc' to find. Additional ASYNC_REG properties deliberately omitted.
--
-- P A Abbey, 22 May 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity sync_reg_bad is
  port (
    clk_dest   : in  std_logic;
    reset_dest : in  std_logic;
    flags_in   : in  std_logic_vector(1 downto 0);
    flags_out  : out std_logic_vector(1 downto 0)
  );
end entity;


architecture rtl of sync_reg_bad is

  -- ASYNC_REG properties deliberately omitted.
  signal reg_retime : std_logic := '0';

begin

  process(clk_dest)
  begin
    if rising_edge(clk_dest) then
      if reset_dest = '1' then
        reg_retime <= '0';
        flags_out  <= "00";
      else
        reg_retime <= flags_in(1);
        flags_out  <= (reg_retime and flags_out(0)) & flags_in(0);
      end if;
    end if;
  end process;

end architecture;
