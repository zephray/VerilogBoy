/*******************************************************************************

    This program is free software (firmware): you can redistribute it and/or
    modify it under the terms of  the GNU General Public License as published
    by the Free Software Foundation, either version 3 of the License, or (at
    your option) any later version.
   
    This program is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.
   
    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/> for a copy.

    Description: VerilogBoy MCU Firmware main source code

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/

#include "inc.h"
#include "usb_cdc.h"
#include "misc.h"
#include "axp.h"

int main(void)
{
	rcc_clock_setup_in_hse_24mhz_out_72mhz();
	delay_setup();
	rcc_periph_clock_enable(RCC_GPIOA);
	usb_disconnect();
	usbcdc_init();
	delay_ms(2000);
    printf("\r\n\r\n");
	printf("VerilogBoy Debug Console\r\n");
    printf("Built on %s\r\n\r\n", __DATE__);
    axp_init();
	while(1) {

    }

}
