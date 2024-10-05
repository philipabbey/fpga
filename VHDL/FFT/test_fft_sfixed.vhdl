-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the individual radix sfixed FFT implementation.
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

-- These are required for all architectures, hence applied at entity level
library ieee;
  use ieee.std_logic_1164.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library local;
  use local.testbench_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;
  use work.test_fft_pkg.all;
  use work.test_data_fft_pkg.all;

entity test_fft_sfixed is
  constant radix_c : positive := 2;
end entity;


architecture point4 of test_fft_sfixed is

  constant log_num_inputs_c : positive            := 2;
  -- 1 bit sign, 8 bits integer, 8 bits fractional
  constant template_c       : sfixed(8 downto -8) := to_sfixed(0.0, 8, -8);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o  : complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  clock(clk, 10 ns);

  process
    constant input_data_c       : complex_arr_arr_t    := to_complex_arr_arr_t(input_data_point4_c, template_c);
    constant output_data_c      : complex_vector_arr_t := output_data_point4_c;
    constant tolerance_c        : real                 := 0.001;
    variable passed             : boolean              := true;
    -- Additional delay for adder tree of depth log(radix_c, 2)
    constant adder_tree_depth_c : natural              := log_num_inputs_c;
    constant num_stages_c       : positive             := local.math_pkg.ceil_log(i'length, radix_c);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive             := (num_stages_c*(1+adder_tree_depth_c))+1;
  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait_nf_ticks(clk, fft_delay_c);

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait_nr_ticks(clk, 1);
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 4-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 4-point FFT results: FAILED" severity warning;
    end if;
    stop_clocks;

    wait;
  end process;

  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point8 of test_fft_sfixed is

  constant log_num_inputs_c : positive            := 3;
  -- 1 bit sign, 8 bits integer, 8 bits fractional
  constant template_c       : sfixed(8 downto -8) := to_sfixed(0.0, 8, -8);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o  : complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  clock(clk, 10 ns);

  process
    constant input_data_c       : complex_arr_arr_t    := to_complex_arr_arr_t(input_data_point8_c, template_c);
    constant output_data_c      : complex_vector_arr_t := output_data_point8_c;
    constant tolerance_c        : real                 := 0.001;
    variable passed             : boolean              := true;
    -- Additional delay for adder tree of depth log(radix_c, 2)
    constant adder_tree_depth_c : natural              := log_num_inputs_c;
    constant num_stages_c       : positive             := local.math_pkg.ceil_log(i'length, radix_c);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive             := (num_stages_c*(1+adder_tree_depth_c))+1;
  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait_nf_ticks(clk, fft_delay_c);

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait_nr_ticks(clk, 1);
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 8-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 8-point FFT results: FAILED" severity warning;
    end if;
    stop_clocks;

    wait;
  end process;

  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point16 of test_fft_sfixed is

  constant log_num_inputs_c : positive := 4;
  constant template_c       : sfixed(8 downto -8) := to_sfixed(0.0, 8, -8);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o : complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  clock(clk, 10 ns);

  process
    constant input_data_c       : complex_arr_arr_t    := to_complex_arr_arr_t(input_data_point16_c, template_c);
    constant output_data_c      : complex_vector_arr_t := output_data_point16_c;
    constant tolerance_c        : real                 := 0.05;
    variable passed             : boolean              := true;
    -- Additional delay for adder tree of depth log(radix_c, 2)
    constant adder_tree_depth_c : natural              := log_num_inputs_c;
    constant num_stages_c       : positive             := local.math_pkg.ceil_log(i'length, radix_c);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive             := (num_stages_c*(1+adder_tree_depth_c))+1;

  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait_nf_ticks(clk, fft_delay_c);

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait_nr_ticks(clk, 1);
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 16-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 16-point FFT results: FAILED" severity warning;
    end if;
    stop_clocks;

    wait;
  end process;

  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point32 of test_fft_sfixed is

  constant log_num_inputs_c : positive := 5;
  constant template_c       : sfixed(8 downto -8) := to_sfixed(0.0, 8, -8);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o : complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  clock(clk, 10 ns);

  process
    constant input_data_c       : complex_arr_arr_t    := to_complex_arr_arr_t(input_data_point32_c, template_c);
    constant output_data_c      : complex_vector_arr_t := output_data_point32_c;
    constant tolerance_c        : real                 := 0.05;
    variable passed             : boolean              := true;
    -- Additional delay for adder tree of depth log(radix_c, 2)
    constant adder_tree_depth_c : natural              := log_num_inputs_c;
    constant num_stages_c       : positive             := local.math_pkg.ceil_log(i'length, radix_c);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive             := (num_stages_c*(1+adder_tree_depth_c))+1;

  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait_nf_ticks(clk, fft_delay_c);

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait_nr_ticks(clk, 1);
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 32-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 32-point FFT results: FAILED" severity warning;
    end if;
    stop_clocks;

    wait;
  end process;

  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture point512 of test_fft_sfixed is

  constant log_num_inputs_c : positive            := 9;
  constant template_c       : sfixed(8 downto -8) := to_sfixed(0.0, 8, -8);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o : complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  clock(clk, 10 ns);

  process
    constant input_data_c       : complex_arr_arr_t    := to_complex_arr_arr_t(input_data_point512_c, template_c);
    constant output_data_c      : complex_vector_arr_t := output_data_point512_c;
    constant tolerance_c        : real                 := 0.3;
    variable passed             : boolean              := true;
    -- Additional delay for adder tree of depth log(radix_c, 2)
    constant adder_tree_depth_c : natural              := log_num_inputs_c;
    constant num_stages_c       : positive             := local.math_pkg.ceil_log(i'length, radix_c);
    -- This is sufficient but not exact. It is too large when later stages reduce the radix, but that is safe.
    constant fft_delay_c        : positive             := (num_stages_c*(1+adder_tree_depth_c))+1;
  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);

    for k in input_data_c'range loop
      i <= input_data_c(k);
      wait_nf_ticks(clk, fft_delay_c);

      report "Checking data set " & integer'image(k);
      for j in output_data_c(k)'range loop
        if not compare_output(o(j), output_data_c(k)(j), tolerance_c) then
          passed := false;
          report "Index " & integer'image(j) & " values " & complex_str(o(j)) & " /= "
               & complex_str(output_data_c(k)(j)) & " (test data)." severity warning;
        end if;
      end loop;
      wait_nr_ticks(clk, 1);
    end loop;

    if passed then
      report "Radix-" & integer'image(radix_c) & " 512-point FFT results: PASSED" severity note;
    else
      report "Radix-" & integer'image(radix_c) & " 512-point FFT results: FAILED" severity warning;
    end if;
    stop_clocks;

    wait;
  end process;

  dut_g: case radix_c generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_c) & " FFT is not possible."
        severity error;
  end generate;

end architecture;


architecture instance of test_fft_sfixed is

  constant log_num_inputs_c : positive := 3;
  constant radix_l          : positive := 4; -- Ignore radix_c from entity
  constant template_c       : sfixed(9 downto -16) := to_sfixed(0.0, 9, -16);

  signal clk   : std_logic;
  signal reset : std_logic;
  signal i, o  : work.fft_sfixed_pkg.complex_arr_t(0 to (2**log_num_inputs_c)-1)(
    re(template_c'range),
    im(template_c'range)
  );

begin

  assert false
    report "Radix-" & integer'image(radix_l) & " " & integer'image(2**log_num_inputs_c) & "-point FFT"
    severity note;

  dut_g: case radix_l generate
    when 2 =>
      dft_real_i : entity work.dft_sfixed(radix2)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when 4 =>
      dft_real_i : entity work.dft_sfixed(radix4)
        generic map (
          log_num_inputs_g => log_num_inputs_c,
          template_g       => template_c
        )
        port map (
          clk   => clk,
          reset => reset,
          i     => i,
          o     => o
        );
    when others =>
      assert false
        report "Radix-" & integer'image(radix_l) & " FFT is not possible."
        severity error;
  end generate;

  clock(clk, 10 ns);

  process
  begin
    reset <= '1';
    i     <= (others => (re => (others => '0'), im => (others => '0')));
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait_nr_ticks(clk, 2);
    stop_clocks;

    wait;
  end process;

end architecture;
