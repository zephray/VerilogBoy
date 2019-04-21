/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License,
 *  version 2, as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */
#ifndef __I2C_H__
#define __I2C_H__

#include <stdint.h>

void i2c_start(void);
void i2c_stop(void);
bool i2c_send_byte(uint8_t b);
uint8_t i2c_read_byte(void);
void i2c_send_ack(bool ack);
bool i2c_read_reg(uint8_t i2c_addr, uint8_t addr, uint8_t *data);
bool i2c_write_reg(uint8_t i2c_addr, uint8_t addr, uint8_t data);

#endif
