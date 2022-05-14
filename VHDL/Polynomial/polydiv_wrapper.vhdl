-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Wrapper to provide a specific vector length and polynomial to data_in for RTL
-- elaboration and registered I/O.
--
-- P A Abbey, 12 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity polydiv_wrapper is
  port(
    clk           : in  std_ulogic;
    reset         : in  std_ulogic;
    data_in       : in  std_ulogic_vector(7 downto 0);
    data_valid_in : in  std_ulogic;
    data_out      : out std_ulogic_vector(31 downto 0)
  );
end entity;


architecture rtl of polydiv_wrapper is

  signal data_in_i  : std_ulogic_vector(data_in'range);
  signal data_out_i : std_ulogic_vector(data_out'range);

begin

  polydiv_c : entity work.polydiv
    generic map(
      poly_g => "100000100110000010001110110110111"
    )
    port map(
      clk           => clk,
      reset         => reset,
      data_in       => data_in_i,
      data_valid_in => data_valid_in,
      data_out      => data_out_i
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        data_in_i <= (others => '0');
        data_out  <= (others => '0');
      elsif data_valid_in = '1' then
        data_in_i <= data_in;
        data_out  <= data_out_i;
      end if;
    end if;
  end process;

end architecture;
