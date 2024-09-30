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

entity axi_split_join_ip is
  port(
    clk         : in  std_logic;
    resetn      : in  std_logic;
    s_axi_data  : in  std_logic_vector(15 downto 0) := (others => '0');
    s_axi_valid : in  std_logic                     := '0';
    s_axi_ready : out std_logic                     := '0';
    m_axi_data  : out std_logic_vector(31 downto 0) := (others => '0');
    m_axi_valid : out std_logic                     := '0';
    m_axi_ready : in  std_logic                     := '0'
  );
end entity;


--library xil_defaultlib;

architecture rtl of axi_split_join_ip is

  -- Generated IP cores are fixed width, so this can't be a generic.
  constant data_width_c : positive := 16;

  signal asad1_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal asad1_axi_valid : std_logic                                 := '0';
  signal asad1_axi_ready : std_logic                                 := '0';
  signal asad2_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal asad2_axi_valid : std_logic                                 := '0';
  signal asad2_axi_ready : std_logic                                 := '0';
  signal adaj1_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal adaj1_axi_valid : std_logic                                 := '0';
  signal adaj1_axi_ready : std_logic                                 := '0';
  signal adaj2_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal adaj2_axi_valid : std_logic                                 := '0';
  signal adaj2_axi_ready : std_logic                                 := '0';
  signal asad_axi_valid  : std_logic_vector(1 downto 0);
  signal asad_axi_data   : std_logic_vector(2*data_width_c-1 downto 0);
  signal adaj_axi_ready  : std_logic_vector(1 downto 0);

begin

--  asad_axi_valid <= asad1_axi_valid & asad2_axi_valid;
  (asad1_axi_valid, asad2_axi_valid) <= asad_axi_valid;
  (asad1_axi_data,  asad2_axi_data)  <= asad_axi_data;

  axi_split_i : entity work.axis_broadcaster
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => s_axi_valid,
      s_axis_tready => s_axi_ready,
      s_axis_tdata  => s_axi_data,
      m_axis_tvalid => asad_axi_valid,
      m_axis_tready => (asad1_axi_ready, asad2_axi_ready),
      m_axis_tdata  => asad_axi_data
    );


  axi_delay1 : entity work.axi_delay(simple)
    generic map (
      delay_g      => 20,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => asad1_axi_data,
      s_axi_valid => asad1_axi_valid,
      s_axi_ready => asad1_axi_ready,
      m_axi_data  => adaj1_axi_data,
      m_axi_valid => adaj1_axi_valid,
      m_axi_ready => adaj1_axi_ready
    );


  axi_delay2 : entity work.axi_delay(itdev)
    generic map (
      delay_g      => 19,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => asad2_axi_data,
      s_axi_valid => asad2_axi_valid,
      s_axi_ready => asad2_axi_ready,
      m_axi_data  => adaj2_axi_data,
      m_axi_valid => adaj2_axi_valid,
      m_axi_ready => adaj2_axi_ready
    );


  (adaj1_axi_ready, adaj2_axi_ready) <= adaj_axi_ready;

  axi_join_i : entity work.axis_combiner
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => (adaj1_axi_valid, adaj2_axi_valid),
      s_axis_tready => adaj_axi_ready,
      s_axis_tdata  => (adaj1_axi_data, adaj2_axi_data),
      m_axis_tvalid => m_axi_valid,
      m_axis_tready => m_axi_ready,
      m_axis_tdata  => m_axi_data
    );

end architecture;
