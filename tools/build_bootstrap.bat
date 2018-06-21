cd ..\roms
rgbasm -obootstrap.obj bootstrap.s
rgblink -mbootstrap.map -nbootstrap.sym -obootstrap.rom bootstrap.obj
..\tools\bin2mif\bin2mif bootstrap.rom bootstrap.mif 256
..\tools\bin2mif\bin2mif bootstrap.rom testrom.mif 8192
copy bootstrap.mif ..\rtl\GameBoy\brom.mif
copy testrom.mif ..\rtl\GameBoy\testrom.mif
pause