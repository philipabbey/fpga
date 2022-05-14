-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Test the A pause mechanism for an AXI Data Stream.
--
-- References:
--  * Explanation here: https://www.itdev.co.uk/blog/pipelining-axi-buses-registered-ready-signals
--
-- P A Abbey, 1 April 2022
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

entity axi_delay_mixed is
  generic(
    delay_vector_g : std_logic_vector; -- Any '1' bit gives the pipelined version, otherwise non-pipelined.
    data_width_g   : positive
  );
  port(
    clk         : in  std_logic;
    s_axi_data  : in  std_logic_vector(data_width_g-1 downto 0);
    s_axi_valid : in  std_logic;
    s_axi_ready : out std_logic;
    m_axi_data  : out std_logic_vector(data_width_g-1 downto 0);
    m_axi_valid : out std_logic;
    m_axi_ready : in  std_logic
  );
end entity;


architecture structural of axi_delay_mixed is

  constant delay_c        : positive := delay_vector_g'length;
  -- Make sure we know the range of this generic for indexing. Aliases cannot be used.
  constant delay_vector_c : std_logic_vector(delay_c-1 downto 0) := delay_vector_g;

  type delay_reg_t is array(delay_c downto 0) of std_logic_vector(data_width_g-1 downto 0);

  signal data_stage  : delay_reg_t                        := (others => (others => '0'));
  signal valid_stage : std_logic_vector(delay_c downto 0) := (others => '0');
  signal ready_stage : std_logic_vector(delay_c downto 0) := (others => '0');

begin

  m_axi_valid          <= valid_stage(0);
  m_axi_data           <= data_stage(0);
  ready_stage(0)       <= m_axi_ready;
  valid_stage(delay_c) <= s_axi_valid;
  data_stage(delay_c)  <= s_axi_data;
  s_axi_ready          <= ready_stage(delay_c);

  delay_g : for i in delay_vector_c'range generate

    pipe_g : if delay_vector_c(i) = '1' generate

      axi_delay_stage_i : entity work.axi_delay_stage(rtl_pipe)
        generic map (
          data_width_g => data_width_g
        )
        port map (
          clk      => clk,
          us_valid => valid_stage(i+1),
          us_data  => data_stage(i+1),
          us_ready => ready_stage(i+1),
          ds_valid => valid_stage(i),
          ds_data  => data_stage(i),
          ds_ready => ready_stage(i)
        );

    else generate

      axi_delay_stage_i : entity work.axi_delay_stage(rtl_basic)
        generic map (
          data_width_g => data_width_g
        )
        port map (
          clk      => clk,
          us_valid => valid_stage(i+1),
          us_data  => data_stage(i+1),
          us_ready => ready_stage(i+1),
          ds_valid => valid_stage(i),
          ds_data  => data_stage(i),
          ds_ready => ready_stage(i)
        );

    end generate;

  end generate;

end architecture;
