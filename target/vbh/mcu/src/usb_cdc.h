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

    Description: USB CDC ACM related functions

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __USB_CDC_H__
#define __USB_CDC_H__

#include "inc.h"

#define USBCDC_PKT_SIZE_DAT 64
#define USBCDC_PKT_SIZE_INT 16

#define DEV_VID  0x0483 /* ST Microelectronics */
#define DEV_PID  0x5740 /* STM32 */
#define DEV_VER  0x0009 /* 0.9 */

#define EP_INT   0x83
#define EP_OUT   0x82
#define EP_IN    0x01

#define STR_MAN  0x01
#define STR_PROD 0x02
#define STR_SER  0x03

extern char usbcdc_rxbuf[USBCDC_PKT_SIZE_DAT]; /* DMA needs access */
extern volatile bool usb_ready;

int _write(int file, char *ptr, int len);

void     usb_disconnect(void);
void     usbcdc_init(void);
uint16_t usbcdc_write(void *buf, size_t len);
uint16_t usbcdc_putc(char c);
uint16_t usbcdc_putu32(uint32_t word);
uint16_t usbcdc_fetch_packet(void);
char     usbcdc_getc(void);
uint32_t usbcdc_getu24(void);
uint32_t usbcdc_getu32(void);
uint8_t usbcdc_get_remainder(char **bufpp);

#endif