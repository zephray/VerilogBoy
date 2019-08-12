This dir contains simple cores to access the internal SPI-flash via BSCAN/USER1.

The bitfiles are provided for your convenience.

All IOBs are unused and set to float.
The config + JTAG pins have their default pull-up/downs enabled. 
You have to make your own bitstream if you don't like that.

The Spartan-3E Starterkit (ug320.pdf) can have a lot of possible
contentions. So BSCAN_SPI needs some more Pins set to work. Often the first
run with the -I option still fails. The kit also fails to reboot after some
-I run has been done.

