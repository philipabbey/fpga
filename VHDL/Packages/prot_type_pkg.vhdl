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

package prot_type_pkg is

  type bool_pt is protected
    procedure set(i : boolean);
    impure function get return boolean;
  end protected;

end package;


package body prot_type_pkg is

  type bool_pt is protected body

    variable bool : boolean := false;

    procedure set(i : boolean) is
    begin
      bool := i;
    end procedure;

    impure function get return boolean is
    begin
      return bool;
    end function;

  end protected body;

end package body;
