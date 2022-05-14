-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado register colouring by clock
-- source.
--
-- P A Abbey, 21 May 2021
--
-------------------------------------------------------------------------------------

entity test_transfer is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;
library std;
  use std.env.all;

architecture test of test_transfer is

  constant num_bits1_c : integer := 2;
  constant num_bits2_c : integer := 4;

  signal clk_src1   : std_logic;
  signal reset_src1 : std_logic;
  signal clk_src2   : std_logic;
  signal reset_src2 : std_logic;
  signal clk_dest   : std_logic;
  signal reset_dest : std_logic;
  signal flags_src1 : std_logic_vector(num_bits1_c-1 downto 0);
  signal flags_src2 : std_logic_vector(num_bits2_c-1 downto 0);
  signal flags_out  : std_logic_vector(num_bits1_c+num_bits2_c-1 downto 0);

begin

  clkgen_src1 : clock(clk_src1, 4 ns, 0.5, 1 ns);
  clkgen_src2 : clock(clk_src2, 6 ns, 0.5, 3 ns);
  clkgen_dest : clock(clk_dest, 10 ns);

  dut : entity work.transfer
    generic map (
      num_bits1 => num_bits1_c,
      num_bits2 => num_bits2_c
    )
    port map (
      clk_src1   => clk_src1,
      reset_src1 => reset_src1,
      clk_src2   => clk_src2,
      reset_src2 => reset_src2,
      clk_dest   => clk_dest,
      reset_dest => reset_dest,
      flags_src1 => flags_src1,
      flags_src2 => flags_src2,
      flags_out  => flags_out
    );

    process
    begin
      reset_src1 <= '1';
      reset_src2 <= '1';
      reset_dest <= '1';
      flags_src1 <= (others => '0');
      flags_src2 <= (others => '0');
      wait_nr_ticks(clk_src1, 4);
      reset_src1 <= '0';
      wait_nr_ticks(clk_src2, 1);
      reset_src2 <= '0';
      wait_nr_ticks(clk_dest, 1);
      reset_dest <= '0';

      wait_nr_ticks(clk_src1, 4);
      for i in flags_src1'range loop
        flags_src1(i) <= '1';
        wait_nr_ticks(clk_src1, 1);
        flags_src1(i) <= '0';
        wait_nr_ticks(clk_src1, 2);
      end loop;

      wait_nr_ticks(clk_src2, 4);
      for i in flags_src2'range loop
        flags_src2(i) <= '1';
        wait_nr_ticks(clk_src2, 1);
        flags_src2(i) <= '0';
        wait_nr_ticks(clk_src2, 2);
      end loop;

      wait_nr_ticks(clk_dest, 10);
      stop;
      wait;
    end process;

end architecture;
