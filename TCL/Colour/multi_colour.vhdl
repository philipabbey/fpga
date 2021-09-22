-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado register colouring by clock
-- source.
--
-- P A Abbey, 21 May 2021
--
-------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity multi_colour is
  generic (
    num_clks : positive := 5;
    num_bits : positive := 12;
    num_pipe : positive := 4
  );
  port (
    clks     : in  std_logic_vector(num_clks-1 downto 0);
    resets   : in  std_logic_vector(num_clks-1 downto 0);
    data_in  : in  std_logic_vector(num_bits-1 downto 0);
    data_out : out std_logic_vector(num_bits-1 downto 0)
  );
end entity;

architecture rtl of multi_colour is

  type slv_array_t is array (num_pipe-1 downto 0) of std_logic_vector(num_bits-1 downto 0);

  signal reg : slv_array_t;

begin

  clk_g : for i in 0 to num_pipe-1 generate
    bit_g : for j in data_in'range generate
      constant clk_idx : natural := (i+j) mod num_clks;
    begin

      first_g : if i = 0 generate

        process(clks(clk_idx))
        begin
          if rising_edge(clks(clk_idx)) then
            if resets(clk_idx) = '1' then
              reg(i)(j) <= '0';
            else
              reg(i)(j) <= data_in(j);
            end if;
          end if;
        end process;

      else generate

        process(clks(clk_idx))
        begin
          if rising_edge(clks(clk_idx)) then
            if resets(clk_idx) = '1' then
              reg(i)(j) <= '0';
            else
              reg(i)(j) <= reg(i-1)(j);
            end if;
          end if;
        end process;

      end generate;

    end generate;
  end generate;
  
  data_out <= reg(num_pipe-1);

end architecture;
