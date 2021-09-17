entity test_counters is
end entity;

library ieee;
use ieee.std_logic_1164.all;
library std;
use std.textio.all;
library local;
use local.testbench.all;

architecture behav of test_counters is

  component compare_counters is
    generic(
      max : positive range 3 TO positive'high
    );
    port(
      clk      : in  std_ulogic;
      reset    : in  std_ulogic;
      enable   : in  std_ulogic;
      finished : out std_ulogic;
      compare  : out std_ulogic
    );
  end component;

  type compare_array_t is array(natural range <>) of positive range 3 TO positive'high;
  constant compare_array : compare_array_t := (
    3,
    2**2+1,
    2**3+3,
    2**4+7,
    2**5+30,
    2**6+49,
    2**7+80,
    2**8+170,
    2**9+340,
    2**10+700,
    2**16+1234
  );

  -- Signal declarations
  signal clk      : std_ulogic := '0';
  signal reset    : std_ulogic := '0';
  signal enable   : std_ulogic := '0';
  signal finished : std_ulogic_vector(compare_array'range);
  signal compare  : std_ulogic_vector(compare_array'range);
  signal compall  : std_ulogic := '0';
  signal fail     : std_ulogic := '0';

  function array_max(arr : compare_array_t) return natural is
    variable ret : natural := arr'left;
    variable max : natural := 0;
  begin
    for i in arr'range loop
      if arr(i) > max then
        max := arr(i);
        ret := i;
      end if;
    end loop;
    return ret;
  end function;

  constant longest : natural := array_max(compare_array);
  
begin

  duts: for com in compare_array'range generate
   comp_compare_counters : compare_counters
     generic map (
       max => compare_array(com)
     )
     port map (
       clk      => clk,
       reset    => reset,
       enable   => enable,
       finished => finished(com),
       compare  => compare(com)
     );
  end generate;
  
  clock(clk, 5 ns, 5 ns);
  wiggle_r(enable, clk, 0.75);
  
  process
    variable res : line;
  begin
    -- Expect to see 'X's from before the reset
    wait until rising_edge(clk);
    -- Initialise the inputs
    wait until rising_edge(clk);
    toggle_r(reset, clk, 2);

    wait until rising_edge(clk);
    wait until finished(longest) = '1';
    wait until finished(longest) = '1';
    write(res, string'("End of simulation."));
    writeline(OUTPUT, res);
    if fail = '1' then
      write(res, string'("Result: FAIL - LFSR Counter does not mirror synchronous one."));
    else
      write(res, string'("Result: PASS - LFSR and synchronous counters match."));
    end if;
    writeline(OUTPUT, res);
    wait_nr_ticks(clk, 2);

    -- simulation stops here
    stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;
  
  process(compare)
    variable ca : std_ulogic := '1';
  begin
    ca := '1';
    for i in compare'range loop
      ca := ca and compare(i);
    end loop;
    if now > 20 ns then
      assert ca = '0' report "Counter comparison failure" severity warning;
    end if;
    compall <= ca;
  end process;
  
  -- But remember the failure:
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        fail <= '0';
      elsif compall = '0' then
        fail <= '1';
      end if;
    end if;
  end process;

end architecture;
