-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/house-of-abbey/scratch_vhdl/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- IO for the Standard 4 button input 4 LED output entity, including synchronisers
-- for the buttons. The four switches and buttons are OR'ed together respectively,
-- so ensure the switches are off when using the buttons.
--
-- References:
--  * https://digilent.com/reference/programmable-logic/zybo/reference-manual
--  * https://digilent.com/reference/programmable-logic/zybo/start
--  * https://digilent.com/reference/programmable-logic/guides/installing-vivado-and-vitis
--
-- J D Abbey & P A Abbey, 18 October 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity pl is
  generic(
    sim_g    : boolean := false;
    rm_num_g : natural := 1
  );
  port(
    clk_port : in  std_logic; -- 125 MHz External Clock
    sw       : in  std_logic_vector(3 downto 0);
    btn      : in  std_logic_vector(3 downto 0);
    led      : out std_logic_vector(3 downto 0) := "0000";
    disp_sel : out std_logic                    := '0';
    sevseg   : out std_logic_vector(6 downto 0) := "0000000"
  );
end entity;


library xil_defaultlib;

architecture rtl of pl is

  component reconfig_rm is
    generic(
      rm_num_g : natural := 0 -- 0 is intentionally empty
    );
    port(
      clk     : in  std_logic;
      reset   : in  std_logic;
      incr    : in  std_logic;
      buttons : in  std_logic_vector(3 downto 0);
      leds    : out std_logic_vector(3 downto 0) := "0000";
      display : out std_logic_vector(3 downto 0) := x"0"
    );
  end component;

  function divide(sim : boolean) return positive is
  begin
    if sim then
      return 10;
    else
      -- ERROR: [Synth 8-27] Division of physical type values not supported
      -- return positive(500 ms / 8 ns);
      -- Vivado does not support division of physical quantites, even when the result is
      -- assigned to a constant. You can't even convert to real by dividing by "1 ns".
      -- Using real literals instead.
      return positive(500.0e-3 / 8.0e-9);
    end if;
  end function;

  constant divide_c : positive := divide(sim_g);

  signal clk          : std_logic                     := '0';
  signal reset        : std_logic                     := '1';
  signal locked       : std_logic;
  signal rst_reg      : std_logic_vector(3 downto 0)  := (others => '1');
  signal sw_r         : std_logic_vector(sw'range)    := (others => '0');
  signal btn_r        : std_logic_vector(btn'range)   := (others => '0');
  signal buttons      : std_logic_vector(btn'range)   := (others => '0');
  signal incr         : std_logic                     := '0';
  signal count        : natural range 0 to divide_c-1 := 0;
  signal display      : std_logic_vector(3 downto 0)  := (others => '0');
  signal display_l    : std_logic_vector(3 downto 0)  := (others => '0');
  signal sevseg0      : std_logic_vector(6 downto 0)  := (others => '0');
  signal sevseg1      : std_logic_vector(6 downto 0)  := (others => '0');
  signal led_i        : std_logic_vector(3 downto 0)  := (others => '0');
  signal sevseg_i     : std_logic_vector(6 downto 0)  := (others => '0');
  signal disp_sel_i   : std_logic                     := '0';
  signal reset_rp     : std_logic                     := '0';

  -- Needs to be here as this part of the design is synthesised *before* the constraints
  -- for the top level are applied.
  attribute KEEP_HIERARCHY : string;
  attribute KEEP_HIERARCHY of reconfig_rp : label is "true";

  -- This will produce warnings during Out Of Context synthesis
  attribute IOB : string;
  attribute IOB of led : signal is "true";

begin

  pll_i : entity xil_defaultlib.pll
    port map (
      -- Clock in ports
      clk_in   => clk_port,
      -- Clock out ports
      clk_out  => clk,
      -- Status and control signals
      locked   => locked
    );


  -- Take advantage of initial values set GSR to generate the reset. It's not obvious
  -- how to tap GSR directly and discouraged too. 'locked' goes high earlier than GSR
  -- allows 'rst_reg' to start shifting, so this is belt & braces to ensure that reset
  -- cannot preceed the PLL entering the locked state.
  process(clk)
  begin
    if rising_edge(clk) then
      (reset, rst_reg) <= rst_reg & not locked;
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
        incr    <= '0';
        count   <= 0;
        buttons <= "0000";
      else
        -- Arbitrate between buttons and switches
        buttons <= btn_r or sw_r;

        incr    <= '0';
        if count = divide_c-1 then
          incr  <= '1';
          count <= 0;
        else
          count <= count + 1;
        end if;
      end if;
    end if;
  end process;

  -- Reconfigurable Partition, filled by a Reconfigurable Module
  reconfig_rp : reconfig_rm
    generic map (
      rm_num_g => rm_num_g -- An alternative selection method when configurations can't be used.
    )
    port map (
      clk     => clk,
      reset   => reset or reset_rp,
      incr    => incr,
      buttons => buttons,
      leds    => open,
      display => display
    );

  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        display_l <= x"0";
      else
        if buttons(0) = '1' then
          display_l <= display;
        end if;
      end if;
    end if;
  end process;

  --       a
  --     #####
  --    #     #
  --  f #     # b
  --    #  g  #
  --     #####
  --    #     #
  --  e #     # c
  --    #  d  #
  --     #####
  --
  -- https://digilent.com/reference/_media/reference/pmod/pmodssd/pmodssd_rm.pdf
  --
  -- This does not need to be registered as the 'dual_seven_seg_display' component
  -- will register it before the IO.
  process(display)
  begin
    -- Right
    case display is --          "gfedcba"
      when x"0"   => sevseg1 <= "0111111";
      when x"1"   => sevseg1 <= "0000110";
      when x"2"   => sevseg1 <= "1011011";
      when x"3"   => sevseg1 <= "1001111";
      when x"4"   => sevseg1 <= "1100110";
      when x"5"   => sevseg1 <= "1101101";
      when x"6"   => sevseg1 <= "1111101";
      when x"7"   => sevseg1 <= "0000111";
      when x"8"   => sevseg1 <= "1111111";
      when x"9"   => sevseg1 <= "1101111";
      when x"a"   => sevseg1 <= "1110111"; -- A
      when x"b"   => sevseg1 <= "1111100"; -- b
      when x"c"   => sevseg1 <= "0111001"; -- C
      when x"d"   => sevseg1 <= "1011110"; -- d
      when x"e"   => sevseg1 <= "1111001"; -- E
      when x"f"   => sevseg1 <= "1110001"; -- F
      when others => sevseg1 <= "0000000";
    end case;
  end process;

  process(display_l)
  begin
    -- Left
    case display_l is --        "gfedcba"
      when x"0"   => sevseg0 <= "0111111";
      when x"1"   => sevseg0 <= "0000110";
      when x"2"   => sevseg0 <= "1011011";
      when x"3"   => sevseg0 <= "1001111";
      when x"4"   => sevseg0 <= "1100110";
      when x"5"   => sevseg0 <= "1101101";
      when x"6"   => sevseg0 <= "1111101";
      when x"7"   => sevseg0 <= "0000111";
      when x"8"   => sevseg0 <= "1111111";
      when x"9"   => sevseg0 <= "1101111";
      when x"a"   => sevseg0 <= "1110111"; -- A
      when x"b"   => sevseg0 <= "1111100"; -- b
      when x"c"   => sevseg0 <= "0111001"; -- C
      when x"d"   => sevseg0 <= "1011110"; -- d
      when x"e"   => sevseg0 <= "1111001"; -- E
      when x"f"   => sevseg0 <= "1110001"; -- F
      when others => sevseg0 <= "0000000";
    end case;
  end process;

  dual_seven_seg_display_i : entity work.dual_seven_seg_display
    generic map (
      sim_g         => sim_g,
      switch_rate_g => 2.0e-3 -- 2 ms
    )
    port map (
      clk      => clk,
      reset    => reset,
      sevseg0  => sevseg0, -- left
      sevseg1  => sevseg1, -- right
      disp_sel => disp_sel_i,
      sevseg   => sevseg_i
    );

  -- To enable IOB packing and timing closure
  process(clk)
  begin
    if rising_edge(clk) then
      disp_sel <= disp_sel_i;
      sevseg   <= sevseg_i;
    end if;
  end process;


  reconfig_action_i : entity work.reconfig_action(by_dfx_ip)
    generic map(
      sim_g => sim_g
    )
    port map (
      clk         => clk,
      reset       => reset,
      start       => buttons(3),
      reset_rp    => reset_rp,
      programming => led_i(3),
      error       => led_i(2),
      rom_num     => led_i(1 downto 0)
    );

  -- To enable IOB packing and timing closure
  process(clk)
  begin
    if rising_edge(clk) then
      led <= led_i;
    end if;
  end process;

end architecture;
