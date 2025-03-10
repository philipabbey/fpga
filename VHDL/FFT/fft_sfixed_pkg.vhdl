-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Radix-n FFT package for VHDL sfixed type.
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.numeric_std.all;
  use ieee.math_complex.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library local;
  use local.rtl_pkg.natural_vector;

package fft_sfixed_pkg is

  type complex_t is record
    re : sfixed; -- Real part
    im : sfixed; -- Imaginary part
  end record;

  type complex_arr_t        is array (integer range <>) of complex_t;
  type complex_2darr_t      is array (integer range <>) of complex_arr_t;
  type natural_vector_arr_t is array (integer range <>) of natural_vector;


  -- Addition operator for complex_t type.
  --
  function "+" (
    l : complex_t;
    r : complex_t
  ) return complex_t;


  -- Subtraction operator for complex_t type.
  --
  function "-" (
    l : complex_t;
    r : complex_t
  ) return complex_t;


  -- Multiplication operator for complex_t type.
  --
  function "*" (
    l : complex_t;
    r : complex_t
  ) return complex_t;


  -- Equality operator for complex_t type.
  --
  function "=" (
    l : complex_t;
    r : complex_t
  ) return boolean;


  -- Resize operator for complex_t type. A dual application of the sfixed type's resize operator.
  --
  function resize(
    val      : complex_t;
    template : sfixed
  ) return complex_t;


  -- Convert complex type to complex_t.
  --
  function to_complex_t(
    z        : complex;
    template : sfixed
  ) return complex_t;


  -- Convert real + imaginary pair type to complex_t.
  --
  function to_complex_t(
    re       : real;
    im       : real;
    template : sfixed
  ) return complex_t;


  -- Convert complex_vector type to complex_arr_t.
  --
  function to_complex_arr_t(
    i        : work.fft_real_pkg.complex_vector;
    template : sfixed
  ) return complex_arr_t;


  -- Easiest illustrated through an example, here is the bit reversal of the indices of 8 values
  --
  -- | Value | Binary | Bit Reverse Binary | Bit Reversed Value |
  -- +-------+--------+--------------------+--------------------+
  -- |   0   |  000   |        000         |         0          |
  -- |   1   |  001   |        100         |         4          |
  -- |   2   |  010   |        010         |         2          |
  -- |   3   |  011   |        110         |         6          |
  -- |   4   |  100   |        001         |         1          |
  -- |   5   |  101   |        101         |         5          |
  -- |   6   |  110   |        011         |         3          |
  -- |   7   |  111   |        111         |         7          |
  --
  function bit_reverse(i : natural; bits : positive) return natural;


  -- Return an array of complex numbers with their positions permuted according to the bit reversal
  -- function above.
  --
  function array_reverse(i : complex_arr_t) return complex_arr_t;


  -- Return the first num of 2*num roots of unity, where the second half
  -- are negative version of the first half.
  -- Let k = 0..(num-1)
  -- Euler: e**(-i*2*pi*k/(2*num)) = cos(2*pi*k/(2*num)) - i*sin(2*pi*k/(2*num))
  --
  function init_twiddles_half(
    num      : positive;
    template : sfixed
  ) return complex_arr_t;


  -- Return the nth root of unity from the twiddle array, wrapping around at N-1 back to 0, i.e. mod N.
  -- Where the root of unity is given by:
  --
  --  n+kN     n
  -- W      = W ,   for all integers k
  --  N        N
  --
  -- Usage:
  --   -- Assign the (N/2) twiddle factors
  --   constant twid_c : complex_vector(0 to (2**(log_num_inputs_g-1))-1) := init_twiddles_half(2**(log_num_inputs_g-1));
  --   -- Return the nth (of N) twiddle factor
  --   twid_mod(twid_c, n)
  --
  function twid_mod(
    t : complex_arr_t;
    n : natural
  ) return complex_t;


  -- Powers to use for the nth "twiddle factor", the value is actually the "bit reverse" of n.
  --
  -- Return the powers to raise the twiddle factors by according to the Danielson-Lanczos Lemma.
  -- Essentially for a Radix-n implementation, the sequence of numbers 0..(n-1) are individually bit
  -- reversed and returned as an array. E.g. the sequence "0, 1, 2, 3, 4, 5, 6, 7" becomes
  -- "0, 4, 2, 6, 1, 5, 3, 7" as in the columns of the table above. The need for this will become more
  -- obvious with the higher radix implementations.
  --
  function twiddle_power(num : positive) return natural_vector;


  -- Avoid trivial multiplications and only infer a multiplier when not +/-1 or +/-i.
  --
  --    0          N/4          N/2          4N/4
  --   W   = 0,   W   = -i,    W   = -1,    W   = i
  --    N          N            N            N
  --
  -- All of these convert multiplications to sign swaps or real and imaginary part swaps avoiding much
  -- more expensive multiplications. Here the requirement is to intercept trivial multiplication requests
  -- such as those shown above and provide the '+1', '-1', '+i' or '-i' operator based on the power of the
  -- twiddle factor. If the multiplication is non-trivial, performs the actual multiplication and records
  -- the fact of using a multiplication for subsequent log analysis.
  --
  function operation(
    twids   : complex_arr_t;
    power   : natural;
    operand : complex_t;
    id      : string
  ) return complex_t;


  -- Intended to be the array of "optimising powers" of the twiddle factors, i.e. those that were factored
  -- out as trivial multiplies for Radix-2 and Radix-4 and applied separately. Optimised powers that are
  -- +/-1 or +/-i and hence avoid multiplication. Radix-2 & Radix-4 collapse these via the operation()
  -- function.
  --
  -- Usage:
  --   constant opt_pwr : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1) := opt_pwr_arr(powers_c, group_width_c);
  --
  -- To convert these to their respective twiddle factors use:
  --   opt_twid(j)(k) <= operation(twid_c, opt_pwr(j)(k), (re => 1.0, im => 0.0));
  --
  function opt_pwr_arr(
    powers      : natural_vector;
    group_width : positive
  ) return natural_vector_arr_t;


  -- Intended to be the array of "partial powers" of the twiddle factors, i.e. those that are unavoidably
  -- non-trivial multiplies, typically roots of unity between +1, -i, -1 and +i.
  --
  -- Usage:
  --   constant part_pwr : natural_vector_arr_t(1 to radix_c-1)(0 to group_width_c-1) := part_pwr_arr(powers_c, group_width_c);
  --
  -- To convert these to their respective twiddle factors use:
  --   part_twid(j)(k) <= operation(twid_c, part_pwr(j)(k), (re => 1.0, im => 0.0));
  --
  function part_pwr_arr(
    powers      : natural_vector;
    group_width : positive
  ) return natural_vector_arr_t;

end package;


library local;

package body fft_sfixed_pkg is

  function "+" (
    l : complex_t;
    r : complex_t
  ) return complex_t is
  begin
    return (
      re => l.re + r.re,
      im => l.im + r.im
    );
  end function;


  function "-" (
    l : complex_t;
    r : complex_t
  ) return complex_t is
  begin
    return (
      re => l.re - r.re,
      im => l.im - r.im
    );
  end function;


  function "-" (
    z : complex_t
  ) return complex_t is
  begin
    return (
      re => - z.re,
      im => - z.im
    );
  end function;


  function "*" (
    l : complex_t;
    r : complex_t
  ) return complex_t is
  begin
    return (
      re => (l.re * r.re) - (l.im * r.im),
      im => (l.re * r.im) + (l.im * r.re)
    );
  end function;


  function "=" (
    l : complex_t;
    r : complex_t
  ) return boolean is
  begin
    if (l.re = r.re) and (l.im = r.im) then
      return true;
    else
      return false;
    end if;
  end function;


  function resize(
    val      : complex_t;
    template : sfixed
  ) return complex_t is
  begin
    return (
      re => resize(
        val.re,
        template
      ),
      im => resize(
        val.im,
        template
      )
    );
  end function;


  function to_complex_t(
    z        : complex;
    template : sfixed
  ) return complex_t is
  begin
    return (
      re => to_sfixed(z.re, template),
      im => to_sfixed(z.im, template)
    );
  end function;


  function to_complex_t(
    re       : real;
    im       : real;
    template : sfixed
  ) return complex_t is
  begin
    return (
      re => to_sfixed(re, template),
      im => to_sfixed(im, template)
    );
  end function;


  function to_complex_arr_t(
    i        : work.fft_real_pkg.complex_vector;
    template : sfixed
  ) return complex_arr_t is
    variable ret : complex_arr_t(i'range)(
      re(template'range),
      im(template'range)
    );
  begin
    for k in i'range loop
      ret(k) := to_complex_t(i(k), template);
    end loop;
    return ret;
  end function;


  function bit_reverse(i : natural; bits : positive) return natural is
    variable tmp : unsigned(bits-1 downto 0) := to_unsigned(i, bits);
    variable ret : unsigned(bits-1 downto 0);
  begin
    for j in 0 to bits-1 loop
      ret(j) := tmp(tmp'high-j);
    end loop;
    return to_integer(ret);
  end function;


  function array_reverse(i : complex_arr_t) return complex_arr_t is
    variable ret : complex_arr_t(i'range)(
      re(i(i'low).re'range),
      im(i(i'low).im'range)
    );
  begin
    -- Copy the input array elements across to theire new location.
    for j in i'range loop
      ret(bit_reverse(j, local.math_pkg.ceil_log(i'length))) := i(j);
    end loop;
    return ret;
  end function;


  -- Return the first num of 2*num roots
  -- Let n = 2*num
  -- Euler: e**(-i*2*pi/n) = cos(2*pi/n) - i*sin(2*pi/n)
  function init_twiddles_half(
    num      : positive;
    template : sfixed
  ) return complex_arr_t is
    -- NB. Really just need element 0 initialised
    variable ret : complex_arr_t(0 to num-1)(
      re(template'range),
      im(template'range)
    );
  begin
    -- Calculate the num'th root of unity and raise to the power of k.
    for k in ret'range loop
      ret(k) := (
        re => to_sfixed( ieee.math_real.cos(ieee.math_real.math_pi * real(k) / real(num)), template),
        im => to_sfixed(-ieee.math_real.sin(ieee.math_real.math_pi * real(k) / real(num)), template)
      );
    end loop;
    return ret;
  end function;


  -- constant twid_c : complex_vector(0 to (2**(log_num_inputs_g-1))-1) := init_twiddles_half(2**(log_num_inputs_g-1));
  -- Return the nth root of unity from the twiddle array, wrapping around at n-1 back to 0, i.e. the modulus.
  -- i.e. t(1)**n
  -- Usage twid_mod(twid_c, 2*j)
  function twid_mod(
    t : complex_arr_t;
    n : natural
  ) return complex_t is
    variable idx : natural := n mod (2*t'length);
  begin
    if idx < t'length then
      return t(idx);
    else
      -- Exploit the symmetry of FFT twiddles
      return -t(idx-t'length);
    end if;
  end function;


  -- Powers to use for the nth "twiddle factor", the value is actually the "bit reverse" of n.
  function twiddle_power(num : positive) return natural_vector is
    variable ret : natural_vector(0 to num-1);
  begin
    for i in ret'range loop
      ret(i) := bit_reverse(i, local.math_pkg.ceil_log(num));
    end loop;
    return ret;
  end function;


  function operation(
    twids   : complex_arr_t;
    power   : natural;
    operand : complex_t;
    id      : string
  ) return complex_t is
    constant debug : boolean := true;
    variable p     : natural := power mod (2*twids'length);
  begin
    if p = 0 then
      -- n=0, avoid multiply by 1
      return operand;
    elsif (4 * p) = (2 * twids'length) then
      -- n=N/4, avoid multiply by -i
      return (re => operand.im, im => -operand.re);
    elsif (2 * p) = (2 * twids'length) then
      -- n=N/2, avoid multiply by -1
      return (re => -operand.re, im => -operand.im);
    elsif (4 * p) = (3 * (2 * twids'length)) then
      -- n=3*N/4, avoid multiply by i
      return (re => -operand.im, im => operand.re);
    else
      -- We have to perform the multiplication
      if debug then
        report "Multiplier ID " & id & ": For W^n_N, N=" & integer'image(2*twids'length) & " n=" & integer'image(p) severity note;
      end if;
      return twid_mod(twids, p) * operand;
    end if;
  end function;


  function opt_pwr_arr(
    powers      : natural_vector;
    group_width : positive
  ) return natural_vector_arr_t is
    constant radix_c : positive := powers'length;
    variable opt_pwr : natural_vector_arr_t(1 to radix_c-1)(0 to radix_c-1);
  begin
    col : for j in 1 to radix_c-1 loop
      row : for k in opt_pwr(opt_pwr'low)'range loop -- (0 to radix_c-1)
        opt_pwr(j)(k) := (powers(j)*k*group_width) mod (radix_c*group_width); -- NB. o'length = radix_c * group_width
      end loop;
    end loop;
    return opt_pwr;
  end function;


  function part_pwr_arr(
    powers      : natural_vector;
    group_width : positive
  ) return natural_vector_arr_t is
    constant radix_c : positive := powers'length;
    variable part_pwr : natural_vector_arr_t(1 to radix_c-1)(0 to group_width-1);
  begin
    col : for j in 1 to radix_c-1 loop
      row : for k in part_pwr(part_pwr'low)'range loop -- (0 to group_width_c-1)
        part_pwr(j)(k) := (powers(j)*k) mod (radix_c*group_width); -- NB. o'length = radix_c * group_width
      end loop;
    end loop;
    return part_pwr;
  end function;

end package body;
