-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A pause mechanism for an AXI Data Stream.
--
-- Reference: Register ready signals in low latency, zero bubble pipeline
--            https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 2 March 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_edit is
  generic(
    data_width_g : positive
  );
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_rd    : in  std_logic                                 := '1';
    s_axi_ready : out std_logic                                 := '0';
    alt_data    : in  std_logic_vector(data_width_g-1 downto 0);
    alt_valid   : in  std_logic                                 := '0';
    m_axi_data  : out std_logic_vector(data_width_g-1 downto 0) := (others => '0');
    m_axi_valid : out std_logic                                 := '0';
    m_axi_wr    : in  std_logic                                 := '1';
    m_axi_ready : in  std_logic
  );
end entity;


architecture rtl of axi_edit is
begin

  with to_bitvector(s_axi_rd & m_axi_wr) select
    s_axi_ready <= '0'                            when "00", -- Pause
                   '0'                            when "01", -- Insert
                   '1'                            when "10", -- Drop
                   m_axi_ready or not m_axi_valid when "11"; -- Pass / Swap

  process(clk)
  begin
    if rising_edge(clk) then

      case to_bitvector(s_axi_rd & m_axi_wr) is

        when "00" => -- Pause
          if m_axi_ready = '1' or m_axi_valid = '0' then
            m_axi_valid <= '0';
          end if;

        when "01" => -- Insert, need alt_valid
          if m_axi_ready = '1' and alt_valid = '1' then
            m_axi_data  <= alt_data;
            m_axi_valid <= '1';
          end if;

        when "10" => -- Drop
            m_axi_valid <= '0';

        when "11" => -- Pass / Swap, dependent on alt_valid
          if m_axi_ready = '1' or m_axi_valid = '0' then
            if alt_valid = '1' then
              m_axi_data <= alt_data;
            else
              m_axi_data <= s_axi_data;
            end if;
            m_axi_valid <= s_axi_valid;
          end if;

      end case;

    end if;
  end process;

end architecture;
