library ieee;
use ieee.std_logic_1164.all;
library local;
use local.lfsr.all;

entity lfsr_counter_wrapper is
  generic(
    max : positive range 3 TO positive'high
  );
  port(
    clk      : in  std_ulogic;
    reset    : in  std_ulogic;
    enable   : in  std_ulogic;
    finished : out std_ulogic
  );
end entity;

architecture rtl of lfsr_counter_wrapper is

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
  
  -- Double retime inputs to new clock domain
  signal enable_reg   : std_ulogic_vector(1 downto 0);
  signal reset_reg    : std_ulogic_vector(1 downto 0);
  signal finished_i   : std_ulogic;

begin

  process(clk, reset)
  begin
    -- Asynchronous reset for synchronising the reset
    -- See articles at:
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-other-Design/bc-p/931744
    -- * https://forums.xilinx.com/t5/Adaptable-Advantage-Blog/Demystifying-Resets-Synchronous-Asynchronous-and-other-Design/ba-p/887366
    if reset = '1' then
      enable_reg <= "00";
      reset_reg  <= "11";
    elsif rising_edge(clk) then
      enable_reg <= enable_reg(0) & enable;
      reset_reg  <= reset_reg(0) & '0';
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset_reg(1) = '1' then
        finished <= '0';
      else
        finished <= finished_i;
      end if;
    end if;
  end process;

  comp_lfsr_counter : lfsr_counter
    generic map (
      max => max
    )
    port map (
      clk      => clk,
      reset    => reset_reg(1),
      enable   => enable_reg(1),
      finished => finished_i
    );

end architecture;
