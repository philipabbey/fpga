library ieee;
use ieee.std_logic_1164.all;

entity polybitdiv is
  generic(
    len : positive := 5
  );
  port(
    clk           : in  std_ulogic;
    reset         : in  std_ulogic;
    poly          : in  std_ulogic_vector(len-1 downto 0);
    data_in       : in  std_ulogic;
    data_valid_in : in  std_ulogic;
    data_out      : out std_ulogic_vector(len-2 downto 0)
  );
end entity;

architecture rtl of polybitdiv is

  subtype reg_t is std_ulogic_vector(len-1 downto 0); -- poly'length
  signal reg : reg_t;

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg <= (others => '0');
      elsif data_valid_in = '1' then
        -- NB. at this point reg(reg'high) = '1' always
        reg <= (reg(reg'high-1 downto 0) & data_in) xor
               (poly and reg_t'(others => reg(reg'high-1)));
      end if;
    end if;
  end process;

  data_out <= reg(data_out'range);

end architecture;
