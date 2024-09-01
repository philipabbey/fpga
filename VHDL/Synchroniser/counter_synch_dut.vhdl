-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- This code implements a demonstration of a counter synchroniser solution gleaned
-- from a Doulos training video on clock domain crossings available at
-- https://www.doulos.com/webinars/on-demand/clock-domain-crossing/.
--
-- P A Abbey, 1 September 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity counter_synch_dut is
  generic(
    width_g : positive := 8;
    -- Synchroniser chain length
    len_g   : positive := 2
  );
  port(
    clk1      : in  std_logic;
    reset1    : in  std_logic;
    clk2      : in  std_logic;
    reset2    : in  std_logic;
    incr_cnt1 : in  std_logic;        -- Counter in clock domain 1
    incr_cnt2 : in  std_logic;        -- Counter in clock domain 2
    gt12_1    : out std_logic := '0'; -- Counter in clock domain 1 greater than that in clock domain 2, compared in clock domain 1
    gt12_2    : out std_logic := '0'  -- Counter in clock domain 1 greater than that in clock domain 2, compared in clock domain 2
  );
end entity;


library ieee;
  use ieee.numeric_std_unsigned.all;

architecture rtl of counter_synch_dut is

  signal cnt11 : std_logic_vector(width_g-1 downto 0) := (others => '0');
  signal cnt12 : std_logic_vector(width_g-1 downto 0) := (others => '0');
  signal cnt22 : std_logic_vector(width_g-1 downto 0) := (others => '0');
  signal cnt21 : std_logic_vector(width_g-1 downto 0) := (others => '0');

begin

  process(clk1)
  begin
    if rising_edge(clk1) then
      if reset1 = '1' then
        cnt11  <= (others => '0');
        gt12_1 <= '0';
      else
        if incr_cnt1 = '1' then
          cnt11 <= cnt11 + 1;
        end if;
        gt12_1 <= '1' when (cnt11 > cnt21) else '0';
      end if;
    end if;
  end process;

  -- Clock domain 1 to 2
  counter_synchroniser_12 : entity work.counter_synchroniser
    generic map (
      width_g => width_g,
      len_g   => len_g
    )
    port map (
      clk_wr   => clk1,
      reset_wr => reset1,
      clk_rd   => clk2,
      reset_rd => reset2,
      cnt_wr   => cnt11, -- Counter 1 in clock domain 1
      cnt_rd   => cnt12  -- Counter 1 in clock domain 2
    );

  process(clk2)
  begin
    if rising_edge(clk2) then
      if reset2 = '1' then
        cnt22  <= (others => '0');
        gt12_2 <= '0';
      else
        if incr_cnt2 = '1' then
          cnt22 <= cnt22 + 1;
        end if;
        gt12_2 <= '1' when (cnt12 > cnt22) else '0';
      end if;
    end if;
  end process;

  -- Clock domain 2 to 1
  counter_synchroniser_21 : entity work.counter_synchroniser
    generic map (
      width_g => width_g,
      len_g   => len_g
    )
    port map (
      clk_wr   => clk2,
      reset_wr => reset2,
      clk_rd   => clk1,
      reset_rd => reset1,
      cnt_wr   => cnt22, -- Counter 2 in clock domain 2
      cnt_rd   => cnt21  -- Counter 2 in clock domain 1
    );

end architecture;
