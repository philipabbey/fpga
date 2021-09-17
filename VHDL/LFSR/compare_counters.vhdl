library ieee;
use ieee.std_logic_1164.all;

entity compare_counters is
  generic(
    max : positive range 3 TO positive'high
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    enable   : in  std_ulogic;
    finished : out std_ulogic;
    compare  : out std_ulogic
  );
end entity;

architecture rtl of compare_counters is

  signal sync_max : std_ulogic;
  signal lfsr_max : std_ulogic;

  component sync_counter is
    generic(
      max : positive range 2 TO positive'high
    );
    port(
      clk      : in  std_ulogic;
      reset    : in  std_ulogic;
      enable   : in  std_ulogic;
      finished : out std_ulogic
    );
  end component;

  component lfsr_counter is
    generic(
      max : positive range 3 TO positive'high
    );
    port(
      clk      : in  std_ulogic;
      reset    : in  std_ulogic;
      enable   : in  std_ulogic;
      finished : out std_ulogic
    );
  end component;
  
begin

  sync_counter_c : sync_counter 
    generic map (
      max => max
    )
    port map (
      clk      => clk,
      reset    => reset,
      enable   => enable,
      finished => sync_max
    );

  lfsr_counter_c : lfsr_counter
    generic map (
      max => max
    )
    port map (
      clk      => clk,
      reset    => reset,
      enable   => enable,
      finished => lfsr_max
    );

  finished <= sync_max;
  
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        compare <= '1';
      else
        compare <= sync_max xnor lfsr_max;
      end if;
    end if;
  end process;
  
end architecture;
