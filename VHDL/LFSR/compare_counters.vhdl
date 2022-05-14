-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Compare the outputs of a synchronous and a LFSR counter having the same generic
-- maximum count value.
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity compare_counters is
  generic(
    max_g : positive range 2 TO positive'high
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

begin

  sync_counter_c : entity work.counter(sync)
    generic map (
      max_g => max_g
    )
    port map (
      clk      => clk,
      reset    => reset,
      enable   => enable,
      finished => sync_max
    );

  lfsr_counter_c : entity work.counter(lfsr)
    generic map (
      max_g => max_g
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
