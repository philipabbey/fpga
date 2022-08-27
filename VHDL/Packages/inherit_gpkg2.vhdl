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

-- Java: class inherit_pkg extends base_pkg {..}


package inherit_gpkg2 is
  generic(width_g : positive := 8);

  package inst_pkg is new work.base_gpkg
    generic map (width_g => width_g);

  -- Without the type alias, th function alias would need to include the package
  -- alias reverse is inst_pkg.reverse [inst_pkg.slv_vector_t return inst_pkg.slv_vector_t];
  alias slv_vector_t is inst_pkg.slv_vector_t;
  alias reverse is inst_pkg.reverse[slv_vector_t return slv_vector_t];

  -- Barrel shift a std_logic_vector
  --  * s > 0 -> rotate left
  --  * s < 0 -> rotate right
  --
  function shift (
    v : slv_vector_t;
    s : integer := 1
  ) return slv_vector_t;

end package;


package body inherit_gpkg2 is

  function shift (
    v : slv_vector_t;
    s : integer := 1
  ) return slv_vector_t is
    variable ret : slv_vector_t;
  begin
    for i in v'range loop
      ret(i) := v((i - s) mod v'length);
    end loop;
    return ret;
  end function;

end package body;
