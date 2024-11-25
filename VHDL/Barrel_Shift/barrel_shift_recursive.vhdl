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

entity barrel_shift_recursive is
  generic (
    shift_bits_g   : positive;
    -- Rotation direction left/right
    shift_left_g   : boolean := true; -- Otherwise shift right
    -- Pipeline stages
    num_clks_g     : positive;
    -- Internal use only on recursion. Number of shift bits remaining.
    -- 0 means use 'shift_bits_g', otherwise it is < shift_bits_g.
    recurse_bits_g : natural := shift_bits_g
  );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    shift    : in  std_logic_vector(   shift_bits_g-1 downto 0);
    data_in  : in  std_logic_vector(2**shift_bits_g-1 downto 0);
    data_out : out std_logic_vector(2**shift_bits_g-1 downto 0)
  );
end entity;


-- Tail recursive implementation.
-- Uses manual bit rotations, one bit at a time in a loop per clock cycle to accumulate
-- multi-bit manipulations in one clock cycle.
--
library local;

architecture recursive of barrel_shift_recursive is

  constant bits_c : natural := work.barrel_shift_pkg.num_bits(
    shift_len => recurse_bits_g,
    num_clks  => num_clks_g
  );

begin

  clks : if bits_c > 0 generate
    signal data : local.rtl_pkg.slv_arr_t(recurse_bits_g downto recurse_bits_g-bits_c)(data_in'range);
  begin

    data(recurse_bits_g) <= data_in;

    shft : for i in recurse_bits_g-1 downto recurse_bits_g-bits_c generate
      constant bot_high : natural := work.barrel_shift_pkg.split_high_fn(
        data_len   => data_in'length,
        idx        => i,
        shift_left => shift_left_g
      );
    begin

      reg : if i = recurse_bits_g-bits_c generate

        -- Each of these performs a registered 2**i-bit rotation
        rotate : process (clk)
        begin
          if rising_edge(clk) then
            if reset = '1' then
              data(i) <= (others => '0');
            else
              if shift(i) = '1' then
                data(i) <= data(i+1)(bot_high downto 0) & data(i+1)(data(i)'high downto bot_high+1);
              else
                data(i) <= data(i+1);
              end if;
            end if;
          end if;
        end process;

      else generate

        -- Each of these performs a unregistered 2**i-bit rotation
        data(i) <= data(i+1)(bot_high downto 0) & data(i+1)(data(i)'high downto bot_high+1) when shift(i) = '1' else data(i+1);

      end generate;

    end generate;

    recurse : if num_clks_g > 1 generate
      signal shift_i  : std_logic_vector(shift'high-bits_c downto 0) := (others => '0');
      signal shift_ii : std_logic_vector(shift'range)                := (others => '0');
    begin

      shft : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            shift_i <= (others => '0');
          else
            shift_i <= shift(shift_i'range);
          end if;
        end if;
      end process;

      -- Replace used shift bits with constants at the top of shift port.
      -- (shift_i'range => shift_i, others => '0')
      -- (vcom-1048) Non-locally static choice (association #1, choice #1) is allowed only if it is the only choice of the only association.
      -- Resorting to assigning an intermediate signal
      shift_ii(shift_i'range) <= shift_i;

      barrel_shift_i : entity work.barrel_shift_recursive(recursive)
        generic map (
          shift_bits_g   => shift_bits_g,
          shift_left_g   => shift_left_g,
          num_clks_g     => num_clks_g-1,
          recurse_bits_g => recurse_bits_g-bits_c
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift_ii,
          data_in  => data(recurse_bits_g-bits_c),
          data_out => data_out
        );

    else generate

      data_out <= data(recurse_bits_g-bits_c);

    end generate;

  else generate

    recurse : if num_clks_g > 1 generate
      signal data_in_i : std_logic_vector(data_in'range);
      signal shift_i   : std_logic_vector(shift'range) := (others => '0');
    begin

      -- Single clock cycle delay
      delay : process(clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data_in_i <= (others => '0');
            shift_i   <= (others => '0');
          else
            data_in_i <= data_in;
            shift_i   <= shift;
          end if;
        end if;
      end process;

      barrel_shift_i : entity work.barrel_shift_recursive(recursive)
        generic map (
          shift_bits_g   => shift_bits_g,
          shift_left_g   => shift_left_g,
          num_clks_g     => num_clks_g-1,
          recurse_bits_g => shift_bits_g
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift_i,
          data_in  => data_in_i,
          data_out => data_out
        );

    else generate

      -- Single clock cycle delay
      delay : process(clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data_out <= (others => '0');
          else
            data_out <= data_in;
          end if;
        end if;
      end process;

    end generate;

  end generate;

end architecture;


-- Tail recursive implementation.
-- Uses rol and ror operators to perform multi-bit manipulations in one clock cycle.
-- These operators implement inefficient logic in terms of LUTs, hampering clock speed.
--
library ieee;
  use ieee.numeric_std_unsigned.all;
library local;

architecture recursive2 of barrel_shift_recursive is

  constant bits_c : natural := work.barrel_shift_pkg.num_bits(
    shift_len => recurse_bits_g,
    num_clks  => num_clks_g
  );

  signal shift_ii : std_logic_vector(shift'range) := (others => '0');

begin

  clks : if bits_c > 0 generate
    constant mask   : std_logic_vector := work.barrel_shift_pkg.mask_gen(shift'length, recurse_bits_g-1, recurse_bits_g-bits_c);
    signal   data_i : std_logic_vector(data_in'range);
  begin

    -- Each of these performs a registered 2**i-bit rotation
    rotate : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          data_i <= (others => '0');
        else
          if shift_left_g then
            data_i <= data_in rol to_integer(shift and mask);
          else
            data_i <= data_in ror to_integer(shift and mask);
          end if;
        end if;
      end if;
    end process;

    recurse : if num_clks_g > 1 generate
      signal shift_i : std_logic_vector(shift'high-bits_c downto 0) := (others => '0');
    begin

      shft : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            shift_i <= (others => '0');
          else
            shift_i <= shift(shift_i'range);
          end if;
        end if;
      end process;

      -- Replace used shift bits with constants at the top of shift port.
      -- (shift_i'range => shift_i, others => '0')
      -- (vcom-1048) Non-locally static choice (association #1, choice #1) is allowed only if it is the only choice of the only association.
      -- Resorting to assigning an intermediate signal
      shift_ii(shift_i'range) <= shift_i;

      barrel_shift_i : entity work.barrel_shift_recursive(recursive2)
        generic map (
          shift_bits_g   => shift_bits_g,
          shift_left_g   => shift_left_g,
          num_clks_g     => num_clks_g-1,
          recurse_bits_g => recurse_bits_g-bits_c
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift_ii,
          data_in  => data_i,
          data_out => data_out
        );

    else generate

      data_out <= data_i;

    end generate;

  else generate

    recurse : if num_clks_g > 1 generate
      signal data_in_i : std_logic_vector(data_in'range);
    begin

      -- Single clock cycle delay
      delay : process(clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data_in_i <= (others => '0');
            shift_ii  <= (others => '0');
          else
            data_in_i <= data_in;
            shift_ii  <= shift;
          end if;
        end if;
      end process;

      barrel_shift_i : entity work.barrel_shift_recursive(recursive2)
        generic map (
          shift_bits_g   => shift_bits_g,
          shift_left_g   => shift_left_g,
          num_clks_g     => num_clks_g-1,
          recurse_bits_g => shift_bits_g
        )
        port map (
          clk      => clk,
          reset    => reset,
          shift    => shift_ii,
          data_in  => data_in_i,
          data_out => data_out
        );

    else generate

      -- Single clock cycle delay
      delay : process(clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            data_out <= (others => '0');
          else
            data_out <= data_in;
          end if;
        end if;
      end process;

    end generate;

  end generate;

end architecture;
