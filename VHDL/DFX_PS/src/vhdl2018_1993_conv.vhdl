-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/house-of-abbey/scratch_vhdl/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- VHDL 1993 wrapper for VHDL 2018 top level RTL file in order to keep Vivado's Block
-- Diagram Editor happy. :-(
--
-- P A Abbey, 24 February 2025
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity vhdl2018_1993_conv is
  generic(
    sim_g    : boolean := false;
    rm_num_g : natural
  );
  port(
    clk_port : in  std_logic; -- 125 MHz External Clock
    sw       : in  std_logic_vector(3 downto 0);
    btn      : in  std_logic_vector(3 downto 0);
    led      : out std_logic_vector(3 downto 0) := "0000";
    disp_sel : out std_logic                    := '0';
    sevseg   : out std_logic_vector(6 downto 0) := "0000000"
  );
end entity;


architecture struct of vhdl2018_1993_conv is
begin

  wrapper_i : entity work.pl
    generic map (
      sim_g    => sim_g,
      rm_num_g => rm_num_g
    )
    port map (
      clk_port => clk_port,
      sw       => sw,
      btn      => btn,
      led      => led,
      disp_sel => disp_sel,
      sevseg   => sevseg
    );

end architecture;
