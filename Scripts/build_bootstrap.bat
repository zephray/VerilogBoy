cd ..\Tools\bootstrap
rgbasm -obootstrap.obj bootstrap.s
rgblink -mbootstrap.map -nbootstrap.sym -obootstrap.rom bootstrap.obj
pause