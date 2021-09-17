entity test_force is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
library local;
use local.testbench.all;
library modelsim_lib;

architecture test of test_force is

  constant verbose_c : integer := 0;

  signal clk     : std_logic;
  signal deposit : std_logic;
  signal freeze  : std_logic;
  signal drive   : std_logic;

  type force_state is (INITIALISED, FORCED, ASSERTED, RELEASED);
  signal state : force_state;

begin

  clock(clk, 5 ns, 5 ns);

  process
  begin
    state   <= INITIALISED;
    deposit <= '0';
    freeze  <= '0';
    drive   <= '0';
    wait_nr_ticks(clk, 3);

    state <= FORCED;
    report "Forcing";
    modelsim_lib.util.signal_force(
      destination_signal => "/test_force/deposit",
      force_value        => "1", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.deposit, -- freeze | drive | deposit
      cancel_period      => -1 ms, -- FORCE_DELAY + Increment
      verbose            => verbose_c
    );

    modelsim_lib.util.signal_force(
      destination_signal => "/test_force/freeze",
      force_value        => "1", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze, -- freeze | drive | deposit
      cancel_period      => -1 ms, -- FORCE_DELAY + Increment
      verbose            => verbose_c
    );

    modelsim_lib.util.signal_force(
      destination_signal => "/test_force/drive",
      force_value        => "1", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.drive, -- freeze | drive | deposit
      cancel_period      => -1 ms, -- FORCE_DELAY + Increment
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 3);

    state   <= ASSERTED;
    report "Re-asserting";
    deposit <= '0';
    freeze  <= '0';
    drive   <= '0';
    wait_nr_ticks(clk, 3);

    state <= RELEASED;
    report "Releasing";
    modelsim_lib.util.signal_release (
      destination_signal => "/test_force/deposit",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_force/freeze",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_force/drive",
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 3);

    stop_clocks;
    wait;
  end process;

end architecture;
