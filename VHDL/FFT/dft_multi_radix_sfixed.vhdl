-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Radix-n, implementation using recursive VHDL. The maximum radix to use can be
-- limited, e.g. to Radix-8, forcing recursion for inputs width > 2**8, and limiting
-- the depth of any adder trees in each output's summation. The design is fully
-- pipelined. By that I mean partial products are registered between every step of
-- arithmetic.
--  * After the multiplications before the additions
--  * Through a fully pipelined complex adder tree
--
-- References:
--   1) A DFT and FFT TUTORIAL,
--      http://www.alwayslearn.com/DFT%20and%20FFT%20Tutorial/DFTandFFT_FFT_Overview.html
--
-- P A Abbey, 13 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.std_logic;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;

-- Perform the bit reversal on the input indices once at the top level, then call
-- the recursive component.
entity dft_multi_radix_sfixed is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10
    template_g       : sfixed;   -- Provide an uninitialised vector solely for passing information about the fixed point range
    -- Not using the logarithm here which is inconsistent! Conventionally everyone refers to Radix-2, Radix-4, Radix-8 etc.
    max_radix_g      : positive  -- Limit the FFT Radix to be used, allowing smaller radices for the last stage.
  );
  port (
    clk   : std_logic;
    reset : std_logic;
    i     : in  complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    );
    o     : out complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    )
  );
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;

entity dftr_multi_radix_sfixed is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10. Using the logarithm here ensures an erroneous inputs width cannot be selected.
    template_g       : sfixed;   -- Provide an uninitialised vector solely for passing information about the fixed point range
    -- Not using the logarithm here which is inconsistent! Conventionally everyone refers to Radix-2, Radix-4, Radix-8 etc.
    max_radix_g      : positive  -- Limit the FFT Radix to be used, allowing smaller radices for the last stage.
  );
  port (
    clk   : std_logic;
    reset : std_logic;
    i     : in  complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    );
    o     : out complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    )
  );
end entity;


library local;
library work; -- Implicit anyway, but acts to group.
  use work.adder_tree_pkg.all;

architecture radix_n of dftr_multi_radix_sfixed is

  constant radix_c       : positive                                                   := minimum(max_radix_g, 2**log_num_inputs_g);
  constant group_width_c : natural                                                    := o'length/radix_c;
  constant twid_c        : complex_arr_t(0 to (2**(log_num_inputs_g-1))-1)            := init_twiddles_half(2**(log_num_inputs_g-1), template_g);
  constant powers_c      : local.rtl_pkg.natural_vector                               := twiddle_power(radix_c);
  constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
  constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);

  signal t : complex_arr_t(0 to (2**log_num_inputs_g)-1)(
    re(template_g'range),
    im(template_g'range)
  );

  signal prods : complex_2darr_t(1 to radix_c-1)(0 to group_width_c-1)(
    re(template_g'range),
    im(template_g'range)
  );

  signal sums : complex_2darr_t(o'range)(0 to radix_c-1)(
    re(template_g'range),
    im(template_g'range)
  );

begin

  recurse_g : if (2**log_num_inputs_g) <= radix_c generate
    -- No recursion, just map the inputs to the intermediate values
    t <= i;
  else generate
    -- Recurse with radix_c instantiations
    dft_g : for j in 0 to radix_c-1 generate

      dftr_i : entity work.dftr_multi_radix_sfixed
        generic map (
          log_num_inputs_g => log_num_inputs_g-local.math_pkg.ceil_log(radix_c),
          template_g       => template_g,
          max_radix_g      => max_radix_g
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i(j*i'length/radix_c to (j+1)*i'length/radix_c-1),
          o     => t(j*t'length/radix_c to (j+1)*t'length/radix_c-1)
        );

    end generate;
  end generate;

  -- Combine with the radix_c butterfly
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        prods <= (others => (others => (
          re => (others => '0'),
          im => (others => '0')
        )));
      else
        for j in prods'range loop -- j'th output
          for k in prods(j)'range loop
            prods(j)(k) <= resize(operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), prods'instance_name & integer'image(j) & "," & integer'image(k)), template_g);
          end loop;
        end loop;
      end if;
    end if;
  end process;

  col_g : for j in sums'range generate -- o'range
    constant group_c : natural := (j / group_width_c);
  begin
    sums(j)(0) <= t(j-(group_c*group_width_c));

    row_g : for k in 1 to radix_c-1 generate
      constant id : string := prods'instance_name & integer'image(j) & "," & integer'image(k);
    begin
      sums(j)(k) <= resize(operation(twid_c, opt_pwr(k)(group_c), prods(k)(j-(group_c*group_width_c)), id), template_g);
    end generate;
  end generate;

  adders_g : for j in o'range generate
    signal u : complex_t(
      re(output_bits(template_g'high, sums(j)'length) downto template_g'low),
      im(output_bits(template_g'high, sums(j)'length) downto template_g'low)
    );
  begin

    assert false
      report "Adders: " & integer'image(radix_c-1)
      severity note;

    adder_tree_complex_pipe_i : entity work.adder_tree_complex_pipe
      generic map (
        depth_g        => local.math_pkg.ceil_log(sums(j)'length),
        num_operands_g => sums(j)'length,
        template_g     => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => sums(j),
        o     => u
      );

    -- Slice the results down to size and assume simulation will detect deviation from
    -- Octave derived results comparisons.
    o(j) <= (
      u.re(template_g'range),
      u.im(template_g'range)
    );

  end generate;

end architecture;


library local;

-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix_n of dft_multi_radix_sfixed is
begin

  assert 2**local.math_pkg.ceil_log(max_radix_g) = max_radix_g
    report "max_radix_g must be a power of 2."
    severity error;

  dftr_i : entity work.dftr_multi_radix_sfixed
    generic map (
      log_num_inputs_g => log_num_inputs_g,
      template_g       => template_g,
      max_radix_g      => max_radix_g
    )
    port map (
      clk   => clk,
      reset => reset,
      i     => array_reverse(i),
      o     => o
    );

end architecture;
