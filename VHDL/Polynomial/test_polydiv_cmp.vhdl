-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the alternative multiple bit per clock cycle CRC component.
--
-- P A Abbey, 25 October 2020
--
-------------------------------------------------------------------------------------

entity test_polydiv_cmp is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.testbench_pkg.all;

architecture test of test_polydiv_cmp is

  -- No reflections in or out and no final XOR (CRC-32/MPEG-2), initialised to ones.
  -- NB. Specify the input as Hexadecimal not ASCII
  -- Results correctly compare with:
  --  * https://www.texttool.com/crc-online
  --  * https://crccalc.com/?crc=123456789A&method=CRC-32&datatype=1&outtype=0
  constant message_c : std_ulogic_vector := x"123456789A";
  -- 1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32 (Written in reverse)
  -- "100000100110000010001110110110111"
  constant poly_c    : std_ulogic_vector := 33x"1_04C11DB7";

  signal reset         : std_ulogic;
  signal clk           : std_ulogic;
  signal data_in       : std_ulogic_vector(0 to 7);
  signal data_in_i     : std_ulogic_vector(data_in'length-1 downto 0);
  signal data_valid_in : std_ulogic;
  signal data_out      : std_ulogic_vector(poly_c'length-2 downto 0);
  signal data_out_ol   : std_ulogic_vector(poly_c'length-2 downto 0);

begin

  data_in_i <= data_in;

  dut : entity work.polydiv(rtl2)
    generic map(
      poly_g => poly_c
    )
    port map(
      clk           => clk,
      reset         => reset,
      data_in       => data_in_i,
      data_valid_in => data_valid_in,
      data_out      => data_out
    );

  -------------------------------------------------------------------------------
  -- OutputLogic.com
  -- CRC module for data(7:0)
  --   lfsr(31:0)=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
  -------------------------------------------------------------------------------
  dut_ol : entity work.crc
    port map (
      clk     => clk,
      rst     => reset,
      data_in => data_in_i,
      crc_en  => data_valid_in,
      crc_out => data_out_ol
    );

  clock(clk, 5 ns, 5 ns);

  assert ((message_c'length / data_in'length) * data_in'length) = message_c'length
    report "The message length must be divisible by data_in's length."
    severity failure;

  process
  begin
    reset         <= '0';
    data_in       <= (others => '0');
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    toggle_r(reset, clk, 2);
    wait_nr_ticks(clk, 2);
    for i in 0 to (message_c'length/data_in'length)-1 loop
      data_in       <= message_c(i*data_in'length to i*data_in'length+data_in'length-1);
      data_valid_in <= '1';
      wait_nr_ticks(clk, 1);
    end loop;
    data_valid_in <= '0';
    wait_nr_ticks(clk, 1);
    if data_out = data_out_ol then
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
