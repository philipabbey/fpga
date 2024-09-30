-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Join logic for two AXI Data Streams.
--
-- Reference: Register ready signals in low latency, zero bubble pipeline
--            https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 30 August 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_join is
  generic(
    data_width_g : positive
  );
  port(
    clk          : in  std_logic;
    s1_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s1_axi_valid : in  std_logic;
    s_axi_ready  : out std_logic                                   := '0'; -- For both ports 1 & 2
    s2_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s2_axi_valid : in  std_logic;
    m_axi_data   : out std_logic_vector(2*data_width_g-1 downto 0) := (others => '0');
    m_axi_valid  : out std_logic                                   := '0';
    m_axi_ready  : in  std_logic
  );
end entity;


architecture rtl_reg of axi_join is

  signal backpressure1 : std_logic;
  signal backpressure2 : std_logic;

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if s_axi_ready = '1' then
        m_axi_data  <= s1_axi_data & s2_axi_data;
        m_axi_valid <= s1_axi_valid and s2_axi_valid;
      elsif m_axi_ready = '1' and m_axi_valid = '1' then
        m_axi_valid <= '0';
      end if;
    end if;
  end process;

  s_axi_ready <= (m_axi_ready or not m_axi_valid) and s1_axi_valid and s2_axi_valid;
  -- The following work in simulation too, but without the 'or not m_axi_valid' clause takes a few extra
  -- clock cycles, i.e. lower throughput:
  --   s_axi_ready <= m_axi_ready and s1_axi_valid and s2_axi_valid;

  -- synthesis translate_off
  -- NB. Invert this logic when using in an assert statement.
  backpressure1 <= s1_axi_valid and not s_axi_ready after 1 ps;
  backpressure2 <= s2_axi_valid and not s_axi_ready after 1 ps;
  -- synthesis translate_on

end architecture;


architecture rtl_comb of axi_join is

  signal backpressure1 : std_logic;
  signal backpressure2 : std_logic;

begin

  m_axi_valid <= s1_axi_valid and s2_axi_valid;
  s_axi_ready <= s1_axi_valid and s2_axi_valid and m_axi_ready;
  m_axi_data  <= s1_axi_data & s2_axi_data;

  -- synthesis translate_off
  -- NB. Invert this logic when using in an assert statement.
  backpressure1 <= s1_axi_valid and not s_axi_ready after 1 ps;
  backpressure2 <= s2_axi_valid and not s_axi_ready after 1 ps;
  -- synthesis translate_on

end architecture;
