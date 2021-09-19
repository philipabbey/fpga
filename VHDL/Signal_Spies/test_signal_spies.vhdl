-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for ModelSim's "Signal Spies" with procedures from 'signal_spies_pkg'.
--
-- P A Abbey, 11 July 2021
--
-------------------------------------------------------------------------------------

entity test_signal_spies is
end entity;


library ieee;
use ieee.std_logic_1164.all;
library local;
use local.testbench_pkg.all;
library modelsim_lib;

architecture behav of test_signal_spies is

  signal clk     : std_logic;
  signal reset   : std_logic;
  signal int_in  : natural range 0 to 15;
  signal vec_in  : std_logic_vector(3 downto 0);
  signal int_out : natural range 0 to 15;
  signal int_spy : natural range 0 to 15;
  signal vec_out : std_logic_vector(3 downto 0);
  signal vec_spy : std_logic_vector(3 downto 0);

  signal state : work.signal_spies_pkg.force_state := work.signal_spies_pkg.RELEASED;

begin

  dut : entity work.dut_register
    port map (
      clk     => clk,
      reset   => reset,
      int_in  => int_in,
      vec_in  => vec_in,
      int_out => int_out,
      vec_out => vec_out
    );

  clock(clk, 5 ns, 5 ns);

  -- For VHDL procedures, you should place all init_signal_spy calls in a VHDL process and code
  -- this VHDL process correctly so that it is executed only once. The VHDL process should not be
  -- sensitive to any signals and should contain only init_signal_spy calls and a simple wait
  -- statement. The process will execute once and then wait forever, which is the desired behavior.
  --
  -- These procedures work fine outside a process too. The requirement to be inside an execute
  -- once only process seems to be overstated.
  process
  begin
    work.signal_spies_pkg.init_spies;

    -- Initialise the inputs
    state <= work.signal_spies_pkg.RELEASED;
    reset  <= '0';
    int_in <= 0;
    vec_in <= "0000";
    wait_nr_ticks(clk, 1);
    reset  <= '1';
    wait_nr_ticks(clk, 1);
    reset  <= '0';
    wait_nr_ticks(clk, 3);

    work.signal_spies_pkg.force_tests(clk, state);

    stop_clocks;
    wait;
  end process;

end architecture;
