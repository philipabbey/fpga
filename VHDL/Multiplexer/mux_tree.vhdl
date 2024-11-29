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

entity mux_tree is
  generic (
    sel_bits_g   : positive;
    data_width_g : positive;
    -- Pipeline stages
    num_clks_g   : positive
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    -- The timing on these bits must be staggered and arranged to reach the desired level of recursion at the right time.
    sel      : in  std_logic_vector(sel_bits_g-1 downto 0);
    data_in  : in  local.rtl_pkg.slv_arr_t(2**sel_bits_g-1 downto 0)(data_width_g-1 downto 0);
    data_out : out std_logic_vector(data_width_g-1 downto 0)
  );
end entity;


library ieee;
  -- This is for the benefit of Quartus Prime and its limited VHDL-2008 support.
  --use ieee.numeric_std_unsigned.all;
  use ieee.numeric_std.all;

architecture rtl of mux_tree is

  constant bits_c       : natural := work.mux_pkg.num_bits(sel_bits_g, num_clks_g);
  constant num_inputs_c : natural := data_in'length / 2**bits_c;

begin

  clk_chk : if bits_c > 0 generate
    signal data_mux : local.rtl_pkg.slv_arr_t(2**bits_c-1 downto 0)(data_width_g-1 downto 0);
  begin

    rec_chk : if sel'length-bits_c > 0 generate

      recurse : for i in 0 to 2**bits_c-1 generate
        constant top : natural := (num_inputs_c * i) + num_inputs_c-1;
        constant bot : natural := num_inputs_c * i;
      begin

        mux_i : entity work.mux_tree
          generic map (
            sel_bits_g   => sel'length-bits_c,
            data_width_g => data_width_g,
            num_clks_g   => num_clks_g-1
          )
          port map (
            clk      => clk,
            reset    => reset,
            sel      => sel(sel'high-bits_c downto 0), -- The subset of selection bits
            data_in  => data_in(top downto bot),
            data_out => data_mux(i)
          );

      end generate;

    else generate

      -- No more recursion
      data_mux <= data_in;

    end generate;

    mux_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          data_out <= (others => '0');
        else
          data_out <= data_mux(to_integer(unsigned(sel(sel'high downto sel'high-bits_c+1))));
        end if;
      end if;
    end process;

  else generate
    signal data_mux : std_logic_vector(data_width_g-1 downto 0);
  begin

    mux_i : entity work.mux_tree
      generic map (
        sel_bits_g   => sel'length,
        data_width_g => data_width_g,
        num_clks_g   => num_clks_g-1
      )
      port map (
        clk      => clk,
        reset    => reset,
        sel      => sel,
        data_in  => data_in,
        data_out => data_mux
      );

    -- Single clock cycle delay
    delay : process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          data_out <= (others => '0');
        else
          data_out <= data_mux;
        end if;
      end if;
    end process;

  end generate;

end architecture;
