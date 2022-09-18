-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Seven segment display decoder, converts a hexadecimal integer 0x0-0xF into the
-- standard segment illuminations.
--
-- P A Abbey, 18 September 2020
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity sevseg_display is
  port(
    digit : in  integer range 0 to 15;
    disp  : out std_logic_vector(6 downto 0)
  );
end entity;

architecture rtl of sevseg_display is
begin

  process(digit)
  begin
    case digit is --         "abcdefg"
      when  0     => disp <= "1111110";
      when  1     => disp <= "0110000";
      when  2     => disp <= "1101101";
      when  3     => disp <= "1111001";
      when  4     => disp <= "0110011";
      when  5     => disp <= "1011011";
      when  6     => disp <= "1011111";
      when  7     => disp <= "1110000";
      when  8     => disp <= "1111111";
      when  9     => disp <= "1111011";
      when 10     => disp <= "1110111"; -- A
      when 11     => disp <= "0011111"; -- b
      when 12     => disp <= "1001110"; -- C
      when 13     => disp <= "0111101"; -- d
      when 14     => disp <= "1001111"; -- E
      when 15     => disp <= "1000111"; -- F
      when others => disp <= "0000000";
    end case;
  end process;

end architecture;
