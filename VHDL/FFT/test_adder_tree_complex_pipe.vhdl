-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for the pipelined adder tree.
--
-- P A Abbey, 10 September 2021
--
-------------------------------------------------------------------------------------

entity test_adder_tree_complex_pipe is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;
library std;
  use std.textio.all;
library local;
  use local.math_pkg.ceil_root;
  use local.testbench_pkg.all;
library work; -- Implicit anyway, but acts to group.
  use work.fft_sfixed_pkg.all;
  use work.adder_tree_pkg.all;
  use work.test_fft_pkg.complex_str;

architecture test of test_adder_tree_complex_pipe is

  subtype negative is integer range integer'low to 0;

  type adder_tree_pipe_item_t is record
    depth        : positive;
    num_operands : positive;
    input_high   : natural;
    input_low    : negative;
  end record;

  type adder_tree_pipe_array_t is array(natural range <>) of adder_tree_pipe_item_t;

  constant adder_tree_pipe_array_c : adder_tree_pipe_array_t := (
    -- (depth, num_operands, input_high, input_low)
    (1,  2,  8, -3), -- Needs depth = 1
    (2,  2,  8, -3), -- Needs depth = 1
    (2,  3,  9, -4), -- Needs depth = 2
    (2,  4, 10, -3), -- Needs depth = 2
    (5,  5, 11, -3), -- Needs depth = 3 -- Excess depth
    (2,  6, 12, -4), -- Needs depth = 3 -- Compromise timing
    (3,  7, 13, -5), -- Needs depth = 3
    (4, 40,  9, -6), -- Needs depth = 6 -- Compromise timing
    (3, 80,  9, -7)  -- Needs depth = 7 -- Compromise timing
  );

  constant ones_c : std_logic_vector(adder_tree_pipe_array_c'range) := (others => '1');

  function sum_inputs(i : complex_arr_t) return complex_t is
    variable sum : complex_t(
      re(output_bits(i(i'low).re'high, i'length) downto i(i'low).re'low),
      im(output_bits(i(i'low).im'high, i'length) downto i(i'low).im'low)
    ) := (
      re => (others => '0'),
      im => (others => '0')
    );
  begin
    for j in i'range loop
      sum := resize(sum + i(j), sum.re);
    end loop;
    return sum;
  end function;

  signal clk      : std_logic := '0';
  signal reset    : std_logic := '0';
  signal finished : std_logic_vector(adder_tree_pipe_array_c'range) := (others => '0');
  signal passed   : std_logic_vector(adder_tree_pipe_array_c'range) := (others => '1');

  shared variable success : bool_t;

  type level_item_t is record
    depth        : positive;
    num_operands : positive;
    divide       : positive;
    output_width : positive;
  end record;

  type level_array_t is array(natural range <>) of level_item_t;

  -- From the one dimensional array of stats following the first branch line at each level of hierarchy, extract
  -- the largest value of "LUT Depth" as an indication of the achievable clock speed.
  function max_division(constant la : level_array_t) return natural is
    variable ret : natural := 0;
  begin
    for i in la'range loop
      if la(i).divide > ret then
        ret := la(i).divide;
      end if;
    end loop;
    return ret;
  end function;

begin

  clkgen : clock(clk, 10 ns);

  process
  begin
    reset <='1';
    wait_nr_ticks(clk, 2);
    reset <= '0';
    wait;
  end process;

  duts : for l in adder_tree_pipe_array_c'range generate

    constant i_t : sfixed(adder_tree_pipe_array_c(l).input_high downto adder_tree_pipe_array_c(l).input_low) := (others => '0');
    constant o_t : sfixed(output_bits(i_t'high, adder_tree_pipe_array_c(l).num_operands) downto i_t'low) := (others => '0');

    signal i : complex_arr_t(0 to adder_tree_pipe_array_c(l).num_operands-1)(
      re(i_t'range),
      im(i_t'range)
    );
    signal o : complex_t(
      re(o_t'range),
      im(o_t'range)
    );

  begin

    adder_tree_complex_pipe_i : entity work.adder_tree_complex_pipe
      generic map (
        depth_g        => adder_tree_pipe_array_c(l).depth,
        num_operands_g => adder_tree_pipe_array_c(l).num_operands,
        template_g     => i_t
      )
      port map (
        clk   => clk,
        reset => reset,
        i     => i,
        o     => o
      );

    test : process

      variable exp : complex_t(
        re(o_t'range),
        im(o_t'range)
      );

    begin
      -- Add different values
      for j in 0 to adder_tree_pipe_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real(j+1) / 2.0,
          real(j+1) / 3.0,
          i(j).re
        );
      end loop;
      wait for 10 ps;
      wait until reset = '0';

      wait_nf_ticks(clk, adder_tree_pipe_array_c(l).depth+2);

      exp := sum_inputs(i);
      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add maximum values: +(2**n)-1, NB. top bit is sign bit
      for j in 0 to adder_tree_pipe_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real((2**i_t'high)-1),
          real((2**i_t'high)-1),
          i_t
        );
      end loop;
      exp.re := to_sfixed((2**(i_t'high)-1)*adder_tree_pipe_array_c(l).num_operands, o_t);
      exp.im := exp.re;

      wait_nr_ticks(clk, adder_tree_pipe_array_c(l).depth+2);

      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      -- Add minimum values: -2**(n-1), NB. top bit is sign bit
      for j in 0 to adder_tree_pipe_array_c(l).num_operands-1 loop
        i(j) <= to_complex_t(
          real(-2**i_t'high),
          real(-2**i_t'high),
          i_t
        );
      end loop;
      exp.re := to_sfixed((-2**i_t'high) * adder_tree_pipe_array_c(l).num_operands, o_t);
      exp.im := exp.re;

      wait_nr_ticks(clk, adder_tree_pipe_array_c(l).depth+2);

      if o = exp then
        report "DUT " & integer'image(l) & " PASSED";
      else
        report "DUT " & integer'image(l) & " FAILED. Output sum is wrong for DUT " & integer'image(l) & " Expected: " & complex_str(exp) & " Read: " & complex_str(o)
          severity warning;
        passed(l) <= '0';
      end if;

      finished(l) <= '1';

      wait;
    end process;

  end generate;

  -- Use VHDL-2008 "external names" to extract statistics about the generated hierarchies to avoid needing to
  -- expand (and collapse) the tree structure to verify the division amounts chosen at each level.
  probe : for i in adder_tree_pipe_array_c'reverse_range generate

    signal la : level_array_t(1 to adder_tree_pipe_array_c(i).depth) := (
      others => (
        depth        => positive'high,
        num_operands => positive'high,
        divide       => positive'high,
        output_width => positive'high
      )
    );

  begin
    assert adder_tree_pipe_array_c(i).depth <= 6
      report "Not enough conditional generate statments for a DUT of pipeline depth " & positive'image(adder_tree_pipe_array_c(i).depth)
      severity failure;

    -- Hierarchical references need to be "globally static" so:
    --   1) Use a generate statement not a process
    --   2) Hope that you have catered for enough depth/levels of hierarchy
    di_g : for p in la'range generate
      di_g1 : if p = 1 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

      di_g2 : if p = 2 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

      di_g3 : if p = 3 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

      di_g4 : if p = 4 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

      di_g5 : if p = 5 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

      di_g6 : if p = 6 and p <= adder_tree_pipe_array_c(i).depth generate
        la(p).depth        <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.depth_g        : positive>>;
        la(p).num_operands <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.num_operands_g : positive>>;
        la(p).divide       <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.divide_c       : positive>>;
        la(p).output_width <= <<constant .test_adder_tree_complex_pipe.duts(i).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.recurse_g.divide_g(0).adder_tree_complex_pipe_i.output_width_c : positive>>;
      end generate;

    end generate;

    print : process
      variable maxdepth : positive;
      -- Calculate the expected maximum division at each stage of the pipelined tree from the top level
      -- parameters to check that the one constructed has not exceeded the value at any level of
      -- hierarchy. This is a basic check for even construction between flops. A separate check is made
      -- later for erring on the side of bottom-heavy.
      variable expdepth : positive := ceil_root(adder_tree_pipe_array_c(i).num_operands, adder_tree_pipe_array_c(i).depth);
      variable l        : line;
    begin
      wait until la'event;
      swrite(l, "************************************************************************************");
      writeline(OUTPUT, l);
      swrite(l, "DUT: ");
      write(l, i);
      writeline(OUTPUT, l);
      swrite(l, " Pipeline depth:     ");
      write(l, adder_tree_pipe_array_c(i).depth, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Coefficients:       ");
      write(l, adder_tree_pipe_array_c(i).num_operands, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Input Width:        ");
      write(l, adder_tree_pipe_array_c(i).input_high-adder_tree_pipe_array_c(i).input_low, right, 5);
      writeline(OUTPUT, l);
      swrite(l, " Expected Division:  ");
      write(l, expdepth, right, 5);
      swrite(l, " (calculated externally from the DUT's toplevel generics)");
      writeline(OUTPUT, l);
      swrite(l, " Maximum Division:   ");
      maxdepth := max_division(la);
      write(l, maxdepth, right, 5);
      writeline(OUTPUT, l);
      if expdepth /= maxdepth then
        swrite(l, "** Tree Construction: FAIL ** (Maximum Division /= Expected Division)");
        writeline(OUTPUT, l);
        success.set(false);
      end if;
      writeline(OUTPUT, l);
      swrite(l, "************************************************************************************");
      writeline(OUTPUT, l);
      swrite(l, "Statistics for top path of recursion of the tree where logic is most densely packed.");
      writeline(OUTPUT, l);
      for d in la'range loop
        if la(d).depth <= adder_tree_pipe_array_c(i).depth then
          swrite(l, "Depth: ");
          write(l, la(d).depth);
          swrite(l, ", Number Coefficients: ");
          write(l, la(d).num_operands, right, 3);
          swrite(l, ", Divide: ");
          write(l, la(d).divide, right, 4);
          swrite(l, ", Output Width: ");
          write(l, la(d).output_width);
          writeline(OUTPUT, l);
        end if;
        if d > la'low then
          -- Wait to second level to start comparing
          -- Constructions should be bottom heavy when uneven.
          if la(d).divide < la(d-1).divide then
            writeline(OUTPUT, l);
            swrite(l, "** Tree Construction: FAIL ** higher layers should never be deeper in adders than lower levels.");
            writeline(OUTPUT, l);
            writeline(OUTPUT, l);
            success.set(false);
          end if;
       end if;
      end loop;
      writeline(OUTPUT, l);
      wait;
    end process;

  end generate;


  halt : process(finished)
    variable l : line;
  begin
    if finished = ones_c then
      if passed = ones_c then
        swrite(l, "Functional tests PASSED");
        writeline(OUTPUT, l);
      else
        swrite(l, "Functional tests FAILED");
        writeline(OUTPUT, l);
      end if;

      if success.get then
        swrite(l, "Construction tests PASSED");
        writeline(OUTPUT, l);
      else
        swrite(l, "Construction tests FAILED - See transcript for fault reports.");
        writeline(OUTPUT, l);
      end if;
      stop_clocks;
    end if;
  end process;

end architecture;
