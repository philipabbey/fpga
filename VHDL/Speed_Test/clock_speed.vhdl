-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Create an OSVVM scoreboard (FIFO) of ASCII characters.
--
-- P A Abbey, 22 September 2024
--
-------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;

entity clock_speed is
    generic (
        clk_wiz_g : natural;
        length_g  : positive := 255
    );
    port (
        clk_ext : in  std_logic;
        input   : in  std_logic;
        output  : out std_logic := '0'
    );
end entity;


architecture rtl of clock_speed is

    signal clk     : std_logic                             := '0';
    signal input_r : std_logic                             := '0';
    signal vector  : std_logic_vector(length_g-1 downto 0) := (others => '0');

begin

    -- Artix-7 and Spartan-7 families
    cw : if clk_wiz_g = 1 generate
      -- MMCME2_ADV primitive
      mmcm_i : entity work.clk_wiz_1
           port map (
           clk_in1  => clk_ext,
           reset    => '0',
           clk_out1 => clk
      );
    else generate
      -- MMCME3_ADV primitive
      mmcm_i : entity work.clk_wiz_0
           port map (
           clk_in1  => clk_ext,
           reset    => '0',
           clk_out1 => clk
      );
    end generate;

    process(clk)
    begin
        if rising_edge(clk) then
            input_r          <= input;
            (output, vector) <= (vector & input_r) XOR ('1' & vector);
        end if;
    end process;

end architecture;
