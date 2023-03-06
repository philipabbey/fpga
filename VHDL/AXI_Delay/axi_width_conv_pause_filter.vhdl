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

  signal s_half    : std_logic := '0'; -- Second half of input data?
  signal s_half_wr : std_logic := '0'; -- Second half of output data?
  signal bytes_rd  : std_logic_vector(1 downto 0);

begin

  s_axi_ready <= m_axi_ready and s_half and enable when s_axi_byte_en = "11" else
                 m_axi_ready            and enable;

  process(clk)

    function case_test(
      be : std_logic_vector(1 downto 0);
      sh : std_logic
    ) return bit_vector is
    begin
      case to_bitvector(be & sh) is
        when "000" => return "00";
        when "010" => return "01";
        when "100" => return "10";
        when "110" => return "11";
        when "001" => return "00";
        when "011" => return "01";
        when "101" => return "10";
        when "111" => return "10"; -- This is where we process the second half of a word where both bytes are valid
      end case;
    end function;

  begin
    if rising_edge(clk) then
--      if m_axi_ready = '1' and enable = '1' then
--        if s_axi_valid = '1' and s_half = '0' then
--          s_half <= '1';
--        elsif s_half = '1' then
--          s_half <= '0';
--        end if;
--      end if;
--
--      if m_axi_ready = '1' and s_half = '0' then
--        m_axi_data  <= s_axi_data(7 downto 0);
--        m_axi_valid <= s_axi_valid and enable;
--      elsif (m_axi_ready = '1' or m_axi_valid = '0') and s_half = '1' then
--        m_axi_data  <= s_axi_data(15 downto 8);
--        m_axi_valid <= enable;
--      end if;

      if s_half = '1' then
        s_half_wr <= '1';
      elsif s_half_wr = '1' and m_axi_ready = '1' and m_axi_valid = '1' then
        s_half_wr <= '0';
      end if;

      if s_axi_ready = '1' and s_axi_valid = '1' then
        case to_bitvector(s_axi_byte_en) is
          when "00" => bytes_rd <= "00";
          when "01" => bytes_rd <= "10";
          when "10" => bytes_rd <= "10";
          when "11" => bytes_rd <= "11";
        end case;
      end if;

      if m_axi_ready = '1' and m_axi_valid = '1' then
        -- Shift to read 2nd byte
        bytes_rd <= bytes_rd(0) & '0';
      end if;

      case case_test(s_axi_byte_en, s_half) is

        when "00" =>
          m_axi_valid <= '0';
          s_half      <= '0';

        when "01" =>
          if m_axi_ready = '1' then
            m_axi_data  <= s_axi_data(7 downto 0);
            m_axi_valid <= s_axi_valid and enable;
            if m_axi_valid = '1' and m_axi_ready = '1' then
              s_half <= '0';
            end if;
          end if;

        when "10" =>
          if m_axi_ready = '1' then
            m_axi_data  <= s_axi_data(15 downto 8);
            m_axi_valid <= (s_axi_valid or s_half) and enable;
            if m_axi_valid = '1' and m_axi_ready = '1' then
              s_half <= '0';
            end if;
          end if;

        when "11" =>
          if m_axi_ready = '1' then
            m_axi_data  <= s_axi_data(7 downto 0);
            m_axi_valid <= s_axi_valid and enable;
            if s_axi_valid = '1' and enable = '1' then
              s_half <= '1';
            end if;
          end if;

      end case;

--      if s_axi_valid = '1' then
--      end if;

    end if;
  end process;

end architecture;
