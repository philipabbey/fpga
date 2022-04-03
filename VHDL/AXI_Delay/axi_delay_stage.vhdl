-------------------------------------------------------------------------------------
--
-- Distributed under Mozilla Public License, v. 2.0
--
-- The source code here is effectively a copy from a 3rd party listed below. The
-- originating VHDL source code is not explicitly marked with a license, but related
-- code is. Therefore I am assuming the original author requires their source code to
-- be distributed under the terms of the Mozilla Public License, v. 2.0. You can
-- obtain a copy of this license at http://mozilla.org/MPL/2.0/.
--
-- Original Author: Tom Jackson, 28 October 2019
--
-------------------------------------------------------------------------------------
--
-- A single stage of AXI delay in two implementations, non-pipelined and pipelined.
--
-- References:
--  * Code provided by https://github.com/tom-jackson-itdev/pipe/
--  * Explanation here: https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 26 March 2022
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity axi_delay_stage is
  generic(
    data_width_g : positive
  );
  port(
    clk      : in  std_logic;

    -- Upstream interface
    us_valid : in  std_logic;
    us_data  : in  std_logic_vector(data_width_g-1 downto 0);
    us_ready : out std_logic := '0';

    -- Downstream interface
    ds_valid : out std_logic := '0';
    ds_data  : out std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    ds_ready : in  std_logic
  );
end entity;


architecture rtl_basic of axi_delay_stage is
begin

  process(clk) is
  begin
    if rising_edge(clk) then

      -- Accept data if ready is high
      if us_ready = '1' then
        ds_valid <= us_valid;
        ds_data  <= us_data;
      end if;

    end if;
  end process;

  -- Ready signal with registered ready or primary data register is not valid
  us_ready <= ds_ready or not ds_valid;

end architecture;


architecture rtl_pipe of axi_delay_stage is

  -- Expansion registers
  signal expansion_data_reg  : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal expansion_valid_reg : std_logic := '0';

  -- Standard registers
  signal primary_data_reg    : std_logic_vector(data_width_g-1 downto 0) := (others => '0');
  signal primary_valid_reg   : std_logic := '0';

begin

  process(clk) is
  begin
    if rising_edge(clk) then

      -- Accept data if ready is high
      if us_ready = '1' then
        primary_valid_reg <= us_valid;
        primary_data_reg  <= us_data;
        -- when ds is not ready, accept data into expansion reg until it is valid
        if ds_ready = '0' then
          expansion_valid_reg <= primary_valid_reg;
          expansion_data_reg  <= primary_data_reg;
        end if;
      end if;

      -- When ds becomes ready the expansion reg data is accepted and we must clear the valid register
      if ds_ready = '1' then
        expansion_valid_reg <= '0';
      end if;

    end if;
  end process;

  -- Ready as long as there is nothing in the expansion register
  us_ready <= not expansion_valid_reg;

  -- Selecting the expansion register if it has valid data
  ds_valid <= expansion_valid_reg or primary_valid_reg;
  ds_data  <= expansion_data_reg when expansion_valid_reg else primary_data_reg;

end architecture;
