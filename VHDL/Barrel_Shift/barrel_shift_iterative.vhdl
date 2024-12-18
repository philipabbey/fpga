-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Generic pipelined barrel shift enabling arbitraily large vector rotations over a
-- user specified number of clock cycles in order to manage timing closure.
--
-- P A Abbey, 15 November 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity barrel_shift_iterative is
  generic (
    shift_bits_g : positive;
    -- Rotation direction left/right
    shift_left_g : boolean := true; -- Otherwise shift right
    -- Pipeline stages
    num_clks_g   : positive
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    shift    : in  std_logic_vector(   shift_bits_g-1 downto 0);
    data_in  : in  std_logic_vector(2**shift_bits_g-1 downto 0);
    data_out : out std_logic_vector(2**shift_bits_g-1 downto 0)
  );
end entity;


-- Uses manual bit rotations, one bit at a time in a loop per clock cycle to accumulate
-- multi-bit manipulations in one clock cycle.

library local;

architecture iterative of barrel_shift_iterative is

  -- Safe to assume this is downto range as we define the function providing the vector.
  constant indexes_c : local.rtl_pkg.natural_vector := work.barrel_shift_pkg.register_stages(
    shift_len => shift_bits_g,
    num_clks  => num_clks_g
  );

  signal data    : local.rtl_pkg.slv_arr_t(shift_bits_g downto minimum(0, shift_bits_g-num_clks_g))(data_in'range);
  signal shift_i : local.rtl_pkg.slv_arr_t(shift_bits_g downto 1)(shift'range);

begin

  data(shift_bits_g)    <= data_in;
  shift_i(shift_bits_g) <= shift;

  -- Take one bit at a time
  shift_g : for c in num_clks_g-1 downto 0 generate

    clks : if indexes_c(c+1) = 0 and indexes_c(c) = 0 generate

      -- Unnecessary additional delays
      delay : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data(c+shift_bits_g-num_clks_g) <= (others => '0');
          else
            data(c+shift_bits_g-num_clks_g) <= data(c+shift_bits_g-num_clks_g+1);
          end if;
        end if;
      end process;

    else generate

      idx : for i in indexes_c(c+1)-1 downto indexes_c(c) generate
        constant bot_high : natural := work.barrel_shift_pkg.split_high_fn(data_in'length, i, shift_left_g);
      begin

        reg : if i = indexes_c(c) generate

          -- vopt complains if this condition is inside the next process to conditionally not assign
          -- an array element that does not exist.
          sr : if i > 0 generate
            process (clk)
            begin
              if rising_edge(clk) then
                if reset = '1' then
                  shift_i(i)(i-1 downto 0) <= (others => '0');
                else
                  -- Unused bits will be minimised away by synthesis. shift_i(0) has no
                  -- assigned bits (-1 downto 0) so can be omitted.
                  shift_i(i)(i-1 downto 0) <= shift_i(i+1)(i-1 downto 0);
                end if;
              end if;
            end process;
          end generate;

          -- Each of these performs a registered 2**i-bit rotation
          rotate : process (clk)
          begin
            if rising_edge(clk) then
              if reset = '1' then
                data(i) <= (others => '0');
              else
                if shift_i(i+1)(i) = '1' then
                  data(i) <= data(i+1)(bot_high downto 0) & data(i+1)(data(i)'high downto bot_high+1);
                else
                  data(i) <= data(i+1);
                end if;
              end if;
            end if;
          end process;

        else generate

          -- Unused bits will be minimised away by synthesis. shift_i(0) has no
          -- assigned bits (-1 downto 0) so can be omitted.
          sr : if i > 0 generate
            shift_i(i)(i-1 downto 0) <= shift_i(i+1)(i-1 downto 0);
          end generate;

          -- Each of these performs a unregistered 2**i-bit rotation
          data(i) <= data(i+1)(bot_high downto 0) & data(i+1)(data(i)'high downto bot_high+1) when shift_i(i+1)(i) = '1' else data(i+1);
        end generate;

      end generate;

    end generate;

  end generate;

  data_out <= data(data'low);

end architecture;


-- Uses rol and ror operators to perform multi-bit manipulations in one clock cycle.
-- These operators implement inefficient logic in terms of LUTs, hampering clock speed.

library ieee;
  use ieee.numeric_std_unsigned.all;
library local;

architecture iterative2 of barrel_shift_iterative is

  -- Safe to assume this is downto range as we define the function providing the vector.
  constant indexes_c : local.rtl_pkg.natural_vector := work.barrel_shift_pkg.register_stages(
    shift_len => shift_bits_g,
    num_clks  => num_clks_g
  );

  signal data    : local.rtl_pkg.slv_arr_t(num_clks_g downto 0)(data_in'range);
  signal shift_i : local.rtl_pkg.slv_arr_t(num_clks_g downto 1)(shift'range) := (others => (others => '0'));

begin

  data(num_clks_g)    <= data_in;
  shift_i(num_clks_g) <= shift;

  shift_g : for c in num_clks_g-1 downto 0 generate

    clks : if indexes_c(c+1) = 0 and indexes_c(c) = 0 generate

      -- Unnecessary additional delays
      delay : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data(c) <= (others => '0');
          else
            data(c) <= data(c+1);
          end if;
        end if;
      end process;

    else generate
      constant mask : std_logic_vector := work.barrel_shift_pkg.mask_gen(shift_bits_g, indexes_c(c+1)-1, indexes_c(c));
    begin

      -- vopt complains if this condition is inside the next process to conditionally not assign
      -- an array element that does not exist.
      sr : if c > 0 generate
        process (clk)
        begin
          if rising_edge(clk) then
            if reset = '1' then
              shift_i(c)(c-1 downto 0) <= (others => '0');
            else
              -- Unused bits will be minimised away by synthesis. shift_i(0) has no
              -- assigned bits (-1 downto 0) so can be omitted.
              shift_i(c)(indexes_c(c)-1 downto 0) <= shift_i(c+1)(indexes_c(c)-1 downto 0);
            end if;
          end if;
        end process;
      end generate;

      -- Each of these performs a registered 2**c-bit rotation
      rotate : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data(c) <= (others => '0');
          else
            if shift_left_g then
              data(c) <= data(c+1) rol to_integer(shift_i(c+1) and mask);
            else
              data(c) <= data(c+1) ror to_integer(shift_i(c+1) and mask);
            end if;
          end if;
        end if;
      end process;

    end generate;

  end generate;

  data_out <= data(data'low);

end architecture;
