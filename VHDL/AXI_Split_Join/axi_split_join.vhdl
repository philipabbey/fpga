-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the split and join mechanisms for two parallel AXI Data Stream loads.
--
-- P A Abbey, 29 September 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_split_join is
  generic(
    data_width_g : positive := 16
  );
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0)   := (others => '0');
    s_axi_valid : in  std_logic                                   := '0';
    s_axi_ready : out std_logic                                   := '0';
    m_axi_data  : out std_logic_vector(2*data_width_g-1 downto 0) := (others => '0');
    m_axi_valid : out std_logic                                   := '0';
    m_axi_ready : in  std_logic                                   := '0'
  );
end entity;


architecture rtl of axi_split_join is

  signal asad1_axi_data    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal asad1_axi_valid   : std_logic                                 := '0';
  signal asad1_axi_ready   : std_logic                                 := '0';
  signal asad2_axi_data    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal asad2_axi_valid   : std_logic                                 := '0';
  signal asad2_axi_ready   : std_logic                                 := '0';
  signal adaj1_axi_data    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal adaj1_axi_valid   : std_logic                                 := '0';
  signal adaj_axi_ready    : std_logic                                 := '0';
  signal adaj2_axi_data    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal adaj2_axi_valid   : std_logic                                 := '0';

begin

  axi_split_i : entity work.axi_split
    generic map (
      data_width_g => data_width_g
    )
    port map (
      s_axi_data   => s_axi_data,
      s_axi_valid  => s_axi_valid,
      s_axi_ready  => s_axi_ready,
      m1_axi_data  => asad1_axi_data,
      m1_axi_valid => asad1_axi_valid,
      m1_axi_ready => asad1_axi_ready,
      m2_axi_data  => asad2_axi_data,
      m2_axi_valid => asad2_axi_valid,
      m2_axi_ready => asad2_axi_ready
    );


  axi_delay1 : entity work.axi_delay(simple)
    generic map (
      delay_g      => 20,
      data_width_g => data_width_g
    )
    port map (
      clk         => clk,
      s_axi_data  => asad1_axi_data,
      s_axi_valid => asad1_axi_valid,
      s_axi_ready => asad1_axi_ready,
      m_axi_data  => adaj1_axi_data,
      m_axi_valid => adaj1_axi_valid,
      m_axi_ready => adaj_axi_ready
    );


  axi_delay2 : entity work.axi_delay(itdev)
    generic map (
      delay_g      => 19,
      data_width_g => data_width_g
    )
    port map (
      clk         => clk,
      s_axi_data  => asad2_axi_data,
      s_axi_valid => asad2_axi_valid,
      s_axi_ready => asad2_axi_ready,
      m_axi_data  => adaj2_axi_data,
      m_axi_valid => adaj2_axi_valid,
      m_axi_ready => adaj_axi_ready
    );


  axi_join_i : entity work.axi_join(rtl_comb) -- Or rtl_reg
    generic map (
      data_width_g => data_width_g
    )
    port map (
      clk          => clk,
      s1_axi_data  => adaj1_axi_data,
      s1_axi_valid => adaj1_axi_valid,
      s_axi_ready  => adaj_axi_ready,
      s2_axi_data  => adaj2_axi_data,
      s2_axi_valid => adaj2_axi_valid,
      m_axi_data   => m_axi_data,
      m_axi_valid  => m_axi_valid,
      m_axi_ready  => m_axi_ready
    );

end architecture;
