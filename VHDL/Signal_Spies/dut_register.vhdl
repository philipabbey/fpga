library ieee;
use ieee.std_logic_1164.all;

entity dut_register is
  port(
    clk     : in  std_logic;
    reset   : in  std_logic;
    int_in  : in  natural range 0 to 15;
    vec_in  : in  std_logic_vector(3 downto 0);
    int_out : out natural range 0 to 15;
    vec_out : out std_logic_vector(3 downto 0)
  );
end entity;

architecture rtl of dut_register is

  signal int_out_i : natural range 0 to 15;
  signal vec_out_i : std_logic_vector(3 downto 0);

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        int_out_i <= 0;
        vec_out_i <= "0000";
      else
        int_out_i <= int_in;
        vec_out_i <= vec_in;
      end if;
    end if;
  end process;

  -- Make copies
  vec_out <= vec_out_i;
  int_out <= int_out_i;

end architecture;
