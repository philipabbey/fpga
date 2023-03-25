-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Demonstartor for editing a protocol in a stream of bytes sent over AXI.
--
-- Reference: AXI Stream General Edit
--            https://blog.abbey1.org.uk/index.php/technology/axi-stream-general-edit
--
-- P A Abbey, 24 March 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity protocol_edit is
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(7 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_ready : out std_logic                    := '0';
    m_axi_data  : out std_logic_vector(7 downto 0) := (others => '0');
    m_axi_valid : out std_logic                    := '0';
    m_axi_ready : in  std_logic
  );
end entity;


architecture rtl of protocol_edit is

  type axi_op_t is (
    pass,
    pause,
    swap,
    drop,
    insert
  );

  type state_t is (
    readip,
    swap1a,
    swap1b,
    swap1c,
    swap1d,
    del3a,
    del3b,
    del3c,
    del3d,
    ins4b,
    ins5a1,
    ins5a2,
    ins5a3,
    ins5b1,
    ins5b2,
    ins5b3
  );

  signal delay_data  : std_logic_vector(7 downto 0);
  signal delay_valid : std_logic;
  signal delay_ready : std_logic;
  signal axi_rd      : std_logic                    := '1';
  signal axi_wr      : std_logic                    := '1';
  signal alt_data    : std_logic_vector(7 downto 0) := ieee.numeric_std_unsigned.to_stdlogicvector(character'pos('-'), 8);
  signal alt_valid   : std_logic                    := '0';
  signal alt_ready   : std_logic                    := '0';
  signal state       : state_t                      := readip;
  signal axi_op      : axi_op_t                     := pass;
  signal consumed    : std_logic                    := '0';
  signal awked_wr    : std_logic                    := '0';
  signal pass_input  : std_logic                    := '1';

  -- Convert the readable enumberated type to the values required to drive signals:
  -- Returns a 3-bit vector formed as read_enable & write_enable & alt_valid
  --
  function opconv(op : axi_op_t) return std_logic_vector is
  begin
    case op is
      when pause  => return "000";
      when insert => return "011";
      when drop   => return "100";
      when pass   => return "110";
      when swap   => return "111";
    end case;
  end function;

  -- ASCII character conversion utility
  --
  function char2vec(c : character) return std_logic_vector is
  begin
    return ieee.numeric_std_unsigned.to_stdlogicvector(character'pos(c), 8);
  end function;

  -- ASCII character conversion utility
  --
  function vec2char(s : std_logic_vector) return character is
  begin
    assert s'length = 8
      report "Error: vec2char() must be passed an 8-bit vector."
      severity failure;
    return character'val(ieee.numeric_std_unsigned.to_integer(s));
  end function;

begin

  axi_delay_i : entity work.axi_edit
    generic map (
      data_width_g => 8
    )
    port map (
      clk         => clk,
      s_axi_data  => s_axi_data,
      s_axi_valid => s_axi_valid,
      s_axi_rd    => pass_input,
      s_axi_ready => s_axi_ready,
      alt_data    => x"00",
      alt_valid   => '0',
      alt_ready   => open,
      m_axi_data  => delay_data,
      m_axi_valid => delay_valid,
      m_axi_wr    => pass_input,
      m_axi_ready => delay_ready
    );


  axi_edit_i : entity work.axi_edit
    generic map (
      data_width_g => 8
    )
    port map (
      clk         => clk,
      s_axi_data  => delay_data,
      s_axi_valid => delay_valid,
      s_axi_rd    => axi_rd,
      s_axi_ready => delay_ready,
      alt_data    => alt_data,
      alt_valid   => alt_valid,
      alt_ready   => alt_ready,
      m_axi_data  => m_axi_data,
      m_axi_valid => m_axi_valid,
      m_axi_wr    => axi_wr,
      m_axi_ready => m_axi_ready
    );

  (axi_rd, axi_wr, alt_valid) <= opconv(axi_op);

  process(clk)
  begin
    if rising_edge(clk) then

      consumed <= '0';
      if alt_ready = '1'and alt_valid = '1' then
        awked_wr <= '1';
      end if;

      awked_wr <= '0';
      if s_axi_ready = '1' and s_axi_valid = '1' then
        consumed <= '1';
      end if;

      case state is

        when readip =>

          -- An insert completes before the stalled word in delay_data, and before or at the same time as the next input word.
          if alt_ready = '1' and alt_valid = '1' then
            axi_op     <= pass;
            pass_input <= '1';
          end if;

          if s_axi_ready = '1' and s_axi_valid = '1' then
            case vec2char(s_axi_data) is

              -- Test 1a: Swap a sequence from character A until character B with 'y' characters, retain A & B characters
              when 'A' =>
                axi_op <= pass;
                state  <= swap1a;

              -- Test 1b: Swap a sequence from characters C until character D with 'y' characters, use D as the stop character
              when 'C' =>
                axi_op <= drop;
                state  <= swap1b;

              -- Test 1c: Swap a sequence from characters E until character F with 'y' characters, use E as the start character
              when 'E' =>
                axi_op <= pass;
                state  <= swap1c;

              -- Test 1d: Swap a sequence from characters G until character H with 'y' characters, drop G & H characters
              when 'G' =>
                axi_op <= drop;
                state  <= swap1d;

              -- Test 2a: Delete a single character
              when 'Z' =>
                axi_op <= drop;

              -- Test 3a. Delete sequence from character I until character J, retain I & J characters
              when 'I' =>
                axi_op <= pass;
                state  <= del3a;

              -- Test 3b. Delete sequence from character K until character L, use L as the stop character
              when 'K' =>
                axi_op <= drop;
                state  <= del3b;

              -- Test 3c. Delete sequence from character M until character N, use M as the start character
              when 'M' =>
                axi_op <= pass;
                state  <= del3c;

              -- Test 3d. Delete sequence from character O until character P, drop O & P characters
              when 'O' =>
                axi_op <= drop;
                state  <= del3d;

              -- Test 4a. Insert a character, before Q
              when 'Q' =>
                axi_op <= insert;

              -- Test 4b. Insert a character, after R
              when 'R' =>
                axi_op <= pass;
                state  <= ins4b;

              -- Test 5a. Insert sequence, before character S
              when 'S' =>
                axi_op   <= insert;
                alt_data <= char2vec('y');
                state    <= ins5a1;

              -- Test 5b. Insert sequence, after character T
              when 'T' =>
                axi_op     <= pass;
                pass_input <= '0';
                state      <= ins5b1;

              -- Test 5c. Insert sequence, instead of character U
              when 'U' =>
                axi_op     <= drop;
                pass_input <= '0';
                state      <= ins5b1;

              -- Test 5d. Insert sequence, between V and W
              when 'V' =>
                axi_op     <= pass;
                pass_input <= '0';
                state      <= ins5b1;

              when others =>
                axi_op <= pass;

            end case;
          end if;

        when swap1a =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= swap;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'B' then
              axi_op   <= pass;
              alt_data <= char2vec('y');
              state    <= readip;
            end if;
          end if;

        when swap1b =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= swap;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'D' then
              axi_op   <= pass;
              alt_data <= char2vec('y');
              state    <= readip;
            end if;
          end if;

        when swap1c =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= swap;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'F' then
              axi_op   <= drop;
              alt_data <= char2vec('y');
              state    <= readip;
            end if;
          end if;

        when swap1d =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= swap;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'H' then
              axi_op   <= drop;
              alt_data <= char2vec('y');
              state    <= readip;
            end if;
          end if;

        when del3a =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= drop;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'J' then
              axi_op   <= pass;
              state    <= readip;
            end if;
          end if;

        when del3b =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= drop;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'L' then
              axi_op   <= pass;
              state    <= readip;
            end if;
          end if;

        when del3c =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= drop;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'N' then
              axi_op   <= drop;
              state    <= readip;
            end if;
          end if;

        when del3d =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= drop;
            alt_data <= char2vec('y');
            if vec2char(s_axi_data) = 'P' then
              axi_op   <= drop;
              state    <= readip;
            end if;
          end if;

        when ins4b =>
          if s_axi_ready = '1' and s_axi_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= readip;
          end if;

        -- Could be done with a counter to save states
        when ins5a1 =>
          if alt_ready = '1' and alt_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= ins5a2;
          end if;

        when ins5a2 =>
          if alt_ready = '1' and alt_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= ins5a3;
          end if;

        when ins5a3 =>
          if alt_ready = '1' and alt_valid = '1' then
            axi_op <= pass;
            state  <= readip;
          end if;

        -- Could be done with a counter to save states
        when ins5b1 =>
          -- The input AXI register delay is currently stalled. Wait for the take, not for the next input.
          if delay_ready = '1' and delay_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= ins5b2;
          end if;

        when ins5b2 =>
          if alt_ready = '1' and alt_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= ins5b3;
          end if;

        when ins5b3 =>
          if alt_ready = '1' and alt_valid = '1' then
            axi_op   <= insert;
            alt_data <= char2vec('y');
            state    <= readip;
          end if;

        when others =>
          state <= readip;

      end case;
    end if;
  end process;

end architecture;
