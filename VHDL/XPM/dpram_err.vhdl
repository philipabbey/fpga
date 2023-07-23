-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Simplifying the use of XPM RAM with error injection in Vivado 2022.1 (version is important).
--
-- P A Abbey, 16 July 2023
--
-- References:
--  * https://docs.xilinx.com/r/2022.1-English/ug953-vivado-7series-libraries/XPM_MEMORY_SDPRAM
--  * Single Error Correction and Double Error Detection, https://docs.xilinx.com/v/u/en-US/xapp645
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity dpram_err is
  generic (
    addr_bits_g : positive := 9;
    data_bits_g : positive := 64 -- Must be a multiple of 64 for error correction due to the use of a (72, 64) Hamming EEC
  );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    -- Port A
    ena            : in  std_logic;
    wea            : in  std_logic;
    addra          : in  std_logic_vector(addr_bits_g-1 downto 0);
    dina           : in  std_logic_vector(data_bits_g-1 downto 0);
    injectsbiterra : in  std_logic;
    injectdbiterra : in  std_logic;
    -- Port B
    enb            : in  std_logic;
    addrb          : in  std_logic_vector(addr_bits_g-1 downto 0);
    doutb          : out std_logic_vector(data_bits_g-1 downto 0) := (others => '0');
    doutv          : out std_logic                                := '0';
    sbiterrb       : out std_logic;
    dbiterrb       : out std_logic
  );
end entity;


library xpm;
  use xpm.vcomponents.all;

-- Two architectures, one each for LUTRAM and BlockRAM?
-- Better than a generic as it simplifies each implementation
-- Could add yet another level of hierarchy to add the generic to generate the appropriate
-- instantiation if desired.
--
-- Cascade option is a generic on just the BlockRAM implementation?
-- Suggests two entities with different generics. Wanting to get away from the all purpose
-- single instance that must have generics set correctly per memory type. Separate and
-- provide correctness.
--
architecture rtl of dpram_err is

  constant memory_size_c : natural := (2**addr_bits_g) * data_bits_g;
  constant latency_c     : natural := 2;

  signal regceb : std_logic := '0';

begin

  ram_i : xpm_memory_sdpram
    generic map (
      MEMORY_SIZE             => memory_size_c,            -- Total memory size in bits
      MEMORY_PRIMITIVE        => "block",                  -- "auto", "block", "distributed", "mixed", "ultra"
      CLOCKING_MODE           => "common_clock",           -- "common_clock", "independent_clock"
      ECC_MODE                => "both_encode_and_decode", -- "no_ecc", "both_encode_and_decode", "decode_only", "encode_only"
      ECC_TYPE                => "ECCH64-8",               -- Ignored until synthesis, this is not defined until the 2023.1 version of the XPM
      ECC_BIT_RANGE           => "7:0",                    -- Ignored until synthesis, this is not defined until the 2023.1 version of the XPM
                                                           -- and "7:0" specifies lower 8 bits are ECC bits.
      MEMORY_INIT_FILE        => "none",                   -- Ignored
      MEMORY_INIT_PARAM       => "0",
      USE_MEM_INIT            => 0,
      USE_MEM_INIT_MMI        => 0,
      WAKEUP_TIME             => "disable_sleep",
      MESSAGE_CONTROL         => 0,                        -- Specify 1 to enable the dynamic message reporting such as collision
                                                           -- warnings, and 0 to disable the message reporting
      USE_EMBEDDED_CONSTRAINT => 0,                        -- Specify 1 to enable the set_false_path constraint addition between
                                                           -- clka of Distributed RAM and doutb_reg on clkb. For distributed RAMs with
                                                           -- two clocks.
      MEMORY_OPTIMIZATION     => "true",                   -- Specify "true" to enable the optimization of unused memory or bits in the
                                                           -- memory structure. Specify "false" to disable the optimization of unused
                                                           -- memory or bits in the memory structure
      CASCADE_HEIGHT          => 0,                        -- 0 - No Cascade Height, Allow Vivado Synthesis to choose.
                                                           -- 1 or more - Vivado Synthesis sets the specified value as Cascade Height.
      SIM_ASSERT_CHK          => 1,                        -- 0 - Disable simulation message reporting. Messages related to potential
                                                           -- misuse will not be reported. For BlockRAMs only.
                                                           -- 1 - Enable simulation message reporting. Messages related to potential
                                                           -- misuse will be reported.
      WRITE_DATA_WIDTH_A      => data_bits_g,
      BYTE_WRITE_WIDTH_A      => data_bits_g,              -- Silly option, keep same as WRITE_DATA_WIDTH_A
      ADDR_WIDTH_A            => addr_bits_g,
      RST_MODE_A              => "SYNC",                   -- "SYNC", "ASYNC"
      READ_DATA_WIDTH_B       => data_bits_g,
      ADDR_WIDTH_B            => addr_bits_g,
      READ_RESET_VALUE_B      => "0",                      -- Specify the reset value of the port B final output register stage in
                                                           -- response to rstb input port is assertion.
      READ_LATENCY_B          => latency_c,                -- To target block memory, a value of 1 or larger is required- 1 causes use
                                                           -- of memory latch only; 2 causes use of output register. To target
                                                           -- distributed memory, a value of 0 or larger is required- 0 indicates
                                                           -- combinatorial output.
                                                           -- Values larger than 2 synthesize additional flip-flops that are not
                                                           -- retimed into memory primitives.
      WRITE_MODE_B            => "no_change",              -- "no_change", "read_first", "write_first"
      RST_MODE_B              => "SYNC"                    -- "SYNC", "ASYNC"
    )
    port map (
      clka           => clk,
      ena            => ena,
      wea            => (0 => wea),
      addra          => addra,
      dina           => dina,
      injectsbiterra => injectsbiterra,                    -- Single bit error
      injectdbiterra => injectdbiterra,                    -- Double bit error
      clkb           => clk,
      rstb           => reset,
      enb            => enb,
      regceb         => regceb,                            -- Clock Enable for the last register stage on the output data path.
      addrb          => addrb,
      doutb          => doutb,
      sleep          => '0',                               -- Never sleep
      sbiterrb       => sbiterrb,
      dbiterrb       => dbiterrb
    );

  -- Create data_valid output
  latency_gen : if latency_c <= 1 generate

    -- Assigned but 'regceb' not actually used by 'xpm_memory_sdpram'
    regceb <= enb;

  elsif latency_c = 2 generate

    process(clk)
    begin
      if rising_edge(clk) then
        regceb <= enb;
      end if;
    end process;

  else generate -- latency_c >= 3
    -- ** Warning: A:\Philip\Work\VHDL\Public\VHDL\XPM/dpram_err.vhdl(150): (vcom-1246) Range -1 downto 0 is null.
    signal enb_dly : std_logic_vector(latency_c-3 downto 0) := (others => '0');
  begin

    process(clk)
    begin
      if rising_edge(clk) then
        (regceb, enb_dly) <= enb_dly & enb;

        if reset = '1' then
          enb_dly <= (others => '0');
        end if;
      end if;
    end process;

  end generate;


  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        doutv <= '0';
      else
        doutv <= regceb;
      end if;
    end if;
  end process;

end architecture;
