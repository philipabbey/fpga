-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- LFSR package to provide the polynomial taps and a number of utility functions to
-- keep the LFSR RTL code clean.
--
-- P A Abbey, 11 August 2019
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package lfsr_pkg is

  -- Look up the polynomial required for the count length and slice the returned
  -- array down to the required size.
  --
  -- Usage:
  --   constant taps : std_ulogic_vector := get_taps(5);
  --
  function get_taps(num : positive range 2 to positive'high) return std_ulogic_vector;


  -- Provide the next state for the LFSR given the current state 'reg' and the
  -- polynomial from a previous call to 'get_taps'.
  --
  -- Usage:
  --   reg <= lsfr_feedback(reg, taps);
  --
  function lsfr_feedback(
    reg  : std_ulogic_vector;
    taps : std_ulogic_vector
  ) return std_ulogic_vector;


  -- Calculate the nth state of the LFSR such that the value can be used for a
  -- comparison, e.g. when the LFSR has reached its maximal count value.
  --
  -- Usage:
  --   constant max_reg : std_ulogic_vector := lfsr_cnt(taps, max);
  --
  function lfsr_cnt(
    taps : std_ulogic_vector;
    num  : natural
  ) return std_ulogic_vector;


  -- ITU-T O.150 Standard
  -- Reference: https://www.itu.int/rec/T-REC-O.150-199210-S
  --
  -- Digital Test Patterns For Performance Measurements On Digital Transmission Equipment
  --
  -- Parameters values for the ITU-T compliant PRBS polynomials
  --                                                        Bit offsets: 33222222222211111111110000000000
  --                                                                     10987654321098765432109876543210
  -- +-------------+----------+--------------+------------+----------+------------------------------------+
  -- | Poly length | Poly tap | Inv pattern? |  Bit seq.  |  Max 0   | Polynomial, x^l + x^t + 1          |
  -- |             |          |              |   length   | sequence | x^0 is omitted from the polynomial |
  -- +-------------+----------+--------------+------------+----------+------------------------------------+
  -- |       7     |     6    |     false    |        127 |     6    |                          "1100000" |
  -- |       9     |     5    |     false    |        511 |     8    |                        "100010000" |
  -- |      11     |     9    |     false    |       2047 |    10    |                      "10100000000" |
  -- |      15     |    14    |     true     |      32767 |    15    |                  "110000000000000" |
  -- |      20     |     3    |     false    |    1048575 |    19    |             "10000000000000000100" |
  -- |      23     |    18    |     true     |    8388607 |    23    |          "10000100000000000000000" |
  -- |      29     |    27    |     true     |  536870911 |    29    |    "10100000000000000000000000000" |
  -- |      31     |    28    |     true     | 2147483647 |    31    |  "1001000000000000000000000000000" |
  -- +-------------+----------+--------------+------------+----------+------------------------------------+
  --                                                                   Where 'l' =length and 't' = tap.

  type itu_t_o150_t is record
    length : integer range 7 to 31;
    tap    : integer range 1 to 31;
    invert : boolean;
  end record;

  type itu_t_o150_arr_t is array (natural range <>) of itu_t_o150_t;

  constant itu_t_o150_c : itu_t_o150_arr_t(1 to 8) := (
    -- length, tap, invert
    1 => (  7,   6, false),
    2 => (  9,   5, false),
    3 => ( 11,   9, false),
    4 => ( 15,  14, true),
    5 => ( 20,   3, false),
    6 => ( 23,  18, true),
    7 => ( 29,  27, true),
    8 => ( 31,  28, true)
  );

  -- Generate the polynomial from the required itu_t_o150_c element. This can be supplied
  -- to the 'itu_prbs_generator' component, which will extract the required values for
  -- the PRBS generator.
  --
  -- Usage: local.lfsr_pkg.itu_t_poly_gen(5) => 23x"420000", 
  --
  function itu_t_poly_gen(index : integer range 1 to 8) return std_logic_vector;

end package;


library local;

package body lfsr_pkg is

  type taps_array_t is array(positive range <>) of std_ulogic_vector(31 downto 0);

  -- LFSR polynomial array taps has been taken from the table listed in the article
  -- "Tutorial: Linear Feedback Shift Registers (LFSRs)" by Max Maxfield, who with
  -- others has also lifted them from a book
  -- "Bebop to the Boolean Boogie (An Unconventional Guide to Electronics)".
  --
  -- Only the second half of each vector after the '&' is required, but in VHDL all
  -- array elements must be of the same type, i.e. same length vector. So the index
  -- array element must be sliced afterwards.
  constant taps_array : taps_array_t := (
    2  => "000000000000000000000000000000" & "11",
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
    constant e : positive range 2 to positive'high := local.math_pkg.ceil_log(num+1);
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
    num  : natural
  ) return std_ulogic_vector is
    subtype fb_t  is std_ulogic_vector(taps'length-2 downto 0);
    variable max_reg : std_ulogic_vector(taps'length-1 downto 0) := (others => '1');
  begin

    for i in 1 to num loop
      max_reg := lsfr_feedback(max_reg, taps);
    end loop;

    return max_reg;
  end function;


  -- ITU-T O.150 Standard Polynomial generator. See package header for a description.
  --
  function itu_t_poly_gen(index : integer range 1 to 8) return std_logic_vector is
    constant length_c : integer range 7 to 31               := itu_t_o150_c(index).length;
    constant tap_c    : integer range 1 to 31               := itu_t_o150_c(index).tap;
    variable ret      : std_logic_vector(length_c downto 1) := (others => '0');
  begin
    ret(length_c) := '1';
    ret(tap_c)    := '1';
    return ret;
  end function;

end package body;
