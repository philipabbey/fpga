-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Simplifying the use of XPM RAM, randomised test bench.
--
-- P A Abbey, 15 July 2023
--
-- Reference: https://docs.xilinx.com/r/en-US/ug953-vivado-7series-libraries/XPM_MEMORY_SDPRAM
--
-------------------------------------------------------------------------------------

entity test_dpram_1clk is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
library osvvm;
  context osvvm.OsvvmContext;
library osvvm_axi4;
  context osvvm_axi4.AxiStreamContext;

architecture test of test_dpram_1clk is

  type test_t is record
    addr_bits    : positive;
    data_bits    : positive;
    primitive    : string(1 to 11); -- "auto", "block", "distributed", "mixed", "ultra"
    read_latency : natural;
  end record;

  type tests_arr_t is array(natural range<>) of test_t;

  constant tests_c : tests_arr_t := (
    test_t'(
      addr_bits    => 5,
      data_bits    => 8,
      primitive    => "distributed",
      read_latency => 0
    ),
    test_t'(
      addr_bits    => 6,
      data_bits    => 12,
      primitive    => "distributed",
      read_latency => 1
    ),
    test_t'(
      addr_bits    => 8,
      data_bits    => 32,
      primitive    => "block      ",
      read_latency => 1
    ),
    test_t'(
      addr_bits    => 9,
      data_bits    => 16,
      primitive    => "block      ",
      read_latency => 2
    )
  );

  -- Remove trail spaces from a string
  --
  function trim_str(s : string) return string is
  begin
    for i in s'reverse_range loop
      if s(i) /= ' ' then
        return s(1 to i);
      end if;
    end loop;
    return "";
  end function;

  constant clk_period_c : time := 10 ns;

  signal clk : std_logic := '0';
  signal rst : std_logic := '0';

  -- OSVVM
  signal finished : std_logic := '0';

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
    Reset       => rst,
    ResetActive => '1',
    Clk         => clk,
    Period      => 4 * clk_period_c,
    tpd         => 0 ns
  );


  t : for i in tests_c'range generate

    signal sleep     : std_logic;
    signal rd_sleep  : std_logic                                         := '0';
    signal wr_sleep  : std_logic                                         := '0';
    signal ena       : std_logic                                         := '0';
    signal wea       : std_logic                                         := '0';
    signal addra     : std_logic_vector(tests_c(i).addr_bits-1 downto 0) := (others => '0');
    signal dina      : std_logic_vector(tests_c(i).data_bits-1 downto 0) := (others => '0');
    signal enb       : std_logic                                         := '0';
    signal addrb     : std_logic_vector(tests_c(i).addr_bits-1 downto 0) := (others => '1');
    signal doutb     : std_logic_vector(tests_c(i).data_bits-1 downto 0) := (others => '0');
    signal doutv     : std_logic                                         := '0';
    signal sleepable : boolean;

    -- OSVVM
    signal setup        : std_logic := '0';
    signal written      : std_logic := '0';
    signal read_data    : std_logic := '0';
    signal gap_cov      : CoverageIDType;
    signal wr_addr_cov  : CoverageIDType;
    signal rd_addr_cov  : CoverageIDType;
    signal wr_sleep_cov : CoverageIDType;
    signal rd_sleep_cov : CoverageIDType;
    signal sb           : osvvm.ScoreBoardPkg_slv.ScoreboardIDType;

  begin

    sleep <= wr_sleep or rd_sleep;

    dut : entity work.dpram_1clk
      generic map (
        addr_bits_g    => tests_c(i).addr_bits,
        data_bits_g    => tests_c(i).data_bits,
        primitive_g    => trim_str(tests_c(i).primitive),
        read_latency_g => tests_c(i).read_latency
      )
      port map (
        clk   => clk,
        rst   => rst,
        sleep => sleep,
        ena   => ena,
        wea   => wea,
        addra => addra,
        dina  => dina,
        enb   => enb,
        addrb => addrb,
        doutb => doutb,
        doutv => doutv
      );


    setup_p : process
    begin
      gap_cov      <= NewID("DUT" & to_string(i) & " Gap Coverage");
      wr_addr_cov  <= NewID("DUT" & to_string(i) & " Write Address Coverage");
      rd_addr_cov  <= NewID("DUT" & to_string(i) & " Read Address Coverage");
      wr_sleep_cov <= NewID("DUT" & to_string(i) & " Write Sleep Coverage");
      rd_sleep_cov <= NewID("DUT" & to_string(i) & " Read Sleep Coverage");
      sb           <= osvvm.ScoreBoardPkg_slv.NewID("RAM Data");
      wait for 0 ns;
      AddBins(gap_cov, "0..0", 19, GenBin(0));
      AddBins(gap_cov, "1..4",  1, GenBin(1, 4));
      AddBins(wr_addr_cov, "Each address once", 1, GenBin(0, 2**tests_c(i).addr_bits-1));
      AddBins(rd_addr_cov, "Each address once", 1, GenBin(0, 2**tests_c(i).addr_bits-1));
      AddBins(wr_sleep_cov, "Wake ", 10, GenBin(0));
      AddBins(wr_sleep_cov, "Sleep",  1, GenBin(1));
      AddBins(rd_sleep_cov, "Wake ", 10, GenBin(0));
      AddBins(rd_sleep_cov, "Sleep",  1, GenBin(1));
      WaitForBarrier(setup);
      WaitForBarrier(read_data);
      BlankLine(1);
      WriteBin(gap_cov);
      BlankLine(1);
      if sleepable then
        WriteBin(wr_sleep_cov);
        BlankLine(1);
        WriteBin(rd_sleep_cov);
        BlankLine(1);
      end if;
      AlertIf(GetAffirmCount < 1, "Test is not Self-Checking.");
      AlertIf(GetAffirmCount < 2**tests_c(i).addr_bits, "Not all addresses have been verified.");
      EndOfTestReports;
      WaitForBarrier(finished);
      std.env.stop(GetAlertCount);
      wait;
    end process;


    write_p : process
      variable addra_v : natural;
      variable delay_v : natural;
      variable sleep_v : natural;
    begin
      case tests_c(i).primitive is
        when "block      " | "ultra      " =>
          wr_sleep  <= '1';
          sleepable <= true;
        when others =>
          wr_sleep  <= '0';
          sleepable <= false;
      end case;
      ena   <= '0';
      wea   <= '0';
      addra <= (others => '0');
      dina  <= (others => '0');
      WaitForBarrier(setup);
      WaitForClock(clk, 20);
      wr_sleep <= '0';
      WaitForClock(clk, 2); -- Seems to require 2 clock cycles to come out of sleep

      while not IsCovered(wr_addr_cov) loop
        addra_v := GetRandPoint(wr_addr_cov);
        ICover(wr_addr_cov, addra_v);
        addra <= std_logic_vector(to_unsigned(addra_v, tests_c(i).addr_bits));
        dina  <= resize(not(std_logic_vector(to_unsigned(addra_v, tests_c(i).addr_bits))), tests_c(i).data_bits);
        ena   <= '1';
        wea   <= '1';
        WaitForClock(clk, 1);
        ena     <= '0';
        wea     <= '0';
        delay_v := GetRandPoint(gap_cov);
        ICover(gap_cov, delay_v);
        if delay_v > 0 then
          WaitForClock(clk, delay_v);
        elsif sleepable then
          sleep_v := GetRandPoint(wr_sleep_cov);
          ICover(wr_sleep_cov, sleep_v);
          if sleep_v = 1 then
            -- Must wait one clock cycle before going into sleep on writes
            WaitForClock(clk, 1);
            wr_sleep <= '1';
            WaitForClock(clk, 10);
            wr_sleep <= '0';
            WaitForClock(clk, 2);
          end if;
        end if;
      end loop;

      Log("DUT" & to_string(i) & " - Finished writing data to RAM.");
      WaitForBarrier(written);

      wait;
    end process;


    read_addr_p : process
      variable addrb_v : natural;
      variable delay_v : natural;
      variable sleep_v : natural;
    begin
      rd_sleep <= '0';
      enb      <= '0';
      WaitForBarrier(written);
      WaitForClock(clk, 4);

      while not IsCovered(rd_addr_cov) loop
        addrb_v := GetRandPoint(rd_addr_cov);
        ICover(rd_addr_cov, addrb_v);
        addrb <= std_logic_vector(to_unsigned(addrb_v, tests_c(i).addr_bits));
        enb   <= '1';
        osvvm.ScoreBoardPkg_slv.Push(sb, resize(not(std_logic_vector(to_unsigned(addrb_v, tests_c(i).addr_bits))), tests_c(i).data_bits));
        WaitForClock(clk, 1);
        enb     <= '0';
        delay_v := GetRandPoint(gap_cov);
        ICover(gap_cov, delay_v);
        if delay_v > 0 then
          WaitForClock(clk, delay_v);
        elsif sleepable then
          sleep_v := GetRandPoint(rd_sleep_cov);
          ICover(rd_sleep_cov, sleep_v);
          if sleep_v = 1 then
            -- No need to wait before going into sleep on reads
            rd_sleep <= '1';
            WaitForClock(clk, 10);
            rd_sleep <= '0';
            WaitForClock(clk, 2);
          end if;
        end if;
      end loop;
      WaitForClock(clk, 10);

      wait;
    end process;


    read_data_p : process
    begin
      WaitForBarrier(written);

      for i in 0 to 2**tests_c(i).addr_bits-1 loop
        while doutv = '0' loop
          WaitForClock(clk, 1);
        end loop;
        AlertIf(osvvm.ScoreBoardPkg_slv.Empty(sb), "Need RAM data to check but none available.", FAILURE);
        osvvm.ScoreBoardPkg_slv.Check(sb, doutb);
        WaitForClock(clk, 1);
      end loop;
      Log("DUT" & to_string(i) & " - Finished reading data from RAM.");
      WaitForClock(clk, 10);
      WaitForBarrier(read_data);
      WaitForBarrier(finished);

      wait;
    end process;

  end generate;

end architecture;
