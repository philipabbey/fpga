-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the individual radix real FFT implementation.
--
-- References:
--   1) Fast Fourier Transform (FFT),
--      https://www.cmlab.csie.ntu.edu.tw/cml/dsp/training/coding/transform/fft.html
--   2) Worked examples from:
--      a) https://www.youtube.com/watch?v=AF71Yqo7CoY
--      b) https://www.youtube.com/watch?v=xnVaHkRaJOw
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

use work.test_fft_pkg.all;
use work.test_data_fft_pkg.all;

entity test_fft_real is
  constant radix_c : positive := 2;
end entity;


architecture point4 of test_fft_real is

  constant log_num_inputs_c : positive := 2;

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  process
    constant input_data_c  : complex_vector_arr_t := input_data_point4_c;
    constant output_data_c : complex_vector_arr_t := output_data_point4_c;
    constant tolerance_c   : real                 := 0.00001;
    variable passed        : boolean              := true;
  begin

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait for iteration_time_c / 2;

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait for iteration_time_c / 2;
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 4-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 4-point FFT results: FAILED" severity warning;
    end if;

    wait;
  end process;


  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT with only 4 points is not possible."
        severity error;
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point8 of test_fft_real is

  constant log_num_inputs_c : positive := 3;

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  process
    constant input_data_c  : complex_vector_arr_t := input_data_point8_c;
    constant output_data_c : complex_vector_arr_t := output_data_point8_c;
    constant tolerance_c   : real                 := 0.00001;
    variable passed        : boolean              := true;
  begin

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait for iteration_time_c / 2;

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait for iteration_time_c / 2;
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 8-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 8-point FFT results: FAILED" severity warning;
    end if;

    wait;
  end process;


  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      dft_real_i : entity work.dft_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point16 of test_fft_real is

  constant log_num_inputs_c : positive := 4;

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  process
    constant input_data_c  : complex_vector_arr_t := input_data_point16_c;
    constant output_data_c : complex_vector_arr_t := output_data_point16_c;
    constant tolerance_c   : real                 := 0.00001;
    variable passed        : boolean              := true;
  begin

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait for iteration_time_c / 2;

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait for iteration_time_c / 2;
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 16-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 16-point FFT results: FAILED" severity warning;
    end if;

    wait;
  end process;


  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      dft_real_i : entity work.dft_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point32 of test_fft_real is

  constant log_num_inputs_c : positive := 5;

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  process
    constant input_data_c  : complex_vector_arr_t := input_data_point32_c;
    constant output_data_c : complex_vector_arr_t := output_data_point32_c;
    constant tolerance_c   : real                 := 0.00001;
    variable passed        : boolean              := true;
  begin

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait for iteration_time_c / 2;

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait for iteration_time_c / 2;
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 32-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 32-point FFT results: FAILED" severity warning;
    end if;

    wait;
  end process;


  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      dft_real_i : entity work.dft_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point512 of test_fft_real is

  constant log_num_inputs_c : positive := 9;

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  process
    constant input_data_c  : complex_vector_arr_t := input_data_point512_c;
    constant output_data_c : complex_vector_arr_t := output_data_point512_c;
    constant tolerance_c   : real                 := 0.0001;
    variable passed        : boolean              := true;
  begin

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait for iteration_time_c / 2;

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values: output of " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;

      wait for iteration_time_c / 2;
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 512-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 512-point FFT results: FAILED" severity warning;
    end if;

    wait;
  end process;


  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      dft_real_i : entity work.dft_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture instance of test_fft_real is

  constant log_num_inputs_c : positive := 4;
  constant radix_l          : positive := 4; -- Ignore radix_c from entity

  signal i, o : work.fft_real_pkg.complex_vector(0 to (2**log_num_inputs_c)-1);

begin

  assert false
    report "Radix-" & integer'image(radix_l) & " " & integer'image(2**log_num_inputs_c) & "-point FFT"
    severity note;

  dut_g: case radix_l generate
    when 2 =>
      dft_real_i : entity work.dft_real(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 4 =>
      dft_real_i : entity work.dft_real(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when 8 =>
      dft_real_i : entity work.dft_real(radix8)
        generic map (
          log_num_inputs_g => log_num_inputs_c
        )
        port map (
          i => i,
          o => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_l) & " FFT is not possible."
        severity error;
  end generate;

end architecture;
