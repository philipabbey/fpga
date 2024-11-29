-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Generic pipelined multiplexer enabling selection of one of a large number of
-- inputs over auser specified number of clock cycles in order to manage timing
-- closure.
--
-- P A Abbey, 22 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library local;
  use local.rtl_pkg.natural_vector;

entity mux_sel is
  generic (
    sel_bits_g : positive;
    indexes_g  : natural_vector
  );
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    -- The timing on these bits must be staggered and arranged to reach the desired level of recursion at the right time.
    sel_in  : in  std_logic_vector(sel_bits_g-1 downto 0);
    sel_out : out std_logic_vector(sel_bits_g-1 downto 0)
  );
end entity;


-- Tail recursive as it manages the delay in the same way as the data is multiplexed.
--
architecture rtl of mux_sel is

  alias indexes_a : natural_vector(indexes_g'length-1 downto 0) is indexes_g;

  signal sel_in_i : std_logic_vector(sel_in'high downto indexes_g(indexes_g'left));

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sel_in_i <= (others => '0');
      else
        sel_in_i <= sel_in(sel_in_i'range);
      end if;
    end if;
  end process;

  -- Recurse on the unused bits
  mux_sel_g : if indexes_g'length > 1 generate

    mux_sel_i : entity work.mux_sel
      generic map (
        sel_bits_g => sel_bits_g,
        indexes_g  => indexes_a(indexes_g'length-2 downto 0)
      )
      port map (
        clk     => clk,
        reset   => reset,
        sel_in  => sel_in_i & sel_in(indexes_g(indexes_g'left)-1 downto 0),
        sel_out => sel_out
      );

  -- Prevent compiler warnings about null ranges
  elsif indexes_g(indexes_g'left) > 0 generate

    sel_out <= sel_in_i & sel_in(indexes_g(indexes_g'left)-1 downto 0);

  else generate

    -- Otherwise null range
    sel_out <= sel_in_i;

  end generate;

end architecture;
