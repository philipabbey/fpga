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
  use ieee.numeric_std_unsigned.all;
library unisim;
library local;

architecture idelay of zybo_z7_10 is

  constant prbs_index_c   : natural range 1 to 8         := 3;
  constant idelay_max_c   : std_logic_vector(4 downto 0) := (others => '1');
  constant prbs_cnt_max_c : positive                     := 100;

  type state_t is (
    waiting,
    training,
    eye,
    running
  );
  type state_qty_t is (
    waiting,
    bads,
    good,
    bade,
    complete
  );
  type count_vector is array (integer range <>) of integer range 0 to prbs_cnt_max_c;
  type total_vector is array (integer range <>) of integer range 0 to prbs_cnt_max_c*2;

  signal clk            : std_logic                                       := '0';
  signal clk_ref        : std_logic                                       := '0';
  signal clk_rx_pll     : std_logic                                       := '0';
  signal reset          : std_logic                                       := '1';
  signal reset_rx       : std_logic                                       := '1';
  signal reset_ref      : std_logic                                       := '1';
  signal locked         : std_logic;
  signal locked_clk     : std_logic;
  signal locked_clk_ref : std_logic;
  signal rx_enable_rx   : std_logic;
  signal rx_locked      : std_logic;
  signal rx_locked_rx   : std_logic;
  signal rst_reg        : std_logic_vector(3 downto 0)                    := (others => '1');
  signal rst_reg_ref    : std_logic_vector(3 downto 0)                    := (others => '1');
  signal rst_reg_rx     : std_logic_vector(3 downto 0)                    := (others => '1');
  signal sw_r           : std_logic_vector(sw'range)                      := (others => '0');
  signal btn_r          : std_logic_vector(btn'range)                     := (others => '0');
  signal buttons        : std_logic_vector(btn'range)                     := (others => '0');
  signal check          : std_logic_vector(rx'range)                      := (others => '1');
  signal state          : state_t                                         := waiting;
  signal idelay         : std_logic_vector(4 downto 0)                    := (others => '0');
  signal idelay_last    : natural range 0 to 31                           := 0;
  signal idelay_ld      : std_logic                                       := '0';
  signal idelay_ldd     : std_logic                                       := '0';
  signal idelay_mux     : local.rtl_pkg.slv_arr_t(2 downto 0)(4 downto 0) := (others => (others => '0'));
  signal counting       : std_logic                                       := '0';
  signal counting_d     : std_logic                                       := '0';
  signal prbs_cnt       : natural range 0 to prbs_cnt_max_c-1             := 0;
  signal rx_f1          : std_logic_vector(rx'range)                      := (others => '0');
  signal rx_f2          : std_logic_vector(rx'range)                      := (others => '0');
  signal rx_r           : std_logic_vector(rx'range)                      := (others => '0');
  signal rx_gated       : std_logic_vector(rx'range);
  signal check_gated    : std_logic_vector(rx'range);
  signal empty          : std_logic_vector(0 to 1)                        := (others => '1');
  signal wrong          : count_vector(2 downto 0)                        := (others => 0);
  signal total_idelay   : total_vector(2 downto 0)                        := (others => 0);

  attribute IODELAY_GROUP : STRING;
  attribute IODELAY_GROUP of idelayctrl_i: label is "rx_data";

  attribute MARK_DEBUG : string;
  attribute MARK_DEBUG of rx_r         : signal is "TRUE";
  attribute MARK_DEBUG of tx           : signal is "TRUE";
  attribute MARK_DEBUG of check        : signal is "TRUE";
  attribute MARK_DEBUG of check_gated  : signal is "TRUE";
  attribute MARK_DEBUG of prbs_cnt     : signal is "TRUE";
  attribute MARK_DEBUG of wrong        : signal is "TRUE";
  attribute MARK_DEBUG of total_idelay : signal is "TRUE";
  attribute MARK_DEBUG of idelay       : signal is "TRUE";
  attribute MARK_DEBUG of idelay_mux   : signal is "TRUE";
  attribute MARK_DEBUG of idelay_ld    : signal is "TRUE";
  attribute MARK_DEBUG of idelay_ldd   : signal is "TRUE";
  attribute MARK_DEBUG of counting     : signal is "TRUE";
  attribute MARK_DEBUG of state        : signal is "TRUE";
  attribute MARK_DEBUG of buttons      : signal is "TRUE";
  attribute MARK_DEBUG of led          : signal is "TRUE";

begin

  pll_i : entity work.pll
    port map (
      -- Clock in ports
      clk_in   => clk_port,
      -- Clock out ports
      clk_out  => clk,
      clk_out2 => clk_ref,
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

  retime_lk_ref : entity work.retime
    generic map (
      num_bits => 1
    )
    port map (
      clk          => clk_ref,
      reset        => '0',
      flags_in(0)  => locked,
      flags_out(0) => locked_clk_ref
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

  process(clk_ref)
  begin
    if rising_edge(clk_ref) then
      (reset_ref, rst_reg_ref) <= rst_reg_ref & not locked_clk_ref;
    end if;
  end process;

   idelayctrl_i : unisim.vcomponents.IDELAYCTRL
     port map (
        REFCLK => clk_ref,   -- 1-bit input: Reference clock input of 200 MHz
        RST    => reset_ref, -- 1-bit input: Active high reset input
        RDY    => open       -- 1-bit output: Ready output. To reset the IDELAYCTRL, assert it High for at least 50 ns.
     );

  -- IDELAY-based capture, 78 ps per increment + 600 ps constant delay.
  -- Range: 0.6 - 3.018 ns variation.
  -- CNTVALUEIN must be a registered output with no delta delays, or LD fails to load the value in.
  rx_g : for i in rx'range generate
    attribute IODELAY_GROUP of idelaye2_i: label is "rx_data";
  begin
    idelaye2_i : unisim.vcomponents.IDELAYE2
      generic map (
        CINVCTRL_SEL          => "FALSE",    -- Enable dynamic clock inversion (FALSE, TRUE)
        DELAY_SRC             => "IDATAIN",  -- Delay input (IDATAIN, DATAIN)
        HIGH_PERFORMANCE_MODE => "FALSE",    -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
        IDELAY_TYPE           => "VAR_LOAD", -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
        IDELAY_VALUE          => 0,          -- Input delay tap setting (0-31)
        PIPE_SEL              => "FALSE",    -- Select pipelined mode, FALSE, TRUE
        REFCLK_FREQUENCY      => 200.0,      -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
        SIGNAL_PATTERN        => "DATA"      -- DATA, CLOCK input signal
      )
      port map (
        C           => clk,           -- 1-bit input: Clock input
        IDATAIN     => rx(i),         -- 1-bit input: Data input from the I/O
        DATAIN      => '0',           -- 1-bit input: Internal delay data input
        DATAOUT     => rx_f1(i),      -- 1-bit output: Delayed data output
        CE          => '0',           -- 1-bit input: Active high enable increment/decrement input
        INC         => '1',           -- 1-bit input: Increment / Decrement tap delay input
        CINVCTRL    => '0',           -- 1-bit input: Dynamic clock inversion input
        CNTVALUEIN  => idelay_mux(i), -- 5-bit input: Counter value input
        LD          => idelay_ldd,    -- 1-bit input: Load IDELAY_VALUE input
        REGRST      => '0',           -- 1-bit input: Active-high reset tap-delay (PIPELINE register) input
        LDPIPEEN    => '0',           -- 1-bit input: Enable PIPELINE register to load data input
        CNTVALUEOUT => open           -- 5-bit output: Counter value output
      );
  end generate;

  -- Capture data in the eye using the 180 degree phase shift
  process(clk_rx_pll)
  begin
    if rising_edge(clk_rx_pll) then
      rx_f2 <= rx_f1;
    end if;
  end process;

  -- State Machine to control IDELAY
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' or buttons(3) = '0' then
        state       <= waiting;
        idelay      <= (others => '0');
        idelay_ld   <= '0';
        prbs_cnt    <= 0;
        counting    <= '0';
        idelay_last <= 0;
        if reset = '1' then
          idelay_mux <= (others => (others => '0'));
        end if;
      else
        -- Default assignments
        idelay_ld <= '0';
        for i in idelay_mux'range loop
          idelay_mux(i) <= idelay;
        end loop;

        case state is

          when waiting =>
            if empty(0) = '0' then
              idelay_ld <= '1';
              counting  <= '1';
              state     <= training;
            end if;

          when training =>
            if prbs_cnt = prbs_cnt_max_c-1 then
              prbs_cnt  <= 0;
              idelay_ld <= '1';
              if idelay = idelay_max_c then
                idelay   <= (others => '0');
                state    <= eye;
                counting <= '0';
              else
                idelay <= idelay + 1;
              end if;
              idelay_last <= to_integer(idelay);
            else
              prbs_cnt <= prbs_cnt + 1;
            end if;

          when eye =>
            -- Assign average (above)
            for i in idelay_mux'range loop
              idelay_mux(i) <= to_slv(total_idelay(i), 6)(5 downto 1);
            end loop;
            state <= running;

          when running =>
            -- Assign average (above)
            for i in idelay_mux'range loop
              idelay_mux(i) <= to_slv(total_idelay(i), 6)(5 downto 1);
            end loop;
            state <= running; -- until reset

        end case;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        idelay_ldd <= '0';
        counting_d <= '0';
      else
        idelay_ldd <= idelay_ld;
        counting_d <= counting;
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
      din    => rx_f2,
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
        wrong                            <= (others => 0);
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

          if counting_d = '1' then
            for i in check_gated'range loop
              if rx_gated(i) = check_gated(i) then
                if idelay_ldd = '1' then
                  wrong(i) <= 0;
                end if;
              else
                if idelay_ldd = '1' then
                  wrong(i) <= 1;
                else
                  wrong(i) <= wrong(i) + 1;
                end if;
              end if;
            end loop;
          end if;
        else
          led(0) <= '0';
          led(1) <= '0';
          wrong  <= (others => 0);
        end if;
        led(2) <= not empty(1);
        led(3) <= empty(1);
      end if;
    end if;
  end process;


  w_g : for i in wrong'range generate

    signal state_qty : state_qty_t := waiting;

    attribute MARK_DEBUG of state_qty : signal is "TRUE";

  begin
    process(clk)
    begin
      if rising_edge(clk) then
        if reset = '1' or buttons(3) = '0' then
          state_qty       <= waiting;
          total_idelay(i) <= 0;
        else
          if idelay_ldd = '1' then
            case state_qty is

              when waiting =>
                if empty(0) = '0' then
                  state_qty <= bads;
                end if;

              when bads =>
                if wrong(i) = 0 then
                  state_qty       <= good;
                  total_idelay(i) <= idelay_last;
                end if;

              when good =>
                if wrong(i) /= 0 then
                  state_qty       <= bade;
                  total_idelay(i) <= total_idelay(i) + idelay_last;
                elsif idelay_last = 31 then
                  state_qty       <= complete;
                  total_idelay(i) <= total_idelay(i) + 31;
                end if;

              when bade =>
                if idelay_last = 31 then
                  state_qty <= complete;
                end if;

              when complete =>
                state_qty <= complete;

            end case;
          end if;
        end if;
      end if;
    end process;
  end generate;

end architecture;
