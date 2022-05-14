-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A non-pipelined recursive complex adder tree used to add 2 or more operands
-- together. This component is asynchronous. Registering results is done outside this
-- component.
-- NB. This code should work in Quartus Prime _Pro_ but not Quartus Prime Standard
-- nor Lite and not in Vivado.
--
-- P A Abbey, 10 September 2021
--
-------------------------------------------------------------------------------------

library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;
  use work.adder_tree_pkg.all;

entity adder_tree_complex is
  generic (
    num_operands_g : positive; -- ModelSim is struggling with an unconstrained array of constrained vectors
    template_g     : sfixed    -- Provide an uninitialised vector solely for passing information about the fixed point range
  );
  port (
    i : in  complex_arr_t(0 to num_operands_g-1)(
      re(template_g'range),
      im(template_g'range)
    );
    o : out complex_t(
      re(output_bits(template_g'high, num_operands_g) downto template_g'low),
      im(output_bits(template_g'high, num_operands_g) downto template_g'low)
    )
  );
end entity;


architecture rtl of adder_tree_complex is
begin

  recurse_g : if num_operands_g = 1 generate

    -- End recursion
    output1: o <= i(0); -- No resize as log2(1) = 0 additional bits on the output.

  elsif num_operands_g = 2 generate

    output2 : o <= resize(i(0), i(0).re) + resize(i(1), i(1).re);

  elsif num_operands_g = 3 generate

    signal o1 : complex_t(
      re(output_bits(template_g'high, 2) downto template_g'low),
      im(output_bits(template_g'high, 2) downto template_g'low)
    );

  begin

    adder_i : entity work.adder_tree_complex
      generic map (
        num_operands_g => 2,
        template_g     => template_g
      )
      port map (
        i => i(0 to 1),
        o => o1
      );

    output3 : o <= resize(o1, o1.re) + resize(i(2), i(2).re);

  else generate

    constant num_coeffs1_c : natural := first_adder_operands(num_operands_g);

    signal o1 : complex_t(
      re(output_bits(template_g'high, num_coeffs1_c) downto template_g'low),
      im(output_bits(template_g'high, num_coeffs1_c) downto template_g'low)
    );
    signal o2 : complex_t(
      re(output_bits(template_g'high, num_operands_g - num_coeffs1_c) downto template_g'low),
      im(output_bits(template_g'high, num_operands_g - num_coeffs1_c) downto template_g'low)
    );

  begin

    adder1_i : entity work.adder_tree_complex
      generic map (
        num_operands_g => num_coeffs1_c,
        template_g     => template_g
      )
      port map (
        i => i(0 to num_coeffs1_c-1),
        o => o1
      );

    adder2_i : entity work.adder_tree_complex
      generic map (
        num_operands_g => (num_operands_g - num_coeffs1_c),
        template_g     => template_g
      )
      port map (
        i => i(num_coeffs1_c to num_operands_g-1),
        o => o2
      );

    output4plus : o <= resize(o1, o1.re) + resize(o2, o2.re);

  end generate;

end architecture;
