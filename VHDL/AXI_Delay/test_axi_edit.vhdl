-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the edit mechanism for an AXI Data Stream.
--
-- P A Abbey, 2 March 2023
--
-------------------------------------------------------------------------------------

entity test_axi_edit is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library local;
  use local.testbench_pkg.all;
library osvvm;
  context osvvm.OsvvmContext;
--  use osvvm.ScoreboardPkg_slv.all;
library osvvm_axi4 ;
  context osvvm_axi4.AxiStreamContext;

architecture test of test_axi_edit is

  constant timeout           : time     := 36 us;
  constant data_width_c      : positive := 16;
  constant max_loops_c       : positive := 2048;
  constant axi_param_width_c : integer  := 1;
  constant clk_period_c      : time     := 10 ns;

  type axi_op_t is (
    pass,  -- Usual
    pause, -- Done
    swap,  -- Easy
    drop,
    insert
  );

  signal clk         : std_logic;
  signal s_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal s_axi_valid : std_logic                                 := '0';
  signal s_axi_ready : std_logic                                 := '0';
  signal s_axi_rd    : std_logic                                 := '1';
  signal alt_data    : std_logic_vector(data_width_c-1 downto 0) := (others => '1');
  signal alt_valid   : std_logic                                 := '0';
  signal alt_ready   : std_logic                                 := '0';
  signal m_axi_wr    : std_logic                                 := '1';
  signal m_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid : std_logic                                 := '0';
  signal m_axi_ready : std_logic                                 := '0';

  signal sb        : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
  signal complete  : std_logic := '0' ;
  signal TestStart : std_logic := '0' ;
  signal TestDone  : std_logic := '0' ;
  
  signal debug : std_logic := '0';

  signal StreamTxRec, StreamRxRec : StreamRecType(
    DataToModel(data_width_c-1 downto 0),
    ParamToModel(axi_param_width_c-1 downto 0),
    DataFromModel(data_width_c-1 downto 0),
    ParamFromModel(axi_param_width_c-1 downto 0)
  );

--  function op_conv(op : axi_op_t) return std_logic_vector is
--  begin
--    case op is                 -- RW
--      when pause       => return "00";
--      when insert      => return "01";
--      when drop        => return "10";
--      when pass | swap => return "11";
--    end case;
--  end function;

begin

  --clkgen : clock(clk, clk_period_c);
  CreateClock(clk, clk_period_c);
--  CreateReset(
--    Reset       => resetn,
--    ResetActive => '0',
--    Clk         => clk,
--    Period      => 4 * clk_period_c,
--    tpd         => 0 ns
--  );

--  axis_rx : AxiStreamReceiver
--    generic map (
--      tperiod_Clk => clk_period_c
--    )
--    port map (
--      Clk      => clk,
--      nReset   => resetn,
--      TValid   => TValid,
--      TReady   => TReady,
--      TID      => open,
--      TDest    => open,
--      TUser    => open,
--      TData    => TData,
--      TStrb    => open,
--      TKeep    => open,
--      TLast    => TLast,
--      TransRec => StreamRxRec
--    );


  axi_delay_i : entity work.axi_edit
    generic map (
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => s_axi_data,
      s_axi_valid => s_axi_valid,
      s_axi_rd    => s_axi_rd,
      s_axi_ready => s_axi_ready,
      alt_data    => alt_data, -- Alternative data source for m_axi_wr, e.g. swap and insert
      alt_valid   => alt_valid,
      alt_ready   => alt_ready,
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_wr    => m_axi_wr,
      m_axi_ready => m_axi_ready
    );


--  axis_tx : AxiStreamTransmitter
--    generic map (
--      tperiod_Clk => clk_period_c
--    )
--    port map (
--      Clk      => clk,
--      nReset   => resetn,
--      TValid   => TValid,
--      TReady   => TReady,
--      TID      => open,
--      TDest    => open,
--      TUser    => open,
--      TData    => TData,
--      TStrb    => open,
--      TKeep    => open,
--      TLast    => open,
--      TransRec => StreamTxRec
--    );

  debug_p : process(all)
  begin
    if s_axi_valid'last_value = '1' and s_axi_valid'last_value = '1' and
       m_axi_valid            = '1' and m_axi_ready            = '0' and
       s_axi_rd               = '0' and m_axi_wr               = '1' then
      debug <= '1';
    else
      debug <= '0';
    end if;
  end process;

  source : process
    variable i          : natural := 1;
    variable j          : natural := 16#FFFF#;
    variable op         : axi_op_t;
    variable axi_data_v : std_logic_vector(s_axi_data'range);
    variable alt_data_v : std_logic_vector(alt_data'range);
  begin
    SetAlertLogName("AXI_Edit");
    sb          <= osvvm.ScoreboardPkg_slv.NewID("AXI_Data");
    s_axi_data  <= std_logic_vector(to_unsigned(j, s_axi_data'length));
    j           := j - 1;
    s_axi_valid <= '0';
    wait_nr_ticks(clk, 1);
    WaitForBarrier(TestStart);

    for k in 1 to max_loops_c loop
      s_axi_valid <= '0';
      wait_rndr_ticks(clk, 0.25);
      if (i < 5) or (i mod 5) /= 0 then
        op := pass;
      else
        op := axi_op_t'val(random_integer(0, 4));
      end if;

      case op is

        when pause =>
          s_axi_rd <= '0';
          m_axi_wr <= '0';
          wait_rndr_ticks(clk, 3, 5);

        when insert =>
          s_axi_rd   <= '0';
          m_axi_wr   <= '1';
          alt_valid  <= '1';
          alt_data_v := std_logic_vector(to_unsigned(j, alt_data'length));
          alt_data   <= alt_data_v;
          osvvm.ScoreboardPkg_slv.Push(sb, alt_data_v);
          j := j - 1;
          wait_nf_ticks(clk, 1);
          wait_until(alt_ready, '1');
          wait_nr_ticks(clk, 1);
          alt_valid <= '0';

        when drop =>
          s_axi_rd    <= '1';
          m_axi_wr    <= '0';
          s_axi_valid <= '1';
          axi_data_v  := std_logic_vector(to_unsigned(i, s_axi_data'length));
          s_axi_data  <= axi_data_v;
          i           := i + 1;
          wait_nf_ticks(clk, 1);
          wait_until(s_axi_ready, '1');
          wait_nr_ticks(clk, 1);

        when pass =>
          s_axi_rd    <= '1';
          m_axi_wr    <= '1';
          s_axi_valid <= '1';
          axi_data_v  := std_logic_vector(to_unsigned(i, s_axi_data'length));
          s_axi_data  <= axi_data_v;
          osvvm.ScoreboardPkg_slv.Push(sb, axi_data_v);
          i := i + 1;
          wait_nf_ticks(clk, 1);
          wait_until(s_axi_ready, '1');
          wait_nr_ticks(clk, 1);

        when swap =>
          s_axi_rd    <= '1';
          m_axi_wr    <= '1';
          alt_valid   <= '1';
          alt_data_v  := std_logic_vector(to_unsigned(j, alt_data'length));
          alt_data    <= alt_data_v;
          j           := j - 1;
          osvvm.ScoreboardPkg_slv.Push(sb, alt_data_v);
          s_axi_valid <= '1';
          axi_data_v  := std_logic_vector(to_unsigned(i, s_axi_data'length));
          s_axi_data  <= axi_data_v;
          i           := i + 1;
          wait_nf_ticks(clk, 1);
          wait_until(s_axi_ready, '1');
          wait_nr_ticks(clk, 1);
          alt_valid <= '0';

      end case;

    end loop;
    s_axi_valid <= '0';
    complete    <= '1';
    wait_nr_ticks(clk, 1);
    WaitForBarrier(TestDone);

    wait;
  end process;


  sink : process
  begin
    m_axi_ready <= '0';
    WaitForBarrier(TestStart);
    wait_nr_ticks(clk, 10);

    while complete = '0' loop
      m_axi_ready <= '0';
      wait_rndr_ticks(clk, 0.1);
      m_axi_ready <= '1';
      wait_nf_ticks(clk, 1);
      if m_axi_valid /= '1' then
        wait until m_axi_valid = '1' or complete = '1';
        if complete = '1' then
          exit;
        end if;
      end if;
      osvvm.ScoreboardPkg_slv.Check(sb, m_axi_data);
      wait_nr_ticks(clk, 1);
    end loop;
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 1);
    WaitForBarrier(TestDone, timeout);
    AlertIf(now >= timeout, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    EndOfTestReports;
    std.env.stop(GetAlertCount);

    wait;
  end process;

end architecture;
