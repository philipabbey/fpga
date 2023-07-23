-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Simplifying the use of XPM RAM, randomised test bench including error injection.
--
-- P A Abbey, 16 July 2023
--
-- Reference: https://docs.xilinx.com/r/en-US/ug953-vivado-7series-libraries/XPM_MEMORY_SDPRAM
--
-------------------------------------------------------------------------------------

entity test_dpram_err is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library osvvm;
  context osvvm.OsvvmContext;
library osvvm_axi4;
  context osvvm_axi4.AxiStreamContext;

architecture test of test_dpram_err is

  constant addr_bits_c   : positive := 9;
  constant data_bits_c   : positive := 64; -- Required for error injection testing
  constant clk_period_c  : time     := 10 ns;
  constant num_sb_errs_c : natural  := 40; -- Single bits errors
  constant num_db_errs_c : natural  := 20; -- Double bits errors

  signal clk            : std_logic                                := '0';
  signal reset          : std_logic                                := '0';
  signal ena            : std_logic                                := '0';
  signal wea            : std_logic                                := '0';
  signal addra          : std_logic_vector(addr_bits_c-1 downto 0) := (others => '0');
  signal dina           : std_logic_vector(data_bits_c-1 downto 0) := (others => '0');
  signal injectsbiterra : std_logic                                := '0';
  signal injectdbiterra : std_logic                                := '0';
  signal enb            : std_logic                                := '0';
  signal addrb          : std_logic_vector(addr_bits_c-1 downto 0) := (others => '1');
  signal doutb          : std_logic_vector(data_bits_c-1 downto 0) := (others => '0');
  signal doutv          : std_logic                                := '0';
  signal sbiterrb       : std_logic                                := '0';
  signal dbiterrb       : std_logic                                := '0';

  -- OSVVM
  signal setup       : std_logic := '0';
  signal written     : std_logic := '0';
  signal finished    : std_logic := '0';
  signal gap_cov     : CoverageIDType;
  signal wr_addr_cov : CoverageIDType;
  signal rd_addr_cov : CoverageIDType;
  signal err_cov     : CoverageIDType;
  signal sb          : osvvm.ScoreBoardPkg_slv.ScoreboardIDType;
  signal dbl_err_cnt : natural;

  -- Truncate or lengthen a vector 'v' to size 'n' bits.
  -- When lengthing, add '0's to the most significant end.
  --
  function resize(
    v : std_logic_vector;
    n : positive
  ) return std_logic_vector is
    -- Make no assumption about range bounds
    alias vi : std_logic_vector(v'length-1 downto 0) is v;
    variable ret : std_logic_vector(n-1 downto 0) := (others => '0');
  begin
    if n > v'length then
      ret(v'length-1 downto 0) := v;
      return ret;
    else
      return vi(n-1 downto 0);
    end if;
  end function;

begin

  CreateClock(clk, clk_period_c);

  CreateReset(
    Reset       => reset,
    ResetActive => '1',
    Clk         => clk,
    Period      => 4 * clk_period_c,
    tpd         => 0 ns
  );


  dut : entity work.dpram_err
    generic map (
      addr_bits_g => addr_bits_c,
      data_bits_g => data_bits_c
    )
    port map (
      clk            => clk,
      reset          => reset,
      ena            => ena,
      wea            => wea,
      addra          => addra,
      dina           => dina,
      injectsbiterra => injectsbiterra,
      injectdbiterra => injectdbiterra,
      enb            => enb,
      addrb          => addrb,
      doutb          => doutb,
      doutv          => doutv,
      sbiterrb       => sbiterrb,
      dbiterrb       => dbiterrb
    );


  setup_p : process
  begin
    gap_cov     <= NewID("Gap Coverage");
    wr_addr_cov <= NewID("Write Address Coverage");
    rd_addr_cov <= NewID("Read Address Coverage");
    err_cov     <= NewID("Bit Errors");
    sb          <= osvvm.ScoreBoardPkg_slv.NewID("RAM Data");
    wait for 0 ns;
    AddBins(gap_cov, "0..0", 19, GenBin(0));
    AddBins(gap_cov, "1..4",  1, GenBin(1, 4));
    AddBins(wr_addr_cov, "Each address once", 1, GenBin(0, 2**addr_bits_c-1));
    AddBins(rd_addr_cov, "Each address once", 1, GenBin(0, 2**addr_bits_c-1));
    -- Setup Error creation
    AddBins(err_cov, "No Bit Errors    ", 2**addr_bits_c-num_sb_errs_c-num_db_errs_c, GenBin(0));
    AddBins(err_cov, "Single Bit Errors", num_sb_errs_c,                              GenBin(1));
    AddBins(err_cov, "Double Bit Errors", num_db_errs_c,                              GenBin(2));

    WaitForBarrier(setup);
    WaitForBarrier(finished);
    WriteBin(gap_cov);
    BlankLine(1);
    WriteBin(err_cov);
    BlankLine(1);
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking.");
    -- Check this early, or the affirmation count increases!
    AffirmIf(GetAffirmCount = 2**addr_bits_c, "Not all addresses have been verified.");
    AffirmIf(dbl_err_cnt = num_db_errs_c, "Require that percisely " & to_string(num_db_errs_c) & " double errors are detected, counted " & to_string(dbl_err_cnt) & ".");
    EndOfTestReports;
    std.env.stop(GetAlertCount);
    wait;
  end process;


  write_p : process
    variable addra_v : natural;
    variable delay   : natural;
    variable be      : natural;
  begin
    ena            <= '0';
    wea            <= '0';
    addra          <= (others => '0');
    dina           <= (others => '0');
    injectsbiterra <= '0';
    injectdbiterra <= '0';
    WaitForBarrier(setup);
    WaitForClock(clk, 20);

    while not IsCovered(wr_addr_cov) loop
      addra_v := GetRandPoint(wr_addr_cov);
      ICover(wr_addr_cov, addra_v);
      be := GetRandPoint(err_cov);
      ICover(err_cov, be);
      addra          <= std_logic_vector(to_unsigned(addra_v, addr_bits_c));
      dina           <= resize(not(std_logic_vector(to_unsigned(addra_v, addr_bits_c))), data_bits_c);
      ena            <= '1';
      wea            <= '1';
      -- This ensures we don't have both single and double bit errors at the same time
      injectsbiterra <= '1' when be = 1 else '0';
      injectdbiterra <= '1' when be = 2 else '0';
      WaitForClock(clk, 1);
      ena   <= '0';
      wea   <= '0';
      delay := GetRandPoint(gap_cov);
      ICover(gap_cov, delay);
      WaitForClock(clk, delay);
    end loop;

    Log("Finished writing data to RAM.");
    WaitForBarrier(written);

    wait;
  end process;


  read_addr : process
    variable addrb_v : natural;
    variable delay   : natural;
  begin
    enb <= '0';
    WaitForBarrier(written);

    while not IsCovered(rd_addr_cov) loop
      addrb_v := GetRandPoint(rd_addr_cov);
      ICover(rd_addr_cov, addrb_v);
      addrb <= std_logic_vector(to_unsigned(addrb_v, addr_bits_c));
      enb   <= '1';
      osvvm.ScoreBoardPkg_slv.Push(sb, resize(not(std_logic_vector(to_unsigned(addrb_v, addr_bits_c))), data_bits_c));
      WaitForClock(clk, 1);
      enb   <= '0';
      delay := GetRandPoint(gap_cov);
      ICover(gap_cov, delay);
      WaitForClock(clk, delay);
    end loop;
    WaitForClock(clk, 10);

    wait;
  end process;


  read_data : process 
    variable ignore_data : std_logic_vector(data_bits_c-1 downto 0);
  begin
    WaitForBarrier(written);

    for i in 0 to 2**addr_bits_c-1 loop
      while doutv = '0' loop
        WaitForClock(clk, 1);
      end loop;
      AlertIf(osvvm.ScoreBoardPkg_slv.Empty(sb), "Need RAM data to check but none available.", FAILURE);
      if dbiterrb = '1' then
        osvvm.ScoreBoardPkg_slv.Pop(sb, ignore_data);
        -- Log the fact so we excuse the checking and tally the RAM addresses checked correctly as exactly 2**addr_bits_c
        AffirmIf(true, "Uncorrectable error detected.");
        dbl_err_cnt <= dbl_err_cnt + 1;
      else
        osvvm.ScoreBoardPkg_slv.Check(sb, doutb);
      end if;
      WaitForClock(clk, 1);
    end loop;
    Log("Finished reading data from RAM.");
    WaitForClock(clk, 10);
    WaitForBarrier(finished);

    wait;
  end process;

end architecture;
