-------------------------------------------------------------------------------------
--
-- Distributed under MIT Licence
--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
--
-------------------------------------------------------------------------------------
--
-- Aggregate four instantiations of a seven segment display decoder in order to
-- display the time.
--
-- P A Abbey, 18 September 2020
--
-------------------------------------------------------------------------------------

entity time_display is
  port(
    digit : in  work.sevseg_pkg.digits_t;
    disp  : out work.sevseg_pkg.time_disp_t
  );
end entity;

architecture rtl of time_display is
begin

  gd : for i in digit'range generate

    sevseg_display_i : entity work.sevseg_display
      port map (
        digit => digit(i),
        disp  => disp(i)
      );

  end generate;

end architecture;
