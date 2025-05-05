-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/house-of-abbey/scratch_vhdl/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- VHDL 1993 wrapper for VHDL 2018 top level RTL file in order to keep Vivado's Block
-- Diagram Editor happy. :-(
--
-- P A Abbey, 24 February 2025
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity vhdl2018_1993_conv is
  generic(
    sim_g    : boolean := false;
    rm_num_g : natural
  );
  port(
    -- X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 core_clk CLK"
    -- X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi_reg"
    -- X_INTERFACE_PARAMETER = "ASSOCIATED_RESET resetn"
    clk               : in  std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 core_rst RST"
    -- X_INTERFACE_PARAMETER = "ASSOCIATED_RESET resetn"
    resetn            : in  std_logic;
    sw                : in  std_logic_vector(3 downto 0);
    btn               : in  std_logic_vector(3 downto 0);
    led               : out std_logic_vector(3 downto 0) := "0000";
    disp_sel          : out std_logic                    := '0';
    sevseg            : out std_logic_vector(6 downto 0) := "0000000";
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG AWADDR"
    s_axi_reg_awaddr  : in  std_logic_vector(31 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG AWVALID"
    s_axi_reg_awvalid : in  std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG AWREADY"
    s_axi_reg_awready : out std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG WDATA"
    s_axi_reg_wdata   : in  std_logic_vector(31 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG WVALID"
    s_axi_reg_wvalid  : in  std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG WREADY"
    s_axi_reg_wready  : out std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG BRESP"
    s_axi_reg_bresp   : out std_logic_vector(1 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG BVALID"
    s_axi_reg_bvalid  : out std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG BREADY"
    s_axi_reg_bready  : in  std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG ARADDR"
    s_axi_reg_araddr  : in  std_logic_vector(31 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG ARVALID"
    s_axi_reg_arvalid : in  std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG ARREADY"
    s_axi_reg_arready : out std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG RDATA"
    s_axi_reg_rdata   : out std_logic_vector(31 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG RRESP"
    s_axi_reg_rresp   : out std_logic_vector(1 downto 0);
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG RVALID"
    s_axi_reg_rvalid  : out std_logic;
    -- X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI_REG RREADY"
    s_axi_reg_rready  : in  std_logic
  );
end entity;


architecture struct of vhdl2018_1993_conv is

  signal reset : std_logic;

begin

  reset <= not resetn;

  wrapper_i : entity work.pl
    generic map (
      sim_g    => sim_g,
      rm_num_g => rm_num_g
    )
    port map (
      clk               => clk,
      reset             => reset,
      sw                => sw,
      btn               => btn,
      led               => led,
      disp_sel          => disp_sel,
      sevseg            => sevseg,
      s_axi_reg_awaddr  => s_axi_reg_awaddr,
      s_axi_reg_awvalid => s_axi_reg_awvalid,
      s_axi_reg_awready => s_axi_reg_awready,
      s_axi_reg_wdata   => s_axi_reg_wdata,
      s_axi_reg_wvalid  => s_axi_reg_wvalid,
      s_axi_reg_wready  => s_axi_reg_wready,
      s_axi_reg_bresp   => s_axi_reg_bresp,
      s_axi_reg_bvalid  => s_axi_reg_bvalid,
      s_axi_reg_bready  => s_axi_reg_bready,
      s_axi_reg_araddr  => s_axi_reg_araddr,
      s_axi_reg_arvalid => s_axi_reg_arvalid,
      s_axi_reg_arready => s_axi_reg_arready,
      s_axi_reg_rdata   => s_axi_reg_rdata,
      s_axi_reg_rresp   => s_axi_reg_rresp,
      s_axi_reg_rvalid  => s_axi_reg_rvalid,
      s_axi_reg_rready  => s_axi_reg_rready
    );

end architecture;
