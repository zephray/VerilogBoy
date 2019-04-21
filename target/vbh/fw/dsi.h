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

    Description: VBMMP dsicore driver

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __DSI_H__
#define __DSI_H__

#define BIT_RST_OUT (1 << 6)
#define BIT_TIM_EN (1 << 4)
#define BIT_LP_REQ (1 << 1)
#define BIT_CLK_EN (1 << 0)

uint8_t parity(uint32_t d);
uint8_t dsi_ecc(uint32_t data);
uint16_t dsi_crc(const uint8_t *d, int n);
void dsi_lp_write_byte(uint8_t value);
void dsi_lp_write_short(uint8_t ptype, uint8_t w0, uint8_t w1);
void dsi_lp_write_long(int is_dcs, const unsigned char *data, int length);
void dsi_init(void);

#endif