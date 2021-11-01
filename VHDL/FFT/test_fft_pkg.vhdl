-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Package to support testing of an FFT with complex results.
--
-- P A Abbey, 2 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.math_complex.all;
library ieee_proposed;
use ieee_proposed.fixed_pkg.all;

package test_fft_pkg is

  -- Used for real FFT
  constant iteration_time_c : time := 100 ns;

  type complex_vector_arr_t is array (integer range <>) of work.fft_real_pkg.complex_vector;
  type complex_arr_arr_t    is array (integer range <>) of work.fft_sfixed_pkg.complex_arr_t;

  type tests_real_t is record
    log_num_inputs : positive;
    radix          : positive;
  end record;

  subtype negative is integer range integer'low to 0;

  type tests_sfixed_t is record
    log_num_inputs : positive;
    radix          : positive;
    input_high     : natural;
    input_low      : negative;
  end record;

  type tests_real_arr_t   is array(natural range<>) of tests_real_t;
  type tests_sfixed_arr_t is array(natural range<>) of tests_sfixed_t;


  -- Compare two complex type values for equality within a tolerance.
  --
  function compare_output(
    a         : complex;
    b         : complex;
    tolerance : real
  ) return boolean;


  -- Compare a complex_t type value with a complex type value for equality within a tolerance.
  --
  function compare_output(
    a         : work.fft_sfixed_pkg.complex_t;
    b         : complex;
    tolerance : real
  ) return boolean;


  -- Create a string for printing from a complex type value.
  --
  function complex_str(z : complex) return string;


  -- Create a string for printing from a complex_t type value.
  --
  function complex_str(z : work.fft_sfixed_pkg.complex_t) return string;


  -- Convert a complex_vector_arr_t type to a complex_arr_arr_t type.
  --
  function to_complex_arr_arr_t(
    i        : complex_vector_arr_t;
    template : sfixed
  ) return complex_arr_arr_t;

end package;


package body test_fft_pkg is

  function compare_output(
    a         : complex;
    b         : complex;
    tolerance : real
  ) return boolean is
  begin
    if abs(a.re - b.re) < tolerance and
       abs(a.im - b.im) < tolerance then
      return true;
    else
      return false;
    end if;
  end function;


  function compare_output(
    a         : work.fft_sfixed_pkg.complex_t;
    b         : complex;
    tolerance : real
  ) return boolean is
  begin
    if abs(to_real(a.re) - b.re) < tolerance and
       abs(to_real(a.im) - b.im) < tolerance then
      return true;
    else
      return false;
    end if;
  end function;


  function complex_str(z : complex) return string is
  begin
    return real'image(maximum(minimum(z.re, real'high), real'low)) & " + " & real'image(maximum(minimum(z.im, real'high), real'low)) & "i";
  end function;


  function complex_str(z : work.fft_sfixed_pkg.complex_t) return string is
  begin
    return real'image(to_real(z.re)) & " + " & real'image(to_real(z.im)) & "i";
  end function;


  function to_complex_arr_arr_t(
    i        : complex_vector_arr_t;
    template : sfixed
  ) return complex_arr_arr_t is
    variable ret : complex_arr_arr_t(i'range)(i(i'low)'range)(
      re(template'range),
      im(template'range)
    );
  begin
    for k in i'range loop
      ret(k) := work.fft_sfixed_pkg.to_complex_arr_t(i(k), template);
    end loop;
    return ret;
  end function;

end package body;
