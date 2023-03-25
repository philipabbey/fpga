-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Create an OSVVM scoreboard (FIFO) of ASCII characters.
--
-- P A Abbey, 24 March 2023
--
-------------------------------------------------------------------------------------

library osvvm;

package ScoreBoardPkg_char is new osvvm.ScoreboardGenericPkg
  generic map (
    ExpectedType        => character,
    ActualType          => character,
    Match               => "=",
    expected_to_string  => to_string,
    actual_to_string    => to_string
  );
