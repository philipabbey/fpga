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
  generic(
    seed_g : integer := 5
  );
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library osvvm;
  context osvvm.OsvvmContext;
--  use osvvm.ScoreboardPkg_slv.all;
library osvvm_axi4;
  context osvvm_axi4.AxiStreamContext;

architecture test of test_axi_edit is

  constant timeout              : time     := 36 us;
  constant data_width_c         : positive := 16;
  constant axi_tuser_width_tx_c : integer  := 2;
  constant axi_tuser_width_rx_c : integer  := 0;
  constant clk_period_c         : time     := 10 ns;
  constant default_delay_c      : time     := 1 ps;

  type axi_op_t is (
    pass,
    pause,
    swap,
    drop,
    insert
  );

  type trans_arr_t is array(
    axi_op_t'pos(axi_op_t'low) to axi_op_t'pos(axi_op_t'high),
    axi_op_t'pos(axi_op_t'low) to axi_op_t'pos(axi_op_t'high)
  ) of natural;
  -- Check each type of transition is covered, 5^2 = 25
  -- {axi_op_t x axi_op_t}
  --
  constant trans_arr : trans_arr_t := (
    --                       pass, pause, swap, drop, insert
    axi_op_t'pos(pass)   => (  10,    10,   10,   10,   10 ),
    axi_op_t'pos(pause)  => (  10,     2,    2,    2,    2 ),
    axi_op_t'pos(swap)   => (  10,     2,    2,    2,    2 ),
    axi_op_t'pos(drop)   => (  10,     2,    2,    2,    2 ),
    axi_op_t'pos(insert) => (  10,     2,    2,    2,    2 )
  );

  package axis_tx_pkg is new osvvm_axi4.AxiStreamGenericSignalsPkg
    generic map (
      AXI_DATA_WIDTH  => data_width_c,
      AXI_BYTE_WIDTH  => data_width_c/8,
      TID_MAX_WIDTH   => 0,
      TDEST_MAX_WIDTH => 0,
      TUSER_MAX_WIDTH => axi_tuser_width_tx_c
    );

  package axis_alt_pkg is new osvvm_axi4.AxiStreamGenericSignalsPkg
    generic map (
      AXI_DATA_WIDTH  => data_width_c,
      AXI_BYTE_WIDTH  => data_width_c/8,
      TID_MAX_WIDTH   => 0,
      TDEST_MAX_WIDTH => 0,
      TUSER_MAX_WIDTH => axi_tuser_width_tx_c
    );

  package axis_rx_pkg is new osvvm_axi4.AxiStreamGenericSignalsPkg
    generic map (
      AXI_DATA_WIDTH  => data_width_c,
      AXI_BYTE_WIDTH  => data_width_c/8,
      TID_MAX_WIDTH   => 0,
      TDEST_MAX_WIDTH => 0,
      TUSER_MAX_WIDTH => axi_tuser_width_rx_c
    );

  signal clk       : std_logic := '0';
  signal resetn    : std_logic := '0';
  signal s_axi_rd  : std_logic := '1'; -- After selecting them from the AXI VC's
  signal m_axi_wr  : std_logic := '1'; -- After selecting them from the AXI VC's
  signal op_now    : axi_op_t;

  signal sb        : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
  signal edit_cov  : CoverageIDType;
  signal trans_cov : CoverageIDType;
  signal valid_cov : CoverageIDType;
  signal ready_cov : CoverageIDType;
  signal complete  : std_logic := '0';
  signal TestStart : std_logic := '0';
  signal TestDone  : std_logic := '0';

  signal StreamTxRec, StreamAltRec : StreamRecType(
    DataToModel(data_width_c-1 downto 0),
    ParamToModel(axi_tuser_width_tx_c downto 0),  -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
    DataFromModel(data_width_c-1 downto 0),
    ParamFromModel(axi_tuser_width_tx_c downto 0) -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
  );

  signal StreamRxRec : StreamRecType(
    DataToModel(data_width_c-1 downto 0),
    ParamToModel(axi_tuser_width_rx_c downto 0),  -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
    DataFromModel(data_width_c-1 downto 0),
    ParamFromModel(axi_tuser_width_rx_c downto 0) -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
  );

  function getop(
    rd  : std_logic;
    wr  : std_logic;
    alt : std_logic
  ) return axi_op_t is
  begin
    case to_bitvector(rd & wr) is

      when "00" =>
        return pause;

      when "01" =>
        return insert;

      when "10" =>
        return drop;

      when "11" =>
        if alt = '1' then
          return swap;
        else
          return pass;
        end if;

    end case;
  end function;

  function opconv(op : axi_op_t) return std_logic_vector is
  begin
    case op is
      when pause       => return "00";
      when insert      => return "01";
      when pass | swap => return "11";
      when drop        => return "10";
    end case;
  end function;

begin

  -- Debug, visual sugar for the waveform
  op_now <= getop(s_axi_rd, m_axi_wr, axis_alt_pkg.TValid);

  CreateClock(clk, clk_period_c);

  CreateReset(
    Reset       => resetn,
    ResetActive => '0',
    Clk         => clk,
    Period      => 4 * clk_period_c,
    tpd         => 0 ns
  );


  axis_tx : entity osvvm_axi4.AxiStreamTransmitter
    generic map (
      INIT_ID       => axis_tx_pkg.INIT_ID,
      INIT_DEST     => axis_tx_pkg.INIT_DEST,
      INIT_USER     => "00", --axis_tx_pkg.INIT_USER,
      INIT_LAST     => 0,
      DEFAULT_DELAY => default_delay_c,
      tperiod_Clk   => clk_period_c
    )
    port map (
      Clk      => clk,
      nReset   => resetn,
      TValid   => axis_tx_pkg.TValid,
      TReady   => axis_tx_pkg.TReady,
      TID      => axis_tx_pkg.TID,
      TDest    => axis_tx_pkg.TDest,
      TUser    => axis_tx_pkg.TUser,
      TData    => axis_tx_pkg.TData,
      TStrb    => axis_tx_pkg.TStrb,
      TKeep    => axis_tx_pkg.TKeep,
      TLast    => axis_tx_pkg.TLast,
      TransRec => StreamTxRec
    );


  axis_alt : entity osvvm_axi4.AxiStreamTransmitter
    generic map (
      INIT_ID       => axis_tx_pkg.INIT_ID,
      INIT_DEST     => axis_tx_pkg.INIT_DEST,
      INIT_USER     => "00", --axis_tx_pkg.INIT_USER,
      INIT_LAST     => 0,
      DEFAULT_DELAY => default_delay_c,
      tperiod_Clk   => clk_period_c
    )
    port map (
      Clk      => clk,
      nReset   => resetn,
      TValid   => axis_alt_pkg.TValid,
      TReady   => axis_alt_pkg.TReady,
      TID      => axis_alt_pkg.TID,
      TDest    => axis_alt_pkg.TDest,
      TUser    => axis_alt_pkg.TUser,
      TData    => axis_alt_pkg.TData,
      TStrb    => axis_alt_pkg.TStrb,
      TKeep    => axis_alt_pkg.TKeep,
      TLast    => axis_alt_pkg.TLast,
      TransRec => StreamAltRec
    );


  (s_axi_rd, m_axi_wr) <= axis_alt_pkg.TUser when axis_alt_pkg.TValid = '1' else
                          axis_tx_pkg.TUser  when axis_tx_pkg.TValid  = '1' else
                          "00";

  axi_edit_i : entity work.axi_edit
    generic map (
      data_width_g => data_width_c
    )
    port map (
      clk         => clk,
      s_axi_data  => axis_tx_pkg.TData,
      s_axi_valid => axis_tx_pkg.TValid,
      s_axi_rd    => s_axi_rd,
      s_axi_ready => axis_tx_pkg.TReady,
      alt_data    => axis_alt_pkg.TData, -- Alternative data source for m_axi_wr, e.g. swap and insert
      alt_valid   => axis_alt_pkg.TValid,
      alt_ready   => axis_alt_pkg.TReady,
      m_axi_data  => axis_rx_pkg.TData,
      m_axi_valid => axis_rx_pkg.TValid,
      m_axi_wr    => m_axi_wr,
      m_axi_ready => axis_rx_pkg.TReady
    );


  axis_rx : entity osvvm_axi4.AxiStreamReceiver
    generic map (
      INIT_ID       => axis_rx_pkg.INIT_ID,
      INIT_DEST     => axis_rx_pkg.INIT_DEST,
      INIT_USER     => axis_rx_pkg.INIT_USER,
      INIT_LAST     => 0,
      DEFAULT_DELAY => default_delay_c,
      tperiod_Clk   => clk_period_c
    )
    port map (
      Clk      => clk,
      nReset   => resetn,
      TValid   => axis_rx_pkg.TValid,
      TReady   => axis_rx_pkg.TReady,
      TID      => axis_rx_pkg.TID,
      TDest    => axis_rx_pkg.TDest,
      TUser    => axis_rx_pkg.TUser,
      TData    => axis_rx_pkg.TData,
      TStrb    => axis_rx_pkg.TStrb,
      TKeep    => axis_rx_pkg.TKeep,
      TLast    => axis_rx_pkg.TLast,
      TransRec => StreamRxRec
    );


  setup : process

    function pad_string(
      str : string;
      len : positive
    ) return string is
      variable ret   : string(1 to len) := (others => ' ');
      alias    str_a : string(1 to str'length) is str;
    begin
      if len >= str'length then
        -- Pad with spaces
        ret(str_a'range) := str_a;
        return ret;
      else
        -- Truncate
        return str_a(1 to len);
      end if;
    end function;

  begin
    edit_cov  <= NewID("Edit AXI Stream");
    trans_cov <= NewID("All pair transitions");
    valid_cov <= NewID("Tx AXI Valid COverage");
    ready_cov <= NewID("Rx AXI Ready Coverage");
    wait for 0 ns;
    InitSeed(edit_cov,  seed_g);
    InitSeed(valid_cov, seed_g+1);
    InitSeed(ready_cov, seed_g+2);
    SetAlertStopCount(ERROR, 2);
    SetAlertStopCount(FAILURE, 2);

    -- Edit actions
    AddBins(edit_cov, "Pass  ", 10, GenBin(axi_op_t'pos(pass)));
    AddBins(edit_cov, "Pause ", 10, GenBin(axi_op_t'pos(pause)));
    AddBins(edit_cov, "Swap  ", 10, GenBin(axi_op_t'pos(swap)));
    AddBins(edit_cov, "Drop  ", 10, GenBin(axi_op_t'pos(drop)));
    AddBins(edit_cov, "Insert", 10, GenBin(axi_op_t'pos(insert)));

    -- Check each type of transition is covered, 5^2 = 25
    for i in axi_op_t'pos(axi_op_t'low) to axi_op_t'pos(axi_op_t'high) loop
      for j in axi_op_t'pos(axi_op_t'low) to axi_op_t'pos(axi_op_t'high) loop
        AddCross(
          trans_cov,
          pad_string(axi_op_t'image(axi_op_t'val(i)), 6) & " -> " & pad_string(axi_op_t'image(axi_op_t'val(j)), 6),
          trans_arr(i, j),
          GenBin(i),
          GenBin(j)
        );
      end loop;
    end loop;

    -- AXI valid behaviour on transmitter (axis_tx)
    AddBins(valid_cov, "Tx No Delay      ", 1, GenBin(0));
    AddBins(valid_cov, "Tx 1 Clock Delay ", 3, GenBin(1));
    AddBins(valid_cov, "Tx 2 Clocks Delay", 1, GenBin(2));

    -- AXI ready behaviour on receiver (axis_rx)
    AddCross(ready_cov, "Rx No Delay  ", 4, GenBin(0, 1), GenBin(0));
    AddCross(ready_cov, "Rx Some Delay", 2, GenBin(0, 1), GenBin(1, 2));
    -- These don't appear in the reports and I can't see where they might be used.
    SetItemBinNames(ready_cov, "Rx Ready Before Valid", "Rx Valid Delay");

    WaitForBarrier(TestStart);

    WaitForBarrier(TestDone, timeout);
    AlertIf(now >= timeout, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

    SetReportOptions (
      WritePassFail   => ENABLED,
      WriteBinInfo    => ENABLED,
      WriteCount      => ENABLED,
      WriteAnyIllegal => ENABLED
    );

    BlankLine(1);
    WriteBin(edit_cov);
    BlankLine(1);
    WriteBin(trans_cov);
    BlankLine(1);
    WriteBin(valid_cov);
    BlankLine(1);
    WriteBin(ready_cov);
    BlankLine(1);
    EndOfTestReports;
    std.env.stop(GetAlertCount);

    wait;
  end process;


  source : process

    variable rand       : RandomPType;
    variable i          : natural := 1;
    variable j          : natural := 16#FFFF#;
    variable op         : axi_op_t;
    variable opi        : integer;
    variable del        : integer;
    variable axi_data_v : std_logic_vector(axis_tx_pkg.TData'range);
    variable alt_data_v : std_logic_vector(axis_alt_pkg.TData'range);

  begin
    SetAlertLogName("AXI Edit Coverage");
    sb <= osvvm.ScoreboardPkg_slv.NewID("AXI_Data");
    WaitForBarrier(TestStart);
    -- Make sure each Tx has been used before setting the TRANSMIT_VALID_DELAY_CYCLES option.
    SendAsync(StreamTxRec,  std_logic_vector(to_unsigned(0, data_width_c)), opconv(pass) & '0');
    Send     (StreamAltRec, std_logic_vector(to_unsigned(0, data_width_c)), opconv(pass) & '0');

    loop
      opi := GetRandPoint(edit_cov);
      op  := axi_op_t'val(opi);
      ICover(edit_cov, opi);
      TCover(trans_cov, opi);
      del := GetRandPoint(valid_cov);
      ICover(valid_cov, del);
      SetAxiStreamOptions(StreamTxRec,  TRANSMIT_VALID_DELAY_CYCLES, del);
      SetAxiStreamOptions(StreamAltRec, TRANSMIT_VALID_DELAY_CYCLES, del);

      case op is

        when pause =>
          WaitForClock(clk, rand.RandInt(3, 5));

        when insert =>
          alt_data_v := std_logic_vector(to_unsigned(j, data_width_c));
          j          := j - 1;
          osvvm.ScoreboardPkg_slv.Push(sb, alt_data_v);
          Send(StreamAltRec, alt_data_v, opconv(op) & '0');

        when drop =>
          axi_data_v := std_logic_vector(to_unsigned(i, data_width_c));
          i          := i + 1;
          Send(StreamTxRec, axi_data_v, opconv(op) & '0');

        when pass =>
          axi_data_v := std_logic_vector(to_unsigned(i, data_width_c));
          i          := i + 1;
          osvvm.ScoreboardPkg_slv.Push(sb, axi_data_v);
          Send(StreamTxRec, axi_data_v, opconv(op) & '0');

        when swap =>
          alt_data_v := std_logic_vector(to_unsigned(j, data_width_c));
          j          := j - 1;
          axi_data_v := std_logic_vector(to_unsigned(i, data_width_c));
          i          := i + 1;
          osvvm.ScoreboardPkg_slv.Push(sb, alt_data_v);
          SendAsync(StreamTxRec,  axi_data_v, opconv(op) & '0');
          Send     (StreamAltRec, alt_data_v, opconv(op) & '0');

      end case;

      exit when IsCovered(edit_cov) and IsCovered(trans_cov);

    end loop;
    complete <= '1';
    WaitForClock(clk, 1);
    WaitForBarrier(TestDone);

    wait;
  end process;


  sink : process
    variable before : natural range 0 to 1;
    variable delay  : natural range 0 to 2;
    variable ignore : std_logic_vector(15 downto 0);
  begin
    WaitForBarrier(TestStart);
    -- Throw away the initial values.
    Get(StreamRxRec, ignore);

    chk : while complete = '0' loop
      (before, delay) := GetRandPoint(ready_cov);
      ICover(ready_cov, (before, delay));
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, to_boolean(before));
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, delay);
      while osvvm.ScoreboardPkg_slv.Empty(sb) loop
        exit chk when complete = '1';
        WaitForClock(clk, 1);
      end loop;
      Check(StreamRxRec, osvvm.ScoreboardPkg_slv.Pop(sb));
    end loop;
    WaitForBarrier(TestDone);

    wait;
  end process;

  -- Silence the follow types of warnings in ModelSim:
  --
  -- # ** Warning: (vsim-8683) Uninitialized inout port /test_axi_edit/axis_tx/TransRec.DataToModel(15) has no driver.
  -- # This port will contribute value (U) to the signal network.
  --
  silence : block
  begin
    -- NB. These must be applied to "external signals", not Stream*Rec at this level or they have no effect
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.Rdy            <= 0;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.Operation      <= NOT_DRIVEN;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.DataToModel    <= (others => '0');
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.ParamToModel   <= (others => '0');
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.DataFromModel  <= (others => '0');
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.IntToModel     <= 0;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.BoolToModel    <= false;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.BoolFromModel  <= false;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.TimeToModel    <= 0 ns;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.TimeFromModel  <= 0 ns;
    <<signal .test_axi_edit.axis_tx.TransRec : StreamRecType >>.Options        <= 0;

    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.Rdy           <= 0;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.Operation     <= NOT_DRIVEN;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.DataToModel   <= (others => '0');
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.ParamToModel  <= (others => '0');
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.DataFromModel <= (others => '0');
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.IntToModel    <= 0;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.BoolToModel   <= false;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.BoolFromModel <= false;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.TimeToModel   <= 0 ns;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.TimeFromModel <= 0 ns;
    <<signal .test_axi_edit.axis_alt.TransRec : StreamRecType >>.Options       <= 0;

    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.Rdy            <= 0;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.Operation      <= NOT_DRIVEN;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.DataToModel    <= (others => '0');
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.ParamToModel   <= (others => '0');
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.DataFromModel  <= (others => '0');
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.IntToModel     <= 0;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.BoolToModel    <= false;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.TimeToModel    <= 0 ns;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.TimeFromModel  <= 0 ns;
    <<signal .test_axi_edit.axis_rx.TransRec : StreamRecType >>.Options        <= 0;
  end block;

end architecture;
