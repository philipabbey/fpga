-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for VHDL 2008 external signals using procedures from
-- 'external_signals_pkg'.
--
-- P A Abbey, 11 July 2021
--
-------------------------------------------------------------------------------------

entity test_external_signals_procedure is
end entity;


library ieee;
use ieee.std_logic_1164.all;
library local;
use local.testbench_pkg.all;

architecture test of test_external_signals_procedure is

  signal clk     : std_logic;
  signal reset   : std_logic;
  signal int_in  : natural range 0 to 15;
  signal vec_in  : std_logic_vector(3 downto 0);
  signal int_out : natural range 0 to 15;
  signal int_spy : natural range 0 to 15;
  signal vec_out : std_logic_vector(3 downto 0);
  signal vec_spy : std_logic_vector(3 downto 0);

  -- # ** Warning: (vsim-8523) Cannot reference the signal "/test_external_signals_procedure/dut/int_out_i" before it has been elaborated.
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_procedure File: .../Signal_Spies/test_external_signals_procedure.vhdl
  alias int_spy_alias : natural range 0 to 15 is << signal .test_external_signals_procedure.dut.int_out_i : natural range 0 to 15 >>;

  -- # ** Warning: (vsim-8523) Cannot reference the signal "/test_external_signals_procedure/dut/vec_out_i" before it has been elaborated.
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_procedure File: .../Signal_Spies/test_external_signals_procedure.vhdl
  alias vec_spy_alias : std_logic_vector(3 downto 0) is << signal .test_external_signals_procedure.dut.vec_out_i : std_logic_vector(3 downto 0) >>;

  signal state : work.external_signals_pkg.force_state := work.external_signals_pkg.RELEASED;

begin

  -- VHDL External Signal
  int_spy <= << signal .test_external_signals_procedure.dut.int_out_i : natural range 0 to 15 >>;
  vec_spy <= << signal .test_external_signals_procedure.dut.vec_out_i : std_logic_vector(3 downto 0) >>;

  -- # ** Error: (vsim-3344) Signal "/test_external_signals_procedure/dut/int_out_i" has multiple drivers but is not a resolved signal.
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_procedure/dut
  -- # ** Note: Signal "/test_external_signals_procedure/dut/int_out_i" has an existing driver:
  -- #          Process: /test_external_signals_procedure/line__66
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_procedure/dut
  -- # No Design Loaded!
--  << signal .test_external_signals_procedure.dut.int_out_i : natural range 0 to 15 >> <= 0;

  -- Causes 'X's in multiply driven net(s)
  << signal .test_external_signals_procedure.dut.vec_out_i : std_logic_vector(3 downto 0) >> <= "ZZZZ";

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

  process
  begin
    -- Initialise the inputs
    reset  <= '0';
    int_in <= 0;
    vec_in <= "0000";
    wait_nr_ticks(clk, 1);
    reset  <= '1';
    wait_nr_ticks(clk, 1);
    reset  <= '0';
    wait_nr_ticks(clk, 3);

    work.external_signals_pkg.force_tests(clk, state);

    stop_clocks;
    wait;
  end process;

end architecture;
