library ieee;
  use ieee.std_logic_1164.all;
library osvvm;

package sent_pkg is
  generic(width : positive);

  type sent_t is record
    data  : std_logic_vector(width-1 downto 0);
    delay : time;
  end record;
  
  constant sent_init_c : sent_t := (
    data  => (others => '0'),
    delay => 0 ns
  );

  function to_string(s : sent_t) return string;

  package ScoreBoardPkg_sent is new osvvm.ScoreboardGenericPkg
    generic map (
      ExpectedType       => sent_t,
      ActualType         => sent_t,
      match              => "=",
      expected_to_string => to_string,
      actual_to_string   => to_string
    );

end package;


package body sent_pkg is

  function to_string(s : sent_t) return string is
  begin
    return "data: 0x" & to_hstring(s.data) & " delay: " & to_string(s.delay, ns);
  end function;

end package body;
