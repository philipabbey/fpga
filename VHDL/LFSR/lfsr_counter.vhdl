library ieee;
use ieee.std_logic_1164.all;
library local;
use local.lfsr.all;

entity lfsr_counter is
  generic(
    max : positive range 3 to positive'high
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    enable   : in  std_ulogic;
    finished : out std_ulogic
  );
end entity;

architecture rtl of lfsr_counter is

  constant taps    : std_ulogic_vector := get_taps(max);
  constant max_reg : std_ulogic_vector := lfsr_cnt(taps, max-1);
  constant fin_reg : std_ulogic_vector := lfsr_cnt(taps, max-2);
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
          reg <= lsfr_feedback(reg, taps);
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
