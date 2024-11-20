-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A pipelined recursive complex adder tree used to add 2 or more operands together.
-- NB. This code should work in Quartus Prime _Pro_ but not Quartus Prime Standard
-- nor Lite and not in Vivado.
--
-- P A Abbey, 10 September 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;
  use work.adder_tree_pkg.all;

entity adder_tree_complex_pipe is
  generic (
    depth_g        : positive;
    num_operands_g : positive; -- ModelSim is struggling with an unconstrained array of constrained vectors
    template_g     : sfixed    -- Provide an uninitialised vector solely for passing information about the fixed point range
  );
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    i     : in  complex_arr_t(0 to num_operands_g-1)(
      re(template_g'range),
      im(template_g'range)
    );
    o     : out complex_t(
      re(output_bits(template_g'high, num_operands_g) downto template_g'low),
      im(output_bits(template_g'high, num_operands_g) downto template_g'low)
    )
  );
end entity;


library ieee;
  use ieee.math_real.all;
library local;

architecture rtl of adder_tree_complex_pipe is

  -- For debug only, extracted by VHDL-2008 signal spies.
  constant divide_c          : positive                                                                  := recurse_divide(num_operands_g, depth_g);
  constant part_length_c     : positive                                                                  := positive(ceil(real(num_operands_g) / real(divide_c)));
  constant sum_input_range_c : sfixed(output_bits(template_g'high, part_length_c) downto template_g'low) := (others => '0');
  -- Read by VHDL-2008 signal spies in the test bench
  constant output_width_c    : positive := o.re'length;

  signal sum : complex_arr_t(0 to divide_c-1)(
    re(sum_input_range_c'range),
    im(sum_input_range_c'range)
  );
  signal lsum : complex_t(
    re(output_bits(sum_input_range_c'high, divide_c) downto sum_input_range_c'low),
    im(output_bits(sum_input_range_c'high, divide_c) downto sum_input_range_c'low)
  );

begin

  recurse_g : if depth_g > 1 generate

    -- Recurse
    divide_g : for l in 0 to divide_c-1 generate

      constant ilow_c         : natural := l * part_length_c;
      -- Remaining coefficients might be less than 'part_length_c'
      constant ihigh_c        : natural := local.math_pkg.minimum(num_operands_g, ilow_c + part_length_c)-1;
      constant output_range_c : sfixed(output_bits(template_g'high, (ihigh_c - ilow_c + 1)) downto template_g'low) := (others => '0');

      signal z : complex_t(
        re(output_range_c'range),
        im(output_range_c'range)
      );

    begin

      adder_tree_complex_pipe_i : entity work.adder_tree_complex_pipe
        generic map (
          depth_g        => depth_g-1,
          num_operands_g => (ihigh_c - ilow_c + 1),
          template_g     => template_g
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i(ilow_c to ihigh_c),
          o     => z
        );
      -- ModelSim can't handle driving partial ranges within element of a record.
      sum(l).re(output_range_c'range) <= z.re;
      sum(l).im(output_range_c'range) <= z.im;

      msbs_g : if output_range_c'high < sum_input_range_c'high generate
        -- Must sign extend, might be multiple bits
        sum(l).re(sum_input_range_c'high downto output_range_c'high+1) <= (others => z.re(output_range_c'high));
        sum(l).im(sum_input_range_c'high downto output_range_c'high+1) <= (others => z.im(output_range_c'high));
      end generate;

    end generate;

  else generate

    -- Terminate recursion, just pass values directly to the non-pipelined adder.
    bypass : sum <= i;

  end generate;


  adder_g : if divide_c > 1 generate

    adder_i : entity work.adder_tree_complex
      generic map (
        num_operands_g => divide_c,
        template_g     => sum_input_range_c
      )
      port map (
        i => sum,
        o => lsum
      );

  else generate

    -- Does not seem to work in ModelSim with: lsum <= sum(0)
    bypass : lsum <= (re => sum(0).re, im => sum(0).im);

  end generate;


  -- Pipeline the adder tree here, before returning from recursion
  reg_output : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset should be replaced by GSR initialisation for FPGA.
        o <= (
          re => (others => '0'),
          im => (others => '0')
        );
      else
        -- LHS is (output_bits(input_width_g, num_operands_g)-1 downto 0) due to excessive bit growth, so chop extra bit off MSB end.
        o <= (
          re => lsum.re(o.re'range),
          im => lsum.im(o.im'range)
        );
      end if;
    end if;
  end process;

end architecture;
