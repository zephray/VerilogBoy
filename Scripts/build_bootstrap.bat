cd ..\Tools\bootstrap
rgbasm -obootstrap.obj bootstrap.s
rgblink -mbootstrap.map -nbootstrap.sym -obootstrap.rom bootstrap.obj
..\bin2mif\bin2mif bootstrap.rom bootstrap.mif 256
..\bin2mif\bin2mif bootstrap.rom testrom.mif 8192
copy bootstrap.mif ..\..\Verilog\GameBoy\brom.mif
copy testrom.mif ..\..\Verilog\GameBoy\testrom.mif
pause