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


architecture rtl of axi_split_join_ip is

  type axis_t is record
    data  : std_logic_vector;
    valid : std_logic;
    ready : std_logic;
  end record;

  -- Generated IP cores are fixed width, so this can't be a generic.
  constant data_width_c : positive := 16;

  constant axis_default_c : axis_t(data(data_width_c-1 downto 0)) := (
    data  => (others => '0'),
    valid => '0',
    ready => '0'
  );

  signal asar_axi_valid  : std_logic_vector(1 downto 0);
  signal asar_axi_data   : std_logic_vector(2*data_width_c-1 downto 0);
  signal araj_axi_ready  : std_logic_vector(1 downto 0);

  signal asar1 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal asar2 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal arad1 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal arad2 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal adar1 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal adar2 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal araj1 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;
  signal araj2 : axis_t(data(data_width_c-1 downto 0)) := axis_default_c;

begin

  (asar1.valid, asar2.valid) <= asar_axi_valid;
  (asar1.data,  asar2.data)  <= asar_axi_data;

  axi_split_i : entity work.axis_broadcaster
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => s_axi_valid,
      s_axis_tready => s_axi_ready,
      s_axis_tdata  => s_axi_data,
      m_axis_tvalid => asar_axi_valid,
      m_axis_tready => (asar1.ready, asar2.ready),
      m_axis_tdata  => asar_axi_data
    );

  axis_reg_slice1 : entity work.axis_register_slice
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => asar1.valid,
      s_axis_tready => asar1.ready,
      s_axis_tdata  => asar1.data,
      m_axis_tvalid => arad1.valid,
      m_axis_tready => arad1.ready,
      m_axis_tdata  => arad1.data
    );

  axi_delay1 : entity work.axi_delay(simple)
    generic map (
      delay_g      => 20,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => arad1.data,
      s_axi_valid => arad1.valid,
      s_axi_ready => arad1.ready,
      m_axi_data  => adar1.data,
      m_axi_valid => adar1.valid,
      m_axi_ready => adar1.ready
    );

  axis_reg_slice2 : entity work.axis_register_slice
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => asar2.valid,
      s_axis_tready => asar2.ready,
      s_axis_tdata  => asar2.data,
      m_axis_tvalid => arad2.valid,
      m_axis_tready => arad2.ready,
      m_axis_tdata  => arad2.data
    );

  axi_delay2 : entity work.axi_delay(itdev)
    generic map (
      delay_g      => 19,
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => arad2.data,
      s_axi_valid => arad2.valid,
      s_axi_ready => arad2.ready,
      m_axi_data  => adar2.data,
      m_axi_valid => adar2.valid,
      m_axi_ready => adar2.ready
    );

  axis_reg_slice3 : entity work.axis_register_slice
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => adar1.valid,
      s_axis_tready => adar1.ready,
      s_axis_tdata  => adar1.data,
      m_axis_tvalid => araj1.valid,
      m_axis_tready => araj1.ready,
      m_axis_tdata  => araj1.data
    );

  axis_reg_slice4 : entity work.axis_register_slice
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => adar2.valid,
      s_axis_tready => adar2.ready,
      s_axis_tdata  => adar2.data,
      m_axis_tvalid => araj2.valid,
      m_axis_tready => araj2.ready,
      m_axis_tdata  => araj2.data
    );

  (araj1.ready, araj2.ready) <= araj_axi_ready;

  axi_join_i : entity work.axis_combiner
    port map (
      aclk          => clk,
      aresetn       => resetn,
      s_axis_tvalid => (araj1.valid, araj2.valid),
      s_axis_tready => araj_axi_ready,
      s_axis_tdata  => (araj1.data, araj2.data),
      m_axis_tvalid => m_axi_valid,
      m_axis_tready => m_axi_ready,
      m_axis_tdata  => m_axi_data
    );

end architecture;
