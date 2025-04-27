-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Reconfigurable partition and modules for partial reconfiguration demonstration.
--
-- P A Abbey, 12 February 2025
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity reconfig_fn is
  generic(
    display_g : std_logic_vector(3 downto 0) := x"8"
  );
  port(
    clk     : in  std_logic;
    reset   : in  std_logic;
    incr    : in  std_logic;
    buttons : in  std_logic_vector(3 downto 0);
    leds    : out std_logic_vector(3 downto 0) := x"0";
    display : out std_logic_vector(3 downto 0) := x"0"
  );
end entity;

architecture rtl of reconfig_fn is
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        leds    <= "0000";
        display <= x"0";
      else
        leds    <= "1010";
        display <= display_g;
      end if;
    end if;
  end process;

end architecture;


library ieee;
  use ieee.std_logic_1164.all;

entity reconfig_rm is
  generic(
    rm_num_g : natural := 0 -- 0 is intentionally empty
  );
  port(
    clk     : in  std_logic;
    reset   : in  std_logic;
    incr    : in  std_logic;
    buttons : in  std_logic_vector(3 downto 0);
    leds    : out std_logic_vector(3 downto 0) := x"0";
    display : out std_logic_vector(3 downto 0) := x"0"
  );
end entity;

architecture rm_sel of reconfig_rm is
begin

  -- Typically these would be very differnt sub-components defined in different entities.
  -- This layer is used as a wrapper to stitch them to a common interface for the RP
  -- If rm_num = 0, include nothing intentionally (default)
  rm_g : if rm_num_g = 1 generate

    comp_reconfig : entity work.reconfig_fn
      generic map (
        display_g => x"1" -- Could use to_slv(rm_num_g, 4), but that solution is specific to the simple 'reconfig_fn'.
      )
      port map (
        clk     => clk,
        reset   => reset,
        incr    => incr,
        buttons => buttons,
        leds    => leds,
        display => display
      );

  elsif rm_num_g = 2 generate

    comp_reconfig : entity work.reconfig_fn
      generic map (
        display_g => x"2"
      )
      port map (
        clk     => clk,
        reset   => reset,
        incr    => incr,
        buttons => buttons,
        leds    => leds,
        display => display
      );

  elsif rm_num_g = 3 generate

    comp_reconfig : entity work.reconfig_fn
      generic map (
        display_g => x"3"
      )
      port map (
        clk     => clk,
        reset   => reset,
        incr    => incr,
        buttons => buttons,
        leds    => leds,
        display => display
      );

  elsif rm_num_g = 4 generate

    comp_reconfig : entity work.reconfig_fn
      generic map (
        display_g => x"4"
      )
      port map (
        clk     => clk,
        reset   => reset,
        incr    => incr,
        buttons => buttons,
        leds    => leds,
        display => display
      );

  end generate;

end architecture;
