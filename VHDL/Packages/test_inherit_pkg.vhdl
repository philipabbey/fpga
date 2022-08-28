-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Experiments on packages post VHDL-2008.
--
-- P A Abbey, 27 August 2022
--
-------------------------------------------------------------------------------------

entity test_inherit_pkg is
end entity;


library ieee;
  use ieee.std_logic_1164.std_ulogic;

architecture test1 of test_inherit_pkg is

  signal v1 : work.inherit_pkg1.inst_pkg.slv_vector_t;
  signal v2 : work.inherit_pkg1.inst_pkg.slv_vector_t;
  signal v3 : work.inherit_pkg1.inst_pkg.slv_vector_t;
  signal v4 : work.inherit_pkg1.inst_pkg.slv_vector_t;

begin

  v1 <= "10110010";
  v2 <= work.inherit_pkg1.shift(v1, 2);

  v3 <= "10000010";
  v4 <= work.inherit_pkg1.inst_pkg.reverse(v3);

end architecture;


library ieee;
  use ieee.std_logic_1164.std_ulogic;

architecture test2 of test_inherit_pkg is

  -- Create a new local package
  package inst_pkg is new work.inherit_pkg1;

  signal v1 : inst_pkg.inst_pkg.slv_vector_t;
  signal v2 : inst_pkg.inst_pkg.slv_vector_t;
  signal v3 : inst_pkg.inst_pkg.slv_vector_t;
  signal v4 : inst_pkg.inst_pkg.slv_vector_t;

begin

  v1 <= "10110010";
  v2 <= inst_pkg.shift(v1, 2);

  v3 <= "10000010";
  v4 <= inst_pkg.inst_pkg.reverse(v3);

end architecture;


library ieee;
  use ieee.std_logic_1164.std_ulogic;

architecture test3 of test_inherit_pkg is

  -- Create a new local package
  package inst_pkg is new work.inherit_pkg2;

  signal v1 : inst_pkg.slv_vector_t;
  signal v2 : inst_pkg.slv_vector_t;
  signal v3 : inst_pkg.slv_vector_t;
  signal v4 : inst_pkg.slv_vector_t;

begin

  v1 <= "10110010";
  v2 <= inst_pkg.shift(v1, 2);

  v3 <= "10000010";
  v4 <= inst_pkg.reverse(v3);

end architecture;


library ieee;
  use ieee.std_logic_1164.std_ulogic;

architecture test4 of test_inherit_pkg is

  -- Create a new local package
  package inst_pkg is new work.inherit_gpkg2
    generic map (width_g => 11);

  signal v1 : inst_pkg.slv_vector_t;
  signal v2 : inst_pkg.slv_vector_t;
  signal v3 : inst_pkg.slv_vector_t;
  signal v4 : inst_pkg.slv_vector_t;

begin

  v1 <= "10110010010";
  v2 <= inst_pkg.shift(v1, 2);

  v3 <= "10000010100";
  v4 <= inst_pkg.reverse(v3);

end architecture;
