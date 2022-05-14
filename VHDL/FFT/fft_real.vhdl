-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Radix-2, Radix-4 and Radix-8 FFT implementation using the unsynthesisable real
-- type and recursive VHDL.
--
-- References:
--   1) A DFT and FFT TUTORIAL,
--      http://www.alwayslearn.com/DFT%20and%20FFT%20Tutorial/DFTandFFT_FFT_Overview.html
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.math_complex.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_real_pkg.all;

entity dftr_real is
  generic (
    log_num_inputs_g : positive -- E.g. 1024 point FFT => log_num_inputs_g = 10
  );
  port (
    i : in  complex_vector(0 to (2**log_num_inputs_g)-1);
    o : out complex_vector(0 to (2**log_num_inputs_g)-1)
  );
end entity;


library work; -- Implicit anyway, but acts to group.
  use work.fft_real_pkg.all;

-- Perform the bit reversal on the input indices once at the top level, then call
-- the recursive component.
entity dft_real is
  generic (
    log_num_inputs_g : positive -- E.g. 1024 point FFT => log_num_inputs_g = 10
  );
  port (
    i : in  complex_vector(0 to (2**log_num_inputs_g)-1);
    o : out complex_vector(0 to (2**log_num_inputs_g)-1)
  );
end entity;


-------------
-- Radix-2 --
-------------

architecture radix2 of dftr_real is

  constant twid_c : complex_vector(0 to (2**(log_num_inputs_g-1))-1) := init_twiddles_half(2**(log_num_inputs_g-1));

begin

  recurse_g : if log_num_inputs_g = 1 generate
    constant radix_c : positive := 2;
    signal   m       : complex;
  begin

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    -- Perform the Radix-2 FFT on two operands
    m    <= i(1);     -- operation(twid_c, 0, i(1));
    o(0) <= i(0) + m; --  twid_c(0)
    o(1) <= i(0) - m; -- -twid_c(0) == twid(1) when using init_twiddles_full

  else generate

    constant radix_c       : positive                                                   := 2;
    constant group_width_c : positive                                                   := o'length/radix_c;
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);
    signal   t             : complex_vector(0 to (2**log_num_inputs_g)-1);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- Recurse and combine
    dftr_i0 : entity work.dftr_real(radix2)
      generic map (
        log_num_inputs_g => log_num_inputs_g-1
      )
      port map (
        i => i(0 to i'length/2-1),
        o => t(0 to t'length/2-1)
      );

    dftr_i1 : entity work.dftr_real(radix2)
      generic map (
        log_num_inputs_g => log_num_inputs_g-1
      )
      port map (
        i => i(i'length/2 to i'high),
        o => t(t'length/2 to t'high)
      );

    -- Reusable multiplications
    col_g : for j in m'range generate
      row_g : for k in m(j)'range generate -- (0 to group_width_c-1)
        constant id : string := m'instance_name & integer'image(j) & "," & integer'image(k);
      begin
        m(j)(k) <= operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), id);
      end generate;
    end generate;

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    butterfly_g : for j in o'range generate
      constant id : string := o'instance_name & integer'image(j);
    begin
      -- Optimised multiplication & sum as operation() avoids multiplications of 1, -i.
      half_g : if j < group_width_c generate
        -- Top Half of Butterfly
        o(j) <= t(j) +
                operation(twid_c, opt_pwr(1)(0), m(1)(j), id & "," & integer'image(1));
      else generate
        -- Bottom Half of Butterfly
        o(j) <= t(j-group_width_c) +
                operation(twid_c, opt_pwr(1)(1), m(1)(j-group_width_c), id & "," & integer'image(1));
      end generate;
    end generate;

  end generate;

end architecture;


-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix2 of dft_real is
begin

  dftr_i : entity work.dftr_real(radix2)
    generic map (
      log_num_inputs_g => log_num_inputs_g
    )
    port map (
      i => array_reverse(i),
      o => o
    );

end architecture;


-------------
-- Radix-4 --
-------------

architecture radix4 of dftr_real is

  constant twid_c : complex_vector(0 to (2**(log_num_inputs_g-1))-1) := init_twiddles_half(2**(log_num_inputs_g-1));

begin

  recurse_g : if log_num_inputs_g = 1 generate
    constant radix_c : positive := 2;
    signal   m       : complex;
  begin

    -- Perform the Radix-2 FFT on two operands
    m    <= i(1);     -- operation(twid_c, 0, i(1));
    o(0) <= i(0) + m; --  twid_c(0)
    o(1) <= i(0) - m; -- -twid_c(0) == twid(1) when using init_twiddles_full

  elsif log_num_inputs_g = 2 generate

    constant radix_c       : positive                                                   := 4;
    constant group_width_c : positive                                                   := o'length/radix_c; -- Always 1
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- As group_width_c = 1, There are no roots of unity between opt_pwr roots.
    m(1)(0) <= i(1); -- +1 x i(1)
    m(2)(0) <= i(2); -- +1 x i(2)
    m(3)(0) <= i(3); -- +1 x i(3)

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    butterfly_g : for j in o'range generate
      constant id : string := o'instance_name & integer'image(j);
    begin
      -- Optimised multiplication & sum as operation() avoids multiplications of 1, -i, -1 & i.
      quarter_g : if j < group_width_c generate
        o(j) <= i(j) +
                operation(twid_c, opt_pwr(1)(0), m(1)(j), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(0), m(2)(j), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(0), m(3)(j), id & "," & integer'image(3));
      elsif j < 2 * group_width_c generate
        o(j) <= i(j-   group_width_c ) +
                operation(twid_c, opt_pwr(1)(1), m(1)(j-group_width_c), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(1), m(2)(j-group_width_c), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(1), m(3)(j-group_width_c), id & "," & integer'image(3));
      elsif j < 3 * group_width_c generate
        o(j) <= i(j-(2*group_width_c)) +
                operation(twid_c, opt_pwr(1)(2), m(1)(j-(2*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(2), m(2)(j-(2*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(2), m(3)(j-(2*group_width_c)), id & "," & integer'image(3));
      else generate
        o(j) <= i(j-(3*group_width_c)) +
                operation(twid_c, opt_pwr(1)(3), m(1)(j-(3*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(3), m(2)(j-(3*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(3), m(3)(j-(3*group_width_c)), id & "," & integer'image(3));
      end generate;
    end generate;

--    -- Perform the Radix-4 FFT on four operands. Indexing of twiddle factors has been generalised and hence is unoptimised by butterflies
--    o(0) <= i(0) + (twid_mod(twid_c, 0) * i(1)) + (twid_mod(twid_c, 0) * i(2)) + (twid_mod(twid_c, 0) * i(3));
--    o(1) <= i(0) + (twid_mod(twid_c, 2) * i(1)) + (twid_mod(twid_c, 1) * i(2)) + (twid_mod(twid_c, 3) * i(3));
--    o(2) <= i(0) + (twid_mod(twid_c, 4) * i(1)) + (twid_mod(twid_c, 2) * i(2)) + (twid_mod(twid_c, 6) * i(3));
--    o(3) <= i(0) + (twid_mod(twid_c, 6) * i(1)) + (twid_mod(twid_c, 3) * i(2)) + (twid_mod(twid_c, 9) * i(3));

  else generate

    constant radix_c       : positive                                                   := 4;
    constant group_width_c : positive                                                   := o'length/radix_c;
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);
    signal   t             : complex_vector(0 to (2**log_num_inputs_g)-1);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- Recurse

    dftr_i0 : entity work.dftr_real(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2
      )
      port map (
        i => i(0 to i'length/4-1),
        o => t(0 to t'length/4-1)
      );

    dftr_i1 : entity work.dftr_real(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2
      )
      port map (
        i => i(i'length/4 to i'length/2-1),
        o => t(t'length/4 to t'length/2-1)
      );

    dftr_i2 : entity work.dftr_real(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2
      )
      port map (
        i => i(i'length/2 to 3*i'length/4-1),
        o => t(t'length/2 to 3*t'length/4-1)
      );

    dftr_i3 : entity work.dftr_real(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2
      )
      port map (
        i => i(3*i'length/4 to i'high),
        o => t(3*t'length/4 to t'high)
      );

    -- Combine
    -- Reusable multiplications
    col_g : for j in m'range generate
      row_g : for k in m(j)'range generate -- (0 to group_width_c-1)
        constant id : string := m'instance_name & integer'image(j) & "," & integer'image(k);
      begin
        m(j)(k) <= operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), id);
      end generate;
    end generate;

    -- Pre-multiplication
    -- 32-inputs Radix-4
--    m(1)(0) <= operation(twid_c, 0, t(0+8));
--    m(1)(1) <= operation(twid_c, 2, t(1+8));
--    m(1)(2) <= operation(twid_c, 4, t(2+8));
--    m(1)(3) <= operation(twid_c, 6, t(3+8));
--    m(1)(4) <= operation(twid_c, 0, t(4+8));
--    m(1)(5) <= operation(twid_c, 2, t(5+8));
--    m(1)(6) <= operation(twid_c, 4, t(6+8));
--    m(1)(7) <= operation(twid_c, 6, t(7+8));
--
--    m(2)(0) <= operation(twid_c, 0, t(0+16));
--    m(2)(1) <= operation(twid_c, 1, t(1+16));
--    m(2)(2) <= operation(twid_c, 2, t(2+16));
--    m(2)(3) <= operation(twid_c, 3, t(3+16));
--    m(2)(4) <= operation(twid_c, 4, t(4+16));
--    m(2)(5) <= operation(twid_c, 5, t(5+16));
--    m(2)(6) <= operation(twid_c, 6, t(6+16));
--    m(2)(7) <= operation(twid_c, 7, t(7+16));
--
--    m(3)(0) <= operation(twid_c, 0, t(0+24));
--    m(3)(1) <= operation(twid_c, 3, t(1+24));
--    m(3)(2) <= operation(twid_c, 6, t(2+24));
--    m(3)(3) <= operation(twid_c, 1, t(3+24)); --  9
--    m(3)(4) <= operation(twid_c, 4, t(4+24)); -- 12
--    m(3)(5) <= operation(twid_c, 7, t(5+24)); -- 15
--    m(3)(6) <= operation(twid_c, 2, t(6+24)); -- 18
--    m(3)(7) <= operation(twid_c, 5, t(7+24)); -- 21

    -- 16-inputs Radix-4
--    m(1)(0) <= operation(twid_c, 0, t(0+4));
--    m(1)(1) <= operation(twid_c, 2, t(1+4));
--    m(1)(2) <= operation(twid_c, 0, t(2+4)); -- 4
--    m(1)(3) <= operation(twid_c, 2, t(3+4)); -- 6
--
--    m(2)(0) <= operation(twid_c, 0, t(0+8));
--    m(2)(1) <= operation(twid_c, 1, t(1+8));
--    m(2)(2) <= operation(twid_c, 2, t(2+8));
--    m(2)(3) <= operation(twid_c, 3, t(3+8));
--
--    m(3)(0) <= operation(twid_c, 0, t(0+12));
--    m(3)(1) <= operation(twid_c, 3, t(1+12));
--    m(3)(2) <= operation(twid_c, 2, t(2+12)); -- 6
--    m(3)(3) <= operation(twid_c, 1, t(3+12)); -- 9

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    butterfly_g : for j in o'range generate
      constant id : string := o'instance_name & integer'image(j);
    begin

      -- Perform the Radix-4 FFT on four operands. Indexing of twiddle factors has been generalised and hence is unoptimised by butterflies
--      quarter_g : if j < group_width_c generate
--        o(j) <= t(j                  ) + (twid_mod(twid_c, 2*j) * t(j+   group_width_c )) + (twid_mod(twid_c, j) * t(j+(2*group_width_c))) + (twid_mod(twid_c, 3*j) * t(j+(3*group_width_c)));
--      elsif j < 2 * group_width_c generate
--        o(j) <= t(j-   group_width_c ) + (twid_mod(twid_c, 2*j) * t(j                  )) + (twid_mod(twid_c, j) * t(j+   group_width_c )) + (twid_mod(twid_c, 3*j) * t(j+(2*group_width_c)));
--      elsif j < 3 * group_width_c generate
--        o(j) <= t(j-(2*group_width_c)) + (twid_mod(twid_c, 2*j) * t(j-   group_width_c )) + (twid_mod(twid_c, j) * t(j                  )) + (twid_mod(twid_c, 3*j) * t(j+   group_width_c ));
--      else generate
--        o(j) <= t(j-(3*group_width_c)) + (twid_mod(twid_c, 2*j) * t(j-(2*group_width_c))) + (twid_mod(twid_c, j) * t(j-   group_width_c )) + (twid_mod(twid_c, 3*j) * t(j                  ));
--      end generate;

      -- Optimised multiplication & sum as operation() avoids multiplications of 1, -i, -1 & i.
      quarter_g : if j < group_width_c generate
        o(j) <= t(j ) +
                operation(twid_c, opt_pwr(1)(0), m(1)(j), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(0), m(2)(j), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(0), m(3)(j), id & "," & integer'image(3));
      elsif j < 2 * group_width_c generate
        o(j) <= t(j-   group_width_c ) +
                operation(twid_c, opt_pwr(1)(1), m(1)(j-group_width_c), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(1), m(2)(j-group_width_c), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(1), m(3)(j-group_width_c), id & "," & integer'image(3));
      elsif j < 3 * group_width_c generate
        o(j) <= t(j-(2*group_width_c)) +
                operation(twid_c, opt_pwr(1)(2), m(1)(j-(2*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(2), m(2)(j-(2*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(2), m(3)(j-(2*group_width_c)), id & "," & integer'image(3));
      else generate
        o(j) <= t(j-(3*group_width_c)) +
                operation(twid_c, opt_pwr(1)(3), m(1)(j-(3*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(3), m(2)(j-(3*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(3), m(3)(j-(3*group_width_c)), id & "," & integer'image(3));
      end generate;

    end generate;
  end generate;

end architecture;


-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix4 of dft_real is
begin

  dftr_i : entity work.dftr_real(radix4)
    generic map (
      log_num_inputs_g => log_num_inputs_g
    )
    port map (
      i => array_reverse(i),
      o => o
    );

end architecture;


-------------
-- Radix-8 --
-------------

architecture radix8 of dftr_real is

  constant twid_c : complex_vector(0 to (2**(log_num_inputs_g-1))-1) := init_twiddles_half(2**(log_num_inputs_g-1));

begin

  recurse_g : if log_num_inputs_g = 1 generate

    constant radix_c : positive := 2;
    signal   m       : complex;

  begin

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    -- Perform the Radix-2 FFT on two operands
    m    <= i(1);     -- operation(twid_c, 0, i(1));
    o(0) <= i(0) + m; --  twid_c(0)
    o(1) <= i(0) - m; -- -twid_c(0) == twid(1) when using init_twiddles_full

  elsif log_num_inputs_g = 2 generate

    constant radix_c       : positive                                             := 4;
    constant group_width_c : natural                                              := o'length/radix_c; -- Always 1
    constant powers_c      : natural_vector                                       := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1) := opt_pwr_arr(powers_c, group_width_c);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- As group_width_c = 1, There are no roots of unity between opt_pwr roots.
    m(1)(0) <= i(1); -- +1 x i(1)
    m(2)(0) <= i(2); -- +1 x i(2)
    m(3)(0) <= i(3); -- +1 x i(3)

    -- Perform the Radix-4 FFT on four operands.
--    --        +1              +1              +1              +1
--    o(0) <= i(0) + opt_pwr(1)(0) + opt_pwr(2)(0) + opt_pwr(3)(0);
--    --        +1              -1              -i              +i
--    o(1) <= i(0) + opt_pwr(1)(1) + opt_pwr(2)(1) + opt_pwr(3)(1);
--    --        +1              +1              -1              -1
--    o(2) <= i(0) + opt_pwr(1)(0) + opt_pwr(2)(0) + opt_pwr(3)(0);
--    --        +1              -1              +i              -i
--    o(3) <= i(0) + opt_pwr(1)(1) + opt_pwr(2)(1) + opt_pwr(3)(1);

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    butterfly_g : for j in o'range generate
      constant id : string := o'instance_name & integer'image(j);
    begin
      -- Optimised multiplication & sum as operation() avoids multiplications of 1, -i, -1 & i.
      -- As group_width_c = 1, (j-(group*group_width_c)) = 0.
      quarter_g : if j < group_width_c generate
        o(j) <= i(j) +
                operation(twid_c, opt_pwr(1)(0), m(1)(j), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(0), m(2)(j), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(0), m(3)(j), id & "," & integer'image(3));
      elsif j < 2 * group_width_c generate
        o(j) <= i(j-group_width_c) +
                operation(twid_c, opt_pwr(1)(1), m(1)(j-group_width_c), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(1), m(2)(j-group_width_c), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(1), m(3)(j-group_width_c), id & "," & integer'image(3));
      elsif j < 3 * group_width_c generate
        o(j) <= i(j-(2*group_width_c)) +
                operation(twid_c, opt_pwr(1)(2), m(1)(j-(2*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(2), m(2)(j-(2*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(2), m(3)(j-(2*group_width_c)), id & "," & integer'image(3));
      else generate
        o(j) <= i(j-(3*group_width_c)) +
                operation(twid_c, opt_pwr(1)(3), m(1)(j-(3*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(3), m(2)(j-(3*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(3), m(3)(j-(3*group_width_c)), id & "," & integer'image(3));
      end generate;
    end generate;

  elsif log_num_inputs_g = 3 generate

    constant radix_c       : positive                                             := 8;
    constant group_width_c : natural                                              := o'length/radix_c; -- Always 1
    constant powers_c      : natural_vector                                       := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1) := opt_pwr_arr(powers_c, group_width_c);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- Perform the Radix-8 FFT on eight operands. Indexing of twiddle factors has been generalised,
    -- leaving simplifications to a function 'twid_mod'.
--    o(0) <= i(0) + (twid_mod(twid_c,  0) * i(1)) + (twid_mod(twid_c,  0) * i(2)) + (twid_mod(twid_c,  0) * i(3)) + (twid_mod(twid_c, 0) * i(4)) + (twid_mod(twid_c,  0) * i(5)) + (twid_mod(twid_c,  0) * i(6)) + (twid_mod(twid_c,  0) * i(7));
--    o(1) <= i(0) + (twid_mod(twid_c,  4) * i(1)) + (twid_mod(twid_c,  2) * i(2)) + (twid_mod(twid_c,  6) * i(3)) + (twid_mod(twid_c, 1) * i(4)) + (twid_mod(twid_c,  5) * i(5)) + (twid_mod(twid_c,  3) * i(6)) + (twid_mod(twid_c,  7) * i(7));
--    o(2) <= i(0) + (twid_mod(twid_c,  8) * i(1)) + (twid_mod(twid_c,  4) * i(2)) + (twid_mod(twid_c, 12) * i(3)) + (twid_mod(twid_c, 2) * i(4)) + (twid_mod(twid_c, 10) * i(5)) + (twid_mod(twid_c,  6) * i(6)) + (twid_mod(twid_c, 14) * i(7));
--    o(3) <= i(0) + (twid_mod(twid_c, 12) * i(1)) + (twid_mod(twid_c,  6) * i(2)) + (twid_mod(twid_c, 18) * i(3)) + (twid_mod(twid_c, 3) * i(4)) + (twid_mod(twid_c, 15) * i(5)) + (twid_mod(twid_c,  9) * i(6)) + (twid_mod(twid_c, 21) * i(7));
--    o(4) <= i(0) + (twid_mod(twid_c, 16) * i(1)) + (twid_mod(twid_c,  8) * i(2)) + (twid_mod(twid_c, 24) * i(3)) + (twid_mod(twid_c, 4) * i(4)) + (twid_mod(twid_c, 20) * i(5)) + (twid_mod(twid_c, 12) * i(6)) + (twid_mod(twid_c, 28) * i(7));
--    o(5) <= i(0) + (twid_mod(twid_c, 20) * i(1)) + (twid_mod(twid_c, 10) * i(2)) + (twid_mod(twid_c, 30) * i(3)) + (twid_mod(twid_c, 5) * i(4)) + (twid_mod(twid_c, 25) * i(5)) + (twid_mod(twid_c, 15) * i(6)) + (twid_mod(twid_c, 35) * i(7));
--    o(6) <= i(0) + (twid_mod(twid_c, 24) * i(1)) + (twid_mod(twid_c, 12) * i(2)) + (twid_mod(twid_c, 36) * i(3)) + (twid_mod(twid_c, 6) * i(4)) + (twid_mod(twid_c, 30) * i(5)) + (twid_mod(twid_c, 18) * i(6)) + (twid_mod(twid_c, 42) * i(7));
--    o(7) <= i(0) + (twid_mod(twid_c, 28) * i(1)) + (twid_mod(twid_c, 14) * i(2)) + (twid_mod(twid_c, 42) * i(3)) + (twid_mod(twid_c, 7) * i(4)) + (twid_mod(twid_c, 35) * i(5)) + (twid_mod(twid_c, 21) * i(6)) + (twid_mod(twid_c, 49) * i(7));

    -- As group_width_c = 1, There are no roots of unity between opt_pwr roots.
    m(1)(0) <= i(1); -- operation(twid_c,  powers_c(1)*0, i(1))
    m(2)(0) <= i(2); -- operation(twid_c,  powers_c(2)*0, i(2))
    m(3)(0) <= i(3); -- operation(twid_c,  powers_c(3)*0, i(3))
    m(4)(0) <= i(4); -- operation(twid_c,  powers_c(4)*0, i(4))
    m(5)(0) <= i(5); -- operation(twid_c,  powers_c(5)*0, i(5))
    m(6)(0) <= i(6); -- operation(twid_c,  powers_c(6)*0, i(6))
    m(7)(0) <= i(7); -- operation(twid_c,  powers_c(7)*0, i(7))

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    -- Perform the Radix-8 FFT on eight operands. As group_width_c = 1, (j-(group*group_width_c)) = 0.
    butterfly_g : for j in o'range generate
      constant id : string := o'instance_name & integer'image(j);
    begin
      eigth_g : if j < group_width_c generate
--        assert false report "m(?)(" & integer'image(j) & ")" severity note;
        o(j) <= i(j) +
                operation(twid_c, opt_pwr(1)(0), m(1)(j), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(0), m(2)(j), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(0), m(3)(j), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(0), m(4)(j), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(0), m(5)(j), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(0), m(6)(j), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(0), m(7)(j), id & "," & integer'image(7));
      elsif j < 2 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-group_width_c) & ")" severity note;
        o(j) <= i(j-group_width_c) +
                operation(twid_c, opt_pwr(1)(1), m(1)(j-group_width_c), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(1), m(2)(j-group_width_c), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(1), m(3)(j-group_width_c), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(1), m(4)(j-group_width_c), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(1), m(5)(j-group_width_c), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(1), m(6)(j-group_width_c), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(1), m(7)(j-group_width_c), id & "," & integer'image(7));
      elsif j < 3 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-(2*group_width_c)) & ")" severity note;
        o(j) <= i(j-(2*group_width_c)) +
                operation(twid_c, opt_pwr(1)(2), m(1)(j-(2*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(2), m(2)(j-(2*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(2), m(3)(j-(2*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(2), m(4)(j-(2*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(2), m(5)(j-(2*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(2), m(6)(j-(2*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(2), m(7)(j-(2*group_width_c)), id & "," & integer'image(7));
      elsif j < 4 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-(3*group_width_c)) & ")" severity note;
        o(j) <= i(j-(3*group_width_c)) +
                operation(twid_c, opt_pwr(1)(3), m(1)(j-(3*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(3), m(2)(j-(3*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(3), m(3)(j-(3*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(3), m(4)(j-(3*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(3), m(5)(j-(3*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(3), m(6)(j-(3*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(3), m(7)(j-(3*group_width_c)), id & "," & integer'image(7));
      elsif j < 5 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-(4*group_width_c)) & ")" severity note;
        o(j) <= i(j-(4*group_width_c)) +
                operation(twid_c, opt_pwr(1)(4), m(1)(j-(4*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(4), m(2)(j-(4*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(4), m(3)(j-(4*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(4), m(4)(j-(4*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(4), m(5)(j-(4*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(4), m(6)(j-(4*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(4), m(7)(j-(4*group_width_c)), id & "," & integer'image(7));
      elsif j < 6 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-(5*group_width_c)) & ")" severity note;
        o(j) <= i(j-(5*group_width_c)) +
                operation(twid_c, opt_pwr(1)(5), m(1)(j-(5*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(5), m(2)(j-(5*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(5), m(3)(j-(5*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(5), m(4)(j-(5*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(5), m(5)(j-(5*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(5), m(6)(j-(5*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(5), m(7)(j-(5*group_width_c)), id & "," & integer'image(7));
      elsif j < 7 * group_width_c generate
--        assert false report "m(?)(" & integer'image(j-(6*group_width_c)) & ")" severity note;
        o(j) <= i(j-(6*group_width_c)) +
                operation(twid_c, opt_pwr(1)(6), m(1)(j-(6*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(6), m(2)(j-(6*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(6), m(3)(j-(6*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(6), m(4)(j-(6*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(6), m(5)(j-(6*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(6), m(6)(j-(6*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(6), m(7)(j-(6*group_width_c)), id & "," & integer'image(7));
      else generate
--        assert false report "m(?)(" & integer'image(j-(7*group_width_c)) & ")" severity note;
        o(j) <= i(j-(7*group_width_c)) +
                operation(twid_c, opt_pwr(1)(7), m(1)(j-(7*group_width_c)), id & "," & integer'image(1)) +
                operation(twid_c, opt_pwr(2)(7), m(2)(j-(7*group_width_c)), id & "," & integer'image(2)) +
                operation(twid_c, opt_pwr(3)(7), m(3)(j-(7*group_width_c)), id & "," & integer'image(3)) +
                operation(twid_c, opt_pwr(4)(7), m(4)(j-(7*group_width_c)), id & "," & integer'image(4)) +
                operation(twid_c, opt_pwr(5)(7), m(5)(j-(7*group_width_c)), id & "," & integer'image(5)) +
                operation(twid_c, opt_pwr(6)(7), m(6)(j-(7*group_width_c)), id & "," & integer'image(6)) +
                operation(twid_c, opt_pwr(7)(7), m(7)(j-(7*group_width_c)), id & "," & integer'image(7));
      end generate;
    end generate;

  else generate

    constant radix_c       : positive                                                   := 8;
    constant group_width_c : natural                                                    := o'length/radix_c;
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);
    signal   t             : complex_vector(0 to (2**log_num_inputs_g)-1);
    signal   m             : complex_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1);

  begin

    -- Recurse and combine
    dft_g : for j in 0 to radix_c-1 generate

      dftr_i : entity work.dftr_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_g-3
        )
        port map (
          i => i(j*i'length/8 to (j+1)*i'length/8-1),
          o => t(j*t'length/8 to (j+1)*t'length/8-1)
        );

    end generate;

    -- Combine
    -- Reusable multiplications
    col_g : for j in m'range generate -- (1 to radix_c-1)
      row_g : for k in m(j)'range generate -- (0 to group_width_c-1)
        constant id : string := m'instance_name & integer'image(j) & "," & integer'image(k);
      begin
        m(j)(k) <= operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), id);
      end generate;
    end generate;

    -- m(1)(0) <= operation(twid_c,  0, i(1)); -- +1 x i(1)
    -- m(1)(1) <= operation(twid_c,  4, i(1)); -- -1 x i(1),
    -- m(1)(2) <= m(1)(0);       --  8
    -- m(1)(3) <= m(1)(1);       -- 12
    --
    -- m(2)(0) <= operation(twid_c,  0, i(2)); -- +1 x i(2)
    -- m(2)(1) <= operation(twid_c,  2, i(2)); -- -i x i(2)
    -- m(2)(2) <= operation(twid_c,  4, i(2)); -- -1 x i(2)
    -- m(2)(3) <= operation(twid_c,  6, i(2)); -- +i x i(2)
    --
    -- m(3)(0) <= operation(twid_c,  0, i(3)); -- +1 x i(3)
    -- m(3)(1) <= operation(twid_c,  6, i(3)); -- +i x i(3)
    -- m(3)(2) <= operation(twid_c, 12, i(3)); -- -1 x i(3)
    -- m(3)(3) <= operation(twid_c, 18, i(3)); -- -i x i(3)
    --
    -- m(4)(0) <= operation(twid_c,  0, i(4)); -- +1 x i(4)
    -- m(4)(1) <= operation(twid_c,  1, i(4));
    -- m(4)(2) <= operation(twid_c,  2, i(4)); -- -i x i(4)
    -- m(4)(3) <= operation(twid_c,  3, i(4));
    --
    -- m(5)(0) <= operation(twid_c,  0, i(5)); -- +1 x i(5)
    -- m(5)(1) <= operation(twid_c,  5, i(5));
    -- m(5)(2) <= operation(twid_c, 10, i(5)); -- -i x i(5)
    -- m(5)(3) <= operation(twid_c, 15, i(5));
    --
    -- m(6)(0) <= operation(twid_c,  0, i(6)); -- +1 x i(6)
    -- m(6)(1) <= operation(twid_c,  3, i(6));
    -- m(6)(2) <= operation(twid_c,  6, i(6)); -- +i x i(6)
    -- m(6)(3) <= operation(twid_c,  9, i(6));
    --
    -- m(7)(0) <= operation(twid_c,  0, i(7)); -- +1 x i(7)
    -- m(7)(1) <= operation(twid_c,  7, i(7));
    -- m(7)(2) <= operation(twid_c, 14, i(7));
    -- m(7)(3) <= operation(twid_c, 21, i(7));

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    butterfly_g : for j in o'range generate
      constant group_c : natural := (j / group_width_c);
      constant id      : string  := o'instance_name & integer'image(j);
    begin
      -- Optimised multiplication & sum as operation() avoids multiplications of 1, -i, -1 & i.
      o(j) <= t(j-(group_c*group_width_c)) +
              operation(twid_c, opt_pwr(1)(group_c), m(1)(j-(group_c*group_width_c)), id & "," & integer'image(1)) +
              operation(twid_c, opt_pwr(2)(group_c), m(2)(j-(group_c*group_width_c)), id & "," & integer'image(2)) +
              operation(twid_c, opt_pwr(3)(group_c), m(3)(j-(group_c*group_width_c)), id & "," & integer'image(3)) +
              operation(twid_c, opt_pwr(4)(group_c), m(4)(j-(group_c*group_width_c)), id & "," & integer'image(4)) +
              operation(twid_c, opt_pwr(5)(group_c), m(5)(j-(group_c*group_width_c)), id & "," & integer'image(5)) +
              operation(twid_c, opt_pwr(6)(group_c), m(6)(j-(group_c*group_width_c)), id & "," & integer'image(6)) +
              operation(twid_c, opt_pwr(7)(group_c), m(7)(j-(group_c*group_width_c)), id & "," & integer'image(7));
    end generate;

  end generate;

end architecture;


-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix8 of dft_real is
begin

  dftr_i : entity work.dftr_real(radix8)
    generic map (
      log_num_inputs_g => log_num_inputs_g
    )
    port map (
      i => array_reverse(i),
      o => o
    );

end architecture;
