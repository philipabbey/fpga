entity test_adder_tree is
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library local;
use local.testbench.all;
use work.adder_tree_pkg.all;

architecture test of test_adder_tree is

  type adder_tree_item_t is record
    num_coeffs  : positive;
    input_width : positive;
  end record;

  type adder_tree_array_t is array(natural range <>) of adder_tree_item_t;

  constant adder_tree_array : adder_tree_array_t := (
    -- (num_coeffs, input_width)
    (2,  8),
    (3,  9),
    (4, 10),
    (5, 11),
    (6, 12),
    (7, 13)
  );

  constant ones : std_logic_vector(adder_tree_array'range) := (others => '1');

  function sum_inputs(i : input_arr_t) return signed is
    variable sum : signed(i(0)'range) := (others => '0');
  begin
    for j in i'range loop
      sum := sum + i(j);
    end loop;
    return sum;
  end function;

  signal finished : std_logic := '0';
  signal passed   : std_logic_vector(adder_tree_array'range) := (others => '1');

begin

  duts : for l in adder_tree_array'range generate

    signal i : input_arr_t(0 to adder_tree_array(l).num_coeffs-1)(adder_tree_array(l).input_width-1 downto 0);
    signal o : signed(output_bits(adder_tree_array(l).input_width, adder_tree_array(l).num_coeffs)-1 downto 0);

  begin

    adder_tree_i : entity work.adder_tree
      generic map (
        num_coeffs_g  => adder_tree_array(l).num_coeffs,
        input_width_g => adder_tree_array(l).input_width
      )
      port map (
        i => i,
        o => o
      );

    test : process

      variable exp : integer := 0;

    begin
      for j in 0 to adder_tree_array(l).num_coeffs-1 loop
        i(j) <= to_signed(j+1, adder_tree_array(l).input_width);
      end loop;

      wait for 20 ns;

      if o = sum_inputs(i) then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & integer'image(to_integer(sum_inputs(i))) & " Read: " & integer'image(to_integer(o))
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add maximum values: +(2**(n-1))-1
      for j in 0 to adder_tree_array(l).num_coeffs-1 loop
        i(j) <= to_signed(2**(i(j)'length-1)-1, adder_tree_array(l).input_width);
      end loop;
      exp := (2**(i(0)'length-1)-1)*adder_tree_array(l).num_coeffs;

      wait for 20 ns;

      if to_integer(o) = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & integer'image(exp) & " Read: " & integer'image(to_integer(o))
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add minimum values: -2**(n-1)
      for j in 0 to adder_tree_array(l).num_coeffs-1 loop
        i(j) <= to_signed(-2**(i(j)'length-1), adder_tree_array(l).input_width);
      end loop;
      exp := (-2**(i(0)'length-1))*adder_tree_array(l).num_coeffs;

      wait for 20 ns;

      if to_integer(o) = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & integer'image(exp) & " Read: " & integer'image(to_integer(o))
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
