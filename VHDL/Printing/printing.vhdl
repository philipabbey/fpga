-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- A non-pipelined recursive adder tree used to add 2 or more operands together. This
-- component is asynchronous. Registering results is done outside this component.
--
-- P A Abbey, 16 June 2023
--
-- References:
--  * https://stackoverflow.com/questions/57116951/in-vhdl-2008-how-to-format-real-similar-to-f-in-c-language-example-sprin/57117446#57117446
--  * http://ebook.pldworld.com/_eBook/FPGA%EF%BC%8FHDL/-Eng-/VHDL-2008.%20Just%20the%20New%20Stuff%20(Peter%20Ashenden,%20Jim%20Lewis).pdf
--
-------------------------------------------------------------------------------------

entity printing_tb is
end entity;


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.math_complex.all;
library std;
  use std.textio.all;

architecture test of printing_tb is

  procedure print(s : string) is
    variable l : line;
  begin
    write(l, s);
    writeline(output, l);
  end procedure;


--  procedure print(s1, s2 : string) is
--    variable l : line;
--  begin
--    write(
--      l,
--      justify(
--        value     => s1,
--        justified => right,
--        field     => 10
--      ) & " " & s2
--    );
--    writeline(output, l);
--  end procedure;


  procedure print(s1, s2 : string) is
    variable l : line;
  begin
    write(l, s1, right, 18);
    swrite(l, " ");
    write(l, s2);
    writeline(output, l);
  end procedure;


  function to_string(
    c      : complex;
    digits : natural := 0
  ) return string is
  begin
    return to_string(c.re, digits) & " " & to_string(c.im, digits) & "i";
  end function;


  function to_string(
    c      : complex;
    format : string
  ) return string is
  begin
    return to_string(c.re, format) & " " & to_string(c.im, format) & "i";
  end function;


  -- Create a string from a real in non-normalised scientific form. That means the significand or
  -- mantissa does not need to be a value between 1 and 10. This is convenient when wanting to display
  -- real values as strings in an ISO unit, typically where the exponent is -9, -6, -3, 0, 3, 6 etc,
  -- i.e. in engineering notation. But this function is more general in that it works for any exponent.
  --
  function to_scientific(
    value  : real;
    exp    : integer; -- e.g. -6 for micro
    digits : positive := 1
  ) return string is

    -- For a real printed as x.xxxe+04, extract the part starting with 'e' to the end of the string.
    -- i.e. e+04" in this example.
    function exponent(
      str : string
    ) return string is
    begin
      for i in str'range loop
        if str(i) = 'e' then
          return str(i to str'high);
        end if;
      end loop;
      return "";
    end function;

    constant scale : real := 10.0**exp;

  begin
    return to_string(value / scale, digits) & exponent(to_string(scale));
  end function;


  -- Use overloaded read() functions to convert from string to a real.
  --
  function to_real(str : string) return real is
    variable l : line;
    variable r : real;
  begin
    write(l, str);
    read(l, r);
    return r;
  end function;

begin

  process
    variable r   : real := 3.141592653589793238e-4;
    variable slv : std_logic_vector(7 downto 0) := "10110101";
    variable c   : complex := (1.2345, -1.2345);
  begin

    -- Printing real
    print("real 1:", to_string(r));
    -- #            real 1: 3.141593e-04
    print("real 2:", to_string(r, 5));
    -- #            real 2: 0.00031
    -- If the 'digits' parameter is zero, the conversion behaves as if it were absent.
    print("real 3:", to_string(r, 0));
    -- #            real 3: 3.141593e-04
    print("real 4:", to_string(r, "%.2g"));
    -- #            real 4: 0.00031
    print("scientific 1:", to_scientific(50.123e+7, 7, 2));
    -- #      scientific 1: 50.12e+07
    r := to_real(to_scientific(50.123e+7, 7, 2));
    print("real 5:", to_string(r));
    -- #            real 5: 5.012000e+08

    for i in -4 to 4 loop
      print(
        "scientific exp=" & justify(to_string(i), field => 2) & ":",
        to_scientific(1.23456789e+0, i, 4)
      );
    end loop;
    -- # scientific exp=-4: 12345.6789e-04
    -- # scientific exp=-3: 1234.5679e-03
    -- # scientific exp=-2: 123.4568e-02
    -- # scientific exp=-1: 12.3457e-01
    -- # scientific exp= 0: 1.2346e+00
    -- # scientific exp= 1: 0.1235e+01
    -- # scientific exp= 2: 0.0123e+02
    -- # scientific exp= 3: 0.0012e+03
    -- # scientific exp= 4: 0.0001e+04

    -- printing time
    print("time 1:", to_string(12.5 ns, ps));
    -- #            time 1: 12500 ps

    print(
      "time 2:",
      justify(
        value => to_string(321.5 ps, fs),
        field => 20
      )
    );
    -- #            time 2:               322 ps

    -- You would most likely use 'justify()' for a right justification (the default for the 'justified' parameter),
    -- otherwise you are just adding spaces to pad to the right.
    print(
      "vector 1:",
      justify(
        value     => to_string(std_ulogic_vector'("00010110")),
        -- Pointless justification specification
        justified => left, -- 'right' or 'left' only.
        field     => 20
      )
    );
    -- #          vector 1: 00010110

    print("vector 2:", "0x" & to_hstring(slv));
    -- #          vector 2: 0xB5

    print(
      "int 1:",
      justify(
        value => to_string(20),
        field => 20
      )
    );
    -- #             int 1:                   20

    print("complex 1:", to_string(c, 2));
    -- #         complex 1: 1.23 -1.23i

    print(
      "complex 2:",
      justify(
        value => to_string(c, "%.3f"),
        field => 20
      )
    );
    -- #         complex 2:        1.234 -1.234i

    std.env.stop;
    wait;
  end process;

end architecture;
