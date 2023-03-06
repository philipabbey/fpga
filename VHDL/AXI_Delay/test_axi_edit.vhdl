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

architecture test of test_axi_edit is

  constant data_width_c : positive := 16;
  constant max_loops_c  : positive := 128;

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
  signal m_axi_wr    : std_logic                                 := '1';
  signal m_axi_data  : std_logic_vector(data_width_c-1 downto 0) := (others => '0');
  signal m_axi_valid : std_logic                                 := '0';
  signal m_axi_ready : std_logic                                 := '0';

  signal sb        : osvvm.ScoreboardPkg_slv.ScoreboardIDType;
  signal complete  : std_logic := '0' ;
  signal TestStart : std_logic := '0' ;
  signal TestDone  : std_logic := '0' ;

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

  clkgen : clock(clk, 10 ns);


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
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_wr    => m_axi_wr,
      m_axi_ready => m_axi_ready
    );


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
          wait_nr_ticks(clk, 1);

        when drop =>
          s_axi_rd    <= '1';
          m_axi_wr    <= '0';
          s_axi_valid <= '1';
          axi_data_v  := std_logic_vector(to_unsigned(i, s_axi_data'length));
          s_axi_data  <= axi_data_v;
          i := i + 1;
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
          i := i + 1;
          wait_nf_ticks(clk, 1);
          wait_until(s_axi_ready, '1');
          wait_nr_ticks(clk, 1);

      end case;

      alt_valid <= '0';
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
      wait_until(m_axi_valid, '1');
      osvvm.ScoreboardPkg_slv.Check(sb, m_axi_data);
      wait_nr_ticks(clk, 1);
    end loop;
    m_axi_ready <= '0';
    wait_nr_ticks(clk, 1);
    WaitForBarrier(TestDone);
    stop_clocks;
    ReportAlerts;

    wait;
  end process;

end architecture;
