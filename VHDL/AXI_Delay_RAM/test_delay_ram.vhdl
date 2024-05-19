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

entity test_delay_ram is
  generic(
    seed_g : integer := 5
  );
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;
library osvvm;
  context osvvm.OsvvmContext;
library osvvm_axi4;
  context osvvm_axi4.AxiStreamContext;

architecture test of test_delay_ram is

  constant timeout              : time     := 16 us;
  constant clk_period_c         : time     := 10 ns;
  constant default_delay_c      : time     :=  1 ps;
  constant ram_addr_width_c     : positive :=  5;
  constant ram_data_width_c     : positive := 16;
  constant axi_tuser_width_rx_c : integer  :=  0;
  constant num_iterations_c     : positive :=  4;

  type ram_contents_t is array (natural range <>) of std_logic_vector;

  impure function ram_init(
    l : positive;
    w : positive
  ) return ram_contents_t is
    variable ret  : ram_contents_t(0 to l-1)(w-1 downto 0);
    variable rand : RandomPType;
  begin
    rand.InitSeed(seed_g+1);
    for i in 0 to l-1 loop
      -- Make this more interesting in due course
      ret(i) := to_slv(rand.RandInt(0, (2**ram_data_width_c)-1), ram_data_width_c);
    end loop;
    return ret;
  end function;

  constant ram_contents_c : ram_contents_t(0 to 2**ram_addr_width_c-1)(ram_data_width_c-1 downto 0)
    := ram_init(2**ram_addr_width_c, ram_data_width_c);

  package axis_rx_pkg is new osvvm_axi4.AxiStreamGenericSignalsPkg
    generic map (
      AXI_DATA_WIDTH  => ram_data_width_c,
      AXI_BYTE_WIDTH  => ram_data_width_c / 8,
      TID_MAX_WIDTH   => 0,
      TDEST_MAX_WIDTH => 0,
      TUSER_MAX_WIDTH => axi_tuser_width_rx_c
    );

  signal clk          : std_logic                                     := '0';
  signal reset        : std_logic                                     := '1';
  signal resetn       : std_logic                                     := '0';
  signal run          : std_logic                                     := '0';
  signal ram_addr     : std_logic_vector(ram_addr_width_c-1 downto 0) := (others => '0');
  signal ram_wr_data  : std_logic_vector(ram_data_width_c-1 downto 0) := (others => '0');
  signal ram_wr_en    : std_logic                                     := '0';
  signal ram_rd_en    : std_logic                                     := '0';
  signal ram_rd_data  : std_logic_vector(ram_data_width_c-1 downto 0) := (others => '0');
  signal ram_rd_valid : std_logic                                     := '0';
  signal ready_cov    : CoverageIDType;
  signal CheckRAM     : std_logic                                     := '0';
  signal TestStart    : std_logic                                     := '0';
  signal TestDone     : std_logic                                     := '0';
  signal complete     : std_logic                                     := '0';

  signal StreamRxRec : StreamRecType(
    DataToModel(ram_data_width_c-1 downto 0),
    ParamToModel(axi_tuser_width_rx_c downto 0),  -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
    DataFromModel(ram_data_width_c-1 downto 0),
    ParamFromModel(axi_tuser_width_rx_c downto 0) -- Total LENGTH: TID'length + TDest'length + TUser'length + 1;
  );

begin

  CreateClock(clk, clk_period_c);

  CreateReset(
    Reset       => reset,
    ResetActive => '1',
    Clk         => clk,
    Period      => 4 * clk_period_c,
    tpd         => 0 ns
  );

  CreateReset(
    Reset       => resetn,
    ResetActive => '0',
    Clk         => clk,
    Period      => 4 * clk_period_c,
    tpd         => 0 ns
  );


  axi_delay_ram_i : entity work.axi_delay_ram
    generic map (
      ram_addr_width_g => ram_addr_width_c,
      ram_data_width_g => ram_data_width_c
    )
    port map (
      clk          => clk,
      reset        => reset,
      run          => run,
      ram_addr     => ram_addr,
      ram_wr_data  => ram_wr_data,
      ram_wr_en    => ram_wr_en,
      ram_rd_en    => ram_rd_en,
      ram_rd_data  => ram_rd_data,
      ram_rd_valid => ram_rd_valid,
      item_tdata   => axis_rx_pkg.TData,
      item_tvalid  => axis_rx_pkg.TValid,
      item_tready  => axis_rx_pkg.TReady
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
  begin
    ready_cov <= NewID("Rx AXI Ready Coverage");
    wait for 0 ns;
    InitSeed(ready_cov, seed_g);
    SetAlertStopCount(ERROR, 2);
    SetAlertStopCount(FAILURE, 2);
    -- Flip this to see what is happening inside the AXI-S Rx Bus Functional Model
    SetLogEnable(<< signal axis_rx.ModelID : AlertLogIDType >>, DEBUG, false);

    -- AXI ready behaviour on receiver (axis_rx)
    AddCross(ready_cov, "Rx No Delay  ", 10, GenBin(1), GenBin(0));
    AddCross(ready_cov, "Rx Some Delay",  1, GenBin(1), GenBin(1, 3));
    --                 No need for GenBin(0) ^^^^^^^^ here as data is always ready since it is replayed from a RAM
    -- These don't appear in the reports and I can't see where they might be used.
    SetItemBinNames(ready_cov, "Rx Ready Before Valid", "Rx Valid Delay");

    WaitForBarrier(TestStart);

    WaitForBarrier(TestDone, timeout);
    WaitForClock(clk, 10);
    AlertIf(now >= timeout, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

    SetReportOptions (
      WritePassFail   => ENABLED,
      WriteBinInfo    => ENABLED,
      WriteCount      => ENABLED,
      WriteAnyIllegal => ENABLED
    );

    BlankLine(1);
    WriteBin(ready_cov);
    BlankLine(1);
    EndOfTestReports;
    std.env.stop(GetAlertCount);

    wait;
  end process;


  source : process
    variable rand : RandomPType;
  begin
    rand.InitSeed(seed_g+1);
    SetAlertLogName("AXI RAM Delay");
    WaitForClock(clk, 10);
    -- Initialise RAM
    ram_wr_en <= '1';
    for i in 0 to (2**ram_addr_width_c)-1 loop
      ram_addr    <= to_slv(i, ram_addr_width_c);
      ram_wr_data <= ram_contents_c(i);
      WaitForClock(clk, 1);
    end loop;
    ram_wr_en <= '0';
    WaitForClock(clk, 10);
    -- Readback RAM and check RAM
    WaitForBarrier(CheckRAM);
    ram_rd_en <= '1';
    for i in 0 to (2**ram_addr_width_c)-1 loop
      ram_addr <= to_slv(i, ram_addr_width_c);
      WaitForClock(clk, 1);
    end loop;
    ram_rd_en <= '0';
    WaitForClock(clk, 10);
    WaitForBarrier(TestStart);
    run <= '1';
    loop
      WaitForClock(clk, rand.RandInt(10, 20));
      run <= '0';
      exit when complete = '1';
      WaitForClock(clk, rand.RandInt(4, 8));
      run <= '1';
    end loop;
    run <= '0';
    WaitForBarrier(TestDone);

    wait;
  end process;


  sink : process
    variable before : natural range 0 to 1;
    variable delay  : natural range 0 to 2;
  begin
    -- These forces are required because OSVVM sets enacts them before the 'SetAxiStreamOptions()' calls take effect.
    << signal axis_rx.ReceiveReadyBeforeValid : boolean >> <= force false;
    << signal axis_rx.ReceiveReadyDelayCycles : integer >> <= force 10;
    SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, false);
    -- Lets the initial values trickle through the AXI-S delay line
    SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, 10);
    << signal axis_rx.ReceiveReadyBeforeValid : boolean >> <= release;
    << signal axis_rx.ReceiveReadyDelayCycles : integer >> <= release;

    WaitForBarrier(CheckRAM);
    WaitForLevel(ram_rd_valid, '1');
    wait for clk_period_c / 2;
    for i in 0 to (2**ram_addr_width_c)-1 loop
      AffirmIf(
        condition       => ram_rd_data = ram_contents_c(i),
        ReceivedMessage => "RAM contents check: ram_rd_data = 0x" & to_hstring(ram_rd_data),
        ExpectedMessage => ", expected = 0x" & to_hstring(ram_contents_c(i)),
        Enable          => IsLogEnabled(INFO)
      );
      -- Stay in the eye of the data. Annoyingly OSVVM does not allow for both wait for rising edge
      -- as well as wait for falling edge clocks without amending constants.
      wait for clk_period_c;
    end loop;

    WaitForBarrier(TestStart);
    Log("Starting AXI-S RAM Delay checking.", ALWAYS);
    WaitForLevel(run, '1');

    for i in 0 to (num_iterations_c * 2**ram_addr_width_c)-1 loop
      (before, delay) := GetRandPoint(ready_cov);
      ICover(ready_cov, (before, delay));
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_BEFORE_VALID, to_boolean(before));
      SetAxiStreamOptions(StreamRxRec, RECEIVE_READY_DELAY_CYCLES, delay);
      Check(StreamRxRec, ram_contents_c(i mod 2**ram_addr_width_c));
    end loop;
    complete <= '1';
    WaitForBarrier(TestDone);

    wait;
  end process;

  -- Silence the follow types of warnings in ModelSim:
  --
  -- # ** Warning: (vsim-8683) Uninitialized inout port /test_axi_edit/axis_tx/TransRec.DataToModel(15) has no driver.
  -- # This port will contribute value (U) to the signal network.
  --
  OSVVM_Common.StreamTransactionPkg.ReleaseTransactionRecord(
      << signal axis_rx.TransRec : OSVVM_Common.StreamTransactionPkg.StreamRecType >>
  );

end architecture;
