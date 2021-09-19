-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Provide a number of general functions required for stimulus generation in test
-- benches. These functions are for (clock) cycle-based rather than bus-based test
-- benches.
--
-- Compile as VHDL-2008
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package testbench_pkg is

  -- Create a clock whose name is indicated by the 'clk' parameter with a period of
  -- 'highperiod' + 'lowperiod', which allows for the setting of a non-symmetric
  -- clock waveform. 'offset' can be used to shift the phase of the clock relative to
  -- 0 ns. 'maxtime' > 0 ns can be used to turn the clock off after a specified time
  -- has elapsed. The clock can also be stopped by calling 'stop_clocks'.
  --
  -- Usage:
  --   clock(my_clk, 5 ns, 5 ns, 70 us);
  --
  procedure clock(
    signal   clk        : out std_ulogic;
    constant highperiod :     time;
    constant lowperiod  :     time;
    constant offset     :     time := 0 ns;
    constant maxtime    :     time := 0 ns -- Stop the clock after this time limit
  );


  -- Create a clock whose name is indicated by the 'clk' parameter with the specified
  -- 'period'. The duty cycle can be altered using the 'dutycycle' parameter to make
  -- a non-symmetric clock signal. 'offset' can be used to shift the phase of the
  -- clock relative to 0 ns. 'maxtime' > 0 ns can be used to turn the clock off after
  -- a specified time has elapsed. The clock can also be stopped by calling
  -- 'stop_clocks'.
  --
  -- Usage:
  --   clock(mem_clk, 12 ns, 0.6);
  --
  procedure clock(
    signal   clk       : out std_ulogic;
    constant period    :     time;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5;
    constant offset    :     time := 0 ns;
    constant maxtime   :     time := 0 ns
  );

  -- Stop all clocks created with 'clock' procedure calls above. This call is an
  -- alternative to 'std.env.stop' which has the irritating habit of bringing up a
  -- source window to cover the wave window in ModelSim.
  procedure stop_clocks;


  -- Wait for 'num' rising edges of 'sig'.
  --
  -- Usage:
  --   wait_nr_ticks(clk, 4);
  --
  procedure wait_nr_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  );


  -- Wait for 'num' falling edges of 'sig'.
  --
  -- Usage:
  --   wait_nf_ticks(clk, 4);
  --
  procedure wait_nf_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  );


  -- Non event-triggered 'wait for' condition. If 'sig' is not currently 'val', then
  -- wait until it is and then return.
  --
  -- Usage:
  --   wait_until(data_valid, '1');
  --
  procedure wait_until(
    signal sig : in std_ulogic;
           val : in std_ulogic
  );


  -- Invert the state of 'sig', wait for 'num' rising edges of 'clk' and invert the
  -- 'sig' back.
  --
  -- Usage:
  --   toggle_r(reset, clk, 2);
  --
  procedure toggle_r(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  );


  -- Invert the state of 'sig', wait for 'num' falling edges of 'clk' and invert the
  -- 'sig' back.
  --
  -- Usage:
  --   toggle_f(reset, clk, 2);
  --
  procedure toggle_f(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  );


  -- Create a random wiggle on 'sig', typically a data valid input. The transitions
  -- are aligned with rising edges on the signal specified by 'clk', and the aim is
  -- to achieve a waveform that has a ratio of high to low states close to
  -- 'dutycycle'. The signal can remain high for multiple clock cycles and low for
  -- multiple clock cycles such that the speed with which valid data is clocked in
  -- is governed by 'dutycycle', without having a constant mark space ratio. This is
  -- intended to avoid designs inadvertently only working for a 1 in n cycle data
  -- valid signal because the designer did not realise the logic exploited some form
  -- of periodicity of the stimulus.
  --
  -- Usage:
  --   wiggle_r(data_valid_in, clk, 0.8);
  --
  procedure wiggle_r(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  );


  -- Create a random wiggle on 'sig', typically a data valid input. The transitions
  -- are aligned with falling edges on the signal specified by 'clk', and the aim is
  -- to achieve a waveform that has a ratio of high to low states close to
  -- 'dutycycle'. The signal can remain high for multiple clock cycles and low for
  -- multiple clock cycles such that the speed with which valid data is clocked in
  -- is governed by 'dutycycle', without having a constant mark space ratio. This is
  -- intended to avoid designs inadvertently only working for a 1 in n cycle data
  -- valid signal because the designer did not realise the logic exploited some form
  -- of periodicity of the stimulus.
  --
  -- Usage:
  --   wiggle_f(data_valid_in, clk, 0.2);
  --
  procedure wiggle_f(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  );


  -- Generate a vector with randomly allocated '0's and '1's returning a
  -- std_ulogic_vector.
  --
  -- Usage:
  --   data_random <= random_vector(data_random'length);
  --
  impure function random_vector(width : natural) return std_ulogic_vector;


  -- The seed for the current state of the random number generator.
  type seeds_t is array(0 to 1) of positive;


  -- The type for the "shared variable" used to provide a sequence of pseudo-random
  -- numbers.
  type rndgen_t is protected

    -- Set the current seed values for the random number generator.
    procedure set(val : seeds_t);

    -- Get the current seed values for the random number generator.
    impure function get return seeds_t;

    -- Get a random real-number value in range 0 to 1.0.
    impure function random return real;

  end protected;

end package;


library ieee;
use ieee.math_real.all;
library std;
use std.textio.all;

package body testbench_pkg is

  type rndgen_t is protected body

    variable seeds : seeds_t;

    procedure set(val : seeds_t) is
    begin
      seeds := val;
    end procedure;

    impure function get return seeds_t is
    begin
      return seeds;
    end function;

    impure function random return real is
      variable rand : real;
    begin
      uniform(seeds(0), seeds(1), rand);
      return rand;
    end function;

  end protected body;

  shared variable rndgen : rndgen_t; -- seed values for random generator

  -- This declaration is still required even though it is private to this package.
  -- Feels entirely unnecessary!
  type clk_en_t is protected

    -- Set the clock enable to true.
    procedure start;

    -- Set the clock enable to false.
    procedure stop;

    -- Get the current state of the clock enable.
    impure function get return boolean;

  end protected;


  type clk_en_t is protected body

    variable enable : boolean := false;

    procedure start is
    begin
      enable := true;
    end procedure;

    procedure stop is
    begin
      enable := false;
    end procedure;

    impure function get return boolean is
    begin
      return enable;
    end function;

  end protected body;

  -- Want to stop simulations by ending all event generation rather than by using
  -- 'std.env.stop' so that the wave window does not get covered by a source file
  -- window.
  shared variable clk_en : clk_en_t; -- Clock enable

  procedure clock(
    signal   clk        : out std_ulogic;
    constant highperiod :     time;
    constant lowperiod  :     time;
    constant offset     :     time := 0 ns;
    constant maxtime    :     time := 0 ns
  ) is
  begin
    assert highperiod > 0 ns
      report "Periods need to be specified > 0"
      severity warning;
    assert lowperiod > 0 ns
      report "Periods need to be specified > 0"
      severity warning;
    wait for offset;
    clk_en.start;
    loop
      clk <= '1';
      wait for highperiod;
      clk <= '0';
      wait for lowperiod;
      if maxtime > 0 ns then
        if now > maxtime then
          exit;
        end if;
      end if;
      if not clk_en.get then
        return;
      end if;
    end loop;
    wait;
  end procedure;


  procedure clock(
    signal   clk       : out std_ulogic;
    constant period    :     time;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5;
    constant offset    :     time := 0 ns;
    constant maxtime   :     time := 0 ns
  ) is
    constant highperiod : time := period * dutycycle;
    constant lowperiod  : time := period - highperiod;
  begin
    assert highperiod > 0 ns
      report "'dutycycle' must be < 1.0"
      severity warning;
    assert lowperiod > 0 ns
      report "'dutycycle' must be > 0.0"
      severity warning;
    clk_en.start;
    wait for offset;
    loop
      clk <= '1';
      wait for highperiod;
      clk <= '0';
      wait for lowperiod;
      if maxtime > 0 ns then
        if now > maxtime then
          exit;
        end if;
      end if;
      if not clk_en.get then
        return;
      end if;
    end loop;
    wait;
  end procedure;


  procedure stop_clocks is
  begin
    clk_en.stop;
  end procedure;


  procedure wait_nr_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  ) is
  begin
    for n in 1 to num loop
      wait until rising_edge(sig);
    end loop;
  end procedure;


  procedure wait_nf_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  ) is
  begin
    for n in 1 to num loop
      wait until falling_edge(sig);
    end loop;
  end procedure;


  procedure wait_until(
    signal sig : in std_ulogic;
           val : in std_ulogic
  ) is
  begin
    if sig /= val then
      wait until sig = val;
    end if;
  end procedure;


  procedure toggle_r(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  ) is
  begin
    sig <= not sig;
    wait_nr_ticks(clk, num);
    sig <= not sig;
  end procedure;


  procedure toggle_f(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  ) is
  begin
    sig <= not sig;
    wait_nf_ticks(clk, num);
    sig <= not sig;
  end procedure;


  procedure wiggle_r(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  ) is
    variable rand : real; -- random real-number value in range 0 to 1.0
  begin
    loop
      sig <= '0';
      rand := rndgen.random;
      if rand < dutycycle then
        sig <= '1';
      end if;
      wait_nr_ticks(clk, 1);
    end loop;
    wait;
  end procedure;


  procedure wiggle_f(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  ) is
    variable rand : real; -- random real-number value in range 0 to 1.0
  begin
    loop
      sig <= '0';
      rand := rndgen.random;
      if rand < dutycycle then
        sig <= '1';
      end if;
      wait_nf_ticks(clk, 1);
    end loop;
    wait;
  end procedure;


  impure function random_vector(width : natural) return std_ulogic_vector is
    variable ret : std_ulogic_vector(width-1 downto 0) := (others => '0');
  begin
    for i in ret'range loop
      if rndgen.random >= 0.5 then
        ret(i) := '1';
      else
        ret(i) := '0';
      end if;
    end loop;
    return ret;
  end function;

end package body;
