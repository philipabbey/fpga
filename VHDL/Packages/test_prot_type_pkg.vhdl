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

entity test_prot_type_pkg is
end entity;


architecture test of test_prot_type_pkg is

  shared variable bool : work.prot_type_pkg.bool_pt;

begin

  set_p : process
  begin
    -- Initialise at start if protectwed type's initial value is not as required.
    bool.set(true);
    while true loop
      wait for 10 ns;
      bool.set(true);
      wait for 10 ns;
    end loop;
  end process;

  unset_p : process
  begin
    bool.set(false);
    wait for 20 ns;
  end process;

end architecture;
