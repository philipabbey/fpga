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

package inherit_pkg1 is

  package inst_pkg is new work.base_pkg;

  -- Without the type alias, th function alias would need to include the package
  -- alias reverse is inst_pkg.reverse [inst_pkg.slv_vector_t return inst_pkg.slv_vector_t];
  alias slv_vector_t is inst_pkg.slv_vector_t;
  alias reverse is inst_pkg.reverse[slv_vector_t return slv_vector_t];

  -- Barrel shift a std_logic_vector
  --  * s > 0 -> rotate left
  --  * s < 0 -> rotate right
  --
  function shift (
    v : inst_pkg.slv_vector_t;
    s : integer := 1
  ) return inst_pkg.slv_vector_t;

end package;


package body inherit_pkg1 is

  function shift (
    v : inst_pkg.slv_vector_t;
    s : integer := 1
  ) return inst_pkg.slv_vector_t is
    variable ret : inst_pkg.slv_vector_t;
  begin
    for i in v'range loop
      ret(i) := v((i - s) mod v'length);
    end loop;
    return ret;
  end function;

end package body;
