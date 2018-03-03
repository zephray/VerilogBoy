cd ..\Roms
for %%i in (*.gb) do (
  ..\Tools\bin2mif\bin2mif %%i %%~ni.hex 32768
  C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\promgen -r %%~ni.hex -p mcs -data_width 16 -w -o %%~ni.mcs
)
pause