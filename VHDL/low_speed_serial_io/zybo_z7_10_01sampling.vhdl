-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Low Speed Serial IO Interface with sampling based on
-- https://www.01signal.com/electronics/01-signal-sampling/.
--
-- References:
--  * https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
--  * https://digilent.com/reference/programmable-logic/zybo-z7/start
--  * https://www.01signal.com/electronics/source-synchronous-inputs/
--
-- P A Abbey, 30 December 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.numeric_std_unsigned.all;
library unisim;
library local;

architecture sampling of zybo_z7_10 is

  constant prbs_index_c : natural range 1 to 8 := 3;
  
  signal clk_samp        : std_logic                    := '0';
  signal clk             : std_logic                    := '0';
  signal clk_rx_r        : std_logic                    := '0';
  signal clk_rx_rd       : std_logic                    := '0';
  signal reset           : std_logic                    := '1';
  signal reset_samp      : std_logic                    := '1';
  signal locked          : std_logic;
  signal locked_clk      : std_logic;
  signal locked_clk_samp : std_logic;
  signal rst_reg         : std_logic_vector(3 downto 0) := (others => '1');
  signal rst_reg_samp    : std_logic_vector(3 downto 0) := (others => '1');
  signal sw_r            : std_logic_vector(sw'range)   := (others => '0');
  signal btn_r           : std_logic_vector(btn'range)  := (others => '0');
  signal buttons         : std_logic_vector(btn'range)  := (others => '0');
  signal tx_r            : std_logic_vector(tx'range)   := (others => '0');
  signal check           : std_logic_vector(rx'range)   := (others => '1');
  signal rx_port_r       : std_logic_vector(4 downto 0) := (others => '0');
  signal rx_r            : std_logic_vector(rx'range)   := (others => '0');
  signal rx_samp         : std_logic_vector(rx'range)   := (others => '0');
  signal rx_enable       : std_logic_vector(0 to 1)     := (others => '0');
  signal rx_enable_samp  : std_logic;
  signal rx_gated        : std_logic_vector(rx'range);
  signal check_gated     : std_logic_vector(rx'range);
  signal empty           : std_logic_vector(0 to 1)     := (others => '1');

begin

  pll_i : entity work.pll
    port map (
      -- Clock in ports
      clk_in   => clk_port,
      -- Clock out ports
      clk_out  => clk,
      clk_out2 => clk_samp,
      -- Status and control signals
      locked   => locked
    );

  retime_lk : entity work.retime
    generic map (
      num_bits => 1
    )
    port map (
      clk          => clk,
      reset        => '0',
      flags_in(0)  => locked,
      flags_out(0) => locked_clk
    );

  retime_lk_samp : entity work.retime
    generic map (
      num_bits => 1
    )
    port map (
      clk          => clk_samp,
      reset        => '0',
      flags_in(0)  => locked,
      flags_out(0) => locked_clk_samp
    );

  -- NB. This will create a delta cycle which can be like gating the clock in simulation.
  clk_tx <= clk;

  -- Take advantage of initial values set GSR to generate the reset. It's not obvious
  -- how to tap GSR directly and discouraged too. 'locked' goes high earlier than GSR
  -- allows 'rst_reg' to start shifting, so this is belt & braces to ensure that reset
  -- cannot preceed the PLL entering the locked state.
  process(clk)
  begin
    if rising_edge(clk) then
      (reset, rst_reg) <= rst_reg & not locked_clk;
    end if;
  end process;

  process(clk_samp)
  begin
    if rising_edge(clk_samp) then
      (reset_samp, rst_reg_samp) <= rst_reg_samp & not locked_clk_samp;
    end if;
  end process;

  -- I don't like this double flop synchroniser on a data bus.
  -- It is however what is used in the source blog at
  -- https://www.01signal.com/electronics/01-signal-sampling/
  retime_rx : entity work.retime
    generic map (
      num_bits => rx_port_r'length
    )
    port map (
      clk       => clk_samp,
      reset     => '0',
      flags_in  => clk_rx & rx & rx_enable(rx_enable'high),
      flags_out => rx_port_r
    );

  (clk_rx_r, rx_r, rx_enable_samp) <= rx_port_r;

  process(clk_samp)
  begin
    if rising_edge(clk_samp) then
      if reset_samp = '1' then
        clk_rx_rd <= '0';
      else
        -- Arbitrate between buttons and switches
        clk_rx_rd <= clk_rx_r;
      end if;
    end if;
  end process;

  -- Double retime buttons and switches
  retime_sw : entity work.retime
    generic map (
      num_bits => sw'length
    )
    port map (
      clk       => clk,
      reset     => reset,
      flags_in  => sw,
      flags_out => sw_r
    );

  -- Double retime buttons and switches
  retime_btn : entity work.retime
    generic map (
      num_bits => btn'length
    )
    port map (
      clk       => clk,
      reset     => reset,
      flags_in  => btn,
      flags_out => btn_r
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        buttons   <= "0000";
        rx_enable <= (others => '0');
      else
        -- Arbitrate between buttons and switches
        buttons   <= btn_r or sw_r;
        rx_enable <= buttons(3) & rx_enable(0 to rx_enable'high-1);
      end if;
    end if;
  end process;

  itu_prbs_generator_tx : entity work.itu_prbs_generator
    generic map (
      index_g      => prbs_index_c,
      data_width_g => tx'length
    )
    port map (
      clk      => clk,
      reset    => reset or not buttons(3),
      enable   => buttons(3),
      data_out => tx_r
    );

  process(clk)
  begin
    if falling_edge(clk) then
      tx <= tx_r;
    end if;
  end process;

  itu_prbs_generator_rx : entity work.itu_prbs_generator
    generic map (
      index_g      => prbs_index_c,
      data_width_g => rx'length
    )
    port map (
      clk      => clk,
      reset    => reset or empty(0),
      enable   => not empty(0),
      data_out => check
    );

  fifo_rx_i : entity work.fifo_rx
    port map (
      rst    => reset_samp, -- Sync to clk_samp
      wr_clk => clk_samp,
      wr_en  => (not clk_rx_rd) and clk_rx_r and rx_enable_samp,
      din    => rx_r,
      rd_clk => clk,
      rd_en  => not empty(0),
      dout   => rx_samp,
      full   => open,
      empty  => empty(0)
    );

  -- Pulled out for simulation check
  rx_gated    <= (rx_samp or buttons(2 downto 0));
  check_gated <= (check   or buttons(2 downto 0));

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        led                              <= "1000";
        empty(empty'low+1 to empty'high) <= (others => '1');
      else
        empty(empty'low+1 to empty'high) <= empty(empty'low to empty'high-1);

        if empty(1) = '0' then
          if rx_gated = check_gated then
            led(0) <= '1';
            led(1) <= '0';
          else
            led(0) <= '0';
            led(1) <= '1';
          end if;
        else
          led(0) <= '0';
          led(1) <= '0';
        end if;
        led(2) <= not empty(1);
        led(3) <= empty(1);
      end if;
    end if;
  end process;

end architecture;
