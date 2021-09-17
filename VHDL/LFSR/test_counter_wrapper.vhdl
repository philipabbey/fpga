entity test_counter_wrapper is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library local;
use local.testbench.all;

architecture behav of test_counter_wrapper is

  component lfsr_counter_wrapper is
    generic(
      max : positive range 3 TO positive'high
    );
    port(
      clk      : in  std_ulogic;
      reset    : in  std_ulogic;
      enable   : in  std_ulogic;
      finished : out std_ulogic
    );
  end component;

  -- Signal declarations
  signal clk      : std_ulogic := '0';
  signal reset    : std_ulogic := '0';
  signal enable   : std_ulogic := '0';
  signal finished : std_ulogic;

  constant max : natural := 250;

begin

  dut : lfsr_counter_wrapper
    generic map (
      max => max
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
