-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Package used to provide the tricky calculations for how to divide the logic tree
-- at each level or recursion, calculating top-down as the layers are logic are
-- created. Challenges to take into consideration.
--  1) How much to divide by at each level. How can that be distributed so as to not
--     use more level of logic (LUTs) than is optimally required?
--  2) How to avoid poor division where LUTS are only partially packed, and hence
--     more LUTs end up being consumed than is strictly necessary.
--  3) How to avoid 'pathological' cases where the amount of pipelining requested
--     exceeds that which is really necessary, and causes inefficient LUT packing.
--     E.g. Divide by 2 at each stage when LUTs have 6 inputs (e.g. Xilinx Virtex-6
--     or UltraScale devices, Intel Stratix 10 devices).
--
-- P A Abbey, 23 August 2019
--
-------------------------------------------------------------------------------------

package comp_pkg is

  type divide_item_t is record
    divide   : positive;
    maxwidth : positive;
    lutdepth : natural;
  end record;


  -- Return the minimum of 'a' and 'b'.
  --
  -- This function has not been implemented for 'positive' in some tools! Where it
  -- has been implemented, the function's presence causes ambiguity. Helpful...
  --
  -- Quartus Prime:
  -- Error (10482): VHDL error at file.vhdl(xx): object "minimum" is used but not declared
  -- Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
  --
  -- ModelSim: ** Error: file.vhdl(xx): Subprogram "minimum" is ambiguous.
  --
  -- Therefore qualification by full path name might be required,
  --   e.g. 'local.math_pkg.minimum(..)'.
  --
  -- Usage:
  --   constant min : positive := minimum(4, width_g);
  --
  function minimum(a, b : positive) return positive;


  -- For the height in the hierarchy given by 'depth', what is the expected depth of LUTs between
  -- flops for the tree below?
  --
  --          | Depth=1         | Depth=2         | Depth=3         |
  --   Output | Flop - LUT Tree | Flop - LUT tree | Flop - LUT Tree | Inputs
  --
  -- For 'depth' levels of pipelining of 2 * data_width inputs, calculate the LUT depth for the
  -- whole tree and divide by the number of levels that will be spread over. Take into account
  -- that leaf nodes will compare two data buses, so will have 2 * width work to do, or should be
  -- given half the data width on a single bus to work with.
  --
  -- log(width, lutsize)
  --   Gives the LUT depth required when failing to take into account the extra work at leaf nodes.
  --
  -- Extra work at leaf nodes needs to be taken into account, allowing for a doubling of bus width
  -- when calculating the LUT depth.
  --
  -- log(width*2, lutsize)
  --   Becomes the new amount of work to do in the remaining tree.
  --
  -- log(width*2, lutsize) / depth
  --   Averages out that adjusted work over levels of hierarchy or pipeline stages.
  --
  -- This calculation leaves leaf nodes with half the bus width in 2 inputs. The more naive or
  -- basic 'log(width, lutsize)' does not allowed for this, potentially doubling the LUT depth in
  -- the leaf nodes and slowing the achievable maximum clock speed.
  --
  -- Some notes for odd values of 'lutsize'.
  -- =======================================
  --
  -- log(2 * lutsize / (lutsize-1), lutsize)
  --   Replaces the previous calculation taking into account the extra work done in leaf nodes,
  --   where one LUT input can no longer be used. Take for example lutsize = 5:
  --
  -- LUT inputs | Pairs of input bits compared | Usage Ratio
  --      4     |               2              |      2
  --      5     |               2              |     5/2
  --      6     |               3              |      2
  --      7     |               3              |     7/3
  --
  -- '2 * lutsize / (lutsize-1)' is the ratio of the number of inputs to the LUT over the number
  -- of pairs of bits compared. In this example 5/2. In the even case this is equivalent to 6/3
  -- or 4/2, hence the fixed factor of '2' in the adjustment of 'width'.
  --
  -- Given the comparison between adjustment factors of '2' and '2 * lutsize / (lutsize-1)', this
  -- formula can be made more concise with:
  --
  --   2 * lutsize / (lutsize - (lutsize mod 2))
  --
  -- With even lutsize, '2 * lutsize / (lutsize - (lutsize mod 2))' reduces to '2'.
  --
  -- Usage:
  --   variable expdepth : natural := lut_depth(compare_array_t'(2, 23, 4));
  --
  function lut_depth(
    constant depth   : positive;
    constant width   : positive;
    constant lutsize : positive := 4
  ) return natural;


  -- Decide how much to divide the work with 'depth' levels of hierarchy to go.
  --
  -- If 'depth' is 1, just consume the remaining bits in a comparator implemented with LUTs.
  -- This function is never actually called by leaf nodes, so this clause is perhaps irrelevant.
  --
  -- if 'depth' > 1, then test if we can afford to delay by one level of hierarchy before doing
  -- the work. This tests for the situation where excessive pipelining is requested and avoids
  -- the gratuitous and wasteful use of partially filled LUTs.
  --
  -- If it is appropriate to perform division then:
  --
  --   lutsize ** lutdepth
  --     is the maximum number of inputs that can be consumed by the LUT tree in a single level
  --     of hierarchy.
  --
  --   (lutsize ** lutdepth) ** (depth-1)
  --     is the maximum number of inputs that can be consumed by the remaining 'depth-1' levels
  --     of hierarchy.
  --
  --   maxwidth = (lutsize ** lutdepth) ** (depth-1) / 2
  --                       or
  --   maxwidth = (lutsize ** (lutdepth * (depth-1))) / 2
  --     accounts for leaf nodes having to compare two data buses, so should be assigned half
  --     the width in each input.
  --
  --   round up or ceiling of '(data) width / maxwidth'
  --     the number of divisions of the input data width, maximising the early divisions, leaving
  --     fragments for the last division. Fragments are managed by using the 'minimum' function
  --     to calculate the actual bus width and array indices at comparator instantiation.
  --
  -- Some notes for odd values of 'lutsize'.
  -- =======================================
  --
  -- recurse_divide(): 'maxwidth' needs amending to give a series
  --  depth | maxwidth
  --  ------+---------------------------
  --    1   | (lutsize-1) / 2
  --    2   | lutsize * (lutsize-1) / 2
  --    3   | lutsize**2 * (lutsize-1) / 2
  --
  -- i.e. maxwidth := ((lutsize ** (lutdepth * (depth-1))) - (lutsize ** ((lutdepth * (depth-1))-1))) / 2;
  --
  -- For calculation efficiency, return multiple values from this function call. Otherwise
  -- the same calculations are made repeatedly and unnecessarily in the separate functions.
  --
  -- Usage:
  --   constant rc : divide_item_t := recurse_divide(depth, data_width, lutsize);
  --
  function recurse_divide(
    constant depth   : positive;
    constant width   : positive;
    constant lutsize : positive := 4
  ) return divide_item_t;

end package;


library ieee;
use ieee.math_real.all;

package body comp_pkg is

  function minimum(a, b : positive) return positive is
  begin
    if a < b then
      return a;
    else
      return b;
    end if;
  end function;


  function lut_depth(
    constant depth   : positive;
    constant width   : positive;
    constant lutsize : positive := 4
  ) return natural is
  begin
    return natural(ceil(
      log(
        real(width * 2 * lutsize / (lutsize - (lutsize mod 2))),
        real(lutsize)
      ) / real(depth)
    ));
  end function;


  function recurse_divide(
    constant depth   : positive;
    constant width   : positive;
    constant lutsize : positive := 4
  ) return divide_item_t is
    variable maxwidth : positive;
    variable lutdepth : natural;
  begin
    if depth = 1 then
      return divide_item_t'(
        width,
        -- Leaf nodes have two input buses, so don't forget to double the logic work.
        width * 2,
        -- lut_depth() takes into account the doubling of width in leaf nodes.
        lut_depth(1, width, lutsize)
      );
    else
      lutdepth := lut_depth(depth, width, lutsize);
      -- If delaying the work for one level of hierarchy does not adversely affect the LUT
      -- depth, do no work this time.
      if lutdepth = lut_depth(depth-1, width, lutsize) then
        return divide_item_t'(1, width, 0);
      else
        maxwidth := (
          -- (lutsize ** lutdepth) bits per level, for depth-1 levels
          (lutsize ** (lutdepth * (depth-1))) -
          -- For odd 'lutsize' only subtract the LUT inputs that can't be connected at leaf nodes.
          ( (lutsize mod 2) * (lutsize ** ((lutdepth * (depth-1))-1)) )
        ) / 2;
        return divide_item_t'(
          positive(ceil( real(width) / real(maxwidth) )),
          maxwidth,
          lutdepth
        );
      end if;
    end if;
  end function;

end package body;
