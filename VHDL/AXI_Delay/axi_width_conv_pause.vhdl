-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A data width converter with pause mechanism for an AXI Data Stream.
--
-- P A Abbey, 24 February 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_width_conv_pause is
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(15 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_ready : out std_logic                    := '0';
    enable      : in  std_logic;
    m_axi_data  : out std_logic_vector(7 downto 0) := (others => '0');
    m_axi_valid : out std_logic                    := '0';
    m_axi_ready : in  std_logic
  );
end entity;


architecture rtl of axi_width_conv_pause is

  -- We're processing the first half of the input word and hence about to process the second half
  signal s_half : std_logic := '0';

begin

  s_axi_ready <= m_axi_ready and s_half and enable;

  process(clk)
  begin
    if rising_edge(clk) then
      if m_axi_ready = '1' and enable = '1' then
        if s_axi_valid = '1' and s_half = '0' then
          s_half <= '1';
        elsif s_half = '1' then
          s_half <= '0';
        end if;
      end if;

      if m_axi_ready = '1' and s_half = '0' then
        m_axi_data  <= s_axi_data(7 downto 0);
        m_axi_valid <= s_axi_valid and enable;
      elsif (m_axi_ready = '1' or m_axi_valid = '0') and s_half = '1' then
        m_axi_data  <= s_axi_data(15 downto 8);
        m_axi_valid <= enable;
      end if;
    end if;
  end process;

end architecture;
