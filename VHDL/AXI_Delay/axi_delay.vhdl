-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Two AXI Delay implementations to demonstrate how to implement a delay register for
-- AXI streaming data.
--
-- Reference: Register ready signals in low latency, zero bubble pipeline
--            https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 26 March 2022
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity axi_delay is
  generic(
    delay_g      : positive;
    data_width_g : positive
  );
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_ready : out std_logic;
    m_axi_data  : out std_logic_vector(data_width_g-1 downto 0);
    m_axi_valid : out std_logic;
    m_axi_ready : in  std_logic
  );
end entity;


architecture simple of axi_delay is

  type delay_reg_t is array(delay_g-1 downto 0) of std_logic_vector(data_width_g-1 downto 0);

  signal data_reg  : delay_reg_t                          := (others => (others => '0'));
  signal valid_reg : std_logic_vector(delay_g-1 downto 0) := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if s_axi_ready = '1' then
        data_reg  <= s_axi_data  & data_reg(delay_g-1 downto 1);
        valid_reg <= s_axi_valid & valid_reg(delay_g-1 downto 1);
      end if;
    end if;
  end process;

  m_axi_data  <= data_reg(0);
  m_axi_valid <= valid_reg(0);

  s_axi_ready <= m_axi_ready or not valid_reg(0);

end architecture;


--
-- https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
architecture itdev of axi_delay is

  type delay_reg_t is array(delay_g-1 downto 0) of std_logic_vector(data_width_g-1 downto 0);

  signal data_reg    : delay_reg_t                          := (others => (others => '0'));
  signal valid_reg   : std_logic_vector(delay_g-1 downto 0) := (others => '0');
  signal ready_stage : std_logic_vector(delay_g-1 downto 0) := (others => '0');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      for i in delay_g-2 downto 0 loop
        if ready_stage(i) = '1' then
          data_reg(i)  <= data_reg(i+1);
          valid_reg(i) <= valid_reg(i+1);
        end if;
      end loop;

      if ready_stage(delay_g-1) = '1' then
        data_reg(delay_g-1)  <= s_axi_data;
        valid_reg(delay_g-1) <= s_axi_valid;
      end if;
    end if;
  end process;

  m_axi_data  <= data_reg(0);
  m_axi_valid <= valid_reg(0);

  ready_gen : for i in delay_g-1 downto 1 generate
    ready_stage(i) <= ready_stage(i-1) or not valid_reg(i);
  end generate;

  ready_stage(0) <= m_axi_ready or not valid_reg(0);
  s_axi_ready    <= ready_stage(ready_stage'high);

end architecture;
