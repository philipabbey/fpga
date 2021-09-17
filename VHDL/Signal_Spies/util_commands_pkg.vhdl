library ieee;
use ieee.std_logic_1164.all;
library modelsim_lib;
library local;
use local.testbench.all;

package util_commands_pkg is

  constant verbose_c : integer := 0;

  type spy_state is (ENABLED, DISABLED);

  procedure init_spies;

  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out spy_state
  );

end package;

package body util_commands_pkg is

  procedure init_spies is
  begin

    -- If we wait 15 clocks we get the following error.
    -- # ** Error: (vsim-3861) enable_signal_spy [.../test_util_comands.vhdl] : Unable to find an associated init_signal_spy to enable/disable.

    -- control_state
    --
    -- Optional integer. Possible values are -1, 0, or 1. Specifies whether or not you want the
    -- ability to enable/disable mirroring of values and, if so, specifies the initial state.
    --
    -- * -1 - no ability to enable/disable and mirroring is enabled. (default)
    -- *  0 - turns on the ability to enable/disable and initially disables mirroring.
    -- *  1 - turns on the ability to enable/disable and initially enables mirroring.
    modelsim_lib.util.init_signal_spy(
      source_signal      => "/test_util_comands/test_subject1",
      destination_signal => "/test_util_comands/spy1", -- Mirror
      verbose            => verbose_c,
      control_state      => 0 -- Start disabled
    );

    -- For the VHDL init_signal_driver procedure, when driving a Verilog net, the only delay_type
    -- allowed is inertial. If you set the delay type to mti_transport, the setting will be
    -- ignored and the delay type will be mti_inertial.
    modelsim_lib.util.init_signal_driver(
      source_signal      => "/test_util_comands/test_subject2", -- Driver
      destination_signal => "/test_util_comands/spy2inertial5", -- Driven
      -- With 'MTI_INERTIAL', works up to 10 ns which gives a 1 clock period delay. After that
      -- the inertial effect seems to kick in with the value being some function of the signal
      -- history.
      delay              => 5 ns,
      -- Either modelsim_lib.util.MTI_INERTIAL or modelsim_lib.util.MTI_TRANSPORT
      delay_mode         => modelsim_lib.util.MTI_INERTIAL,
      verbose            => verbose_c
    );
    modelsim_lib.util.init_signal_driver(
      source_signal      => "/test_util_comands/test_subject2",  -- Driver
      destination_signal => "/test_util_comands/spy2inertial11", -- Driven
      -- Ensure less than the rate of change!
      delay              => 11 ns,
      -- Either modelsim_lib.util.MTI_INERTIAL or modelsim_lib.util.MTI_TRANSPORT
      delay_mode         => modelsim_lib.util.MTI_INERTIAL,
      verbose            => verbose_c
    );

    modelsim_lib.util.init_signal_driver(
      source_signal      => "/test_util_comands/test_subject2", -- Driver
      destination_signal => "/test_util_comands/spy2transport", -- Driven
      -- No constraint on 'delay' parameter with 'MTI_TRANSPORT'
      delay              => 15 ns,
      -- Either modelsim_lib.util.MTI_INERTIAL or modelsim_lib.util.MTI_TRANSPORT
      delay_mode         => modelsim_lib.util.MTI_TRANSPORT,
      verbose            => verbose_c
    );

    -- Demonstrate the difference between init_signal_spy & init_signal_driver
    modelsim_lib.util.init_signal_driver(
      source_signal      => "/test_util_comands/test_driver", -- Driver
      destination_signal => "/test_util_comands/test_driven", -- Driven
      delay              => 3 ns,
      delay_mode         => modelsim_lib.util.MTI_INERTIAL,
      verbose            => verbose_c
    );

  end procedure;

  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out spy_state
  ) is
  begin

    -- See what it looks like at the start
    state <= DISABLED;
    wait_nr_ticks(clk, 10);

    modelsim_lib.util.enable_signal_spy(
      source_signal      => "/test_util_comands/test_subject1",
      destination_signal => "/test_util_comands/spy1",
      verbose            => verbose_c
    );
    state <= ENABLED;
    wait_nr_ticks(clk, 10);

    modelsim_lib.util.disable_signal_spy(
      source_signal      => "/test_util_comands/test_subject1",
      destination_signal => "/test_util_comands/spy1",
      verbose            => verbose_c
    );
    state <= DISABLED;
    wait_nr_ticks(clk, 10);

    modelsim_lib.util.enable_signal_spy(
      source_signal      => "/test_util_comands/test_subject1",
      destination_signal => "/test_util_comands/spy1",
      verbose            => verbose_c
    );
    state <= ENABLED;
    wait_nr_ticks(clk, 10);

    modelsim_lib.util.disable_signal_spy(
      source_signal      => "/test_util_comands/test_subject1",
      destination_signal => "/test_util_comands/spy1",
      verbose            => verbose_c
    );
    state <= DISABLED;
    wait_nr_ticks(clk, 10);

  end procedure;

end package body;
