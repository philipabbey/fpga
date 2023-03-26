-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Conversion utilities between ASCII characters and vectors.
--
-- P A Abbey, 26 March 2023
--
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package char_utils_pkg is

  function char2vec(c : character) return std_logic_vector;

  function vec2char(s : std_logic_vector) return character;

end package;


package body char_utils_pkg is

  function char2vec(c : character) return std_logic_vector is
  begin
    return ieee.numeric_std_unsigned.to_stdlogicvector(character'pos(c), 8);
  end function;

  function vec2char(s : std_logic_vector) return character is
  begin
    assert s'length = 8
      report "Error: vec2char() must be passed an 8-bit vector."
      severity failure;
    return character'val(ieee.numeric_std_unsigned.to_integer(s));
  end function;

end package body;
