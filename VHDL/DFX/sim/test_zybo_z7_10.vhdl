-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Top level test bench for partial reconfiguration demonstration.
--
-- P A Abbey, 12 February 2025
--
-------------------------------------------------------------------------------------

entity test_zybo_z7_10 is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library std;
library local;
  use local.testbench_pkg.all;

architecture test of test_zybo_z7_10 is

  signal clk      : std_logic                    := '0';
  signal sw       : std_logic_vector(3 downto 0) := "0000";
  signal btn      : std_logic_vector(3 downto 0) := "0000";
  signal leds     : std_logic_vector(3 downto 0) := "0000";
  signal disp_sel : std_logic                    := '0';
  signal sevseg   : std_logic_vector(6 downto 0) := "0000000";

begin

  clkgen : clock(clk, 8 ns);

  dut : entity work.zybo_z7_10
    generic map (
      sim_g => true
    )
    port map (
      clk_port => clk,
      sw       => sw,
      btn      => btn,
      led      => leds,
      disp_sel => disp_sel,
      sevseg   => sevseg
    );

  process
  begin
    sw  <= "0000";
    btn <= "0000";
    -- Wait for PLL to lock
    wait_nr_ticks(clk, 100);
    -- Hold the value from the RM in the static partition
    btn  <= "0001";
    wait_nr_ticks(clk, 10);
    btn  <= "0000";
    wait_nr_ticks(clk, 40);
    
    --stop_clocks;
    -- PLL IP Core won't stop creating events, must use 'stop' instead of 'stop_clocks'.
    std.env.stop;
    wait;
  end process;

end architecture;
