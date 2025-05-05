-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Top level test bench for partial reconfiguration demonstration.
--
-- P A Abbey, 12 February 2025
--
-------------------------------------------------------------------------------------

entity test_pl is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
library std;
library local;
  use local.testbench_pkg.all;

architecture test of test_pl is

  signal clk         : std_logic                    := '0';
  signal reset       : std_logic                    := '0';
  signal sw          : std_logic_vector(3 downto 0) := "0000";
  signal btn         : std_logic_vector(3 downto 0) := "0000";
  signal leds        : std_logic_vector(3 downto 0) := "0000";
  signal disp_sel    : std_logic                    := '0';
  signal sevseg      : std_logic_vector(6 downto 0) := "0000000";
  signal programming : std_logic;

begin

  programming <= leds(3); -- << signal dut.reconfig_action_i.dfx_controller_i.vsm_VS_0_rm_decouple : std_logic >>;

  clkgen : clock(clk, 8 ns);

  dut : entity work.pl
    generic map (
      sim_g => true
    )
    port map (
      clk               => clk,
      reset             => reset,
      sw                => sw,
      btn               => btn,
      led               => leds,
      disp_sel          => disp_sel,
      sevseg            => sevseg,
      -- We are not testing the AXI-Lite interface, use software.
      s_axi_reg_awaddr  => (others => '0'),
      s_axi_reg_awvalid => '0',
      s_axi_reg_awready => open,
      s_axi_reg_wdata   => (others => '0'),
      s_axi_reg_wvalid  => '0',
      s_axi_reg_wready  => open,
      s_axi_reg_bresp   => open,
      s_axi_reg_bvalid  => open,
      s_axi_reg_bready  => '0',
      s_axi_reg_araddr  => (others => '0'),
      s_axi_reg_arvalid => '0',
      s_axi_reg_arready => open,
      s_axi_reg_rdata   => open,
      s_axi_reg_rresp   => open,
      s_axi_reg_rvalid  => open,
      s_axi_reg_rready  => '0'
    );

  process
  begin
    reset <= '1';
    sw    <= "0000";
    btn   <= "0000";
    wait_nr_ticks(clk, 40);
    reset <= '0';
    report "Resets completed";

    wait_nr_ticks(clk, 20);
    -- Hold the value from the RM in the static partition
    btn <= "0001";
    wait_nr_ticks(clk, 10);
    btn <= "0000";
    wait_nr_ticks(clk, 1000);

    for i in 0 to 3 loop
      -- Trigger IPROG
      report "Trigger ICAP for RM" & to_string(i);
      btn <= "1000";
      wait_nr_ticks(clk, 20);
      btn <= "0000";
      wait_until(programming, '1');
      report "Reprogram started";
      wait until programming = '0';
      report "Reprogram completed";
      wait_nr_ticks(clk, 200);
    end loop;

    --stop_clocks;
    -- PLL IP Core won't stop creating events, must use 'stop' instead of 'stop_clocks'.
    report "WARNING - This is not a self checking test bench";
    std.env.stop;
    wait;
  end process;

end architecture;
