library ieee;
use ieee.std_logic_1164.all;

entity sync_counter is
  generic(
    max : positive range 2 TO positive'high
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    enable   : in  std_ulogic;
    finished : out std_ulogic
  );
end entity;

architecture rtl of sync_counter is

  signal cnt : natural range 0 to max-1;

begin

  process(clk)
  begin
    if rising_edge(clk) then
    
      if reset = '1' then
        cnt      <= 0;
        finished <= '0';
      elsif enable = '1' then

        if cnt = max-1 then
          cnt <= 0;
        else
          cnt <= cnt + 1;
        end if;

        -- Needs to go high during the 50th clock cycle for which enable is high.
        -- This allows a follow-on clocked process to have notice.
        if cnt = max-2 then
          finished <= '1';
        else
          finished <= '0';
        end if;

      end if;
    end if;
  end process;

end architecture;
