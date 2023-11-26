-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test bench for 'bus_data_valid_synch' CDC solution to verify assertion for
-- sampling data_in twice before changing. Much of the complexity in here is dealing
-- with intimate verification across an asynchronous clock boundary.
--
-- P A Abbey, 4 November 2023
--
-------------------------------------------------------------------------------------

entity test_bus_data_valid_synch is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library osvvm;
  context osvvm.OsvvmContext;

architecture osvvm of test_bus_data_valid_synch is

  type slv_arr_t is array(integer range <>) of std_logic_vector;

  type test_t is record
    width       : positive;
    sync_len    : integer range 2 to integer'high;
    src_reg     : boolean;
    src_period  : time;
    dest_period : time; -- Must be shorted (faster) than 'src_period_c'
  end record;

  type tests_arr_t is array(natural range<>) of test_t;

  constant tests_c : tests_arr_t := (
    test_t'(
      width       => 8,
      sync_len    => 4,
      src_reg     => false,
      src_period  => 8 ns,
      dest_period => 7 ns
    ),
    test_t'(
      width       => 4,
      sync_len    => 3,
      src_reg     => true,
      src_period  => 12 ns,
      dest_period => 10 ns
    ),
    test_t'(
      width       => 16,
      sync_len    => 2,
      src_reg     => false,
      src_period  => 11 ns,
      dest_period => 8 ns
    ),
    test_t'(
      width       => 6,
      sync_len    => 2,
      src_reg     => true,
      src_period  => 9 ns,
      dest_period => 7 ns
    ),
    test_t'(
      width       => 3,
      sync_len    => 3,
      src_reg     => false,
      src_period  => 11 ns,
      dest_period => 5 ns
    ),
    test_t'(
      width       => 2,
      sync_len    => 2,
      src_reg     => false,
      src_period  => 10 ns,
      dest_period => 5 ns
    )
  );

  -- OSVVM
  constant timeout_c     : time    := 100 us;
  constant print_stats_c : boolean := false;

  signal finished : std_logic := '0';
  signal results  : std_logic := '0';

begin

  -- Global AlertLogID
  process
  begin
    SetLogEnable(INFO,  true);
    WaitForBarrier(finished, timeout_c); -- All generated tests
    if now >= timeout_c then
      Alert("Test finished due to Time Out");
    else
      WaitForBarrier(results);
    end if;
    -- Prefer as last line in the log
    BlankLine(1);
    EndOfTestReports;
    std.env.stop(GetAlertCount);
    wait;
  end process;


  t : for i in tests_c'range generate

    package my_sent_pkg is new work.sent_pkg
      generic map(tests_c(i).width);

    type sent_arr_t is array(0 to 2) of my_sent_pkg.sent_t;

    signal clk_src        : std_logic                                     := '0';
    signal clk_dest       : std_logic                                     := '0';
    signal reset_dest     : std_logic                                     := '0';
    signal data_in        : std_logic_vector(tests_c(i).width-1 downto 0) := (others => '0');
    signal data_valid_in  : std_logic                                     := '0';
    signal data_out       : std_logic_vector(tests_c(i).width-1 downto 0);
    signal data_valid_out : std_logic;

    -- OSVVM
    signal delay_cov : CoverageIDType;
    signal sb        : my_sent_pkg.ScoreBoardPkg_sent.ScoreboardIDType;
    signal localId   : AlertLogIDType;
    signal setup     : std_logic := '0';
    signal sent_arr  : sent_arr_t;

    constant min_c : natural := maximum(1, tests_c(i).sync_len-3);
    constant max_c : natural := tests_c(i).sync_len+3;

  begin

    CreateClock(clk_src,  tests_c(i).src_period);
    CreateClock(clk_dest, tests_c(i).dest_period);

    CreateReset(
      Reset       => reset_dest,
      ResetActive => '1',
      Clk         => clk_dest,
      Period      => 4 * tests_c(i).dest_period,
      tpd         => 0 ns
    );


    setup_p : process
      variable PassedCount, AffirmCheckCount : integer;
    begin
      delay_cov <= NewID("DUT" & to_string(i) & " Delay Coverage");
      sb        <= my_sent_pkg.ScoreBoardPkg_sent.NewID("Synchroniser Data");
      wait for 0 ns; -- Wait one delta for signal assignments
      localId   <= GetAlertLogID(delay_cov);
      wait for 0 ns;
      SetLogEnable(localId, INFO,  true);
      SetLogEnable(localId, DEBUG, false);

      AlertIf(
        localId,
        tests_c(i).dest_period > tests_c(i).src_period,
        "This DUT is a synchroniser for transfer of data to a faster clock domain.",
        ERROR
      );

      AddBins(
        ID      => delay_cov,
        Name    => "Delay",
        AtLeast => 200,
        CovBin  => GenBin(min_c, max_c)
      );
      WaitForBarrier(setup);
      WaitForBarrier(finished); -- All generated tests
      BlankLine(1);
      WriteBin(delay_cov);
      BlankLine(1);
      AlertIf(
        localId,
        GetAffirmCount < 1,
        "Test is not Self-Checking.",
        ERROR
      );
      ReportAlerts("DUT" & to_string(i) & " results", localId);
      WaitForBarrier(results);
      wait;
    end process;


    write_p : process

      variable rand_v   : RandomPType;
      variable src_clks : natural;
      variable sent_v   : my_sent_pkg.sent_t                            := my_sent_pkg.sent_init_c;
      variable sent_lv  : my_sent_pkg.sent_t                            := my_sent_pkg.sent_init_c; -- One before sent_v
      variable data_lv  : std_logic_vector(tests_c(i).width-1 downto 0) := (others => '0'); -- Last data value

      constant bad_his_c : integer_vector(0 to 0) := (others => 1);

      -- Ensure each new data item is different to the last returned.
      --
      -- Get new random data this is not the same as the last value (more likely with short
      -- tests_c(i).width), because we need data_in to change each time in order to verify
      -- data stability inside the DUT.
      --
      impure function new_data return std_logic_vector is
        variable ret : std_logic_vector(tests_c(i).width-1 downto 0) := data_lv;
      begin
        while ret = data_lv loop
          ret := rand_v.RandSlv(0, (2**tests_c(i).width)-1, tests_c(i).width);
        end loop;
        data_lv := ret;
        return ret;
      end function;

    begin
      rand_v.InitSeed(i);
      WaitForBarrier(setup);
      WaitForLevel(reset_dest, '1');
      WaitForLevel(reset_dest, '0');
      WaitForClock(clk_src, 2);

      while not IsCovered(delay_cov) loop
        sent_lv  := sent_v; -- Not the same as 'sent_arr(*)'
        src_clks := GetRandPoint(delay_cov);
        -- Delay in source domain clock cycles
        sent_v := (
          data  => new_data,
          delay => src_clks * tests_c(i).src_period
        );
        sent_arr(0) <= sent_v; -- Gets updated at next wait. Just avoid a glitch in the waves due to an otherwise required "wait for 0 ns".
        ICover(delay_cov, src_clks);

        -- Push the first one with a no_check flag, swallow the second and subsequent with sent_v.delay=1.
        if sent_lv.delay /= tests_c(i).src_period and src_clks = 1 then
          my_sent_pkg.ScoreBoardPkg_sent.Push(sb, sent_v);
          log(localId, "Sent first of consecutive coalesced " & my_sent_pkg.to_string(sent_v), DEBUG);
        elsif sent_lv.delay /= tests_c(i).src_period and src_clks > 1 then
          my_sent_pkg.ScoreBoardPkg_sent.Push(sb, sent_v);
          log(localId, "Sent result " & my_sent_pkg.to_string(sent_v), DEBUG);
        else
          log(localId, "Did not send " & my_sent_pkg.to_string(sent_v), DEBUG);
        end if;

        data_in       <= sent_v.data;
        data_valid_in <= '1';
        WaitForClock(clk_src, 1);
        data_valid_in <= '0';
        if src_clks > 1 then
          WaitForClock(clk_src, src_clks-1);
        end if;
      end loop;

      -- If we end of a string of sent_v.delay=1, we'll hang waiting for 'data_valid_out' to go high, so make
      -- sure there's a gap in order to create the pulse on 'data_valid_out'. Otherwise make sure we add a
      -- new word immediately in order to cause expected problems.
      if sent_lv.delay = tests_c(i).src_period and src_clks = 1 then
        WaitForClock(clk_src, 1);
      end if;
      -- Complete the timing for the last submitted value, i.e. when it should fail for being to short a delay
      data_in       <= (others => '1');
      data_valid_in <= '1';
      WaitForClock(clk_src, 1);
      data_valid_in <= '0';

      wait;
    end process;


    dut : entity work.bus_data_valid_synch
      generic map (
        width_g       => tests_c(i).width,
        len_g         => tests_c(i).sync_len,
        src_reg_g     => tests_c(i).src_reg
      )
      port map (
        clk_src        => clk_src,
        clk_dest       => clk_dest,
        reset_dest     => reset_dest,
        data_in        => data_in,
        data_valid_in  => data_valid_in,
        data_out       => data_out,
        data_valid_out => data_valid_out
      );


    sent_delay_p : process(clk_src)
    begin
      if rising_edge(clk_src) then
        sent_arr(1 to 2) <= sent_arr(0 to 1);
      end if;
    end process;


    dv_err_chk_p : process(clk_src)
    begin
      if falling_edge(clk_src) then
        if << signal dut.stbl.dv_err : boolean >> then
          if tests_c(i).src_reg then
            AffirmIf(
              localId,
              sent_arr(2).delay = tests_c(i).src_period,
              "Data word lost by coalescing due to being immediately after the previous word."
            );
          else
            AffirmIf(
              localId,
              sent_arr(1).delay = tests_c(i).src_period,
              "Data word lost by coalescing due to being immediately after the previous word."
            );
          end if;
        end if;
      end if;
    end process;


    check_p : process
      variable check_v     : my_sent_pkg.sent_t;
      variable dest_clks_v : natural;
      variable stbl_v      : integer_vector(0 to 1 + max_c * tests_c(i).src_period / tests_c(i).dest_period) := (others => 0);
      variable unstbl_v    : integer_vector(0 to 1 + max_c * tests_c(i).src_period / tests_c(i).dest_period) := (others => 0);
      variable corr_v      : integer_vector(0 to 1 + max_c * tests_c(i).src_period / tests_c(i).dest_period) := (others => 0);
      variable incorr_v    : integer_vector(0 to 1 + max_c * tests_c(i).src_period / tests_c(i).dest_period) := (others => 0);
    begin
      WaitForBarrier(setup);

      while true loop
        wait until falling_edge(clk_dest);

        if data_valid_out = '1' then

          if my_sent_pkg.ScoreBoardPkg_sent.Empty(sb) then
            -- An extra final data word is transferred on the end outside of the randomised coverage in order to provide
            -- the required delay for the final covered data sample. Just exit the check loop.
            exit;
          else

            check_v     := my_sent_pkg.ScoreBoardPkg_sent.Pop(sb);
            dest_clks_v := check_v.delay / tests_c(i).dest_period;

            -- Collect some statistics about the behaviour of each DUT
            if << signal dut.stbl.stbl_at_clk : boolean >> then
              stbl_v(dest_clks_v) := stbl_v(dest_clks_v) + 1;
            else
              unstbl_v(dest_clks_v) := unstbl_v(dest_clks_v) + 1;
            end if;

            if data_out = check_v.data then
              corr_v(dest_clks_v) := corr_v(dest_clks_v) + 1;
            else
              incorr_v(dest_clks_v) := incorr_v(dest_clks_v) + 1;
            end if;


            if check_v.delay / tests_c(i).dest_period = tests_c(i).sync_len then -- Requires integer division and rounding down.
              -- Potentially ignore, depends on DUT stability check
              if << signal dut.stbl.stbl_at_clk : boolean >> then
                -- Its stable, at least verify the data
                AffirmIf(
                  localId,
                  data_out = check_v.data,
                  "Data error: actual = 0x" & to_hstring(data_out),
                  "expected = 0x" & to_hstring(check_v.data) & ", check = " & my_sent_pkg.to_string(check_v) & ", sync chain length = " & to_string(tests_c(i).sync_len)
                );
              else
                -- Ignore
                AffirmIf(
                  localId,
                  true, -- The message below will never be printed, it remains as an explanation only.
                  "Input data change delay of " & to_string(tests_c(i).sync_len) & " destination clock cycles and DUT marks the output as unstable, check = " & my_sent_pkg.to_string(check_v)
                );
              end if;
            elsif check_v.delay / tests_c(i).dest_period < tests_c(i).sync_len then
              -- Should fail
              AffirmIfNot(
                localId,
                << signal dut.stbl.stbl_at_clk : boolean >>,
                "Data out was not flagged as wrong, " & my_sent_pkg.to_string(check_v)
              );
            else
              -- Should pass
              AffirmIf(
                localId,
                data_out = check_v.data,
                "Data error: actual = 0x" & to_hstring(data_out),
                "expected = 0x" & to_hstring(check_v.data) & ", check = " & my_sent_pkg.to_string(check_v) & ", sync chain length = " & to_string(tests_c(i).sync_len)
              );
              AlertIfNot(
                localId,
                << signal dut.stbl.stbl_at_clk : boolean >>,
                "Data out was flagged as wrong, " & my_sent_pkg.to_string(check_v)
              );
            end if;

            if IsCovered(delay_cov) and my_sent_pkg.ScoreBoardPkg_sent.Empty(sb) then
              exit;
            end if;

          end if;
        end if;
      end loop;

      WaitForClock(clk_dest, 4);
      -- Signal this specific test as finished
      WaitForBarrier(finished);

      if print_stats_c then
        BlankLine(2);
        log(localId, "**** DUT " & to_string(i) & " Results with sync chain length = " & to_string(tests_c(i).sync_len) & " ****", INFO);
        for j in stbl_v'range loop
          BlankLine(1);
          log(localId, "Delay Bin = " & to_string(j) & "  T  F", INFO);
          log(localId, "Stable data  : " & to_string(stbl_v(j)) & " " & to_string(unstbl_v(j)), INFO);
          log(localId, "Correct data : " & to_string(corr_v(j)) & " " & to_string(incorr_v(j)), INFO);
        end loop;
      end if;

      wait;
    end process;

  end generate;

end architecture;
