-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Low Speed Serial IO Interface testing
--
-- References:
--  * https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual
--  * https://digilent.com/reference/programmable-logic/zybo-z7/start
--  * https://www.01signal.com/electronics/source-synchronous-inputs/
--
-- P A Abbey, 18 December 2024
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity zybo_z7_10 is
  port(
    clk_port : in  std_logic; -- 125 MHz External Clock
    sw       : in  std_logic_vector(3 downto 0);
    btn      : in  std_logic_vector(3 downto 0);
    led      : out std_logic_vector(3 downto 0);
    -- Tx-Rx Testing
    clk_tx   : out std_logic; -- Source synchronous clock for tx[*]
    tx       : out std_logic_vector(2 downto 0) := "000";
    clk_rx   : in  std_logic;
    rx       : in  std_logic_vector(2 downto 0) := "000"
  );
end entity;


architecture rtl of zybo_z7_10 is

  constant prbs_index_c : natural range 1 to 8 := 3;

  signal clk          : std_logic                    := '0';
  signal clk_rx_pll   : std_logic                    := '0';
  signal reset        : std_logic                    := '1';
  signal reset_rx     : std_logic                    := '1';
  signal locked       : std_logic;
  signal locked_clk   : std_logic;
  signal rx_enable_rx : std_logic;
  signal rx_locked    : std_logic;
  signal rx_locked_rx : std_logic;
  signal rst_reg      : std_logic_vector(3 downto 0) := (others => '1');
  signal rst_reg_rx   : std_logic_vector(3 downto 0) := (others => '1');
  signal sw_r         : std_logic_vector(sw'range)   := (others => '0');
  signal btn_r        : std_logic_vector(btn'range)  := (others => '0');
  signal buttons      : std_logic_vector(btn'range)  := (others => '0');
  signal check        : std_logic_vector(rx'range)   := (others => '1');
  signal rx_f         : std_logic_vector(rx'range)   := (others => '0');
  signal rx_r         : std_logic_vector(rx'range)   := (others => '0');
  signal rx_gated     : std_logic_vector(rx'range);
  signal check_gated  : std_logic_vector(rx'range);
  signal empty        : std_logic_vector(0 to 1)     := (others => '1');

begin

  pll_i : entity work.pll
    port map (
      -- Clock in ports
      clk_in  => clk_port,
      -- Clock out ports
      clk_out => clk,
      -- Status and control signals
      locked  => locked
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

  -- NB. This will create a delta cycle which can be like gating the clock in simulation.
  clk_tx <= clk;

  -- 180 degree phase shift 'clk_rx' to 'clk_rx_pll'
  -- 'clk', 'clk_rx' and 'clk_rx_pll' are related. Make sure the timing constraints
  -- are set up correctly.
  pll_rx : entity work.pll_lssio
    port map (
      -- Clock in ports
      clk_in  => clk_rx,
      -- Clock out ports
      clk_out => clk_rx_pll,
      -- Status and control signals
      locked  => rx_locked
    );

  -- Double retime buttons and switches
  retime_rxl : entity work.retime
    generic map (
      num_bits => 2
    )
    port map (
      clk          => clk_rx_pll,
      reset        => '0',
      flags_in(0)  => buttons(3),
      flags_in(1)  => rx_locked,
      flags_out(0) => rx_enable_rx,
      flags_out(1) => rx_locked_rx
    );

  -- Capture data in the eye using the 180 degree phase shift
  process(clk_rx_pll)
  begin
    if rising_edge(clk_rx_pll) then
      rx_f <= rx;
    end if;
  end process;

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

  process(clk_rx_pll)
  begin
    if rising_edge(clk_rx_pll) then
      (reset_rx, rst_reg_rx) <= rst_reg_rx & not rx_locked_rx;
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
        buttons <= "0000";
      else
        -- Arbitrate between buttons and switches
        buttons <= btn_r or sw_r;
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
      data_out => tx
    );

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
      rst    => reset_rx, -- Sync to wr_clk
      wr_clk => clk_rx_pll,
      wr_en  => rx_enable_rx,
      din    => rx_f,
      rd_clk => clk,
      rd_en  => not empty(0),
      dout   => rx_r,
      full   => open,
      empty  => empty(0)
    );

  -- Pulled out for simulation check
  rx_gated    <= (rx_r  or buttons(2 downto 0));
  check_gated <= (check or buttons(2 downto 0));

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
