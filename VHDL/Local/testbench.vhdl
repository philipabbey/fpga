--
-- Compile as VHDL-2008
--
library ieee;
use ieee.std_logic_1164.all;

package testbench is

  procedure clock(
    signal   clk        : out std_ulogic;
    constant highperiod :     time;
    constant lowperiod  :     time;
    constant offset     :     time := 0 ns;
    constant maxtime    :     time := 0 ns -- Stop the clock after this time limit
  );

  procedure clock(
    signal   clk       : out std_ulogic;
    constant period    :     time;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5;
    constant offset    :     time := 0 ns;
    constant maxtime   :     time := 0 ns
  );

  procedure stop_clocks;

  procedure wait_nr_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  );

  procedure wait_nf_ticks(
    signal   sig : in std_ulogic;
    constant num : in positive
  );

  -- Non edge-triggered wait for condition
  procedure wait_until(
    signal sig : in std_ulogic;
           val : in std_ulogic
  );

  procedure toggle_r(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  );

  procedure toggle_f(
    signal   sig : inout std_ulogic;
    signal   clk : in    std_ulogic;
    constant num : in    positive := 1
  );

  procedure wiggle_r(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  );

  procedure wiggle_f(
    signal   sig       : out std_ulogic;
    signal   clk       : in  std_ulogic;
    constant dutycycle :     real range 0.0 to 1.0 := 0.5 -- ratio = high / low
  );

  impure function random_vector(width : natural) return std_ulogic_vector;

  type seeds_t is array(0 to 1) of positive;

  type rndgen_t is protected
    procedure set(val : seeds_t);
    impure function get return seeds_t;
    -- random real-number value in range 0 to 1.0 (not including 1.0?)
    impure function random return real;
  end protected;

end package;

library ieee;
use ieee.math_real.all;
library std;
use std.textio.all;

package body testbench is

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
    procedure start;
    -- NB. Stop all clocks
    procedure stop;
    impure function get return boolean;
  end protected;

  type clk_en_t is protected body

    variable enable : boolean := false;

    procedure start is
    begin
      enable := true;
    end procedure;

    -- NB. Stop all clocks
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

  -- Non edge-triggered wait for condition
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

  -- Randomly wiggle 'sig' on a rising clock edge
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

  -- Randomly wiggle 'sig' on a rising clock edge
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
