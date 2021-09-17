library ieee;
use ieee.std_logic_1164.all;

package lfsr is

  function get_taps(num : positive range 2 to positive'high) return std_ulogic_vector;

  function lsfr_feedback(
    reg  : std_ulogic_vector;
    taps : std_ulogic_vector
  ) return std_ulogic_vector;

  function lfsr_cnt(
    taps : std_ulogic_vector;
    num  : positive range 1 to positive'high
  ) return std_ulogic_vector;

end package;

library local;
use local.math.all;

package body lfsr is

  type taps_array_t is array(positive range <>) of std_ulogic_vector(31 downto 0);

  constant taps_array : taps_array_t := (
    2  => "000000000000000000000000000000" & "11", -- Never used with maximum counts no less than 3.
    3  => "00000000000000000000000000000" & "101",
    4  => "0000000000000000000000000000" & "1001",
    5  => "000000000000000000000000000" & "10010",
    6  => "00000000000000000000000000" & "100001",
    7  => "0000000000000000000000000" & "1000001",
    8  => "000000000000000000000000" & "10001110",
    9  => "00000000000000000000000" & "100001000",
    10 => "0000000000000000000000" & "1000000100",
    11 => "000000000000000000000" & "10000000010",
    12 => "00000000000000000000" & "100000101001",
    13 => "0000000000000000000" & "1000000001101",
    14 => "000000000000000000" & "10000000010101",
    15 => "00000000000000000" & "100000000000001",
    16 => "0000000000000000" & "1000000000010110",
    17 => "000000000000000" & "10000000000000100",
    18 => "00000000000000" & "100000000001000000",
    19 => "0000000000000" & "1000000000000010011",
    20 => "000000000000" & "10000000000000000100",
    21 => "00000000000" & "100000000000000000010",
    22 => "0000000000" & "1000000000000000000001",
    23 => "000000000" & "10000000000000000010000",
    24 => "00000000" & "100000000000000000001101",
    25 => "0000000" & "1000000000000000000000100",
    26 => "000000" & "10000000000000000000100011",
    27 => "00000" & "100000000000000000000010011",
    28 => "0000" & "1000000000000000000000000100",
    29 => "000" & "10000000000000000000000000010",
    30 => "00" & "100000000000000000000000101001",
    31 => "0" & "1000000000000000000000000000100",
    32 =>      "10000000000000000000000001100010"  -- Never gets used with positive'high = 2**31-1
  );

  function get_taps(num : positive range 2 to positive'high) return std_ulogic_vector is
    -- Need to select the taps correctly when a num-bit LFSR only counts through 2**num-1 states.
    -- So for 'num' is a power of 2, select the next size up.
    constant e : positive range 2 to positive'high := log_ceil(num+1);
  begin
    assert e >= taps_array'low and e <= taps_array'high report "no LFSR taps big or small enough for " & positive'image(num) & "." severity failure;
    return taps_array(e)(e-1 downto 0);
  end function;

  function lsfr_feedback(
    reg  : std_ulogic_vector;
    taps : std_ulogic_vector
  ) return std_ulogic_vector is
    subtype fb_t  is std_ulogic_vector(taps'length-2 downto 0);
  begin
    -- NB. As taps(tap_t'high) = 1 always, then reg(tap_t'high) gets XOR'ed
    -- with itself, hence zero'ed and then discarded.
    return (reg(fb_t'range) xor (taps(fb_t'range) and fb_t'(others => reg(taps'high)))) & reg(taps'high);
  end function;

  -- Loop limits might also limit the maximum value passed to this function.
  -- Xilinx Vivado v2019.1.1 (64-bit)
  --   ERROR: [Synth 8-403] loop limit (65538) exceeded
  function lfsr_cnt(
    taps : std_ulogic_vector;
    num  : positive range 1 to positive'high
  ) return std_ulogic_vector is
    subtype fb_t  is std_ulogic_vector(taps'length-2 downto 0);
    variable max_reg : std_ulogic_vector(taps'length-1 downto 0) := (others => '1');
  begin

    for i in 1 to num loop
      --max_reg := (max_reg(fb_t'range) xor (taps(fb_t'range) and fb_t'(others => max_reg(taps'high)))) & max_reg(taps'high);
      max_reg := lsfr_feedback(max_reg, taps);
    end loop;

    return max_reg;
  end function;

end package body;
