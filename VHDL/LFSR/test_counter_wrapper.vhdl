-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the wrapper code used for 'lfsr_counter_wrapper' component.
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

entity test_counter_wrapper is
end entity;


library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library local;
use local.testbench_pkg.all;

architecture test of test_counter_wrapper is

  -- Signal declarations
  signal clk      : std_ulogic := '0';
  signal reset    : std_ulogic := '0';
  signal enable   : std_ulogic := '0';
  signal finished : std_ulogic;

  constant max_c : natural := 250;

begin

  dut : entity work.lfsr_counter_wrapper
    generic map (
      max_g => max_c
    )
    port map (
      clk      => clk,
      reset    => reset,
      enable   => enable,
      finished => finished
    );

  clock(clk, 5 ns, 5 ns);
  
  process
    variable res : line;
  begin
    -- Expect to see 'X's from before the reset
    wait until rising_edge(clk);
    -- Initialise the inputs
    enable <= '0';
    wait until rising_edge(clk);
    toggle_r(reset, clk, 2);

    wait until rising_edge(clk);
    enable <= '1';
    wait until finished = '1';
    wait until finished = '1';
    write(res, string'("End of simulation."));
    writeline(OUTPUT, res);
    wait_nr_ticks(clk, 2);

    -- simulation stops here
    stop_clocks;
  end process;
  
end architecture;
