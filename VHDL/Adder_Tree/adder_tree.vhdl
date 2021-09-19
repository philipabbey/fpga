-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A non-pipelined recursive adder tree used to add 2 or more operands together. This
-- component is asynchronous. Registering results is done outside this component.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.adder_tree_pkg.all;

-- An entity with:
-- i : in  input_arr_t(open)(input_width_g-1 downto 0);
-- Broke the vcom compiler. Using fully constrained arrays which will aid length checking anyway.

entity adder_tree is
  generic (
    num_operands_g : positive; -- ModelSim is struggling with an unconstrained array of constrained vectors
    input_width_g  : positive := 18
  );
  port (
    i : in  input_arr_t(0 to num_operands_g-1)(input_width_g-1 downto 0);
    o : out signed(output_bits(input_width_g, num_operands_g)-1 downto 0)
  );
end entity;


architecture rtl of adder_tree is
begin

  recurse_g : if num_operands_g = 1 generate

    -- End recursion
    output1: o <= i(0); -- No resize as log2(1) = 0 additional bits on the output.

  elsif num_operands_g = 2 generate

    output2 : o <= resize(i(0), o'length) + resize(i(1), o'length);

  elsif num_operands_g = 3 generate

    signal o1 : signed(output_bits(input_width_g, 2)-1 downto 0);

  begin

    adder_i : entity work.adder_tree
      generic map (
        num_operands_g => 2,
        input_width_g  => input_width_g
      )
      port map (
        i => i(0 to 1),
        o => o1
      );

    output3 : o <= resize(o1, o'length) + resize(i(2), o'length);

  else generate

    constant num_coeffs1_c : natural := first_adder_operands(num_operands_g);

    signal o1 : signed(output_bits(input_width_g, num_coeffs1_c)-1 downto 0);
    signal o2 : signed(output_bits(input_width_g, num_operands_g - num_coeffs1_c)-1 downto 0);

  begin

    adder1_i : entity work.adder_tree
      generic map (
        num_operands_g => num_coeffs1_c,
        input_width_g  => input_width_g
      )
      port map (
        i => i(0 to num_coeffs1_c-1),
        o => o1
      );

    adder2_i : entity work.adder_tree
      generic map (
        num_operands_g => (num_operands_g - num_coeffs1_c),
        input_width_g  => input_width_g
      )
      port map (
        i => i(num_coeffs1_c to num_operands_g-1),
        o => o2
      );

    output4plus : o <= resize(o1, o'length) + resize(o2, o'length);

  end generate;

end architecture;
