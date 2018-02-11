cd ..\Tools\screenlayout
..\bin2mif\bin2mif screen1.txt screen1.mif 80
..\bin2mif\bin2mif screen2.txt screen2.mif 80
copy screen1.mif ..\..\Verilog\GameBoy\screen1.mif
copy screen2.mif ..\..\Verilog\GameBoy\screen2.mif
pause