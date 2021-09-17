library ieee;
use ieee.std_logic_1164.all;

entity polydiv is
  generic(
    poly : std_ulogic_vector -- direction 'to' or 'downto' does not matter.
  );
  port(
    clk           : in  std_ulogic;
    reset         : in  std_ulogic;
    data_in       : in  std_ulogic_vector; -- bus width independent of 'poly', direction 'to' or 'downto' does not matter.
    data_valid_in : in  std_ulogic;
    data_out      : out std_ulogic_vector(poly'length-2 downto 0)
  );
end entity;

architecture rtl of polydiv is

  subtype reg_t is std_ulogic_vector(poly'length-1 downto 0);
  signal reg : reg_t;

begin

  process(clk)
    variable xored_i : reg_t;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg <= (others => '0');
      elsif data_valid_in = '1' then
        xored_i := reg;
        -- Do multiple bits of divisor per cycle.
        for i in data_in'range loop
          -- NB. at this point xored_i(xored_i'high) = '1' always
          -- Written this way, poly can be either "0 to n", or "n downto 0"
          xored_i := (xored_i(xored_i'high-1 downto 0) & data_in(i)) xor
                     (poly and reg_t'(others => xored_i(xored_i'high-1)));
        end loop;
        reg <= xored_i;
      end if;
    end if;
  end process;

  data_out <= reg(data_out'range);

end architecture;
