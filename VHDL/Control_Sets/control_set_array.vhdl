-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Code to experiment with control set remapping to LUTs on D input to registers.
--
-- P A Abbey, 8 August 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity control_set_array is
  generic(
    width : positive := 4;
    depth : positive := 2
  );
  port(
    clk   : in  std_logic;
    reset : in  std_logic;
    d     : in  std_logic_vector(width-1 downto 0);
    ces   : in  std_logic_vector(width-1 downto 0);
    q     : out std_logic_vector(width-1 downto 0)
  );
end entity;


architecture rtl of control_set_array is
begin

  shift_g : if width = 1 generate

    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          q <= (others => '0');
        else
          for i in ces'range loop
            if ces(i) = '1' then
              q(i) <= d(i);
            end if;
          end loop;
        end if;
      end if;
    end process;
    
  else generate -- width >= 2

    type slv_arr_t is array (natural range <>) of std_logic_vector;
    signal dd : slv_arr_t(width-1 downto 0)(depth-2 downto 0);

  begin

    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          dd <= (others => (others => '0'));
          q  <= (others => '0');
        else
          for i in ces'range loop
            if ces(i) = '1' then
              -- Cannot use aggregate assignment "(dd(i), q(i)) <= d(i) & dd(i);" here as the compiler complains
              -- "Error: aggregate targets in an assignment must all be locally static names"
              -- Does not work with unwrapping a generate loop either.
              dd(i) <= d(i) & dd(i)(depth-2 downto 1);
              q(i) <= dd(i)(0);
            end if;
          end loop;
        end if;
      end if;
    end process;

  end generate;

end architecture;
