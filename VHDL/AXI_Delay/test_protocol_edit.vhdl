-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test for the demonstrator for editing a protocol in a stream of bytes sent over
-- AXI.
--
-- References:
--  1. AXI Stream Protocol Editing
--     https://blog.abbey1.org.uk/index.php/technology/axi-stream-protocol-editing
--  2. AXI Stream General Edit
--     https://blog.abbey1.org.uk/index.php/technology/axi-stream-general-edit
--
-- P A Abbey, 24 March 2023
--
-------------------------------------------------------------------------------------

entity test_protocol_edit is
  generic(
    seed_g : integer := 5
  );
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library std;
  use std.textio.all;
library osvvm;
  context osvvm.OsvvmContext;
library osvvm_axi4;
  context osvvm_axi4.AxiStreamContext;
library work;
  use work.ScoreBoardPkg_char;
  use work.char_utils_pkg.all;

architecture test of test_protocol_edit is

  constant timeout              : time     := 10 us;
  constant data_width_c         : positive := 8;
  constant axi_tuser_width_tx_c : integer  := 0;
  constant axi_tuser_width_rx_c : integer  := 0;
  constant clk_period_c         : time     := 10 ns;
  constant default_delay_c      : time     := 1 ps;
  -- Set to true to remove AXI timing and see the pattern of processing more clearly
  constant fast_forward_c       : boolean  := false;

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

  signal sb        : ScoreBoardPkg_char.ScoreboardIDType;
  signal data_cov  : CoverageIDType;
  signal valid_cov : CoverageIDType;
  signal ready_cov : CoverageIDType;
  signal complete  : std_logic := '0';
  signal TestStart : std_logic := '0';
  signal TestDone  : std_logic := '0';

  signal StreamTxRec : StreamRecType(
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

begin

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
      INIT_USER     => axis_tx_pkg.INIT_USER,
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


  protocol_edit_i : entity work.protocol_edit
    port map (
      clk         => clk,
      s_axi_data  => axis_tx_pkg.TData,
      s_axi_valid => axis_tx_pkg.TValid,
      s_axi_ready => axis_tx_pkg.TReady,
      m_axi_data  => axis_rx_pkg.TData,
      m_axi_valid => axis_rx_pkg.TValid,
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

    constant start_symbols_c : string := "ACEGZIKMOQRSTUV";

  begin
    data_cov  <= NewID("Data Coverage");
    valid_cov <= NewID("Tx AXI Valid Coverage");
    ready_cov <= NewID("Rx AXI Ready Coverage");
    wait for 0 ns;
    InitSeed(data_cov,  seed_g);
    InitSeed(valid_cov, seed_g+1);
    InitSeed(ready_cov, seed_g+2);
    SetAlertStopCount(ERROR, 2);
    SetAlertStopCount(FAILURE, 2);

    for i in start_symbols_c'range loop
      AddBins(data_cov, "Letter '" & start_symbols_c(i) & "'", 5, GenBin(character'pos(start_symbols_c(i))));
    end loop;

    -- AXI valid behaviour on transmitter (axis_tx)
    AddBins(valid_cov, "Tx No Delay      ", 2, GenBin(0));
    AddBins(valid_cov, "Tx 1 Clock Delay ", 3, GenBin(1));
    AddBins(valid_cov, "Tx 2 Clocks Delay", 1, GenBin(2));

    -- AXI ready behaviour on receiver (axis_rx)
    AddCross(ready_cov, "Rx No Delay  ", 2, GenBin(0, 1), GenBin(0));
    AddCross(ready_cov, "Rx Some Delay", 1, GenBin(0, 1), GenBin(1, 2));
    -- These don't appear in the reports and I can't see where they might be used.
    SetItemBinNames(ready_cov, "Rx Ready Before Valid", "Rx Valid Delay");

    WaitForBarrier(TestStart);
    AlertIf(fast_forward_c, "Final testing must be completed without fast forward.", WARNING);

    WaitForBarrier(TestDone, timeout);
    AlertIf(now >= timeout, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

    SetReportOptions (
      WritePassFail   => ENABLED,
      WriteBinInfo    => ENABLED,
      WriteCount      => ENABLED,
      WriteAnyIllegal => ENABLED
    );

    if not fast_forward_c then
      BlankLine(1);
      WriteBin(data_cov);
      BlankLine(1);
      WriteBin(valid_cov);
      BlankLine(1);
      WriteBin(ready_cov);
      BlankLine(1);
    end if;
    EndOfTestReports;
    std.env.stop(GetAlertCount);

    wait;
  end process;

  -- Test sequences:
  --
  -- Convention is to use capital letters as a trigger for an action.
  --
  -- 1. Swap a sequence from character A until character B with 'y' characters
  --    a. aaaAxxxBbbb => aaaAyyyBbbb, retain A & B characters
  --    b. aaaCxxxDbbb => aaayyyDbbb,  use D as the stop character
  --    c. aaaExxxFbbb => aaaEyyybbb,  use E as the start character
  --    d. aaaGxxxHbbb => aaayyybbb,   drop G & H characters
  --
  -- 2. Delete a single character
  --    a. aZb => ab
  -- 3. Delete sequence from character I until character J
  --    a. aaaIxxxJbbb => aaaIJbbb, retain I & J characters
  --    b. aaaKxxxLbbb => aaaLbbb,  use L as the stop character
  --    c. aaaMxxxNbbb => aaaMbbb,  use M as the start character
  --    d. aaaOxxxPbbb => aaabbb,   drop O & P characters
  --
  -- 4. Insert a character
  --    a. aaaQbbb => aaayQbbb, before
  --    b. aaaRbbb => aaaRybbb, after
  -- 5. Insert sequence
  --    a. aaaSbbb => aaayyySbbb, before character
  --    b. aaaTbbb => aaaTyyybbb, after character
  --    c. aaaUbbb => aaayyybbb,  instead of character
  --    d. aaVWbb  => aaVyyyWbb,  between V and W
  --
  source : process

    variable i          : positive;
    variable char       : integer range 0 to 255;
    variable del        : integer;
    variable data_array : line;
    variable rand       : RandomPType;

    impure function char_seq(n : natural) return string is
      variable ret : string(1 to n);
    begin
      if n > 0 then
        for i in ret'range loop
          ret(i) := character'val(rand.RandInt(character'pos('a'), character'pos('z')));
        end loop;
        return ret;
      else
        return "";
      end if;
    end function;

    impure function data_seq(c : character) return line is
      variable ret : line;
    begin
      case c is
        when 'A' =>
          write(ret, 'A');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'B');
        when 'C' =>
          write(ret, 'C');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'D');
        when 'E' =>
          write(ret, 'E');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'F');
        when 'G' =>
          write(ret, 'G');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, character'('H'));
        when 'Z' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, character'('Z'));
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'I' =>
          write(ret, 'I');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'J');
        when 'K' =>
          write(ret, 'K');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, character'('L'));
        when 'M' =>
          write(ret, 'M');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'N');
        when 'O' =>
          write(ret, 'O');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'P');
        when 'Q' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'Q');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'R' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'R');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'S' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'S');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'T' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, 'T');
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'U' =>
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
          write(ret, character'('U'));
          write(ret, char_seq(rand.RandInt(0, 3))); -- 0..3 Random lowercase characters
        when 'V' =>
          write(ret, string'("VW"));
        when others =>
          report "Character '" & c & "' not a valid choice." severity failure;
      end case;
      return ret;
    end function;

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
    SetAlertLogName("Protocol Coverage");
    sb <= ScoreBoardPkg_char.NewID("AXI_Data");
    WaitForBarrier(TestStart);
    if fast_forward_c then
      SetAxiStreamOptions(StreamTxRec, TRANSMIT_VALID_DELAY_CYCLES, 0);
    end if;
    -- Make sure each Tx has been used before setting the TRANSMIT_VALID_DELAY_CYCLES option.
    Send(StreamTxRec,char2vec('-'));

    loop
      char := GetRandPoint(data_cov);
      ICover(data_cov, char);
      data_array := data_seq(character'val(char));
      Log("Data Sequence: " & pad_string("""" & data_array.all & """", 9)); -- Maximum pad is 4+1+4 from 'data_seq()'
      i := data_array.all'low;

      while i <= data_array.all'high loop
        if not fast_forward_c then
          del := GetRandPoint(valid_cov);
          ICover(valid_cov, del);
          SetAxiStreamOptions(StreamTxRec, TRANSMIT_VALID_DELAY_CYCLES, del);
        end if;

        case data_array(i) is

          -- Test 1
          when 'A' =>
            ScoreBoardPkg_char.Push(sb, 'A');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'B' loop
              ScoreBoardPkg_char.Push(sb, 'y');
              Send(StreamTxRec, char2vec(data_array(i)));
              i := i + 1;
            end loop;
            ScoreBoardPkg_char.Push(sb, 'B');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'C' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'D' loop
              ScoreBoardPkg_char.Push(sb, 'y');
              Send(StreamTxRec, char2vec(data_array(i)));
              i := i + 1;
            end loop;
            ScoreBoardPkg_char.Push(sb, 'D');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'E' =>
            ScoreBoardPkg_char.Push(sb, 'E');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'F' loop
              ScoreBoardPkg_char.Push(sb, 'y');
              Send(StreamTxRec, char2vec(data_array(i)));
              i := i + 1;
            end loop;
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'G' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'H' loop
              ScoreBoardPkg_char.Push(sb, 'y');
              Send(StreamTxRec, char2vec(data_array(i)));
              i := i + 1;
            end loop;
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          -- Test 2
          when 'Z' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          -- Test 3
          when 'I' =>
            ScoreBoardPkg_char.Push(sb, 'I');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'J' loop
              Send(StreamTxRec, char2vec(data_array(i)));
              -- Skip character
              i := i + 1;
            end loop;
            ScoreBoardPkg_char.Push(sb, 'J');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'K' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'L' loop
              Send(StreamTxRec, char2vec(data_array(i)));
              -- Skip character
              i := i + 1;
            end loop;
            ScoreBoardPkg_char.Push(sb, 'L');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'M' =>
            ScoreBoardPkg_char.Push(sb, 'M');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'N' loop
              Send(StreamTxRec, char2vec(data_array(i)));
              -- Skip character
              i := i + 1;
            end loop;
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'O' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            while data_array(i) /= 'P' loop
              Send(StreamTxRec, char2vec(data_array(i)));
              -- Skip character
              i := i + 1;
            end loop;
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          -- Test 4
          when 'Q' =>
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'Q');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'R' =>
            ScoreBoardPkg_char.Push(sb, 'R');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            ScoreBoardPkg_char.Push(sb, 'y');

          -- Test 5
          when 'S' =>
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'S');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when 'T' =>
            ScoreBoardPkg_char.Push(sb, 'T');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');

          when 'U' =>
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');

          when 'V' =>
            ScoreBoardPkg_char.Push(sb, 'V');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'y');
            ScoreBoardPkg_char.Push(sb, 'W');
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

          when others =>
            ScoreBoardPkg_char.Push(sb, data_array(i));
            Send(StreamTxRec, char2vec(data_array(i)));
            i := i + 1;

        end case;
      end loop;

      exit when IsCovered(data_cov);

    end loop;
    while not ScoreBoardPkg_char.Empty(sb) loop
      WaitForClock(clk, 1);
    end loop;
    complete <= '1';
    WaitForClock(clk, 3);
    WaitForBarrier(TestDone);

    wait;
  end process;


  sink : process

    variable before : natural range 0 to 1;
    variable delay  : natural range 0 to 2;
    variable rxd    : std_logic_vector(axis_rx_pkg.TData'range);

  begin
    WaitForBarrier(TestStart);
    -- Throw away the initial values.
    Get(StreamRxRec, rxd); -- '-' character
    if fast_forward_c then
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, true);
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, 0);
    end if;

    chk : while complete = '0' loop
      if not fast_forward_c then
        (before, delay) := GetRandPoint(ready_cov);
        ICover(ready_cov, (before, delay));
        SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, to_boolean(before));
        SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, delay);
      end if;
      while ScoreBoardPkg_char.Empty(sb) loop
        exit chk when complete = '1';
        WaitForClock(clk, 1);
      end loop;
      Get(StreamRxRec, rxd);
      -- Do the checking in the scoreboard so that the characters get printed instead of the hex of the vector/byte.
      ScoreBoardPkg_char.Check(sb, vec2char(rxd));
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
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.Rdy           <= 0;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.Operation     <= NOT_DRIVEN;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.DataToModel   <= (others => '0');
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.ParamToModel  <= (others => '0');
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.DataFromModel <= (others => '0');
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.IntToModel    <= 0;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.BoolToModel   <= false;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.BoolFromModel <= false;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.TimeToModel   <= 0 ns;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.TimeFromModel <= 0 ns;
    <<signal .test_protocol_edit.axis_tx.TransRec : StreamRecType>>.Options       <= 0;

    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.Rdy           <= 0;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.Operation     <= NOT_DRIVEN;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.DataToModel   <= (others => '0');
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.ParamToModel  <= (others => '0');
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.IntToModel    <= 0;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.BoolToModel   <= false;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.TimeToModel   <= 0 ns;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.TimeFromModel <= 0 ns;
    <<signal .test_protocol_edit.axis_rx.TransRec : StreamRecType>>.Options       <= 0;
  end block;

end architecture;
