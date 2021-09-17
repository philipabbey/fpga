library ieee;
use ieee.std_logic_1164.all;
library modelsim_lib;
library local;
use local.testbench.all;

package signal_spies_pkg is

  constant verbose_c : integer := 0;

  type force_state is (RELEASED, FORCE1, FORCE2, FORCE3, FORCE4);

  procedure init_spies;

  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out force_state
  );

end package;

package body signal_spies_pkg is

  procedure init_spies is
  begin

    modelsim_lib.util.init_signal_spy(
        source_signal      => "/test_signal_spies/dut/int_out_i",
        destination_signal => "int_spy",
        verbose            => work.signal_spies_pkg.verbose_c,
        control_state      => -1
    );

    modelsim_lib.util.init_signal_spy(
        source_signal      => "/test_signal_spies/dut/vec_out_i",
        destination_signal => "vec_spy",
        verbose            => work.signal_spies_pkg.verbose_c,
        control_state      => -1
    );

  end procedure;

  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out force_state
  ) is
  begin

    state <= FORCE1;
    report "Forcing 'cnt_in' part 1";
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/int_in",
      force_value        => "1", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.deposit, -- freeze | drive | deposit
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/vec_in",
      force_value        => "0001", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.deposit,
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 5);

    state <= FORCE2;
    report "Forcing 'cnt_in' part 2";

    -- $ verror vsim-8780
    --
    -- vsim Message # 8780:
    -- This warning is suppressed by default in the modelsim.ini file.
    -- Commenting out the suppress statement will activate the message.
    -- The TCL force command follows Verilog semantics of a single wire.
    -- This warning will appear when force applies the wire model to force
    -- a higher level signal instead of the one specified in the force command.
    --
    -- # ** Warning: (vsim-8780) Forcing /test_signal_spies/int_in as root of /test_signal_spies/dut/int_in specified in the force.
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/dut/int_in",
      force_value        => "2", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    -- # ** Warning: (vsim-8780) Forcing /test_signal_spies/vec_in as root of /test_signal_spies/dut/vec_in specified in the force.
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/dut/vec_in",
      force_value        => "0010", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 5);

    state <= FORCE3;
    report "Forcing 'cnt_in' part 3";
    -- # ** Warning: (vsim-8780) Forcing /test_signal_spies/int_out as root of /test_signal_spies/dut/int_out specified in the force.
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/dut/int_out",
      force_value        => "3",   -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    -- # ** Warning: (vsim-8780) Forcing /test_signal_spies/vec_out as root of /test_signal_spies/dut/vec_out specified in the force.
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/dut/vec_out",
      force_value        => "0011", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms,  -- force_delay + Increment
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 5);

    state <= FORCE4;
    report "Forcing 'cnt_in' part 4";
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/int_out",
      force_value        => "4",   -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms, -- force_delay + Increment
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_force(
      destination_signal => "/test_signal_spies/vec_out",
      force_value        => "0100", -- NB. VHDL string type, don't use '0' for bits.
      force_delay        => 0 ns,
      force_type         => modelsim_lib.util.freeze,
      cancel_period      => -1 ms,  -- force_delay + Increment
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 5);

    report "Releasing 'cnt_in'";
    state <= RELEASED;
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/int_in",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/vec_in",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/dut/int_in",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/dut/vec_in",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/dut/int_out",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/dut/vec_out",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/int_out",
      verbose            => verbose_c
    );
    modelsim_lib.util.signal_release (
      destination_signal => "/test_signal_spies/vec_out",
      verbose            => verbose_c
    );
    wait_nr_ticks(clk, 5);

  end procedure;

end package body;
