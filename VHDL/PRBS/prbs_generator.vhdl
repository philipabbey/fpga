-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Generic pseudorandom binary sequence (PRBS) sequence generator for any provided
-- polynomial and any data width (fixed at compile time).
--
-- P A Abbey, 10 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity prbs_generator is
  generic (
    inv_pattern_g : boolean           := false;
    -- NB. Vector direction 'to' or 'downto' does not matter.
    --                                    9876543210
    poly_g        : std_ulogic_vector := "100010000";
    data_width_g  : positive          := 4
  );
  port (
    clk      : in  std_logic;                                -- System clock
    reset    : in  std_logic;                                -- Sync reset active high
    enable   : in  std_logic;                                -- Enable pattern generation
    data_out : out std_logic_vector(data_width_g-1 downto 0) -- Generated PRBS pattern
  );
end entity;


architecture rtl of prbs_generator is

  signal reg : std_logic_vector(poly_g'length-1 downto 0) := (others => '1');

begin

  process (clk)
    variable reg_v : std_logic_vector(reg'range);
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg      <= (others => '1');
        data_out <= (others => '1');
      elsif enable = '1' then
        reg_v := reg;
        for i in data_out'reverse_range loop
          reg_v       := reg_v(poly_g'length-2 downto 0) & (xor(reg_v and poly_g));
          data_out(i) <= not reg_v(0) when inv_pattern_g else reg_v(0);
        end loop;
        reg <= reg_v;
      end if;
    end if;
  end process;

end architecture;
