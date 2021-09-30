-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the generic "comparator" to check it scales gracefully for any bus width, any
-- pipeline depth and any LUT size. The self checking testbench makes sure each bit
-- of each comparator effects the final result, proving the tree has been correctly
-- constructed to use each data input bit and the pipeline is the correct length. The
-- testbench also prints a topology report for quick visual verification of the
-- division of work. Maximum LUT depth is the strongest indicator of success and can
-- be independently verified from the top level generics, hence this information is
-- verified and included as part of the overall self-test of success.
--
-- P A Abbey, 23 August 2019
--
-------------------------------------------------------------------------------------

-- ModelSim output for 'vsim work.test_comparators; run -all'.
-- Runs to about 400 us in simulation time.
--
-- # ************************************************************************************
-- # DUT: 0
-- #  Pipeline depth:         2
-- #  Compare Width:         23
-- #  LUT Size:               4
-- #  Max LUT Depth:          2
-- #  Expected LUT depth:     2 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 2, Divide:   3, Max Width:    8, LUT Depth: 2
-- # Depth: 1, Divide:   8, Max Width:   16, LUT Depth: 2
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 1
-- #  Pipeline depth:         5
-- #  Compare Width:         49
-- #  LUT Size:               6
-- #  Max LUT Depth:          1
-- #  Expected LUT depth:     1 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 5, Divide:   1, Max Width:   49, LUT Depth: 0
-- # Depth: 4, Divide:   1, Max Width:   49, LUT Depth: 0
-- # Depth: 3, Divide:   3, Max Width:   18, LUT Depth: 1
-- # Depth: 2, Divide:   6, Max Width:    3, LUT Depth: 1
-- # Depth: 1, Divide:   3, Max Width:    6, LUT Depth: 1
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 2
-- #  Pipeline depth:         3
-- #  Compare Width:        101
-- #  LUT Size:               6
-- #  Max LUT Depth:          1
-- #  Expected LUT depth:     1 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:   6, Max Width:   18, LUT Depth: 1
-- # Depth: 2, Divide:   6, Max Width:    3, LUT Depth: 1
-- # Depth: 1, Divide:   3, Max Width:    6, LUT Depth: 1
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 3
-- #  Pipeline depth:         2
-- #  Compare Width:        125
-- #  LUT Size:               3
-- #  Max LUT Depth:          3
-- #  Expected LUT depth:     3 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 2, Divide:  14, Max Width:    9, LUT Depth: 3
-- # Depth: 1, Divide:   9, Max Width:   18, LUT Depth: 3
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 4
-- #  Pipeline depth:         3
-- #  Compare Width:         50
-- #  LUT Size:               5
-- #  Max LUT Depth:          2
-- #  Expected LUT depth:     2 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:   1, Max Width:   50, LUT Depth: 0
-- # Depth: 2, Divide:   5, Max Width:   10, LUT Depth: 2
-- # Depth: 1, Divide:  10, Max Width:   20, LUT Depth: 2
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 5
-- #  Pipeline depth:         2
-- #  Compare Width:        237
-- #  LUT Size:               4
-- #  Max LUT Depth:          3
-- #  Expected LUT depth:     3 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 2, Divide:   8, Max Width:   32, LUT Depth: 3
-- # Depth: 1, Divide:  32, Max Width:   64, LUT Depth: 3
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 6
-- #  Pipeline depth:         3
-- #  Compare Width:       1445
-- #  LUT Size:               6
-- #  Max LUT Depth:          2
-- #  Expected LUT depth:     2 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:   3, Max Width:  648, LUT Depth: 2
-- # Depth: 2, Divide:  36, Max Width:   18, LUT Depth: 2
-- # Depth: 1, Divide:  18, Max Width:   36, LUT Depth: 2
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 7
-- #  Pipeline depth:         3
-- #  Compare Width:       1445
-- #  LUT Size:               5
-- #  Max LUT Depth:          2
-- #  Expected LUT depth:     2 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:   6, Max Width:  250, LUT Depth: 2
-- # Depth: 2, Divide:  25, Max Width:   10, LUT Depth: 2
-- # Depth: 1, Divide:  10, Max Width:   20, LUT Depth: 2
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 8
-- #  Pipeline depth:         6
-- #  Compare Width:       1445
-- #  LUT Size:               4
-- #  Max LUT Depth:          1
-- #  Expected LUT depth:     1 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 6, Divide:   3, Max Width:  512, LUT Depth: 1
-- # Depth: 5, Divide:   4, Max Width:  128, LUT Depth: 1
-- # Depth: 4, Divide:   4, Max Width:   32, LUT Depth: 1
-- # Depth: 3, Divide:   4, Max Width:    8, LUT Depth: 1
-- # Depth: 2, Divide:   4, Max Width:    2, LUT Depth: 1
-- # Depth: 1, Divide:   2, Max Width:    4, LUT Depth: 1
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 9
-- #  Pipeline depth:         3
-- #  Compare Width:      20000
-- #  LUT Size:               4
-- #  Max LUT Depth:          3
-- #  Expected LUT depth:     3 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 3, Divide:  10, Max Width: 2048, LUT Depth: 3
-- # Depth: 2, Divide:  64, Max Width:   32, LUT Depth: 3
-- # Depth: 1, Divide:  32, Max Width:   64, LUT Depth: 3
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # ************************************************************************************
-- # DUT: 10
-- #  Pipeline depth:         2
-- #  Compare Width:      20000
-- #  LUT Size:               4
-- #  Max LUT Depth:          4
-- #  Expected LUT depth:     4 (calculated externally from the DUT's toplevel generics)
-- # 
-- # ** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)
-- # 
-- # ************************************************************************************
-- # Statistics for top path of recursion of the tree where logic is most densely packed.
-- # Depth: 2, Divide: 157, Max Width:  128, LUT Depth: 4
-- # Depth: 1, Divide: 128, Max Width:  256, LUT Depth: 4
-- # NB. For depth=1, there are two data buses to compare, hence double the width is reported.
-- # 
-- # Construction SUCCESS
-- # Wait for simulation to halt...

entity test_comparators is
end entity;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
library std;
use std.textio.all;
library local;
use local.testbench_pkg.all;
use work.comp_pkg.all;

architecture test of test_comparators is

  type compare_item_t is record
    depth      : positive;
    data_width : natural;
    lutsize    : natural;
  end record;

  type compare_array_t is array(natural range <>) of compare_item_t;

  -- Shared variables need to be protected since VHDL-2000. This one is the global variable to track
  -- overall success from all devices under test.
  type success_t is protected
    procedure set(val : boolean);
    impure function get return boolean;
  end protected;

  type success_t is protected body

    variable success : boolean := true;

    procedure set(val : boolean) is
    begin
      success := val;
    end procedure;

    impure function get return boolean is
    begin
      return success;
    end function;

  end protected body;

  type level_item_t is record
    depth : positive;
    di    : divide_item_t;
  end record;

  type level_array_t is array(natural range <>) of level_item_t;

  -- From the one dimensional array of stats following the first branch line at each level of hierarchy, extract
  -- the largest value of "LUT Depth" as an indication of the achievable clock speed.
  function max_lut_depth(constant li : level_array_t) return natural is
    variable ret : natural := 0;
  begin
    for i in li'range loop
      if li(i).di.lutdepth > ret then
        ret := li(i).di.lutdepth;
      end if;
    end loop;
    return ret;
  end function;

  shared variable success : success_t;

  -- Create multiple instances of the comparison components to test, with a range of values across the different
  -- dimensions. Always include an example for the precise comparator you need for your design here and run the
  -- testbench. If pipelining for a depth > 6, you will need to amend the code in the "probe" process to include
  -- more globally static hierarchical path references.
  constant compare_array_c : compare_array_t := (
    -- (depth, data_width, lutsize)
    (2,    23, 4),
    (5,    49, 6), -- Example pathological case where depth is specified larger than required, so divide by 1 at top level
    (3,   101, 6),
    (2,   125, 3), -- Odd value for 'lutsize'
    (3,    50, 5), -- Odd value for 'lutsize'
    (2,   237, 4),
    (3,  1445, 6),
    (3,  1445, 5), -- Odd value for 'lutsize'
    (6,  1445, 4),
    (3, 20000, 4), -- 'Squashed' as a high LUT depth example (3).
    (2, 20000, 4)  -- More 'squashed' to see how the code copes: LUT depth 4.
  );

  -- Common signal declarations
  signal clk          : std_ulogic := '0';
  signal reset        : std_ulogic := '0';
  signal equal        : std_ulogic_vector(compare_array_c'range);
  signal finished     : std_ulogic_vector(compare_array_c'range) := (others => '0');
  signal finished_all : std_ulogic := '0';

begin

  clkgen : clock(clk, 10 ns);

  duts : for i in compare_array_c'range generate

    subtype comp_bus_t is std_ulogic_vector(compare_array_c(i).data_width-1 downto 0);

    -- Local signal declarations
    signal data_a        : comp_bus_t;
    signal data_b        : comp_bus_t;
    signal expected_i    : std_ulogic := '1';
    signal expected      : std_ulogic_vector(compare_array_c(i).depth-1 downto 0) := (others => '1');
    signal equal_valid_i : std_ulogic := '0';
    signal equal_valid   : std_ulogic_vector(compare_array_c(i).depth-1 downto 0) := (others => '0');

  begin

    comparators_c : entity work.comparator
      generic map (
        depth_g      => compare_array_c(i).depth,
        data_width_g => compare_array_c(i).data_width,
        lutsize_g    => compare_array_c(i).lutsize
      )
      port map (
        clk    => clk,
        reset  => reset,
        data_a => data_a,
        data_b => data_b,
        equal  => equal(i)
      );

    drive : process
      variable rndv : comp_bus_t;
    begin
      -- Expect to see 'X's from before the reset
      -- Initialise the inputs
      data_a        <= (others => '0');
      data_b        <= (others => '0');
      expected_i    <= '1';
      equal_valid_i <= '0';
      wait until reset = '1';
      wait until reset = '0';
      equal_valid_i <= '1';
      wait_nr_ticks(clk, 1);
      -- It would be really unlucky to have both these vectors the same!
      data_a     <= random_vector(comp_bus_t'length);
      data_b     <= random_vector(comp_bus_t'length);
      expected_i <= '0';
      wait_nr_ticks(clk, 1);
      rndv := random_vector(comp_bus_t'length);
      data_a     <= rndv;
      data_b     <= rndv;
      expected_i <= '1';
      wait_nr_ticks(clk, 1);
      -- each bit but matching
      for i in comp_bus_t'low to comp_bus_t'high loop -- i.e. Reverse 'range
        data_a     <= (others => '0');
        data_b     <= (others => '0');
        data_a(i)  <= '1';
        data_b(i)  <= '1';
        expected_i <= '1';
        wait_nr_ticks(clk, 1);
      end loop;
      -- each bit but one bit different
      for i in comp_bus_t'low to comp_bus_t'high loop -- i.e. Reverse 'range
        data_a     <= (others => '0');
        data_a(i)  <= '1';
        data_b     <= (others => '0');
        expected_i <= '0';
        wait_nr_ticks(clk, 1);
      end loop;
      rndv := random_vector(comp_bus_t'length);
      data_a     <= rndv;
      data_b     <= rndv;
      expected_i <= '1';
      wait_nr_ticks(clk, 1);
      equal_valid_i <= '0';
      wait_nr_ticks(clk, compare_array_c(i).depth+2);
      finished(i) <= '1';
      wait;
    end process;

    check : process(clk)
      variable l : line;
    begin
      if rising_edge(clk) then
        if reset = '1' then
          expected    <= (others => '0');
          equal_valid <= (others => '0');
        else
          expected    <= expected(expected'high-1 downto 0) & expected_i;
          equal_valid <= equal_valid(equal_valid'high-1 downto 0) & equal_valid_i;
        end if;

        if (equal_valid(equal_valid'high) = '1') and (equal(i) /= expected(expected'high)) then
          success.set(false);
          swrite(l, "Comparison failure at ");
          write(l, now);
          swrite(l, ". dut ");
          write(l, i);
          writeline(OUTPUT, l);
        end if;
      end if;
    end process;

  end generate;

  finished_check : process(finished)
    constant all_ones : std_ulogic_vector(compare_array_c'range) := (others => '1');
  begin
    for i in finished'range loop
      if finished = all_ones then
        finished_all <= '1';
      end if;
    end loop;
  end process;

  common : process
    variable l : line;
  begin
    reset <= '0';
    wait_nr_ticks(clk, 2);
    toggle_r(reset, clk, 2);
    wait until finished_all = '1';
    if success.get then
      swrite(l, "Simulation SUCCESS");
      writeline(OUTPUT, l);
    else
      swrite(l, "Simulation FAILURE - See transcript for fault reports.");
      writeline(OUTPUT, l);
    end if;
    stop_clocks;
    -- Prevent the process repeating after the simulation time has been manually extended.
    wait;
  end process;

  -- Use VHDL-2008 "external names" to extract statistics about the generated hierarchies to avoid needing to
  -- expand (and collapse) the tree structure to verify the division amounts chosen at each level.
  probe : for i in compare_array_c'reverse_range generate

    signal li : level_array_t(1 to compare_array_c(i).depth) := (
      others => (
        positive'high,
        divide_item_t'(
          positive'high,
          positive'high,
          natural'high)
      )
    );

  begin
    assert compare_array_c(i).depth <= 6
      report "Not enough conditional generate statments for a DUT of pipeline depth " & positive'image(compare_array_c(i).depth)
      severity failure;

    -- Hierarchical references need to be "globally static" so:
    --   1) Use a generate statement not a process
    --   2) Hope that you have catered for enough depth/levels of hierarchy
    di_g : for p in li'range generate

      di_g1 : if p = 1 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.depth_g : positive>>;
      end generate;

      di_g2 : if p = 2 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.depth_g : positive>>;
      end generate;

      di_g3 : if p = 3 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.depth_g : positive>>;
      end generate;

      di_g4 : if p = 4 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.depth_g : positive>>;
      end generate;

      di_g5 : if p = 5 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.depth_g : positive>>;
      end generate;

      di_g6 : if p = 6 and p <= compare_array_c(i).depth generate
        li(p).di    <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.rc_c    : divide_item_t>>;
        li(p).depth <= <<constant .test_comparators.duts(i).comparators_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.g.recurse(0).comparator_c.depth_g : positive>>;
      end generate;

    end generate;

    print : process
      function lut_depth(constant ci : compare_item_t) return natural is
        variable adjust : real;
      begin
        return lut_depth(ci.depth, ci.data_width, ci.lutsize);
      end function;

      variable maxdepth : natural;
      -- Calculate the expected maximum LUT depth of the tree from the top level parameters to check that
      -- the one constructed has not exceeded the value at any level of hierarchy. This is a basic check
      -- for even construction between flops. A separate check is made later for erring on the side of
      -- bottom-heavy.
      variable expdepth : natural := lut_depth(compare_array_c(i));
      variable l        : line;
    begin
      wait until li'event;
      swrite(l, "************************************************************************************");
      writeline(OUTPUT, l);
      swrite(l, "DUT: ");
      write(l, i);
      writeline(OUTPUT, l);
      swrite(l, " Pipeline depth:     ");
      write(l, compare_array_c(i).depth, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Compare Width:      ");
      write(l, compare_array_c(i).data_width, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " LUT Size:           ");
      write(l, compare_array_c(i).lutsize, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Max LUT Depth:      ");
      maxdepth := max_lut_depth(li);
      write(l, maxdepth, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Expected LUT depth: ");
      write(l, expdepth, right, 5);
      swrite(l, " (calculated externally from the DUT's toplevel generics)");
      writeline(OUTPUT, l);
      writeline(OUTPUT, l);
      if expdepth = maxdepth then
        swrite(l, "** Tree Construction: PASS ** (Max LUT Depth == Expected LUT Depth)");
      else
        swrite(l, "** Tree Construction: FAIL ** (Max LUT Depth /= Expected LUT Depth)");
        success.set(false);
      end if;
      writeline(OUTPUT, l);
      writeline(OUTPUT, l);
      swrite(l, "************************************************************************************");
      writeline(OUTPUT, l);
      swrite(l, "Statistics for top path of recursion of the tree where logic is most densely packed.");
      writeline(OUTPUT, l);
      for d in li'range loop
        if li(d).depth <= compare_array_c(i).depth then
          swrite(l, "Depth: ");
          write(l, li(d).depth);
          swrite(l, ", Divide: ");
          write(l, li(d).di.divide, right, 3);
          swrite(l, ", Max Width: ");
          write(l, li(d).di.maxwidth, right, 4);
          swrite(l, ", LUT Depth: ");
          write(l, li(d).di.lutdepth);
          writeline(OUTPUT, l);
        end if;
        if d > li'low then
          -- Wait to second level to start comparing
          -- Constructions should be bottom heavy when uneven.
          if li(d).di.lutdepth < li(d-1).di.lutdepth then
            writeline(OUTPUT, l);
            swrite(l, "** Tree Construction: FAIL ** higher layers should never be deeper in LUTs than lower levels.");
            writeline(OUTPUT, l);
            writeline(OUTPUT, l);
            success.set(false);
          end if;
        end if;
      end loop;
      swrite(l, "NB. For depth=1, there are two data buses to compare, hence double the width is reported.");
      writeline(OUTPUT, l);
      writeline(OUTPUT, l);
      wait;
    end process;

  end generate;

  construction_check : process
    variable l : line;
  begin
    -- Wait for previous process to finish at 0+ ns
    wait for 10 ns;
    if success.get then
      swrite(l, "Construction SUCCESS");
      writeline(OUTPUT, l);
    else
      swrite(l, "Construction FAILURE - See transcript for fault reports.");
      writeline(OUTPUT, l);
    end if;
    swrite(l, "Wait for simulation to halt...");
    writeline(OUTPUT, l);
    wait;
  end process;

end architecture;
