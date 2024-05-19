-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- AXI delay register with the first stage being an XPM RAM, using the second stage
-- output registers as a second stage of AXI delay.
--
-- Reference: ???
--            https://www.itdev.co.uk/blog/
--
-- P A Abbey, 16 May 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_delay_ram is
    generic (
        ram_addr_width_g : positive := 8;
        ram_data_width_g : positive := 16
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;
        run          : in  std_logic;
        -- Port A to load and verify the RAM
        ram_addr     : in  std_logic_vector(ram_addr_width_g-1 downto 0);
        ram_wr_data  : in  std_logic_vector(ram_data_width_g-1 downto 0);
        ram_wr_en    : in  std_logic;
        ram_rd_en    : in  std_logic;
        ram_rd_data  : out std_logic_vector(ram_data_width_g-1 downto 0) := (others => '0');
        ram_rd_valid : out std_logic                                     := '0';
        -- Sequentially extracting data from the RAM
        item_tdata   : out std_logic_vector(ram_data_width_g-1 downto 0) := (others => '0');
        item_tvalid  : out std_logic                                     := '0';
        item_tready  : in  std_logic -- Might need to reconsider naming convention, this is the external tready
    );
end entity;


library ieee;
  use ieee.numeric_std_unsigned.all;
library xpm;
  use xpm.vcomponents.all;

architecture rtl of axi_delay_ram is

    -- RAM Pipeline
    signal item_next_addr  : natural range 0 to (2**ram_addr_width_g)-1    := 0;
    signal ram_rd_valid_i  : std_logic                                     := '0';
    signal ram_int_dv      : std_logic                                     := '0'; -- RAM internal register stage
    signal ram_int_rdy     : std_logic                                     := '0'; -- RAM internal register stage
    signal item_next_data  : std_logic_vector(ram_data_width_g-1 downto 0) := (others => '0');
    signal item_next_valid : std_logic                                     := '0';
    signal item_next_rdy   : std_logic                                     := '0';
    signal item_tready_i   : std_logic                                     := '0'; -- item_first/last ready

begin

    -- Pre-fetch the next item from the RAM.
    -- This sets up some pipeline logic that behaves very similar to AXI-Stream
    --
    process(clk)
    begin
        if rising_edge(clk) then
            -- RAM Port A
            ram_rd_valid_i <= ram_rd_en;
            ram_rd_valid   <= ram_rd_valid_i;

            -- RAM Port B
            -- First stage: BlockRAM pure delay single cycle lookup
            if ram_int_rdy = '1' and run = '1' then
                ram_int_dv <= '1';
                if item_next_addr = (2**ram_addr_width_g)-1 then
                    item_next_addr <= 0;
                else
                    item_next_addr <= item_next_addr + 1;
                end if;
            elsif item_next_rdy = '1' then
                ram_int_dv <= '0';
            end if;

            -- Second stage: BlockRAM registered outputs
            if item_next_rdy = '1' then
                item_next_valid <= ram_int_dv;
            end if;

            -- Third stage: first/last in use
            if item_tready_i = '1' then
                item_tdata  <= item_next_data;
                item_tvalid <= item_next_valid;
            end if;

            if reset = '1' then
                ram_rd_valid_i  <= '0';
                ram_rd_valid    <= '0';
                item_next_addr  <= 0;
                ram_int_dv      <= '0';
                item_next_valid <= '0';
                item_tvalid     <= '0';
            end if;
        end if;
    end process;

    -- First stage: BlockRAM pure delay single cycle lookup
    ram_int_rdy   <= item_next_rdy or not ram_int_dv;
    -- Second stage: BlockRAM registered outputs
    item_next_rdy <= item_tready_i or not item_next_valid;
    -- Third stage: first/last in use
    item_tready_i <= item_tready or not item_tvalid;


    ram_i : XPM_MEMORY_TDPRAM
        generic map (
            ADDR_WIDTH_A            => ram_addr_width_g,                       -- DECIMAL
            ADDR_WIDTH_B            => ram_addr_width_g,                       -- DECIMAL
            AUTO_SLEEP_TIME         => 0,                                      -- DECIMAL, number of clk[a|b] cycles to auto-sleep
            BYTE_WRITE_WIDTH_A      => ram_data_width_g,                       -- DECIMAL, To enable byte-wide writes on port A, specify the byte width
            BYTE_WRITE_WIDTH_B      => ram_data_width_g,                       -- DECIMAL, To enable byte-wide writes on port B, specify the byte width
            CASCADE_HEIGHT          => 0,                                      -- DECIMAL, 0  - No Cascade Height, Allow Vivado Synthesis to choose.
                                                                               --          1+ - Vivado Synthesis sets the specified value as Cascade Height.
            CLOCKING_MODE           => "common_clock",                         -- String, "common_clock", "independent_clock"
            ECC_MODE                => "no_ecc",                               -- String, "no_ecc", "both_encode_and_decode", "decode_only", "encode_only"
            MEMORY_INIT_FILE        => "none",                                 -- String
            MEMORY_INIT_PARAM       => "0",                                    -- String
            MEMORY_OPTIMIZATION     => "true",                                 -- String
            MEMORY_PRIMITIVE        => "auto",                                 -- String, "auto", "block", "distributed", "ultra"
            MEMORY_SIZE             => (2**ram_addr_width_g)*ram_data_width_g, -- DECIMAL, specify the total memory array size, in bits.
            MESSAGE_CONTROL         => 0,                                      -- DECIMAL, Specify 1 to enable the dynamic message reporting such as
                                                                               -- collision warnings, and 0 to disable the message reporting
            READ_DATA_WIDTH_A       => ram_data_width_g,                       -- DECIMAL
            READ_DATA_WIDTH_B       => ram_data_width_g,                       -- DECIMAL
            READ_LATENCY_A          => 2,                                      -- DECIMAL, read data output to port douta takes this number of clka cycles.
                                                                               -- BlockRAM           1+: 1 causes use of memory latch only;
                                                                               --                        2 causes use of output register.
                                                                               -- Distributed memory 0+: 0 uses combinatorial output.
                                                                               --                        2+ synthesize additional flip-flops that are not retimed into memory primitives.
            READ_LATENCY_B          => 2,                                      -- DECIMAL, as above on clkb
            READ_RESET_VALUE_A      => "0",                                    -- String
            READ_RESET_VALUE_B      => "0",                                    -- String
            RST_MODE_A              => "SYNC",                                 -- String, "SYNC", "ASYNC"
            RST_MODE_B              => "SYNC",                                 -- String, "SYNC", "ASYNC"
            SIM_ASSERT_CHK          => 0,                                      -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
            USE_EMBEDDED_CONSTRAINT => 0,                                      -- DECIMAL, needed for the independent clock distributed RAM based memory
                                                                               -- if the design takes care of avoiding address collision, see
                                                                               -- https://docs.amd.com/r/en-US/ug974-vivado-ultrascale-libraries/XPM_MEMORY_SDPRAM
            USE_MEM_INIT            => 1,                                      -- DECIMAL
            USE_MEM_INIT_MMI        => 0,                                      -- DECIMAL, Specify 1 to expose this memory information to be written out
                                                                               -- in the MMI file.
            WAKEUP_TIME             => "disable_sleep",                        -- String, "disable_sleep", "use_sleep_pin"
            WRITE_DATA_WIDTH_A      => ram_data_width_g,                       -- DECIMAL
            WRITE_DATA_WIDTH_B      => ram_data_width_g,                       -- DECIMAL
            WRITE_MODE_A            => "read_first",                           -- String, "read_first", "no_change", "write_first"
            WRITE_MODE_B            => "read_first",                           -- String, "read_first", "no_change", "write_first"
            WRITE_PROTECT           => 1                                       -- DECIMAL, means write is protected through enable and write enable and
                                                                               -- hence the LUT is placed before the memory. This is the default behaviour
                                                                               -- to access memory.
        )
        port map (
            clka           => clk,                                      -- 1-bit input: Clock signal for port A. Also clocks port B when
                                                                        -- parameter CLOCKING_MODE is "common_clock".
            rsta           => reset,                                    -- 1-bit input: Reset signal for the final port A output register
                                                                        -- stage. Synchronously resets output port douta to the value specified
                                                                        -- by parameter READ_RESET_VALUE_A.
            addra          => ram_addr,                                 -- ADDR_WIDTH_A-bit input: Address for port A write operations.
            dina           => ram_wr_data,                              -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
            douta          => ram_rd_data,                              -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
            ena            => ram_rd_en or ram_wr_en,                   -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                                                        -- cycles when write operations are initiated. Pipelined internally.
            wea            => (0 => ram_wr_en),                         -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                                                        -- for port A input data port dina. 1 bit wide when word-wide writes
                                                                        -- are used. In byte-wide write configurations, each bit controls the
                                                                        -- writing one byte of dina to address addra. For example, to
                                                                        -- synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                                                        -- is 32, wea would be 4'b0010.
            regcea         => '1',                                      -- 1-bit input: Clock Enable for the last register stage on the output
                                                                        -- data path.
            clkb           => clk,                                      -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                                                        -- "independent_clock". Unused when parameter CLOCKING_MODE is
                                                                        -- "common_clock".
            rstb           => reset,                                    -- 1-bit input: Reset signal for the final port B output register
                                                                        -- stage. Synchronously resets output port doutb to the value specified
                                                                        -- by parameter READ_RESET_VALUE_B.
            addrb          => to_slv(item_next_addr, ram_addr_width_g), -- ADDR_WIDTH_B-bit input: Address for port B read operations.
            dinb           => (others => '0'),                          -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
            doutb          => item_next_data,                           -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
            enb            => ram_int_rdy,                              -- 1-bit input: Memory enable signal for port B. Must be high on clock
                                                                        -- cycles when read operations are initiated. Pipelined internally.
            web            => "0",                                      -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                                                        -- for port B input data port dinb. 1 bit wide when word-wide writes
                                                                        -- are used. In byte-wide write configurations, each bit controls the
                                                                        -- writing one byte of dinb to address addrb. For example, to
                                                                        -- synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
            regceb         => item_next_rdy,                            -- 1-bit input: Clock Enable for the last register stage on the output
                                                                        -- data path.
            sleep          => '0',                                      -- 1-bit input: sleep signal to enable the dynamic power saving feature.
            injectdbiterra => '0',                                      -- 1-bit input: Controls double bit error injection on input data when
                                                                        -- ECC enabled (Error injection capability is not available in
                                                                        -- "decode_only" mode).
            injectsbiterra => '0',                                      -- 1-bit input: Controls single bit error injection on input data when
                                                                        -- ECC enabled (Error injection capability is not available in
                                                                        -- "decode_only" mode).
            injectdbiterrb => '0',                                      -- 1-bit input: Controls double bit error injection on input data when
                                                                        -- ECC enabled (Error injection capability is not available in
                                                                        -- "decode_only" mode).
            injectsbiterrb => '0',                                      -- 1-bit input: Controls single bit error injection on input data when
                                                                        -- ECC enabled (Error injection capability is not available in
                                                                        -- "decode_only" mode).
            sbiterra       => open,                                     -- 1-bit output: Status signal to indicate single bit error occurrence
                                                                        -- on the data output of port A.
            dbiterra       => open,                                     -- 1-bit output: Status signal to indicate double bit error occurrence
                                                                        -- on the data output of port A.
            sbiterrb       => open,                                     -- 1-bit output: Status signal to indicate single bit error occurrence
                                                                        -- on the data output of port B.
            dbiterrb       => open                                      -- 1-bit output: Status signal to indicate double bit error occurrence
                                                                        -- on the data output of port B.
        );

end architecture;
