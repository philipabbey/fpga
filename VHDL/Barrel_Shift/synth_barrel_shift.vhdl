-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Generic pipelined barrel shift enabling arbitraily large vector rotations over a
-- user specified number of clock cycles in order to manage timing closure.
--
-- Synthesis could use the out of context scripts, but I want to report the timing
-- more accurately, so I'm putting a ring of registers around the DUT and false paths
-- on all the external edges. 
--
-- P A Abbey, 16 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity synth_barrel_shift is
  generic (
    -- Rotation direction left/right - LEFT to start with
    -- Pipeline stages
    shift_bits_g : positive := 9;
    shift_left_g : boolean  := true; -- Otherwise shift right
    num_clks_g   : positive := 3;
    -- Iterative or recursive component?
    recursive_g : boolean := true
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    shift    : in  std_logic_vector(   shift_bits_g-1 downto 0);
    data_in  : in  std_logic_vector(2**shift_bits_g-1 downto 0);
    data_out : out std_logic_vector(2**shift_bits_g-1 downto 0)
  );
end entity;


architecture rtl of synth_barrel_shift is

  signal shift_i    : std_logic_vector(   shift_bits_g-1 downto 0);
  signal data_in_i  : std_logic_vector(2**shift_bits_g-1 downto 0);
  signal data_out_i : std_logic_vector(2**shift_bits_g-1 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        shift_i   <= (others => '0');
        data_in_i <= (others => '0');
        data_out  <= (others => '0');
      else
        shift_i   <= shift;
        data_in_i <= data_in;
        data_out  <= data_out_i;
      end if;
    end if;
  end process;


  choose : if recursive_g generate

    dut : entity work.barrel_shift_recursive
      generic map (
        shift_bits_g => shift_bits_g,
        shift_left_g => shift_left_g,
        num_clks_g   => num_clks_g
      )
      port map (
        clk      => clk,
        reset    => reset,
        shift    => shift_i,
        data_in  => data_in_i,
        data_out => data_out_i
      );

  else generate

    dut : entity work.barrel_shift_iterative
      generic map (
        shift_bits_g => shift_bits_g,
        shift_left_g => shift_left_g,
        num_clks_g   => num_clks_g
      )
      port map (
        clk      => clk,
        reset    => reset,
        shift    => shift_i,
        data_in  => data_in_i,
        data_out => data_out_i
      );

  end generate;

end architecture;
