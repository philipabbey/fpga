entity test_util_comands is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
library local;
use local.testbench.all;
library modelsim_lib;

architecture test of test_util_comands is

  constant verbose_c : integer := 0;

  signal clk            : std_logic;
  signal test_subject1  : std_logic;
  signal spy1           : std_logic;
  signal test_subject2  : std_logic := '0';
  signal spy2inertial5  : std_logic; --  5 ns inertial delay
  signal spy2inertial11 : std_logic; -- 11 ns inertial delay
  signal spy2transport  : std_logic; -- 15 ns transport delay
  signal test_driven    : std_logic;
  signal test_driver    : std_logic;

  signal state : work.util_commands_pkg.spy_state;

begin

  clock(clk, 5 ns, 5 ns);
  wiggle_r(test_subject1, clk, 0.5);
  wiggle_r(test_subject2, clk, 0.5);
  wiggle_r(test_driver, clk, 0.4);

  spy1        <= 'X'; -- Does not compete with mirrored value from signal spy below. Get's overridden
  test_driven <= '1'; -- Competing driver causes 'X'.

  -- For VHDL procedures, you should place all init_signal_spy calls in a VHDL process and code
  -- this VHDL process correctly so that it is executed only once. The VHDL process should not be
  -- sensitive to any signals and should contain only init_signal_spy calls and a simple wait
  -- statement. The process will execute once and then wait forever, which is the desired behavior.
  --
  -- In practice you just need the calls to init_signal_spy before enable_signal_spy and
  -- disable_signal_spy.
  process
  begin

    -- As long as the spy is initalised *before* a call to enable_signal_spy or disable_signal_spy there's no error
    wait_nr_ticks(clk, 2);

    work.util_commands_pkg.init_spies;
    work.util_commands_pkg.force_tests(clk, state);

    stop_clocks;
    wait;
  end process;

end architecture;
