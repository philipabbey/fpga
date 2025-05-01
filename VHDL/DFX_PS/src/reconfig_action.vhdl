-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Use the ICAP to effect a reconfiguration.
--
-- P A Abbey, 14 March 2025
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity reconfig_action is
  generic(
    sim_g : boolean := false
  );
  port(
    clk         : in  std_logic;
    reset       : in  std_logic;
    start       : in  std_logic;
    reset_rp    : out std_logic;
    programming : out std_logic := '0';
    error       : out std_logic := '0';
    rom_num     : out std_logic_vector(1 downto 0);
    conf_osc    : out std_logic
  );
end entity;


library unisim;
library xpm;
  use xpm.vcomponents.all;
library xil_defaultlib;
library local;
  use local.rtl_pkg.reverse;
-- synthesis translate_off
library std;
  use std.textio.all;
-- synthesis translate_on

architecture by_dfx_ip of reconfig_action is

  constant mem_init_files_c : string   := "rm_all_comp.mem";
  constant rom_addr_bits_c  : positive := 12; -- 12 is the minimum supported by the axi_bram component.
  constant rom_latency_c    : positive := 2;

  signal csib                        : std_logic;
  signal icap_rdwrb                  : std_logic;
  signal icap_i                      : std_logic_vector(31 downto 0);
  signal icap_o                      : std_logic_vector(31 downto 0);
  signal m_axi_mem_araddr            : std_logic_vector(31 downto 0);
  signal m_axi_mem_arlen             : std_logic_vector(7 downto 0);
  signal m_axi_mem_arsize            : std_logic_vector(2 downto 0);
  signal m_axi_mem_arburst           : std_logic_vector(1 downto 0);
  signal m_axi_mem_arprot            : std_logic_vector(2 downto 0);
  signal m_axi_mem_arcache           : std_logic_vector(3 downto 0);
  signal m_axi_mem_aruser            : std_logic_vector(3 downto 0);
  signal m_axi_mem_arvalid           : std_logic;
  signal m_axi_mem_arready           : std_logic;
  signal m_axi_mem_rdata             : std_logic_vector(31 downto 0);
  signal m_axi_mem_rresp             : std_logic_vector(1 downto 0);
  signal m_axi_mem_rlast             : std_logic;
  signal m_axi_mem_rvalid            : std_logic;
  signal m_axi_mem_rready            : std_logic;
  signal triggers                    : std_logic_vector(3 downto 0) := "0000";
  signal triggers_d                  : std_logic_vector(3 downto 0) := "0000";
  signal vsm_vs_hw_triggers          : std_logic_vector(3 downto 0) := "0000";
  signal vsm_vs_rm_shutdown_req      : std_logic;
  signal vsm_vs_rm_shutdown_req_d    : std_logic := '0';
  signal vsm_vs_rm_shutdown_ack      : std_logic := '0';
  signal vsm_vs_event_error          : std_logic;
  signal vsm_vs_m_axis_status_tdata  : std_logic_vector(31 downto 0);
  signal vsm_vs_m_axis_status_tvalid : std_logic;
  signal start_d                     : std_logic := '0';
  signal rom_addr                    : std_logic_vector(rom_addr_bits_c+1 downto 0); -- In bytes not 32-bit words
  signal rom_data                    : std_logic_vector(31 downto 0);
  signal rom_en                      : std_logic := '0';
  signal ri                          : std_logic_vector(31 downto 0); -- The ICAP data reversed for readability

  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of rom_i : label is "true";

  function onehot2bin(i : std_logic_vector) return std_logic_vector is
  begin
    case i is
      when "0001" => return "00";
      when "0010" => return "01";
      when "0100" => return "10";
      when others => return "11";
    end case;
  end function;

  -- Dynamic Function eXchange Controller v1.0 Product Guide (PG374)
  -- STATUS Register
  type error_reg_t is (
    no_err,
    bad_config,     -- The fetch path was asked to load a 0 byte bitstream
    bs_err,         -- The ICAP returned an error code while loading the bitstream.
    lost_err,       -- Access to the ICAPE3 was removed during a bitstream transfer. This error is only possible when the device to be managed is an UltraScale or UltraScale+ device.
    fetch_err,      -- There was an error fetching the bitstream from the configuration library.
    bs_fetch_err,   -- The ICAP returned an error code while loading the bitstream and there was an error fetching the bitstream from the configuration library.
    lost_fetch_err, -- Access to the ICAPE3 was removed during a bitstream transfer, and there was an error fetching the bitstream from the configuration library. This error is only possible when the device to be managed is an UltraScale or UltraScale+ device.
    bad_size_err,   -- A compressed bitstream ended at an invalid place in the decompression algorithm.
    bad_format_err, -- A compressed bitstream was received in the incorrect format.
    unassigned1,    -- Unassigned error
    unassigned2,    -- Unassigned error
    unassigned3,    -- Unassigned error
    unassigned4,    -- Unassigned error
    unassigned5,    -- Unassigned error
    unassigned6,    -- Unassigned error
    unknown_err     -- An unknown error occurred.
  );

  type state_reg_t is (
    empty,
    hw_shutdown,
    sw_shutdown,
    clearing_bs, -- Clearing bitstream for UltraScale- (not 7-series nor UltraScale+)
    loading,
    sw_startup,
    reset_rm,
    loaded
  );

  signal st_state    : state_reg_t; -- std_logic_vector(2 downto 0);
  signal st_error    : error_reg_t; -- std_logic_vector(3 downto 0);
  signal st_shutdown : std_logic;
  signal st_rm_id    : std_logic_vector(15 downto 0);

begin

  -- https://docs.amd.com/r/en-US/pg134-axi-hwicap/ICAP-Interface
  -- https://docs.amd.com/r/en-US/ug953-vivado-7series-libraries/ICAPE2
  -- C:\Xilinx\Vivado\2023.2\data\vhdl\src\unisims\primitive\ICAPE2.vhd
  icape2_i : unisim.VCOMPONENTS.ICAPE2
    generic map (
      DEVICE_ID         => x"03722093", -- bit_vector := X"03628093"; -- Specifies the fixed Device IDCODE value to be used for simulation purposes.
      ICAP_WIDTH        => "X32",       -- string     := "X32";       -- I & O data widths
      SIM_CFG_FILE_NAME => "NONE"       -- string     := "NONE"       -- Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model.
                                                                      -- Looks like 32-bit BIT vector per line.
    )
    port map (
      CLK   => clk,        -- in  std_ulogic;                              -- Clock input. Gated because this is bit bashed and just needs to be after
                                                                           -- the setup time.
      CSIB  => csib,       -- in  std_ulogic;                              -- Active-Low ICAP input enable.
      I     => icap_o,     -- in  std_logic_vector(31 downto 0);           -- Configuration data input bus.
      RDWRB => icap_rdwrb, -- in  std_ulogic;                              -- Read (Active-High) or Write (Active-Low) Select input.
      O     => icap_i      -- out std_logic_vector(31 downto 0);           -- Configuration data output bus. If no data is being read, contains current status.
    );

    ri <= reverse(icap_o(31 downto 24)) & reverse(icap_o(23 downto 16)) & reverse(icap_o(15 downto 8)) & reverse(icap_o(7 downto 0));

    -- synthesis translate_off
--    process(clk)
--      file fh    : text open write_mode is "bitstream.txt";
--      variable l : line;
--    begin
--      if rising_edge(clk) then
--        if csib = '0' and icap_rdwrb = '0' then
--          write(l, "RM" & to_string(ieee.numeric_std_unsigned.to_integer(rom_num)) & " 0x" & to_hstring(ri));
--          writeline(fh, l);
--        end if;
--      end if;
--    end process;
    -- synthesis translate_on

--  component dfx_controller
--    port (
--      clk                           : in  std_logic;
--      reset                         : in  std_logic;
--      icap_clk                      : in  std_logic;
--      icap_reset                    : in  std_logic;
--      icap_csib                     : out std_logic;
--      icap_rdwrb                    : out std_logic;
--      icap_i                        : in  std_logic_vector(31 downto 0);
--      icap_o                        : out std_logic_vector(31 downto 0);
--      m_axi_mem_araddr              : out std_logic_vector(31 downto 0);
--      m_axi_mem_arlen               : out std_logic_vector(7 downto 0);
--      m_axi_mem_arsize              : out std_logic_vector(2 downto 0);
--      m_axi_mem_arburst             : out std_logic_vector(1 downto 0);
--      m_axi_mem_arprot              : out std_logic_vector(2 downto 0);
--      m_axi_mem_arcache             : out std_logic_vector(3 downto 0);
--      m_axi_mem_aruser              : out std_logic_vector(3 downto 0);
--      m_axi_mem_arvalid             : out std_logic;
--      m_axi_mem_arready             : in  std_logic;
--      m_axi_mem_rdata               : in  std_logic_vector(31 downto 0);
--      m_axi_mem_rresp               : in  std_logic_vector(1 downto 0);
--      m_axi_mem_rlast               : in  std_logic;
--      m_axi_mem_rvalid              : in  std_logic;
--      m_axi_mem_rready              : out std_logic;
--      vsm_vs_0_hw_triggers          : in  std_logic_vector(1 downto 0);
--      vsm_vs_0_rm_shutdown_req      : out std_logic;
--      vsm_vs_0_rm_shutdown_ack      : in  std_logic;
--      vsm_vs_0_rm_decouple          : out std_logic;
--      vsm_vs_0_rm_reset             : out std_logic;
--      vsm_vs_0_event_error          : out std_logic;
--      vsm_vs_0_m_axis_status_tdata  : out std_logic_vector(31 downto 0);
--      vsm_vs_0_m_axis_status_tvalid : out std_logic
--    );
--  end component;


  -- https://docs.amd.com/v/u/en-US/pg374-dfx-controller
  dfx_controller_i : entity xil_defaultlib.dfx_controller
    port map (
      clk                           => clk,
      reset                         => reset, -- Asserted for at least 3 clock cycles
      icap_clk                      => clk,
      icap_reset                    => reset,
      icap_csib                     => csib,
      icap_rdwrb                    => icap_rdwrb,
      icap_i                        => icap_i,
      icap_o                        => icap_o,
      m_axi_mem_araddr              => m_axi_mem_araddr,
      m_axi_mem_arlen               => m_axi_mem_arlen,
      m_axi_mem_arsize              => m_axi_mem_arsize,
      m_axi_mem_arburst             => m_axi_mem_arburst,
      m_axi_mem_arprot              => m_axi_mem_arprot,
      m_axi_mem_arcache             => m_axi_mem_arcache,
      m_axi_mem_aruser              => m_axi_mem_aruser,
      m_axi_mem_arvalid             => m_axi_mem_arvalid,
      m_axi_mem_arready             => m_axi_mem_arready,
      m_axi_mem_rdata               => m_axi_mem_rdata,
      m_axi_mem_rresp               => m_axi_mem_rresp,
      m_axi_mem_rlast               => m_axi_mem_rlast,
      m_axi_mem_rvalid              => m_axi_mem_rvalid,
      m_axi_mem_rready              => m_axi_mem_rready,
      vsm_vs_0_hw_triggers          => vsm_vs_hw_triggers,
      vsm_vs_0_rm_shutdown_req      => vsm_vs_rm_shutdown_req,
      vsm_vs_0_rm_shutdown_ack      => vsm_vs_rm_shutdown_ack,
      vsm_vs_0_rm_decouple          => programming,
      vsm_vs_0_rm_reset             => reset_rp,
      vsm_vs_0_event_error          => vsm_vs_event_error,
      vsm_vs_0_m_axis_status_tdata  => vsm_vs_m_axis_status_tdata,
      vsm_vs_0_m_axis_status_tvalid => vsm_vs_m_axis_status_tvalid
    );

  -- Make the simulation easier to read.
  st_state    <= state_reg_t'val(ieee.numeric_std_unsigned.to_integer(vsm_vs_m_axis_status_tdata(2 downto 0)));
  st_error    <= error_reg_t'val(ieee.numeric_std_unsigned.to_integer(vsm_vs_m_axis_status_tdata(6 downto 3)));
  st_shutdown <= vsm_vs_m_axis_status_tdata(7);
  st_rm_id    <= vsm_vs_m_axis_status_tdata(23 downto 8);


--  component axi_bram
--    port (
--      s_axi_aclk    : in  std_logic;
--      s_axi_aresetn : in  std_logic;
--      s_axi_awaddr  : in  std_logic_vector(13 downto 0);
--      s_axi_awlen   : in  std_logic_vector(7 downto 0);
--      s_axi_awsize  : in  std_logic_vector(2 downto 0);
--      s_axi_awburst : in  std_logic_vector(1 downto 0);
--      s_axi_awlock  : in  std_logic;
--      s_axi_awcache : in  std_logic_vector(3 downto 0);
--      s_axi_awprot  : in  std_logic_vector(2 downto 0);
--      s_axi_awvalid : in  std_logic;
--      s_axi_awready : out std_logic;
--      s_axi_wdata   : in  std_logic_vector(31 downto 0);
--      s_axi_wstrb   : in  std_logic_vector(3 downto 0);
--      s_axi_wlast   : in  std_logic;
--      s_axi_wvalid  : in  std_logic;
--      s_axi_wready  : out std_logic;
--      s_axi_bresp   : out std_logic_vector(1 downto 0);
--      s_axi_bvalid  : out std_logic;
--      s_axi_bready  : in  std_logic;
--      s_axi_araddr  : in  std_logic_vector(13 downto 0);
--      s_axi_arlen   : in  std_logic_vector(7 downto 0);
--      s_axi_arsize  : in  std_logic_vector(2 downto 0);
--      s_axi_arburst : in  std_logic_vector(1 downto 0);
--      s_axi_arlock  : in  std_logic;
--      s_axi_arcache : in  std_logic_vector(3 downto 0);
--      s_axi_arprot  : in  std_logic_vector(2 downto 0);
--      s_axi_arvalid : in  std_logic;
--      s_axi_arready : out std_logic;
--      s_axi_rdata   : out std_logic_vector(31 downto 0);
--      s_axi_rresp   : out std_logic_vector(1 downto 0);
--      s_axi_rlast   : out std_logic;
--      s_axi_rvalid  : out std_logic;
--      s_axi_rready  : in  std_logic;
--      bram_rst_a    : out std_logic;
--      bram_clk_a    : out std_logic;
--      bram_en_a     : out std_logic;
--      bram_we_a     : out std_logic_vector(3 downto 0);
--      bram_addr_a   : out std_logic_vector(13 downto 0);
--      bram_wrdata_a : out std_logic_vector(31 downto 0);
--      bram_rddata_a : in  std_logic_vector(31 downto 0)
--    );
--  end component;


  axi_bram_i : entity xil_defaultlib.axi_bram
    port map (
      s_axi_aclk    => clk,
      s_axi_aresetn => not reset,
      s_axi_awaddr  => (others => '0'),
      s_axi_awlen   => (others => '0'),
      s_axi_awsize  => (others => '0'),
      s_axi_awburst => (others => '0'),
      s_axi_awlock  => '0',
      s_axi_awcache => (others => '0'),
      s_axi_awprot  => (others => '0'),
      s_axi_awvalid => '0',
      s_axi_awready => open,
      s_axi_wdata   => (others => '0'),
      s_axi_wstrb   => (others => '0'),
      s_axi_wlast   => '0',
      s_axi_wvalid  => '0',
      s_axi_wready  => open,
      s_axi_bresp   => open,
      s_axi_bvalid  => open,
      s_axi_bready  => '0',
      s_axi_araddr  => m_axi_mem_araddr(13 downto 0),
      s_axi_arlen   => m_axi_mem_arlen,
      s_axi_arsize  => m_axi_mem_arsize,
      s_axi_arburst => m_axi_mem_arburst,
      s_axi_arlock  => '0',
      s_axi_arcache => m_axi_mem_arcache,
      s_axi_arprot  => m_axi_mem_arprot,
      s_axi_arvalid => m_axi_mem_arvalid,
      s_axi_arready => m_axi_mem_arready,
      s_axi_rdata   => m_axi_mem_rdata,
      s_axi_rresp   => m_axi_mem_rresp,
      s_axi_rlast   => m_axi_mem_rlast,
      s_axi_rvalid  => m_axi_mem_rvalid,
      s_axi_rready  => m_axi_mem_rready,

      bram_rst_a    => open,
      bram_clk_a    => open, -- Do not use this due to delta delays on assignments
      bram_en_a     => rom_en,
      bram_we_a     => open,
      bram_addr_a   => rom_addr,
      bram_wrdata_a => open,
      bram_rddata_a => rom_data
    );

  -- XPM_MEMORY instantiation template for Single Port ROM configurations
  -- Refer to the targeted device family architecture libraries guide for XPM_MEMORY documentation
  -- =======================================================================================================================

  -- Parameter usage table, organized as follows:
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | Parameter name       | Data type          | Restrictions, if applicable                                             |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Description                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ADDR_WIDTH_A         | Integer            | Range: 1 - 20. Default value = 6.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify the width of the port A address port addra, in bits.                                                        |
  -- | Must be large enough to access the entire memory from port A, i.e. &gt;= $clog2(MEMORY_SIZE/READ_DATA_WIDTH_A).     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | AUTO_SLEEP_TIME      | Integer            | Range: 0 - 15. Default value = 0.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Must be set to 0                                                                                                    |
  -- | 0 - Disable auto-sleep feature                                                                                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | CASCADE_HEIGHT       | Integer            | Range: 0 - 64. Default value = 0.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | 0- No Cascade Height, Allow Vivado Synthesis to choose.                                                             |
  -- | 1 or more - Vivado Synthesis sets the specified value as Cascade Height.                                            |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ECC_BIT_RANGE        | String             | Default value = 7:0.                                                    |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | This parameter is only used by synthesis. Specify the ECC bit range on the provided data.                           |
  -- | "7:0" - it specifies lower 8 bits are ECC bits.                                                                     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ECC_MODE             | String             | Allowed values: no_ecc, both_encode_and_decode, decode_only, encode_only. Default value = no_ecc.|
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- |                                                                                                                     |
  -- |   "no_ecc" - Disables ECC                                                                                           |
  -- |   "encode_only" - Enables ECC Encoder only                                                                          |
  -- |   "decode_only" - Enables ECC Decoder only                                                                          |
  -- |   "both_encode_and_decode" - Enables both ECC Encoder and Decoder                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ECC_TYPE             | String             | Allowed values: none, ECCHSIAO32-7, ECCHSIAO64-8, ECCHSIAO128-9, ECCH32-7, ECCH64-8. Default value = none.|
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | This parameter is only used by synthesis. Specify the algorithm used to generate the ecc bits outside the XPM Memory.|
  -- | XPM Memory does not performs ECC operation with this parameter.                                                     |
  -- |                                                                                                                     |
  -- |   "none" - No ECC                                                                                                   |
  -- |   "ECCH32-7" - 32 bit ECC Hamming algorithm is used                                                                 |
  -- |   "ECCH64-8" - 64 bit ECC Hamming algorithm is used                                                                 |
  -- |   "ECCHSIAO32-7" - 32 bit ECC HSIAO algorithm is used                                                               |
  -- |   "ECCHSIAO64-8" - 64 bit ECC HSIAO algorithm is used                                                               |
  -- |   "ECCHSIAO128-9" - 128 bit ECC HSIAO algorithm is used                                                             |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | IGNORE_INIT_SYNTH    | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | 0 - Initiazation file if specified will applies for both simulation and synthesis                                   |
  -- | 1 - Initiazation file if specified will applies for only simulation and will ignore for synthesis                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MEMORY_INIT_FILE     | String             | Default value = none.                                                   |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file-|
  -- | Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").        |
  -- | File format must be ASCII and consist of only hexadecimal values organized into the specified depth by              |
  -- | narrowest data width generic value of the memory. Initialization of memory happens through the file name specified only when parameter|
  -- | MEMORY_INIT_PARAM value is equal to "".                                                                             |
  -- | When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.                |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MEMORY_INIT_PARAM    | String             | Default value = 0.                                                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string          |
  -- | containing the hex characters. Enter only hex characters with each location separated by delimiter (,).             |
  -- | Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by         |
  -- | narrowest data width generic value of the memory.For example, if the narrowest data width is 8, and the depth of    |
  -- | memory is 8 locations, then the parameter value should be passed as shown below.                                    |
  -- | parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"                                                               |
  -- | Where "AB" is the 0th location and "78" is the 7th location.                                                        |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MEMORY_OPTIMIZATION  | String             | Allowed values: true, false. Default value = true.                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify "true" to enable the optimization of unused memory or bits in the memory structure. Specify "false" to      |
  -- | disable the optimization of unused memory or bits in the memory structure.                                          |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MEMORY_PRIMITIVE     | String             | Allowed values: auto, block, distributed, ultra. Default value = auto.  |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Designate the memory primitive (resource type) to use-                                                              |
  -- | "auto"- Allow Vivado Synthesis to choose                                                                            |
  -- | "distributed"- Distributed memory                                                                                   |
  -- | "block"- Block memory                                                                                               |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MEMORY_SIZE          | Integer            | Range: 2 - 150994944. Default value = 2048.                             |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify the total memory array size, in bits.                                                                       |
  -- | For example, enter 65536 for a 2kx32 ROM.                                                                           |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | MESSAGE_CONTROL      | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify 1 to enable the dynamic message reporting such as collision warnings, and 0 to disable the message reporting|
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | RAM_DECOMP           | String             | Allowed values: auto, area, power. Default value = auto.                |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- |  Specifies the decomposition of the memory.                                                                         |
  -- |  "auto" - Synthesis selects default.                                                                                |
  -- |  "power" - Synthesis selects a strategy to reduce switching activity of RAMs and maps using widest configuration possible.|
  -- |  "area" - Synthesis selects a strategy to reduce RAM resource count.                                                |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | READ_DATA_WIDTH_A    | Integer            | Range: 1 - 4608. Default value = 32.                                    |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify the width of the port A read data output port douta, in bits.                                               |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | READ_LATENCY_A       | Integer            | Range: 0 - 100. Default value = 2.                                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify the number of register stages in the port A read data pipeline. Read data output to port douta takes this   |
  -- | number of clka cycles.                                                                                              |
  -- | To target block memory, a value of 1 or larger is required- 1 causes use of memory latch only; 2 causes use of      |
  -- | output register. To target distributed memory, a value of 0 or larger is required- 0 indicates combinatorial output.|
  -- | Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.                  |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | READ_RESET_VALUE_A   | String             | Default value = 0.                                                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify the reset value of the port A final output register stage in response to rsta input port is assertion.      |
  -- | For example, to reset the value of port douta to all 0s when READ_DATA_WIDTH_A is 32, specify 32HHHHh0.             |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | RST_MODE_A           | String             | Allowed values: SYNC, ASYNC. Default value = SYNC.                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Describes the behaviour of the reset                                                                                |
  -- |                                                                                                                     |
  -- |   "SYNC" - when reset is applied, synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A|
  -- |   "ASYNC" - when reset is applied, asynchronously resets output port douta to zero                                  |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | SIM_ASSERT_CHK       | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | 0- Disable simulation message reporting. Messages related to potential misuse will not be reported.                 |
  -- | 1- Enable simulation message reporting. Messages related to potential misuse will be reported.                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | USE_MEM_INIT         | Integer            | Range: 0 - 1. Default value = 1.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify 1 to enable the generation of below message and 0 to disable generation of the following message completely.|
  -- | "INFO - MEMORY_INIT_FILE and MEMORY_INIT_PARAM together specifies no memory initialization.                         |
  -- | Initial memory contents will be all 0s."                                                                            |
  -- | NOTE: This message gets generated only when there is no Memory Initialization specified either through file or      |
  -- | Parameter.                                                                                                          |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | USE_MEM_INIT_MMI     | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify 1 to expose this memory information to be written out in the MMI file.                                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | WAKEUP_TIME          | String             | Allowed values: disable_sleep, use_sleep_pin. Default value = disable_sleep.|
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specify "disable_sleep" to disable dynamic power saving option, and specify "use_sleep_pin" to enable the           |
  -- | dynamic power saving option                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+

  -- Port usage table, organized as follows:
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Description                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | addra          | Input     | ADDR_WIDTH_A                          | clka    | NA          | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Address for port A read operations.                                                                                 |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | clka           | Input     | 1                                     | NA      | Rising edge | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Clock signal for port A.                                                                                            |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | dbiterra       | Output    | 1                                     | clka    | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Leave open.                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | douta          | Output    | READ_DATA_WIDTH_A                     | clka    | NA          | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Data output for port A read operations.                                                                             |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ena            | Input     | 1                                     | clka    | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Memory enable signal for port A.                                                                                    |
  -- | Must be high on clock cycles when read operations are initiated. Pipelined internally.                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | injectdbiterra | Input     | 1                                     | clka    | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Do not change from the provided value.                                                                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | injectsbiterra | Input     | 1                                     | clka    | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Do not change from the provided value.                                                                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | regcea         | Input     | 1                                     | clka    | Active-high | Tie to 1'b1            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Do not change from the provided value.                                                                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rsta           | Input     | 1                                     | clka    | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Reset signal for the final port A output register stage.                                                            |
  -- | Synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A.                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | sbiterra       | Output    | 1                                     | clka    | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Leave open.                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | sleep          | Input     | 1                                     | NA      | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | sleep signal to enable the dynamic power saving feature.                                                            |
  -- +---------------------------------------------------------------------------------------------------------------------+

  rom_i : xpm_memory_sprom
    generic map (
      ADDR_WIDTH_A        => rom_addr_bits_c,         -- DECIMAL
      AUTO_SLEEP_TIME     => 0,                       -- DECIMAL
      CASCADE_HEIGHT      => 0,                       -- DECIMAL
      ECC_BIT_RANGE       => "7:0",                   -- String
      ECC_MODE            => "no_ecc",                -- String
      ECC_TYPE            => "none",                  -- String
      MEMORY_INIT_FILE    => mem_init_files_c,        -- String
      MEMORY_INIT_PARAM   => "",                      -- String
      MEMORY_OPTIMIZATION => "false",                 -- String
      MEMORY_PRIMITIVE    => "block",                 -- String
      MEMORY_SIZE         => (2**rom_addr_bits_c)*32, -- DECIMAL
      MESSAGE_CONTROL     => 0,                       -- DECIMAL
      RAM_DECOMP          => "auto",                  -- String
      READ_DATA_WIDTH_A   => rom_data'length,         -- DECIMAL
      READ_LATENCY_A      => rom_latency_c,           -- DECIMAL
      READ_RESET_VALUE_A  => "FFFFFFFF",              -- String, 0xFFFFFFFF
      RST_MODE_A          => "SYNC",                  -- String
      SIM_ASSERT_CHK      => 1,                       -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_MEM_INIT        => 1,                       -- DECIMAL
      USE_MEM_INIT_MMI    => 1,                       -- DECIMAL
      WAKEUP_TIME         => "disable_sleep"          -- String
    )
    port map (
      clka           => clk,                              -- 1-bit input: Clock signal for port A.
      rsta           => reset,                            -- 1-bit input: Reset signal for the final port A output register
                                                          -- stage. Synchronously resets output port douta to the value specified
                                                          -- by parameter READ_RESET_VALUE_A.
      ena            => rom_en,                           -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                                          -- cycles when read operations are initiated. Pipelined internally.
      regcea         => '1',                              -- 1-bit input: Do not change from the provided value.
      douta          => rom_data,                         -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      addra          => rom_addr(rom_addr'high downto 2), -- ADDR_WIDTH_A-bit input: Address for port A read operations.
      injectdbiterra => '0',                              -- 1-bit input: Do not change from the provided value.
      injectsbiterra => '0',                              -- 1-bit input: Do not change from the provided value.
      dbiterra       => open,                             -- 1-bit output: Leave open.
      sbiterra       => open,                             -- 1-bit output: Leave open.
      sleep          => '0'                               -- 1-bit input: sleep signal to enable the dynamic power saving feature.
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        vsm_vs_rm_shutdown_req_d <= '0';
        vsm_vs_rm_shutdown_ack   <= '0';
      else
        vsm_vs_rm_shutdown_req_d <= vsm_vs_rm_shutdown_req;
        vsm_vs_rm_shutdown_ack   <= vsm_vs_rm_shutdown_req and not vsm_vs_rm_shutdown_req_d;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        start_d    <= '0';
        triggers   <= "0000";
        triggers_d <= "0000";
        error      <= '0';
      else
        start_d <= start;

        if start = '1' and start_d = '0' then
          -- A trigger is a 0 -> 1 transition
          if triggers = "0000" then
            triggers <= "0001";
          else
            triggers <= triggers(2 downto 0) & triggers(3);
          end if;
        end if;
        triggers_d <= triggers;

        if vsm_vs_event_error = '1' then
          error <= '1';
        elsif start = '1' then
          error <= '0';
        end if;

      end if;
    end if;
  end process;

  -- Rising edge of pulse
  vsm_vs_hw_triggers <= triggers and not triggers_d;
  rom_num            <= onehot2bin(triggers);

end architecture;
