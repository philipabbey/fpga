-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Package used by 'test_external_signals'.
--
-- P A Abbey, 11 July 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package external_signals_pkg is

  type force_state is (RELEASED, FORCE1, FORCE2, FORCE3, FORCE4);

  -- Perform a sequence of forces to affect the simulation.
  --
  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out force_state
  );

end package;


library local;
  use local.testbench_pkg.wait_nr_ticks;

package body external_signals_pkg is

  procedure force_tests (
    signal clk   : in std_logic;
    signal state : out force_state
  ) is

    -- Illustration of use of aliases as a short hand when forcing
    alias int_in_tb_alias   : natural range 0 to 15 is  << signal .test_external_signals.int_in      : natural range 0 to 15 >>;
    alias int_in_dut_alias  : natural range 0 to 15 is  << signal .test_external_signals.dut.int_in  : natural range 0 to 15 >>;
    alias int_out_dut_alias : natural range 0 to 15 is  << signal .test_external_signals.dut.int_out : natural range 0 to 15 >>;
    alias int_out_tb_alias  : natural range 0 to 15 is  << signal .test_external_signals.int_out     : natural range 0 to 15 >>;

  begin

    state <= FORCE1;
    report "Forcing 'cnt_in' part 1";
    int_in_tb_alias <= force in 1;
    << signal .test_external_signals.vec_in : std_logic_vector(3 downto 0) >> <= force out "0001";
    wait_nr_ticks(clk, 5);

    state <= FORCE2;
    report "Forcing 'cnt_in' part 2";
    int_in_dut_alias <= force in 2;
    << signal .test_external_signals.dut.vec_in : std_logic_vector(3 downto 0) >> <= force out "0010";
    wait_nr_ticks(clk, 5);

    state <= FORCE3;
    report "Forcing 'cnt_in' part 3";
    int_out_dut_alias <= force in 3; -- Does now propagate to external output, unlike in process in 'test_external_signals'
    << signal .test_external_signals.dut.vec_out : std_logic_vector(3 downto 0) >> <= force out "0011";
    wait_nr_ticks(clk, 5);

    state <= FORCE4;
    report "Forcing 'cnt_in' part 4";
    int_out_tb_alias <= force in 4;
    << signal .test_external_signals.vec_out : std_logic_vector(3 downto 0) >> <= force out "0100";
    wait_nr_ticks(clk, 5);

    report "Releasing 'cnt_in'";
    state <= RELEASED;
    int_in_tb_alias <= release in;
    << signal .test_external_signals.vec_in : std_logic_vector(3 downto 0) >> <= release out;

    int_in_dut_alias <= release in;
    << signal .test_external_signals.dut.vec_in : std_logic_vector(3 downto 0) >> <= release out;

    int_out_dut_alias <= release in;
    << signal .test_external_signals.dut.vec_out : std_logic_vector(3 downto 0) >> <= release out;

    int_out_tb_alias <= release in;
    << signal .test_external_signals.vec_out : std_logic_vector(3 downto 0) >> <= release out;
    wait_nr_ticks(clk, 5);

  end procedure;

end package body;
