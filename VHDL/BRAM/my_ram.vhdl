-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Originally generated from a Xilinx RAM template, but amended in several ways:
--  1) Function 'clogb2' has been removed as it is neater to avoid needing it in the
--     first place by specifying the address width.
--  2) RAM initialisation has been stripped out.
--  3) The generate statement used for the output register has been made VHDL-2008
--     using an 'else generate' clause.
--
-- Note:
-- -----
--
-- (vcom-1236) Shared variables must be of a protected type.
-- [Synth 8-4747] shared variables must be of a protected type
--
-- The shared variable usage cannot be replace by a protected type as Vivado
-- complains during synthesis.
--
-- [Synth 8-6750] Unsupported VHDL type protected. This is not suited for Synthesis
--
-- Therefore this aspect of the VHDL code cannot be updated to VHDL-2008.
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity my_ram is
    generic (
        -- Note: If the chosen data and address width values are low, Synthesis will infer Distributed RAM.
        ram_width_g       : integer := 36;                     -- Specify RAM data width
        ram_addr_g        : integer := 10;                     -- Specify RAM address width (number of entries = 2**ram_addr_g)
        output_register_g : boolean := true                    -- True for higher clock speed or false for lower latency
    );
    port (
        addra  : in  std_logic_vector(ram_addr_g-1 downto 0);  -- Port A Address bus, width determined from RAM_DEPTH
        addrb  : in  std_logic_vector(ram_addr_g-1 downto 0);  -- Port B Address bus, width determined from RAM_DEPTH
        dina   : in  std_logic_vector(ram_width_g-1 downto 0); -- Port A RAM input data
        dinb   : in  std_logic_vector(ram_width_g-1 downto 0); -- Port B RAM input data
        clka   : in  std_logic;                                -- Port A Clock
        clkb   : in  std_logic;                                -- Port B Clock
        wea    : in  std_logic;                                -- Port A Write enable
        web    : in  std_logic;                                -- Port B Write enable
        ena    : in  std_logic;                                -- Port A RAM Enable, for additional power savings, disable port when not in use
        enb    : in  std_logic;                                -- Port B RAM Enable, for additional power savings, disable port when not in use
        rsta   : in  std_logic;                                -- Port A Output reset (does not affect memory contents)
        rstb   : in  std_logic;                                -- Port B Output reset (does not affect memory contents)
        regcea : in  std_logic;                                -- Port A Output register enable
        regceb : in  std_logic;                                -- Port B Output register enable
        douta  : out std_logic_vector(ram_width_g-1 downto 0); -- Port A RAM output data
        doutb  : out std_logic_vector(ram_width_g-1 downto 0)  -- Port B RAM output data
    );
end entity;


library ieee;
use ieee.numeric_std.all;

architecture inferred of my_ram is

    --  Xilinx True Dual Port RAM No Change Dual Clock
    --  This code implements a parameterizable true dual port memory (both ports can read and write).
    --  This is a no change RAM which retains the last read value on the output during writes
    --  which is the most power efficient mode.
    --  If a reset or enable is not necessary, it may be tied off or removed from the code.

    signal ram_data_a : std_logic_vector(ram_width_g-1 downto 0);
    signal ram_data_b : std_logic_vector(ram_width_g-1 downto 0);

    -- 2D Array Declaration for RAM
    type ram_type is array((2**ram_addr_g)-1 downto 0) of std_logic_vector(ram_width_g-1 downto 0);
    -- Define RAM - Do not use VHDL Protected types for synthesis!
    -- ERROR: [Synth 8-6750] Unsupported VHDL type protected. This is not suited for Synthesis [.../VHDL/BRAM/inferred_ram.vhdl:xx]
    -- WARNING: [Synth 8-4747] shared variables must be of a protected type [.../VHDL/BRAM/inferred_ram.vhdl:xx]
    shared variable ram : ram_type := (others => (others => '0'));

begin

    process(clka)
    begin
        if rising_edge(clka) then
            if ena = '1' then
                if wea = '1' then
                    ram(to_integer(unsigned(addra))) := dina;
                else
                    ram_data_a <= ram(to_integer(unsigned(addra)));
              end if;
          end if;
      end if;
    end process;

    process(clkb)
    begin
        if rising_edge(clkb) then
            if enb = '1' then
                if web = '1' then
                    ram(to_integer(unsigned(addrb))) := dinb;
                else
                    ram_data_b <= ram(to_integer(unsigned(addrb)));
                end if;
            end if;
        end if;
    end process;

    output_register : if output_register_g generate
        --  Following code generates HIGH_PERFORMANCE (use output register)
        --  Following is a 2 clock cycle read latency with improved clock-to-out timing
        process(clka)
        begin
            if rising_edge(clka) then
                if rsta = '1' then
                    douta <= (others => '0');
                elsif regcea = '1' then
                    douta <= ram_data_a;
                end if;
            end if;
        end process;

        process(clkb)
        begin
            if rising_edge(clkb) then
                if rstb = '1' then
                    doutb <= (others => '0');
                elsif regceb = '1' then
                    doutb <= ram_data_b;
                end if;
            end if;
        end process;
    else generate
        --  Following code generates LOW_LATENCY (no output register)
        --  Following is a 1 clock cycle read latency at the cost of a longer clock-to-out timing
        douta <= ram_data_a;
        doutb <= ram_data_b;
    end generate;

end architecture;
