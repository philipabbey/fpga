-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the non-pipelined adder tree of complex_t type.
--
-- P A Abbey, 10 September 2021
--
-------------------------------------------------------------------------------------

entity test_adder_tree_complex is
end entity;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use work.fft_sfixed_pkg.all;
use work.adder_tree_pkg.all;
use work.test_fft_pkg.complex_str;
library local;
use local.testbench_pkg.all;


architecture test of test_adder_tree_complex is

  subtype negative is integer range integer'low to 0;

  type adder_tree_item_t is record
    num_operands : positive;
    input_high   : natural;
    input_low    : negative;
  end record;

  type adder_tree_array_t is array(natural range <>) of adder_tree_item_t;

  constant adder_tree_array_c : adder_tree_array_t := (
    -- (num_operands, input_high, input_low)
    (2,  8, -1),
    (3,  9, -2),
    (4, 10, -3),
    (5, 11, -1),
    (6, 12, -2),
    (7, 13, -3)
  );

  constant ones : std_logic_vector(adder_tree_array_c'range) := (others => '1');

  function sum_inputs(i : complex_arr_t) return complex_t is
    variable sum : complex_t(
      re(output_bits(i(i'low).re'high, i'length) downto i(i'low).re'low),
      im(output_bits(i(i'low).im'high, i'length) downto i(i'low).im'low)
    ) := (
      re => (others => '0'),
      im => (others => '0')
    );
  begin
    for j in i'range loop
      sum := resize(sum + i(j), sum.re);
    end loop;
    return sum;
  end function;

  signal finished : std_logic := '0';
  signal passed   : std_logic_vector(adder_tree_array_c'range) := (others => '1');
  
  constant tolerance_c : real := 0.02;

begin

  duts : for l in adder_tree_array_c'range generate
    constant i_t : sfixed(adder_tree_array_c(l).input_high downto adder_tree_array_c(l).input_low) := (others => '0');
    constant o_t : sfixed(output_bits(adder_tree_array_c(l).input_high, adder_tree_array_c(l).num_operands) downto adder_tree_array_c(l).input_low) := (others => '0');

    signal i : complex_arr_t(0 to adder_tree_array_c(l).num_operands-1)(
      re(i_t'range),
      im(i_t'range)
    );
    signal o : complex_t(
      re(o_t'range),
      im(o_t'range)
    );

  begin

    adder_tree_i : entity work.adder_tree_complex
      generic map (
        num_operands_g => adder_tree_array_c(l).num_operands,
        template_g     => i_t
      )
      port map (
        i => i,
        o => o
      );

    test : process

      variable exp : complex_t(
        re(o_t'range),
        im(o_t'range)
      );

    begin
      for j in 0 to adder_tree_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real(j+1) / 2.0,
          real(j+1) / 3.0,
          i(j).re
        );
      end loop;

      wait for 20 ns;

      exp := sum_inputs(i);
      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add maximum values: +(2**n)-1, NB. top bit is sign bit
      for j in 0 to adder_tree_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real((2**i_t'high)-1),
          real((2**i_t'high)-1),
          i_t
        );
      end loop;
      exp.re := to_sfixed((2**(i_t'high)-1)*adder_tree_array_c(l).num_operands, o_t);
      exp.im := exp.re;

      wait for 20 ns;

      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add minimum values: -2**(n-1), NB. top bit is sign bit
      for j in 0 to adder_tree_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real(-2**i_t'high),
          real(-2**i_t'high),
          i_t
        );
      end loop;
      exp.re := to_sfixed((-2**i_t'high) * adder_tree_array_c(l).num_operands, o_t);
      exp.im := exp.re;

      wait for 20 ns;

      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      finished <= '1';

      wait;
    end process;

  end generate;


  check : process
  begin
    wait until finished = '1';
    if passed = ones then
      report "All PASSED";
    else
      report "Something FAILED" severity warning;
    end if;
    wait;
  end process;

end architecture;
