-------------------------------------------------------------------------------------
-- Generic "comparator" to that scales gracefully for any bus width, any pipeline
-- depth and any LUT size. The VHDL constructs a tree, where each level of the tree
-- adds a pipeline stage, making large comparisons automatically pipelined. The logic
-- is minimal at the synthesis stage by packing LUTs fully, and managing the LUT depth
-- across the stages of pipelining, hence knowledge of LUT size used is essential. For
-- an ASIC, choose LUT to represent the minimum logic depth required by your design
-- based on the number of logic inputs, tending to 2 in the extreme need for clock
-- speed.
--
-- A note on LUT usage. Its fixed for a given data width. What varies is the depth
-- between flops, based mainly on the depth generic. If you reduce the depth, you
-- squash the hierarchary. That means you increase the LUT depth at the expense of
-- potential clock speed (depending on whether your timing bottlenecks are elsewhere
-- in your design). If you reduce the depth, you do decrease the flop usage. If you
-- increase depth unnecessarily large, the calculations prevent unnecessary LUTs by
-- retaining their packing efficiency. Additional flops are added to the head of the
-- tree (the equal bit output) to give the required number of pipeline stages.
--
-- Tested using: ModelSim & Quartus Prime
--  * ModelSim - INTEL FPGA STARTER EDITION 10.5b, Revision: 2016.10, Date: Oct 5 2016
--  * Quartus Prime Ver 18.1.1 Build 646 04/11/2019.
--
-- Failed horribly with
--  * Vivado v2019.1.1 (64-bit)
--    SW Build: 2580384 on Sat Jun 29 08:12:21 MDT 2019
--    IP Build: 2579722 on Sat Jun 29 11:35:40 MDT 2019
--
-- Transcript Reported:
-- ERROR: [Synth 8-317] illegal recursive instantiation of design 'comparator' [.../comparator.vhdl:120]
-- ERROR: [Synth 8-285] failed synthesizing module 'comparator' [.../comparator.vhdl:37]
--
-- Xilinx Vivado only supports "tail recursion" (which is really just iteration), it
-- does not support n-ary trees. Use Quartus Prime or Synplify Pro.
--
-- P A Abbey, 23 August 2019
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity comparator is
  generic(
    depth      : positive := 3;  -- pipeline depth required
    data_width : positive := 32; -- data bus width required for data_a and data_b.
    -- number of inputs to a LUT in an FPGA, or for an ASIC, how many bits it is
    -- reasonable to operate on in a single clock cycle. Can be odd number.
    lutsize    : positive range 2 to positive'high := 4
  );
  port(
    clk    : in  std_ulogic;
    reset  : in  std_ulogic;
    data_a : in  std_ulogic_vector(data_width-1 downto 0);
    data_b : in  std_ulogic_vector(data_width-1 downto 0);
    equal  : out std_ulogic
  );
end entity;

use work.comp_pkg.all;

architecture rtl of comparator is

  -- Not used in the building of the leaf node, more for visibility, and consistency with
  -- the 'else' part. The testbench can extract the values from this constant.
  constant rc : divide_item_t := recurse_divide(depth, data_width, lutsize);

begin

  -- 'depth' is descending from its top level (initial) value down to 1. When depth = 1 we
  -- terminate the recursion and implementing a 'leaf node' to implement the comparison
  -- logic.
  g : if depth = 1 generate
  begin

    leaf : process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          equal <= '0';
        else
          if data_a = data_b then
            equal <= '1';
          else
            equal <= '0';
          end if;
        end if;
      end if;
    end process;

  else generate

    subtype equal_t is std_ulogic_vector(0 to rc.divide-1);
    signal equal_in : equal_t;

  begin
    -- Divide the bus up and recurse on smaller sections. 'recurse_divide' works out how much
    -- to divide by at each level of recursion. This includes determining if there are more
    -- pipeline stages than is actually required. If so, save the work until later as it saves
    -- on 'area' by packing LUTs more efficiently, so just add a flop for delay and tail recurse
    -- only (no division).

    recurse : for i in equal_t'range generate

      -- There are inconsistencies between the libraries used for simulation in ModelSim and
      -- synthesis in Quartus Prime.
      --
      -- 'minimum' has not been implemented for 'positive' in some tools! Where it has been
      -- implemented, the function's presence causes ambiguity. Helpful...
      --
      -- Quartus Prime:
      -- Error (10482): VHDL error at comparator.vhdl(85): object "minimum" is used but not declared
      -- Error: Quartus Prime Analysis & Synthesis was unsuccessful. 1 error, 0 warnings
      --
      -- ModelSim: ** Error: A:/Philip/Work/VHDL/Comparator/comparator.vhdl(89): Subprogram "minimum" is ambiguous.
      --
      -- Disambiguate with explicity call of 'work.comp_pkg.minimum'.

      -- Divide up the data buses for the i'th sibling of recursion and setup the generic
      -- values for the next level in the hierarchy.
      constant upper    : positive := work.comp_pkg.minimum((i+1)*rc.maxwidth, data_width);
      constant buslow   : natural  := rc.maxwidth*i;
      constant bushigh  : natural  := upper-1;
      constant recwidth : positive := upper-buslow;

    begin

      comparator_c : entity work.comparator
        generic map(
          depth      => depth-1,
          data_width => recwidth,
          lutsize    => lutsize
        )
        port map(
          clk    => clk,
          reset  => reset,
          data_a => data_a(bushigh downto buslow),
          data_b => data_b(bushigh downto buslow),
          equal  => equal_in(i)
        );

    end generate;

    combine : process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          equal <= '0';
        else
          -- 'rc.divide' input AND gate.
          if equal_in = equal_t'(others => '1') then
            equal <= '1';
          else
            equal <= '0';
          end if;
        end if;
      end if;
    end process;

  end generate;

end architecture;
