-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A pipelined recursive adder tree used to add 2 or more operands together.
-- NB. This code will work in Synplify Pro and Quartus Prime but not in Vivado.
--
-- P A Abbey, 28 August 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.adder_tree_pkg.all;

-- An entity with:
-- i : in  input_arr_t(open)(input_width_g-1 downto 0);
-- Broke the vcom compiler. Using fully constrained arrays which will aid length checking anyway.

entity adder_tree_pipe is
  generic (
    depth_g        : positive;
    num_operands_g : positive; -- ModelSim is struggling with an unconstrained array of constrained vectors
    input_width_g  : positive := 18
  );
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    i     : in  input_arr_t(0 to num_operands_g-1)(input_width_g-1 downto 0);
    o     : out signed(output_bits(input_width_g, num_operands_g)-1 downto 0)
  );
end entity;


library ieee;
use ieee.math_real.all;

architecture rtl of adder_tree_pipe is

  -- For debug only, extracted by VHDL-2008 signal spies.
  constant output_width_c   : positive := o'length;
  constant divide_c         : positive := recurse_divide(num_operands_g, depth_g);
  constant part_length_c    : positive := positive(ceil(real(num_operands_g) / real(divide_c)));
  constant sum_input_bits_c : positive := output_bits(input_width_g, part_length_c);

  signal sum  : input_arr_t(0 to divide_c-1)(sum_input_bits_c-1 downto 0);
  signal lsum : signed(output_bits(sum_input_bits_c, divide_c)-1 downto 0);

begin

  recurse_g : if depth_g > 1 generate

    -- Recurse
    divide_g : for l in 0 to divide_c-1 generate

      constant ilow_c        : natural  := l * part_length_c;
      -- Remaining coefficients might be less than 'part_length_c'
      constant ihigh_c       : natural  := work.adder_tree_pkg.minimum(num_operands_g, ilow_c + part_length_c)-1;
      constant output_bits_c : positive := output_bits(input_width_g, (ihigh_c - ilow_c + 1));

    begin

      adder_tree_pipe_i : entity work.adder_tree_pipe
        generic map (
          depth_g        => depth_g-1,
          num_operands_g => (ihigh_c - ilow_c + 1),
          input_width_g  => input_width_g
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i(ilow_c to ihigh_c),
          o     => sum(l)(output_bits_c-1 downto 0)
        );

      msbs_g : if output_bits_c < sum_input_bits_c generate
        -- Must sign extend, might be multiple bits
        sum(l)(sum_input_bits_c-1 downto output_bits_c) <= (others => sum(l)(output_bits_c-1));
      end generate;

    end generate;

  else generate

    -- Terminate recursion, just pass values directly to the non-pipelined adder.
    bypass : sum <= i;

  end generate;


  adder_g : if divide_c > 1 generate

    adder_i : entity work.adder_tree
      generic map (
        num_operands_g => divide_c,
        input_width_g  => sum_input_bits_c
      )
      port map (
        i => sum,
        o => lsum
      );

  else generate

    bypass : lsum <= sum(0);

  end generate;


  -- Pipeline the adder tree here, before returning from recursion
  reg_output : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        -- Reset should be replaced by GSR initialisation for FPGA.
        o <= (others => '0');
      else
        -- LHS is (output_bits(input_width_g, num_operands_g)-1 downto 0) due to excessive bit growth, so chop extra bit off MSB end.
        o <= lsum(o'range);
      end if;
    end if;
  end process;

end architecture;
