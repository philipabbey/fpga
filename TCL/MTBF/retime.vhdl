-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado's MTBF calculation.
--
-- P A Abbey, 25 June 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity retime is
  generic (
    num_bits_g  : positive := 2;
    reg_depth_g : positive := 2 -- Deliberately does not start at 2 in order to measure the MTBF of a 1-logn resync chain.
  );
  port (
    clk_src    : in  std_logic;
    reset_src  : in  std_logic;
    clk_dest   : in  std_logic;
    reset_dest : in  std_logic;
    flags_in   : in  std_logic_vector(num_bits_g-1 downto 0);
    flags_out  : out std_logic_vector(num_bits_g-1 downto 0)
  );
end entity;


architecture rtl of retime is

  signal reg_capture : std_logic_vector(num_bits_g-1 downto 0);

  type reg_array_t is array(natural range <>) of std_logic_vector(num_bits_g-1 downto 0);
  signal reg_retime : reg_array_t(reg_depth_g-1 downto 0);

  -- Could be placed in a constraints file
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of reg_retime : signal is "TRUE";

begin

  -- Remove glitches from any unregistered combinatorial logic on the source data.
  -- Glitches must not be captured by accident in the new clock domain.
  process(clk_src)
  begin
    if rising_edge(clk_src) then
      if reset_src = '1' then
        reg_capture <= (others => '0');
      else
        reg_capture <= flags_in;
      end if;
    end if;
  end process;

  process(clk_dest)
  begin
    if rising_edge(clk_dest) then
      if reset_dest = '1' then
        reg_retime <= (others => (others => '0'));
      else
        reg_retime <= reg_retime(reg_depth_g-2 downto 0) & reg_capture;
      end if;
    end if;
  end process;
  
  flags_out <= reg_retime(reg_depth_g-1);

end architecture;
