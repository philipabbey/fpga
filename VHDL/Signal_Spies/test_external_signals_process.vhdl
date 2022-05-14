-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for VHDL 2008 external signals using a basic process.
--
-- P A Abbey, 11 July 2021
--
-------------------------------------------------------------------------------------

entity test_external_signals_process is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_external_signals_process is

  signal clk     : std_logic;
  signal reset   : std_logic;
  signal int_in  : natural range 0 to 15;
  signal vec_in  : std_logic_vector(3 downto 0);
  signal int_out : natural range 0 to 15;
  signal int_spy : natural range 0 to 15;
  signal vec_out : std_logic_vector(3 downto 0);
  signal vec_spy : std_logic_vector(3 downto 0);

  -- # ** Warning: (vsim-8523) Cannot reference the signal "/test_external_signals_process/dut/int_out_i" before it has been elaborated.
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_process File: .../Signal_Spies/test_external_signals_process.vhdl
  alias int_spy_alias : natural range 0 to 15 is << signal .test_external_signals_process.dut.int_out_i : natural range 0 to 15 >>;

  -- # ** Warning: (vsim-8523) Cannot reference the signal "/test_external_signals_process/dut/vec_out_i" before it has been elaborated.
  -- #    Time: 0 ps  Iteration: 0  Instance: /test_external_signals_process File: .../Signal_Spies/test_external_signals_process.vhdl
  alias vec_spy_alias : std_logic_vector(3 downto 0) is << signal .test_external_signals_process.dut.vec_out_i : std_logic_vector(3 downto 0) >>;

  -- Illustration of use of aliases as a short hand when forcing
  alias int_in_tb_alias   : natural range 0 to 15 is  << signal .test_external_signals_process.int_in      : natural range 0 to 15 >>;
  alias int_in_dut_alias  : natural range 0 to 15 is  << signal .test_external_signals_process.dut.int_in  : natural range 0 to 15 >>;
  alias int_out_dut_alias : natural range 0 to 15 is  << signal .test_external_signals_process.dut.int_out : natural range 0 to 15 >>;
  alias int_out_tb_alias  : natural range 0 to 15 is  << signal .test_external_signals_process.int_out     : natural range 0 to 15 >>;

  type force_state is (RELEASED, FORCE1, FORCE2, FORCE3, FORCE4);
  signal state : force_state := RELEASED;

begin

  -- VHDL External Signal
  int_spy <= << signal .test_external_signals_process.dut.int_out_i : natural range 0 to 15 >>;
  vec_spy <= << signal .test_external_signals_process.dut.vec_out_i : std_logic_vector(3 downto 0) >>;

  -- Causes 'X's in multiply driven net(s) when defined as a vector of '0's and '1's.
  << signal .test_external_signals_process.dut.vec_out_i : std_logic_vector(3 downto 0) >> <= "ZZZZ";

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

    state <= FORCE1;
    report "Forcing 'cnt_in' part 1";
    int_in_tb_alias <= force in 1;
    << signal .test_external_signals_process.vec_in : std_logic_vector(3 downto 0) >> <= force out "0001";
    wait_nr_ticks(clk, 5);

    state <= FORCE2;
    report "Forcing 'cnt_in' part 2";
    int_in_dut_alias <= force in 2;
    << signal .test_external_signals_process.dut.vec_in : std_logic_vector(3 downto 0) >> <= force out "0010";
    wait_nr_ticks(clk, 5);

    state <= FORCE3;
    report "Forcing 'cnt_in' part 3";
    int_out_dut_alias <= force in 3; -- Does now propagate to external output, unlike in process in 'test_external_signals_process'
    << signal .test_external_signals_process.dut.vec_out : std_logic_vector(3 downto 0) >> <= force out "0011";
    wait_nr_ticks(clk, 5);

    state <= FORCE4;
    report "Forcing 'cnt_in' part 4";
    int_out_tb_alias <= force in 4;
    << signal .test_external_signals_process.vec_out : std_logic_vector(3 downto 0) >> <= force out "0100";
    wait_nr_ticks(clk, 5);

    report "Releasing 'cnt_in'";
    state <= RELEASED;
    int_in_tb_alias <= release in;
    << signal .test_external_signals_process.vec_in : std_logic_vector(3 downto 0) >> <= release out;

    int_in_dut_alias <= release in;
    << signal .test_external_signals_process.dut.vec_in : std_logic_vector(3 downto 0) >> <= release out;

    int_out_dut_alias <= release in;
    << signal .test_external_signals_process.dut.vec_out : std_logic_vector(3 downto 0) >> <= release out;

    int_out_tb_alias <= release in;
    << signal .test_external_signals_process.vec_out : std_logic_vector(3 downto 0) >> <= release out;
    wait_nr_ticks(clk, 5);

    stop_clocks;
    wait;
  end process;

end architecture;
