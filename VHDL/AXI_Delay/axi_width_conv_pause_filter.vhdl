-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A data width converter with pause and filter mechanism for an AXI Data Stream.
--
-- P A Abbey, 25 February 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_width_conv_pause_filter is
  port(
    clk           : in  std_logic;
    s_axi_data    : in  std_logic_vector(15 downto 0);
    s_axi_byte_en : in  std_logic_vector(1 downto 0);
    s_axi_valid   : in  std_logic;
    s_axi_ready   : out std_logic                    := '0';
    enable        : in  std_logic;
    m_axi_data    : out std_logic_vector(7 downto 0) := (others => '0');
    m_axi_valid   : out std_logic                    := '0';
    m_axi_ready   : in  std_logic
  );
end entity;


architecture rtl of axi_width_conv_pause_filter is

  -- 's_axi_byte_en(1:0)'
  --
  -- | 1:0 | Actions
  -- +-----+--------------------------------------------------------
  -- | 0 0 | Emit an invalid data cycle
  -- | 0 1 | Emit low byte and move on to next input word
  -- | 1 0 | Emit high byte and move on to next input word
  -- | 1 1 | Emit low, then high byte and move on to next input word

  -- We're processing the first half of the input word and hence about to process the second half
  signal s_half : std_logic := '0';

begin

  s_axi_ready <= m_axi_ready and s_half when s_axi_byte_en = "11" else
                 m_axi_ready and enable;

  process(clk)
  begin
    if rising_edge(clk) then

      if m_axi_ready = '1' then
        case to_bitvector(s_axi_byte_en & s_half) is

          when "000" | "001" =>
            m_axi_valid <= '0';
            if m_axi_valid = '1' then
              s_half <= '0';
            end if;

          when "010" | "011" =>
            m_axi_data  <= s_axi_data(7 downto 0);
            m_axi_valid <= s_axi_valid and enable;
            if m_axi_valid = '1' then
              s_half <= '0';
            end if;

          when "100" | "101" =>
            m_axi_data  <= s_axi_data(15 downto 8);
            m_axi_valid <= (s_axi_valid or s_half) and enable;
            if m_axi_valid = '1' then
              s_half <= '0';
            end if;

          when "110" =>
            m_axi_data  <= s_axi_data(7 downto 0);
            m_axi_valid <= s_axi_valid and enable;
            if s_axi_valid = '1' and enable = '1' then
              s_half <= '1';
            end if;

          -- This is where we are about to process the second half of a word where both bytes are valid
          when "111" =>
            m_axi_data  <= s_axi_data(15 downto 8);
            m_axi_valid <= '1';
            -- 'enable' is omitted as we're pausing the input only, and finishing the output
            if m_axi_valid = '1' then
              s_half <= '0';
            end if;

        end case;
      end if;

    end if;
  end process;

end architecture;
