cd ..\Tools\bootstrap
rgbasm -obootstrap.obj bootstrap.s
rgblink -mbootstrap.map -nbootstrap.sym -obootstrap.rom bootstrap.obj
..\bin2mif\bin2mif bootstrap.rom bootstrap.mif 256
copy bootstrap.mif ..\..\Verilog\GameBoy\brom.mif
pause