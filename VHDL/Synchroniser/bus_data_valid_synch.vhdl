-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- This code is less about the realisation of a standard synchroniser, and more about
-- the dynamic timing checking to verify that data_in remained stable long enough to
-- be sampled twice before it changed. If it is only sampled once before it changes,
-- then the first sample could be metastable and the value completely missed before
-- it changes.
--
-- P A Abbey, 4 November 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity bus_data_valid_synch is
  generic(
    width_g       : positive := 4;
    -- Synchroniser chain length
    len_g         : positive := 2;
    -- There should be no logic between the final register in the source clock domain
    -- and the first register in the destination clock domain in order to maximise
    -- the positive slack and hence settling time. This register is advised but
    -- optional since data_in and data_valid_in may already come from a register.
    src_reg_g     : boolean := true
  );
  port(
    clk_src        : in  std_logic;
    clk_dest       : in  std_logic;
    reset_dest     : in  std_logic;
    data_in        : in  std_logic_vector(width_g-1 downto 0);
    data_valid_in  : in  std_logic;
    data_out       : out std_logic_vector(width_g-1 downto 0) := (others => '0');
    data_valid_out : out std_logic                            := '0'
  );
end entity;


architecture rtl of bus_data_valid_synch is

  signal dv_in : std_logic                            := '0';
  signal di    : std_logic_vector(width_g-1 downto 0) := (others => '0');
  -- Retime the data valid only, to give time for data_in to settle and then be sampled.
  signal dv    : std_logic_vector(0 to len_g-1)       := (others => '0');
  signal dv_d  : std_logic                            := '0';

  attribute ASYNC_REG    : boolean;
  attribute DIRECT_RESET : boolean;

  attribute ASYNC_REG    of dv         : signal is true;
  -- Make sure 'data_valid_out' does not have a LUT in front of it which causes a hold time violation after synthesis.
  -- NB. The ASYNC_REG attributes already prevent the LUTs infront of the synchronising registers for 'dv'.
  attribute DIRECT_RESET of reset_dest : signal is true;

begin

  capture : if src_reg_g generate

    process(clk_src)
    begin
      if rising_edge(clk_src) then
        dv_in <= data_valid_in;
        di    <= data_in;
      end if;
    end process;

  else generate

      dv_in <= data_valid_in;
      di    <= data_in;

  end generate;


  sample : process(clk_dest)
  begin
    if rising_edge(clk_dest) then
      if reset_dest = '1' then
        dv             <= (others => '0');
        dv_d           <= '0';
        data_valid_out <= '0';
      else
        dv             <= dv_in & dv(0 to dv'high-1);
        dv_d           <= dv(dv'high);
        data_valid_out <= dv(dv'high) and not dv_d;
      end if;

      if dv(dv'high) = '1' and dv_d = '0' then
        data_out <= di;
      end if;
    end if;
  end process;


  -- synthesis translate_off
  stbl : block

    type slv_arr_t is array(integer range <>) of std_logic_vector;

    signal dv_in_d     : std_logic                                   := '0';
    signal dv_err      : boolean                                     := false;
    signal di_stbl     : boolean                                     := false;
    signal di_dly_vec  : slv_arr_t(0 to len_g-1)(width_g-1 downto 0) := (others => (others => '0'));
    -- Signal used by test bench external signal to verify correct operation
    signal stbl_at_clk : boolean                                     := false;
    signal clk_period  : time                                        := 0 ns;

    -- Is each element of 'vec' the same value? i.e. has the value remained stable over all
    -- clock periods?
    --
    -- If the value flips and flips back there has been instability that is in danger of being
    -- overlooked by the test "di_dly_vec(di_dly_vec'high) = di" alone.
    --
    function is_same(vec : slv_arr_t) return boolean is
      variable v : std_logic_vector(width_g-1 downto 0);
    begin
      v := vec(vec'low);
      for i in vec'low+1 to vec'high loop
        if v /= vec(i) then
          return false;
        end if;
      end loop;
      return true;
    end function;

  begin

    dv_test : process(clk_src)
    begin
      if rising_edge(clk_src) then
        dv_in_d <= dv_in;

        if dv_err then
          report "Data supplied faster than the CDC solution is designed for." severity warning;
        end if;
      end if;
    end process;

    dv_err <= (dv_in = '1' and dv_in_d = '1');

    -- We can verify the destination clock period has been correctly set, but we can't determine it and use the value in 'stable().
    timer : process(clk_dest)
      variable last_ev     : time    := 0 ns;
      variable last_ev_asn : boolean := false;
    begin
      if rising_edge(clk_dest) then
        if last_ev_asn then
          clk_period <= now - last_ev;
        end if;
        last_ev     := now;
        last_ev_asn := true;
      end if;
    end process;


    -- 'stable attribute requires a globally static parameter, i.e. 'dest_period_g * len_g' not a signal/variable like 'clk_period'.
    --    E.g. di_stbl <= di'stable(dest_period_g * len_g);
    -- We can recreate this from the measured 'clk_period' instead, NB. must not use a rising clock edge:
    di_dly_vec <= di & di_dly_vec(0 to di_dly_vec'high-1) after clk_period;
    di_stbl    <= (di_dly_vec(di_dly_vec'high) = di) and is_same(di_dly_vec);


    verify : process(clk_dest)
    begin
      if rising_edge(clk_dest) then
        if dv(dv'high) = '1' then
          if not di_stbl then
            report "Metastability Risk: 'di' was not stable for " & integer'image(len_g) & " destination clock periods when sampled." severity warning;
            stbl_at_clk <= false;
          else
            stbl_at_clk <= true;
          end if;
        end if;
      end if;
    end process;

  end block;
  -- synthesis translate_on

end architecture;
