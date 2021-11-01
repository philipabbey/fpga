-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Radix-2 & 4 implementation using fixed point arithmetic using recursive VHDL.
--
-- References:
--   1) A DFT and FFT TUTORIAL,
--      http://www.alwayslearn.com/DFT%20and%20FFT%20Tutorial/DFTandFFT_FFT_Overview.html
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.std_logic;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;
use work.fft_sfixed_pkg.all;

entity dft_sfixed is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10
    template_g       : sfixed    -- Provide an uninitialised vector solely for passing information about the fixed point range
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
use work.fft_sfixed_pkg.all;

entity dftr_sfixed is
  generic (
    log_num_inputs_g : positive; -- E.g. 1024 point FFT => log_num_inputs_g = 10
    template_g       : sfixed    -- Provide an uninitialised vector solely for passing information about the fixed point range
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


-------------
-- Radix-2 --
-------------

architecture radix2 of dftr_sfixed is

  constant radix_c : positive := 2;
  constant twid_c  : complex_arr_t(0 to 2**(log_num_inputs_g-1)-1) := init_twiddles_half(2**(log_num_inputs_g-1), template_g);

begin

  recurse_g : if log_num_inputs_g = 1 generate

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    -- Perform the Radix-2 FFT on two operands
    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          o <= (others => (
            re => (others => '0'),
            im => (others => '0')
          ));
        else
          -- Perform the Radix-2 FFT on two operands
          o(0) <= resize(i(0) + i(1), template_g);
          o(1) <= resize(i(0) - i(1), template_g);
        end if;
      end if;
    end process;

  else generate

    constant group_width_c : positive                                                   := o'length/radix_c;
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);

    signal t : complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    );

    signal prods : complex_2darr_t(0 to radix_c-1)(0 to group_width_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

    signal sums : complex_2darr_t(o'range)(0 to radix_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

  begin

    -- Recurse and combine
    dftr_i0 : entity work.dftr_sfixed(radix2)
      generic map (
        log_num_inputs_g => log_num_inputs_g-1,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(0 to i'length/2-1),
        o     => t(0 to t'length/2-1)
      );

    dftr_i1 : entity work.dftr_sfixed(radix2)
      generic map (
        log_num_inputs_g => log_num_inputs_g-1,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(i'length/2 to i'high),
        o     => t(t'length/2 to t'high)
      );

    -- Combine
    -- Reusable multiplications
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
            if j = 0 then
              for k in 0 to group_width_c-1 loop
                prods(0)(k) <= t(k);
              end loop;
            else
              for k in prods(j)'range loop
                prods(j)(k) <= resize(operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), prods'instance_name & integer'image(j) & "," & integer'image(k)), template_g);
              end loop;
            end if;
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

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    process(clk)
      constant group_width_c : natural := o'length/2;
    begin
      if rising_edge(clk) then
        if reset = '1' then
          o <= (others => (
            re => (others => '0'),
            im => (others => '0')
          ));
        else
          for j in o'range loop
            o(j) <= resize(sums(j)(0) + sums(j)(1), template_g);
          end loop;
        end if;
      end if;
    end process;

  end generate;

end architecture;


-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix2 of dft_sfixed is
begin

  dftr_i : entity work.dftr_sfixed(radix2)
    generic map (
      log_num_inputs_g => log_num_inputs_g,
      template_g       => template_g
    )
    port map (
      clk   => clk,
      reset => reset,
      i     => array_reverse(i),
      o     => o
    );

end architecture;


-------------
-- Radix-4 --
-------------

library local;
use work.adder_tree_pkg.all;

architecture radix4 of dftr_sfixed is

  constant twid_c : complex_arr_t(0 to 2**(log_num_inputs_g-1)-1) := init_twiddles_half(2**(log_num_inputs_g-1), template_g);

begin

  recurse_g : if log_num_inputs_g = 1 generate

    constant radix_c : positive := 2;

  begin

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    -- Perform the Radix-2 FFT on two operands
    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          o <= (others => (
            re => (others => '0'),
            im => (others => '0')
          ));
        else
          -- Perform the Radix-2 FFT on two operands
          o(0) <= resize(i(0) + i(1), template_g);
          o(1) <= resize(i(0) - i(1), template_g);
        end if;
      end if;
    end process;

  elsif log_num_inputs_g = 2 generate

    constant radix_c       : positive                                                   := 4;
    constant group_width_c : positive                                                   := o'length/radix_c; -- Always 1
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);

    signal prods : complex_2darr_t(1 to radix_c-1)(0 to group_width_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

    signal sums : complex_2darr_t(o'range)(0 to radix_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

  begin

    -- Perform the Radix-4 FFT on four operands
    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          prods <= (others => (others => (
            re => (others => '0'),
            im => (others => '0')
          )));
        else
          prods <= (
            (0 => i(1)),
            (0 => i(2)),
            (0 => i(3))
          );
        end if;
      end if;
    end process;

    col_g : for j in sums'range generate -- o'range
      sums(j)(0) <= i(0);

      row_g : for k in 1 to radix_c-1 generate
        constant id : string := prods'instance_name & integer'image(j) & "," & integer'image(k);
      begin
        sums(j)(k) <= resize(operation(twid_c, opt_pwr(k)(j), prods(k)(0), id), template_g);
      end generate;
    end generate;

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    adders_g : for j in o'range generate
      signal u : complex_t(
        re(output_bits(template_g'high, sums(j)'length) downto template_g'low),
        im(output_bits(template_g'high, sums(j)'length) downto template_g'low)
      );
      signal ot : complex_arr_t(0 to (2**log_num_inputs_g)-1)(
        re(template_g'range),
        im(template_g'range)
      );
    begin

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

  else generate

    constant radix_c       : positive                                                   := 4;
    constant group_width_c : natural                                                    := o'length/4;
    constant powers_c      : natural_vector                                             := twiddle_power(radix_c);
    constant opt_pwr       : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1)       := opt_pwr_arr(powers_c, group_width_c);
    constant part_pwr      : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);

    signal t : complex_arr_t(0 to (2**log_num_inputs_g)-1)(
      re(template_g'range),
      im(template_g'range)
    );

    signal prods : complex_2darr_t(0 to radix_c-1)(0 to group_width_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

    signal sums : complex_2darr_t(o'range)(0 to radix_c-1)(
      re(template_g'range),
      im(template_g'range)
    );

  begin

    -- Recurse and combine
    dftr_i0 : entity work.dftr_sfixed(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(0 to i'length/4-1),
        o     => t(0 to t'length/4-1)
      );

    dftr_i1 : entity work.dftr_sfixed(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(i'length/4 to i'length/2-1),
        o     => t(t'length/4 to t'length/2-1)
      );

    dftr_i2 : entity work.dftr_sfixed(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(i'length/2 to 3*i'length/4-1),
        o     => t(t'length/2 to 3*t'length/4-1)
      );

    dftr_i3 : entity work.dftr_sfixed(radix4)
      generic map (
        log_num_inputs_g => log_num_inputs_g-2,
        template_g       => template_g
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i(3*i'length/4 to i'high),
        o     => t(3*t'length/4 to t'high)
      );


    -- Combine
    -- Reusable multiplications
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
            if j = 0 then
              for k in 0 to group_width_c-1 loop
                prods(0)(k) <= t(k);
              end loop;
            else
              for k in prods(j)'range loop
                prods(j)(k) <= resize(operation(twid_c, part_pwr(j)(k), t(k+(j*group_width_c)), prods'instance_name & integer'image(j) & "," & integer'image(k)), template_g);
              end loop;
            end if;
          end loop;
--          for j in o'range loop
--            if j < group_width_c then
--              prods(j) <= (
--                                                         t(j                  ),
--                resize(operation(twid_c, 0,              t(j+   group_width_c ), prods'instance_name & integer'image(0) & "," & integer'image(j+   group_width_c )), template_g),
--                resize(operation(twid_c, 0,              t(j+(2*group_width_c)), prods'instance_name & integer'image(0) & "," & integer'image(j+(2*group_width_c))), template_g),
--                resize(operation(twid_c, 0,              t(j+(3*group_width_c)), prods'instance_name & integer'image(0) & "," & integer'image(j+(3*group_width_c))), template_g)
--              );
--            elsif j < 2 * group_width_c then
--              prods(j) <= (
--                                                         t(j-   group_width_c ),
--                resize(operation(twid_c, part_pwr(j)(1), t(j                  ), prods'instance_name & integer'image(1) & "," & integer'image(j+   group_width_c )), template_g),
--                resize(operation(twid_c, part_pwr(j)(2), t(j+   group_width_c ), prods'instance_name & integer'image(1) & "," & integer'image(j+(2*group_width_c))), template_g),
--                resize(operation(twid_c, part_pwr(j)(3), t(j+(2*group_width_c)), prods'instance_name & integer'image(1) & "," & integer'image(j+(3*group_width_c))), template_g)
--              );
--            elsif j < 3 * group_width_c then
--              -- For each group of width group_width_c
--            else
--              prods(j) <= (
--                                                         t(j-(3*group_width_c)),
--                resize(operation(twid_c, part_pwr(j)(1), t(j-(2*group_width_c)), prods'instance_name & integer'image(3) & "," & integer'image(j+   group_width_c )), template_g),
--                resize(operation(twid_c, part_pwr(j)(2), t(j-   group_width_c ), prods'instance_name & integer'image(3) & "," & integer'image(j+(2*group_width_c))), template_g),
--                resize(operation(twid_c, part_pwr(j)(3), t(j                  ), prods'instance_name & integer'image(3) & "," & integer'image(j+(3*group_width_c))), template_g)
--              );
--            end if;
--          end loop;
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

    assert false
      report "Adders: " & integer'image(o'length*(radix_c-1))
      severity note;

    adders_g : for j in o'range generate
      signal u : complex_t(
        re(output_bits(template_g'high, sums(j)'length) downto template_g'low),
        im(output_bits(template_g'high, sums(j)'length) downto template_g'low)
      );
    begin

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

  end generate;

end architecture;


-- Just perform the bit reversal on the input indices, then call the recursive component.
architecture radix4 of dft_sfixed is
begin

  dftr_i : entity work.dftr_sfixed(radix4)
    generic map (
      log_num_inputs_g => log_num_inputs_g,
      template_g       => template_g
    )
    port map (
      clk   => clk,
      reset => reset,
      i     => array_reverse(i),
      o     => o
    );

end architecture;
