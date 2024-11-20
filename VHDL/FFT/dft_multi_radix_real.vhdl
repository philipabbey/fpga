-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Radix-n, implementation using recursive VHDL. The maximum radix to use can be
-- limited, e.g. to Radix-8, forcing recursion for inputs width > 2**8, and limiting
-- the depth of any adder trees in each output's summation. This code uses the
-- unsynthesisable real type in order to establish the construction with fewer
-- complications.
--
-- References:
--   1) A DFT and FFT TUTORIAL,
--      http://www.alwayslearn.com/DFT%20and%20FFT%20Tutorial/DFTandFFT_FFT_Overview.html
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library work; -- Implicit anyway, but acts to group.
  use work.fft_real_pkg.all;

-- Perform the bit reversal on the input indices once at the top level, then call
-- the recursive component.
entity dft_multi_radix_real is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10
    max_radix_g      : positive
  );
  port (
    i : in  complex_vector(0 to (2**log_num_inputs_g)-1) := (others => (0.0, 0.0));
    o : out complex_vector(0 to (2**log_num_inputs_g)-1) := (others => (0.0, 0.0))
  );
end entity;


library work; -- Implicit anyway, but acts to group.
  use work.fft_real_pkg.all;

entity dftr_multi_radix_real is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10. Using the logarithm here ensures an erroneous inputs width cannot be selected.
    max_radix_g      : positive  -- Not using the logarithm here which is inconsistent! Conventionally everyone refers to Radix-2, Radix-4, Radix-8 etc.
  );
  port (
    i : in  complex_vector(0 to (2**log_num_inputs_g)-1) := (others => (0.0, 0.0));
    o : out complex_vector(0 to (2**log_num_inputs_g)-1) := (others => (0.0, 0.0))
  );
end entity;


library ieee;
  use ieee.math_complex.all;
library local;

architecture radix_n of dftr_multi_radix_real is

  constant radix_c       : positive                                                   := local.math_pkg.minimum(max_radix_g, 2**log_num_inputs_g);
  constant group_width_c : natural                                                    := o'length/radix_c;
  constant twid_c        : complex_vector(0 to (2**(log_num_inputs_g-1))-1)           := init_twiddles_half(2**(log_num_inputs_g-1));
  constant powers_c      : local.rtl_pkg.natural_vector                               := twiddle_power(radix_c);
  constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
  constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);
  signal   t             : complex_vector(0 to (2**log_num_inputs_g)-1)               := (others => (0.0, 0.0));
  signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := (others => (others => (0.0, 0.0)));

begin

  recurse_g : if (2**log_num_inputs_g) <= radix_c generate
    -- No recursion, just map the inputs to the intermediate values
    t <= i;
  else generate
    -- Recurse with radix_c instantiations
    dft_g : for j in 0 to radix_c-1 generate

      dftr_i : entity work.dftr_multi_radix_real
        generic map (
          log_num_inputs_g => log_num_inputs_g-local.math_pkg.ceil_log(radix_c),
          max_radix_g      => max_radix_g
        )
        port map (
          i => i(j*i'length/radix_c to (j+1)*i'length/radix_c-1),
          o => t(j*t'length/radix_c to (j+1)*t'length/radix_c-1)
        );

    end generate;
  end generate;

  -- Reusable multiplications
  col_g : for j in m'range generate -- (1 to radix_c-1)
    row_g : for k in m(j)'range generate -- (0 to group_width_c-1)
      constant id : string := m'instance_name & integer'image(j) & "," & integer'image(k);
    begin
      m(j)(k) <= operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), id);
    end generate;
  end generate;

  -- Combine with the radix_c butterfly
  process(t, m)
    variable s_v     : complex := (re => 0.0, im => 0.0);
    variable group_c : natural := 1;
  begin

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    for j in o'range loop -- j'th output
      group_c := (j / group_width_c);

      -- Generate the radix_c values to sum, and sum them cumulatively
      s_v := t(j-(group_c*group_width_c));
      for k in 1 to radix_c-1 loop
        s_v := s_v + operation(twid_c, opt_pwr(k)(group_c), m(k)(j-(group_c*group_width_c)), m'instance_name & integer'image(j) & "," & integer'image(k));
      end loop;

      o(j) <= s_v;
    end loop;
  end process;

end architecture;


library local;

-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix_n of dft_multi_radix_real is
begin

  assert 2**local.math_pkg.ceil_log(max_radix_g) = max_radix_g
    report "max_radix_g must be a power of 2."
    severity error;

  dftr_i : entity work.dftr_multi_radix_real
    generic map (
      log_num_inputs_g => log_num_inputs_g,
      max_radix_g      => max_radix_g
    )
    port map (
      i => array_reverse(i),
      o => o
    );

end architecture;
