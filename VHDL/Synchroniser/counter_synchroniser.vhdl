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

entity counter_synchroniser is
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
    cnt_wr   : in  std_logic_vector(width_g-1 downto 0);
    cnt_rd   : out std_logic_vector(width_g-1 downto 0) := (others => '0')
  );
end entity;


architecture rtl of counter_synchroniser is

  type sync_arr_t is array(0 to len_g-1) of std_logic_vector(width_g-1 downto 0);

  signal gray : std_logic_vector(width_g-1 downto 0) := (others => '0');

  -- The range is this way round in order to make the specification of constraints specific & easy.
  -- We will want to tell the synthesis tool about a false path of max delay constraint to
  -- *_tgl_sync[0]. If the range is reverse, we have to specify *_tgl_sync[*] as we can't pull out
  -- the highest index value in XDC.
  signal gray_sync : sync_arr_t := (others => (others => '0'));

  attribute ASYNC_REG : boolean;
  attribute ASYNC_REG of gray_sync : signal is true;

begin

  -- N.B. The Doulos video has a mistake, need shift right not rotate right (ror).
  -- See https://en.wikipedia.org/wiki/Gray_code#Converting_to_and_from_Gray_code
  -- Therefore do not use:
  --   gray <= cnt_wr XOR (cnt_wr ror 1);

  -- Synchronisers must be fed from a registered value, with no logic before the first flop in the
  -- destination clock domain. The video implies this step can be purely combinatorial, but that's
  -- bad CDC practice according to Xilinx and their Vivado tool.
  -- Reference https://docs.amd.com/r/en-US/ug906-vivado-design-analysis/Combinatorial-Logic
  bin_to_gray : process(clk_wr)
  begin
    if rising_edge(clk_wr) then
      if reset_wr = '1' then
        gray <= (others => '0');
      else
        -- VHDL-2008: srl is a shift right logic (srl) operator, short hand for:
        --   '0' & cnt_wr(width_g-1 downto 1)
        gray <= cnt_wr XOR (cnt_wr srl 1);
      end if;
    end if;
  end process;


  sync_gray_to_bin : process(clk_rd)
    variable bin_v : std_logic_vector(width_g-1 downto 0);
  begin
    if rising_edge(clk_rd) then
      if reset_rd = '1' then
        gray_sync <= (others => (others => '0'));
        cnt_rd    <= (others => '0');
      else
        -- Each counter bit gets its own synchroniser
        gray_sync <= gray & gray_sync(0 to len_g-2);

        -- Gray to binary conversion
        bin_v(width_g-1) := gray_sync(len_g-1)(width_g-1);
        for i in width_g-2 downto 0 loop
          bin_v(i) := bin_v(i+1) xor gray_sync(len_g-1)(i);
        end loop;
        cnt_rd <= bin_v;
      end if;
    end if;
  end process;

end architecture;
