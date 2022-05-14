-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A pause mechanism for an AXI Data Stream.
--
-- Reference: Register ready signals in low latency, zero bubble pipeline
--            https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 1 April 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_pause is
  generic(
    data_width_g : positive
  );
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_ready : out std_logic := '0';
    enable      : in  std_logic;
    m_axi_data  : out std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    m_axi_valid : out std_logic := '0';
    m_axi_ready : in  std_logic
  );
end entity;


architecture rtl of axi_pause is
begin

  s_axi_ready <= (m_axi_ready or not m_axi_valid) and enable;

  process(clk)
  begin
    if rising_edge(clk) then
      if m_axi_ready = '1' or m_axi_valid = '0' then
        m_axi_data  <= s_axi_data;
        m_axi_valid <= s_axi_valid and enable;
      end if;
    end if;
  end process;

end architecture;
