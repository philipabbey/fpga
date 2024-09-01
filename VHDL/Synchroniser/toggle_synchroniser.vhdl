-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- This code implements a synchroniser solution gleaned from a Doulos training video
-- on clock domain crossings available at
-- https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
--
-- P A Abbey, 31 August 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity toggle_synchroniser is
  generic(
    width_g : positive := 8;
    -- Synchroniser chain length
    len_g   : positive := 2
  );
  port(
    clk_wr   : in  std_logic;
    reset_wr : in  std_logic;
    clk_rd   : in  std_logic;
    reset_rd : in  std_logic;
    data_wr  : in  std_logic_vector(width_g-1 downto 0);
    wr_rdy   : out std_logic;
    wr_tgl   : in  std_logic;
    data_rd  : out std_logic_vector(width_g-1 downto 0) := (others => '0');
    rd_rdy   : out std_logic;
    rd_tgl   : in  std_logic
  );
end entity;


architecture rtl of toggle_synchroniser is

  -- The range is this way round in order to make the specification of constraints specific & easy.
  -- We will want to tell the synthesis tool about a false path of max delay constraint to
  -- *_tgl_sync[0]. If the range is reverse, we have to specify *_tgl_sync[*] as we can't pull out
  -- the highest index value in XDC.
  signal wr_tgl_sync : std_logic_vector(0 to len_g-1) := (others => '0');
  signal rd_tgl_sync : std_logic_vector(0 to len_g-1) := (others => '0');

  attribute ASYNC_REG : boolean;
  attribute ASYNC_REG of wr_tgl_sync : signal is true;
  attribute ASYNC_REG of rd_tgl_sync : signal is true;

begin

  process(clk_wr)
  begin
    if rising_edge(clk_wr) then
      wr_tgl_sync <= rd_tgl & wr_tgl_sync(0 to len_g-2);

      if reset_wr = '1' then
        wr_tgl_sync <= (others => '0');
      end if;
    end if;
  end process;

  wr_rdy <= wr_tgl xnor wr_tgl_sync(len_g-1);

  process(clk_rd)
  begin
    if rising_edge(clk_rd) then
      data_rd     <= data_wr;
      rd_tgl_sync <= wr_tgl & rd_tgl_sync(0 to len_g-2);

      if reset_rd = '1' then
        rd_tgl_sync <= (others => '0');
      end if;
    end if;
  end process;

  rd_rdy <= rd_tgl xor  rd_tgl_sync(len_g-1);

end architecture;
