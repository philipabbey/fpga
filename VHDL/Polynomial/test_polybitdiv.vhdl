-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the single bit per clock cycle polynomial division component.
--
-- P A Abbey, 12 August 2019
--
-------------------------------------------------------------------------------------

entity test_polybitdiv is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_polybitdiv is

  -- Example from https://en.wikipedia.org/wiki/Cyclic_redundancy_check
  -- constant message_c    : std_ulogic_vector := "11010011101100" & "000"; -- message padded by 3 bits
  -- constant poly_c       : std_ulogic_vector := "1011";
  -- constant answer_c     : std_ulogic_vector := "100";
  -- http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=11010011101100000&den=1011&f=d&e=1&p=1&m=1

  constant message_c    : std_ulogic_vector := "101001011010";
  constant poly_c       : std_ulogic_vector := "11010";
  constant answer_c     : std_ulogic_vector := "1000";

  -- Taken example from https://math.stackexchange.com/questions/682301/modulo-2-binary-division-xor-not-subtracting-method
  -- Which looks spookily like a copy & paste from http://www.ee.unb.ca/cgi-bin/tervo/calc.pl?num=111001010000&den=11011&f=d&e=1&p=1&m=1
  --
  --     10101100 quotient
  -- ------------
  -- 111001010000 dividend  x^11+x^10+x^9+x^6+x^4
  -- 11011        divisor   x^4+x^3+x+1
  -- -----
  --  01111
  --  00000  reg'high = 0
  --  -----
  --   11110
  --   11011  reg'high = 1
  --   -----
  --    01011
  --    00000  reg'high = 0
  --    -----
  --     10110
  --     11011  reg'high = 1
  --     -----
  --      11010
  --      11011  reg'high = 1
  --      -----
  --       00010
  --       00000  reg'high = 0
  --       -----
  --        00100
  --        00000  reg'high = 0
  --        -----
  --         0100 * remainder *

  signal reset         : std_ulogic;
  signal clk           : std_ulogic;
  signal data_in       : std_ulogic;
  signal data_valid_in : std_ulogic;
  signal data_out      : std_ulogic_vector(poly_c'length-2 downto 0);

begin

  dut : entity work.polybitdiv
    generic map(
      len_g => poly_c'length
    )
    port map(
      clk           => clk,
      reset         => reset,
      poly          => poly_c,
      data_in       => data_in,
      data_valid_in => data_valid_in,
      data_out      => data_out
    );

  clock(clk, 5 ns, 5 ns);

  process
  begin
    reset         <= '0';
    data_in       <= '0';
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);
    wait_nr_ticks(clk, 2);
    for i in 0 to message_c'length-1 loop
      data_in       <= message_c(i);
      data_valid_in <= '1';
      wait_nr_ticks(clk, 1);
    end loop;
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    if data_out = answer_c then
      report "SUCCESS - remainder supplied matches expected" severity note;
    else
      report "FAILED - remainder supplied does not match expected" severity warning;
    end if;
    wait_nr_ticks(clk, 4);
    stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;

end architecture;
