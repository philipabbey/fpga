-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Simplifying the use of XPM RAM in Vivado 2022.1 (version is important).
--
-- P A Abbey, 14 July 2023
--
-- Reference: https://docs.xilinx.com/r/2022.1-English/ug953-vivado-7series-libraries/XPM_MEMORY_SDPRAM
--
-------------------------------------------------------------------------------------

-- Vivado TCL commands:
-- set_property generic {addr_bits_g=4 data_bits_g=8 primitive_g="block" read_latency_g=1} [current_fileset]
-- repeat_synth ; show_schematic [get_cells {ram_i/xpm_memory_base_inst/*}]

library ieee;
  use ieee.std_logic_1164.all;

-- Apply CASCADE_HEIGHT constraint via XDC if required.
--
entity dpram_2clk is
  generic (
    addr_bits_g    : positive := 8;
    data_bits_g    : positive := 8;
    primitive_g    : string   := "auto"; -- "auto", "block", "distributed", "mixed", "ultra"
    -- 0  Distributed RAM only, combinatorial output
    -- 1  Distributed RAM only, ena is used
    -- 2  ena & regceb used, simple delay
    -- 3+ ena & regceb used with enable pipeline
    read_latency_g : natural  := 1
  );
  port (
    sleep  : in  std_logic                                := '0'; -- Is this synchronous to clka or clkb?
    -- Port A
    clka   : in  std_logic;
    ena    : in  std_logic;
    wea    : in  std_logic;
    addra  : in  std_logic_vector(addr_bits_g-1 downto 0);
    dina   : in  std_logic_vector(data_bits_g-1 downto 0);
    -- Port B
    clkb   : in  std_logic;
    rstb   : in  std_logic;
    enb    : in  std_logic;
    addrb  : in  std_logic_vector(addr_bits_g-1 downto 0);
    doutb  : out std_logic_vector(data_bits_g-1 downto 0) := (others => '0');
    doutv  : out std_logic                                := '0'
  );
end entity;


library xpm;
  use xpm.vcomponents.all;

architecture rtl of dpram_2clk is

  constant memory_size_c : natural := (2**addr_bits_g) * data_bits_g;

  function wake_mode(primitive : string) return string is
  begin
    if primitive'length = 5 and (primitive(1 to 5) = "block" or primitive(1 to 5) = "ultra") then
      return "use_sleep_pin";
    else
      return "disable_sleep"; -- "distributed" | "mixed" | "auto"
    end if;
  end function;

  function write_mode(primitive : string) return string is
  begin
    -- # ** Error: [XPM_MEMORY 40-49] WRITE_MODE_B (2) specifies write-first or no-change mode , but Simple
    -- Dual port distributed RAM configurations must use read-first mode for port B.
    -- test_dpram.dut.ram_i.xpm_memory_base_inst.config_drc
    --
    if primitive'length = 5 and (primitive(1 to 5) = "block" or primitive(1 to 5) = "ultra") then
      return "no_change";  -- The default
    else
      return "read_first"; -- For anything that (might) contains distributed RAM.
    end if;
  end function;

  signal regceb : std_logic := '0';

begin

  assert primitive_g = "distributed" or read_latency_g >= 1
    report "read_latency_g can only be 0 for distributed RAM."
    severity failure;

  -- # ** Warning: MESSAGE_CONTROL (1) specifies simulation message reporting, but this release of XPM_MEMORY only reports
  --      messages for true dual port RAM and simple dual port RAM configurations which specify auto or block memory primitive types.
  ram_i : xpm_memory_sdpram
    generic map (
      MEMORY_SIZE             => memory_size_c,           -- Total memory size in bits
      MEMORY_PRIMITIVE        => primitive_g,             -- "auto", "block", "distributed", "mixed", "ultra"
      CLOCKING_MODE           => "independent_clock",     -- "common_clock", "independent_clock"
      ECC_MODE                => "no_ecc",                -- "no_ecc", "both_encode_and_decode", "decode_only", "encode_only"
      ECC_TYPE                => "none",                  -- Ignored
      ECC_BIT_RANGE           => "7:0",                   -- Ignored
      MEMORY_INIT_FILE        => "none",                  -- Ignored
      MEMORY_INIT_PARAM       => "0",
      USE_MEM_INIT            => 0,
      USE_MEM_INIT_MMI        => 0,
      WAKEUP_TIME             => wake_mode(primitive_g),  -- "disable_sleep", "use_sleep_pin"
      MESSAGE_CONTROL         => 0,                       -- Specify 1 to enable the dynamic message reporting such as collision
                                                          -- warnings, and 0 to disable the message reporting
      USE_EMBEDDED_CONSTRAINT => 0,                       -- Specify 1 to enable the set_false_path constraint addition between
                                                          -- clka of Distributed RAM and doutb_reg on clkb. For distributed RAMs with
                                                          -- two clocks.
      MEMORY_OPTIMIZATION     => "true",                  -- Specify "true" to enable the optimization of unused memory or bits in the
                                                          -- memory structure. Specify "false" to disable the optimization of unused
                                                          -- memory or bits in the memory structure
      CASCADE_HEIGHT          => 0,                       -- 0 - No Cascade Height, Allow Vivado Synthesis to choose.
                                                          -- 1 or more - Vivado Synthesis sets the specified value as Cascade Height.
      SIM_ASSERT_CHK          => 1,                       -- 0 - Disable simulation message reporting. Messages related to potential
                                                          -- misuse will not be reported. For BlockRAMs only.
                                                          -- 1 - Enable simulation message reporting. Messages related to potential
                                                          -- misuse will be reported.
      WRITE_DATA_WIDTH_A      => data_bits_g,
      BYTE_WRITE_WIDTH_A      => data_bits_g,             -- Silly option, keep same as WRITE_DATA_WIDTH_A
      ADDR_WIDTH_A            => addr_bits_g,
      RST_MODE_A              => "SYNC",                  -- "SYNC", "ASYNC"
      READ_DATA_WIDTH_B       => data_bits_g,
      ADDR_WIDTH_B            => addr_bits_g,
      READ_RESET_VALUE_B      => "0",                     -- Specify the reset value of the port B final output register stage in
                                                          -- response to rstb input port is assertion.
      READ_LATENCY_B          => read_latency_g,          -- To target block memory, a value of 1 or larger is required- 1 causes use
                                                          -- of memory latch only; 2 causes use of output register. To target
                                                          -- distributed memory, a value of 0 or larger is required- 0 indicates
                                                          -- combinatorial output.
                                                          -- Values larger than 2 synthesize additional flip-flops that are not
                                                          -- retimed into memory primitives.
      WRITE_MODE_B            => write_mode(primitive_g), -- "no_change", "read_first", "write_first"
      RST_MODE_B              => "SYNC"                   -- "SYNC", "ASYNC"
    )
    port map (
      clka           => clka,
      ena            => ena,
      wea            => (0 => wea),
      addra          => addra,
      dina           => dina,
      clkb           => clkb,
      rstb           => rstb,
      enb            => enb,
      regceb         => regceb,                           -- Clock Enable for the last register stage on the output data path.
      addrb          => addrb,
      doutb          => doutb,
      sleep          => sleep,                            -- Defaults to awake
      injectsbiterra => '0',                              -- Single bit error - Ignore these
      injectdbiterra => '0',                              -- Double bit error - Ignore these
      sbiterrb       => open,
      dbiterrb       => open
    );

  -- Create data_valid output
  latency_gen : if read_latency_g <= 1 generate

    -- Assigned but 'regceb' not actually used by 'xpm_memory_sdpram'
    regceb <= enb;

  elsif read_latency_g = 2 generate

    process(clkb)
    begin
      if rising_edge(clkb) then
        regceb <= enb;
      end if;
    end process;

  else generate -- read_latency_g >= 3
    signal enb_dly : std_logic_vector(read_latency_g-3 downto 0) := (others => '0');
  begin

    process(clkb)
    begin
      if rising_edge(clkb) then
        (regceb, enb_dly) <= enb_dly & enb;

        if rstb = '1' then
          enb_dly <= (others => '0');
        end if;
      end if;
    end process;

  end generate;


  dv_gen : if read_latency_g = 0 generate

    doutv <= enb;

  else generate -- read_latency_g >= 1

    process(clkb)
    begin
      if rising_edge(clkb) then
        if rstb = '1' then
          doutv <= '0';
        else
          doutv <= regceb;
        end if;
      end if;
    end process;

  end generate;

end architecture;
