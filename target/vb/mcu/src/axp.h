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

    Description: Driver for AXP series PMU

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __AXP_H__
#define __AXP_H__

#include "inc.h"

#define AXP_GPIO_RCC    RCC_GPIOA

#define AXP_SDA_PORT    GPIOA
#define AXP_SDA_PIN     GPIO3

#define AXP_SCL_PORT    GPIOA
#define AXP_SCL_PIN     GPIO2

#define AXP_WRITE_ADDR  0x68
#define AXP_READ_ADDR   0x69

void axp_twsi_start(void);
void axp_twsi_stop(void);
bool axp_twsi_wait_ack(void);
void axp_twsi_ack(void);
void axp_twsi_nack(void);
bool axp_twsi_send_byte(uint8_t b);
uint8_t axp_twsi_read_byte(void);
void axp_twsi_send_ack(bool ack);
bool axp_read_reg(uint8_t addr, uint8_t *data);
bool axp_write_reg(uint8_t addr, uint8_t data);
void axp_init(void);

#endif