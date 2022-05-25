-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Example clock domain crossing to demonstrate Vivado 'report_cdc' TCL command.
-- Create the topologies listed at [1] in order to purposely create errors for
-- 'report_cdc' to find.
--
-- References:
--  [1] https://docs.xilinx.com/r/en-US/ug906-vivado-design-analysis/Simplified-Schematics-of-the-CDC-Topologies
--
-- P A Abbey, 22 May 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity report_cdc is
  generic (
    num_bits_g : positive := 2
  );
  port (
    clk_src            : in  std_logic;
    reset_src          : in  std_logic;
    clk_dest           : in  std_logic;
    reset_dest         : in  std_logic;
    flags_in_a         : in  std_logic;
    flags_in_b         : in  std_logic;
    flags_in_c         : in  std_logic;
    flags_in_d         : in  std_logic;
    flags_in_e         : in  std_logic;
    flags_in_f         : in  std_logic;                               -- XPM XPM_CDC_SINGLE
    data_in            : in  std_logic_vector(num_bits_g-1 downto 0);
    data_valid_in      : in  std_logic;
    flags_out1         : out std_logic;                               -- CDC-3 Safe, synchronised with ASYNC_REG property
    flags_out2         : out std_logic;                               -- CDC-1 Critical, unknown CDC Circuitry
    flags_out3         : out std_logic;                               -- CDC-2 Warning, missing ASYNC_REG Property
    flags_out4         : out std_logic;                               -- CDC-11, Create a fan out of 2 from launch flop
    flags_out5         : out std_logic;                               -- CDC-11, Create a fan out of 2 from launch flop
    flags_out6         : out std_logic;                               -- CDC-10, Combinatorial logic detected before synchroniser
    flags_out7         : out std_logic;                               -- Combinatorial logic between ASYNC_REG registers - Detected as a CDC-1 "Unknown CDC Circuitry"
    flags_out8         : out std_logic;                               -- NB. Synchronous to clk_src
    flags_out9         : out std_logic;                               -- XPM XPM_CDC_SINGLE
    data_out           : out std_logic_vector(num_bits_g-1 downto 0); -- CDC-15 Clock enable controlled CDC structure
    data_valid_out     : out std_logic;                               -- CDC-15 Clock enable controlled CDC structure
    data_out_bad       : out std_logic_vector(num_bits_g-1 downto 0);
    data_valid_out_bad : out std_logic                               
  );
end entity;


Library xpm;
  use xpm.vcomponents.all;

architecture rtl of report_cdc is

  signal reg_capture_a : std_logic := '0';
  signal reg_capture_b : std_logic := '0';
  signal reg_capture_c : std_logic := '0';
  signal reg_capture_d : std_logic := '0';
  signal reg_capture_e : std_logic := '0';

  -- Using an XDC file is too late, elaboration has already optimised these two into one
  attribute DONT_TOUCH : string;
  attribute DONT_TOUCH of sync_reg_4 : label is "TRUE";
  attribute DONT_TOUCH of sync_reg_5 : label is "TRUE";

begin

  -- Remove glitches from any unregistered combinatorial logic on the source data.
  -- Glitches must not be captured by accident in the new clock domain.
  capture: process(clk_src)
  begin
    if rising_edge(clk_src) then
      if reset_src = '1' then
        reg_capture_a <= '0';
        reg_capture_b <= '0';
        reg_capture_c <= '0';
        reg_capture_d <= '0';
        reg_capture_e <= '0';
        flags_out8    <= '0';
      else
        reg_capture_a <= flags_in_a;
        reg_capture_b <= flags_in_b;
        reg_capture_c <= flags_in_c;
        reg_capture_d <= flags_in_d;
        reg_capture_e <= flags_in_e;
        flags_out8    <= reg_capture_d or reg_capture_e; -- Create non synchroniser fanout
      end if;
    end if;
  end process;

  -- Double retime instances, intended to prevent optimisations
  sync_reg_1 : entity work.sync_reg
    generic map (
      num_bits_g => 1
    )
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_a,
      flags_out(0) => flags_out1
    );

  sync_reg_bad_i : entity work.sync_reg_bad
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_b,
      flags_in(1)  => reg_capture_e,
      flags_out(0) => flags_out2,
      flags_out(1) => flags_out7
    );

  sync_reg_3 : entity work.sync_reg
    generic map (
      num_bits_g => 1
    )
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_c,
      flags_out(0) => flags_out3
    );

  sync_reg_4 : entity work.sync_reg
    generic map (
      num_bits_g => 1
    )
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_d, -- CDC-11, Create a fan out of 2 from launch flop
      flags_out(0) => flags_out4
    );

  sync_reg_5 : entity work.sync_reg
    generic map (
      num_bits_g => 1
    )
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_d, -- CDC-11, Create a fan out of 2 from launch flop
      flags_out(0) => flags_out5
    );

  sync_reg_6 : entity work.sync_reg
    generic map (
      num_bits_g => 1
    )
    port map (
      clk_dest     => clk_dest,
      reset_dest   => reset_dest,
      flags_in(0)  => reg_capture_d and reg_capture_e, -- CDC-10, Combinatorial logic detected before synchroniser
      flags_out(0) => flags_out6
    );

  -- CDC-15 Clock enable controlled CDC structure
  cdc_validated_data_slow_fast_i : entity work.cdc_validated_data_slow_fast
    generic map (
      width_g      => num_bits_g,
      sync_chain_g => 2
    )
    port map (
      clk_in         => clk_src,
      reset_in       => reset_src,
      data_in        => data_in,
      data_valid_in  => data_valid_in,
      clk_out        => clk_dest,
      reset_out      => reset_dest,
      data_out       => data_out,
      data_valid_out => data_valid_out
    );

  -- CE pins should be on the wrong clock - unsafe
  cdc_invalid_data_slow_fast_i : entity work.cdc_invalid_data_slow_fast
    generic map (
      width_g => num_bits_g
    )
    port map (
      clk_in         => clk_src,
      reset_in       => reset_src,
      data_in        => data_in,
      data_valid_in  => data_valid_in,
      clk_out        => clk_dest,
      reset_out      => reset_dest,
      data_out       => data_out_bad,
      data_valid_out => data_valid_out_bad
    );

  xpm_cdc_single_i : XPM_CDC_SINGLE
    generic map (
      DEST_SYNC_FF   => 2, -- DECIMAL; range: 2-10
      INIT_SYNC_FF   => 0, -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 1, -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SRC_INPUT_REG  => 1  -- DECIMAL; 0=do not register input, 1=register input
    )
    port map (
      src_clk  => clk_src,    -- 1-bit input: optional; required when SRC_INPUT_REG = 1
      src_in   => flags_in_f, -- 1-bit input: Input signal to be synchronized to dest_clk domain.
      dest_clk => clk_dest,   -- 1-bit input: Clock signal for the destination clock domain.
      dest_out => flags_out9  -- 1-bit output: src_in synchronized to the destination clock domain. This output
                              -- is registered.
    );

end architecture;
