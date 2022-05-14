-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Simple fixed point multipler to test the 'sfixed' type.
--
-- P A Abbey, 1 Sep 2021
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library ieee_proposed;
  use ieee_proposed.fixed_pkg.all;

entity sfixed_mult is
  port(
    clk   : in  std_logic;
    reset : in  std_logic;
    a     : in  sfixed( 7 downto  -8);
    b     : in  sfixed( 7 downto  -8);
    o     : out sfixed(15 downto -16)
  );
end entity;


architecture rtl of sfixed_mult is
begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        o <= (others => '0');
      else
        o <= a * b;
      end if;
    end if;
  end process;

end architecture;
