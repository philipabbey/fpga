-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- RTL code to demonstrate the interchangability of the synchronous and LFSR
-- counters.
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity counter is
  generic(
    max_g : positive range 2 to positive'high
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    enable   : in  std_ulogic;
    finished : out std_ulogic
  );
end entity;


architecture sync of counter is

  signal cnt : natural range 0 to max_g-1;

begin

  process(clk)
  begin
    if rising_edge(clk) then
    
      if reset = '1' then
        cnt      <= 0;
        finished <= '0';
      elsif enable = '1' then

        if cnt = max_g-1 then
          cnt <= 0;
        else
          cnt <= cnt + 1;
        end if;

        -- Needs to go high during the 50th clock cycle for which enable is high.
        -- This allows a follow-on clocked process to have notice.
        if cnt = max_g-2 then
          finished <= '1';
        else
          finished <= '0';
        end if;

      end if;
    end if;
  end process;

end architecture;


library local;

architecture lfsr of counter is

  constant taps    : std_ulogic_vector := local.lfsr_pkg.get_taps(max_g);
  constant max_reg : std_ulogic_vector := local.lfsr_pkg.lfsr_cnt(taps, max_g-1);
  constant fin_reg : std_ulogic_vector := local.lfsr_pkg.lfsr_cnt(taps, max_g-2);
  signal   reg     : std_ulogic_vector(taps'range);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        reg      <= (others => '1');
        finished <= '0';
      elsif enable = '1' then

        if reg = max_reg then
          reg <= (others => '1');
        else
          reg <= local.lfsr_pkg.lsfr_feedback(reg, taps);
        end if;

        if reg = fin_reg then
          finished <= '1';
        else
          finished <= '0';
        end if;

      end if;
    end if;
  end process;

end architecture;
