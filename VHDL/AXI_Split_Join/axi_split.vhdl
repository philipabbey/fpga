-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Split logic for an AXI Data Stream.
--
-- Reference: Register ready signals in low latency, zero bubble pipeline
--            https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 30 August 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_split is
  generic(
    data_width_g : positive
  );
  port(
    s_axi_data   : in  std_logic_vector(data_width_g-1 downto 0);
    s_axi_valid  : in  std_logic;
    s_axi_ready  : out std_logic                                 := '0';
    m1_axi_data  : out std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    m1_axi_valid : out std_logic                                 := '0';
    m1_axi_ready : in  std_logic;
    m2_axi_data  : out std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    m2_axi_valid : out std_logic                                 := '0';
    m2_axi_ready : in  std_logic
  );
end entity;


architecture rtl of axi_split is

  signal backpressure : std_logic;

begin

  m1_axi_data  <= s_axi_data;
  m1_axi_valid <= s_axi_valid and m2_axi_ready;

  m2_axi_data  <= s_axi_data;
  m2_axi_valid <= s_axi_valid and m1_axi_ready;

  s_axi_ready  <= m1_axi_ready and m2_axi_ready;

  -- NB. Invert this logic when using in an assert statement.
  backpressure <= s_axi_valid and not s_axi_ready;

end architecture;
