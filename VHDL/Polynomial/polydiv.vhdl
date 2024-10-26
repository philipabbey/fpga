-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Polynomial division performing multiple bits of work per clock cycle. The
-- polynomial is specified as a generic, so constant at compile time. Synthesis of
-- this design will optimise away logic because the polynomial is constant.
--
-- P A Abbey, 12 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity polydiv is
  generic(
    -- Polynomial bit order specification is: x^n + .. + x^4 + x^3 + x^2 + x^1 + 1
    --      543210
    -- E.g. 100101 represents x^5 + x^2 + x^0
    poly_g : std_ulogic_vector -- direction 'to' or 'downto' does not matter.
  );
  port(
    clk           : in  std_ulogic;
    reset         : in  std_ulogic;
    data_in       : in  std_ulogic_vector; -- bus width independent of 'poly_g', direction 'to' or 'downto' does not matter.
    data_valid_in : in  std_ulogic;
    data_out      : out std_ulogic_vector(poly_g'length-2 downto 0)
  );
end entity;


architecture rtl of polydiv is

  subtype reg_t is std_ulogic_vector(poly_g'length-1 downto 0);
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
          -- NB. at this point xored_i(xored_i'high) = '0' always
          -- Written this way, poly_g can be either "0 to n", or "n downto 0"
          xored_i := (xored_i(xored_i'high-1 downto 0) & data_in(i)) xor
                     (poly_g and reg_t'(others => xored_i(xored_i'high-1)));
        end loop;
        reg <= xored_i;
      end if;
    end if;
  end process;

  data_out <= reg(data_out'range);

end architecture;


-- Alternative multiple bit per clock cycle CRC component.
--
-- P A Abbey, 25 October 2020

architecture rtl2 of polydiv is

  -- NB. poly_g(0) is assumed to be '1' and ignored. Alias required in order to slice.
  alias poly_a : std_ulogic_vector(poly_g'length-1 downto 0) is poly_g;

  subtype reg_t is std_ulogic_vector(poly_g'length-2 downto 0);

begin

  process(clk)
    variable xored_i : reg_t;
    variable fb      : std_ulogic;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_out <= (others => '1');
      elsif data_valid_in = '1' then
        xored_i := data_out;
        -- Do multiple bits of divisor per cycle.
        for i in data_in'range loop
          fb      := data_in(i) xor xored_i(xored_i'high);
          xored_i := (xored_i(xored_i'high-1 downto 0) & fb) xor
                     (poly_a(poly_a'high-1 downto 1) & '0' and reg_t'(others => fb));
        end loop;
        data_out <= xored_i;
      end if;
    end if;
  end process;

end architecture;
