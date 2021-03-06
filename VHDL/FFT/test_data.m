%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Distributed under MIT Licence
%%   See https://github.com/philipabbey/fpga/blob/main/LICENCE.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Test data generation for n-point FFT of timeseries used in VHDL simulations.
%%
%% References:
%%   1) https://www.youtube.com/watch?v=AF71Yqo7CoY
%%   2) https://www.youtube.com/watch?v=xnVaHkRaJOw
%%
%% P A Abbey, 1 Sep 2021
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x4=[
  1,   -1,  2,  1;
  1+i,  0, -1,  2;
  0,  5-i,  2, -2;
  0,    0,  1, -1
];

% Initial 8-point Radix-2 Decimation in time FFT test data
% x8(:,1) comes from the worked example at https://www.youtube.com/watch?v=AF71Yqo7CoY
% x8(:,2) comes from the worked example at https://www.youtube.com/watch?v=xnVaHkRaJOw

x8=[
  1, -1,  2,  1;
  1,  0, -1,  2;
  1,  2,  5,  3;
  0,  0,  1,  4;
  0, -4,  5, -4;
  0,  0, -1, -3;
  0,  2,  2, -2;
  0,  0,  1, -1
];

x16=[
  1, -1,  2,  1+i;
  1,  0, -1,  2;
  1,  2,  5,  3;
  0,  0,  1,  4-i;
  0, -4,  5,  5;
  0,  0, -1,  6;
  0,  2,  2,  7-i;
  0,  0,  1,  8;
  1, -1,  2, -8;
  1,  0, -1, -7;
  1,  2,  5, -6+i;
  0,  0,  1, -5;
  0, -4,  5, -4;
  0,  0, -1, -3+i;
  0,  2,  2, -2;
  0,  0,  1, -1
];

x32=[
  1, -1;
  1,  0;
  1,  2;
  0,  0;
  0, -8;
  0,  0;
  0,  2;
  0,  0;
  1, -1;
  1,  0;
  1,  2;
  0,  0;
  0, -4;
  0,  0;
  0,  2;
  0,  0;
  1, -1;
  1,  0;
  1,  2;
  0,  5;
  0, -4;
  0, -1;
  0,  2;
  0,  0;
  1, -1;
  1,  1;
  1,  2;
  0,  0;
  0, -4;
  0,  2;
  0,  2;
  0,  0
];

% Now try superimposing two tones of different frequency and amplitude
t = 0:1:511;
f1 = sin(0.2*t);
f2 = sin(0.1+0.3*t);
% Transpose the summation matrix from rows to columns
x512=(f1 + (0.5 * f2))';

% Uncomment to see the FFT of the superimposed pair of sine waves.
%plot(t, abs(fft(x512)))

function head(fid, package_name)
  fprintf(fid, '-------------------------------------------------------------------------------------\n');
  fprintf(fid, '--\n');
  fprintf(fid, '-- Distributed under MIT Licence\n');
  fprintf(fid, '--   See https://github.com/philipabbey/fpga/blob/main/LICENCE.\n');
  fprintf(fid, '--\n');
  fprintf(fid, '-------------------------------------------------------------------------------------\n');
  fprintf(fid, '--\n');
  fprintf(fid, '-- %s.vhdl\n', package_name);
  fprintf(fid, '-- This file of test data was generated by Octave.\n');
  fprintf(fid, '--\n');
  fprintf(fid, '-- References:\n');
  fprintf(fid, '--   1) https://www.youtube.com/watch?v=AF71Yqo7CoY\n');
  fprintf(fid, '--   2) https://www.youtube.com/watch?v=xnVaHkRaJOw\n');
  fprintf(fid, '--\n');
  fprintf(fid, strftime ("-- P A Abbey, %d %b %Y\n", localtime (time ())));
  fprintf(fid, '--\n');
  fprintf(fid, '-------------------------------------------------------------------------------------\n');
  fprintf(fid, '\n');
  fprintf(fid, 'use work.test_fft_pkg.complex_vector_arr_t;\n');
  fprintf(fid, '\n');
  fprintf(fid, 'package %s is\n', package_name);
  fprintf(fid, '\n');
end

function vhdl_test_data(fid, data, const_str)
  points=size(data)(1); % Rows, n-opint FFT inputs, i.e. time series
  sets=size(data)(2);   % Columns, array of inputs
  col=1;
  fprintf(fid, '  constant %s : complex_vector_arr_t(open)(0 to %d) := (\n', const_str, points-1);
  for col=1:sets
    fprintf(fid, '    %d => (\n', col);
    for row=1:points
      % Final comma must be omitted for VHDL array
      if (row < points)
        comma=",";
      else
        comma="";
      endif
      z=data(row, col);
      fprintf(fid, '      (re => %11.6f, im => %11.6f)%s\n', real(z), imag(z), comma);
    end
    if (col < sets)
      fprintf(fid, '    ),\n');
    else
      fprintf(fid, '    )\n');
      fprintf(fid, '  );\n');
    end
  end
  fprintf(fid, '\n');
end

function tail(fid, package_name)

  fprintf(fid, '  function test_data_inputs(p : positive) return complex_vector_arr_t;\n');
  fprintf(fid, '\n');
  fprintf(fid, '  function test_data_outputs(p : positive) return complex_vector_arr_t;\n');
  fprintf(fid, '\n');

  fprintf(fid, 'end package;\n');
  fprintf(fid, '\n\n');
  fprintf(fid, 'package body %s is\n', package_name);
  fprintf(fid, '\n');
  fprintf(fid, '  function test_data_inputs(p : positive) return complex_vector_arr_t is\n');
  fprintf(fid, '  begin\n');
  fprintf(fid, '    case p is\n');
  fprintf(fid, '      when      4 => return work.test_data_fft_pkg.input_data_point4_c;\n');
  fprintf(fid, '      when      8 => return work.test_data_fft_pkg.input_data_point8_c;\n');
  fprintf(fid, '      when     16 => return work.test_data_fft_pkg.input_data_point16_c;\n');
  fprintf(fid, '      when     32 => return work.test_data_fft_pkg.input_data_point32_c;\n');
  fprintf(fid, '      when    512 => return work.test_data_fft_pkg.input_data_point512_c;\n');
  fprintf(fid, '      when others =>\n');
  fprintf(fid, "        report \"Missing test data for \" & integer\'image(p) severity error;\n");
  fprintf(fid, '        -- A nonsense value to keep the compiler quiet about not returning a anything\n');
  fprintf(fid, '        return (0 => (0 => (re => 0.0, im => 0.0)));\n');
  fprintf(fid, '    end case;\n');
  fprintf(fid, '  end function;\n');
  fprintf(fid, '\n\n');
  fprintf(fid, '  function test_data_outputs(p : positive) return complex_vector_arr_t is\n');
  fprintf(fid, '  begin\n');
  fprintf(fid, '    case p is\n');
  fprintf(fid, '      when      4 => return work.test_data_fft_pkg.output_data_point4_c;\n');
  fprintf(fid, '      when      8 => return work.test_data_fft_pkg.output_data_point8_c;\n');
  fprintf(fid, '      when     16 => return work.test_data_fft_pkg.output_data_point16_c;\n');
  fprintf(fid, '      when     32 => return work.test_data_fft_pkg.output_data_point32_c;\n');
  fprintf(fid, '      when    512 => return work.test_data_fft_pkg.output_data_point512_c;\n');
  fprintf(fid, '      when others =>\n');
  fprintf(fid, "        report \"Missing test data for \" & integer\'image(p) severity error;\n");
  fprintf(fid, '        -- A nonsense value to keep the compiler quiet about not returning a anything\n');
  fprintf(fid, '        return (0 => (0 => (re => 0.0, im => 0.0)));\n');
  fprintf(fid, '    end case;\n');
  fprintf(fid, '  end function;\n');
  fprintf(fid, '\n');
  fprintf(fid, 'end package body;\n');
end

% Compose the test data file from multiple sources
package_name="test_data_fft_pkg";
fid = fopen(strcat(package_name, ".vhdl"), 'wt');
head(fid, package_name);
vhdl_test_data(fid, x4, "input_data_point4_c");
vhdl_test_data(fid, fft(x4), "output_data_point4_c");
vhdl_test_data(fid, x8, "input_data_point8_c");
vhdl_test_data(fid, fft(x8), "output_data_point8_c");
vhdl_test_data(fid, x16, "input_data_point16_c");
vhdl_test_data(fid, fft(x16), "output_data_point16_c");
vhdl_test_data(fid, x32, "input_data_point32_c");
vhdl_test_data(fid, fft(x32), "output_data_point32_c");
vhdl_test_data(fid, x512, "input_data_point512_c");
vhdl_test_data(fid, fft(x512), "output_data_point512_c");
tail(fid, package_name);
fclose(fid);
