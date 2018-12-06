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

#include "inc.h"

#define REG_DSIC_CTL   0x10
#define REG_DSIC_TICK  0x11
#define REG_DSIC_TXDR  0x12
#define REG_DSIC_HFP   0x13
#define REG_DSIC_HBP   0x14
#define REG_DSIC_HACTL 0x15
#define REG_DSIC_HTL   0x16
#define REG_DSIC_HATH  0x17
#define REG_DSIC_VFP   0x18
#define REG_DSIC_VBP   0x19
#define REG_DSIC_VACTL 0x1A
#define REG_DSIC_VTL   0x1B
#define REG_DSIC_VATH  0x1C

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