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
#include <stdbool.h>
#include "misc.h"
#include "i2c.h"


#define i2c_scl  *((volatile uint32_t *)0x03000014)
#define i2c_sda  *((volatile uint32_t *)0x03000018)

/* Reset to 1 by hardware
void i2c_init(void) {
	i2c_sda = 1;
	i2c_scl = 1;
}*/

void i2c_start(void) {
    // Start: negedge of DATA when CLK is high
    
    i2c_sda = 1;
    //delay_loop(1);
    i2c_scl = 1;
    //delay_loop(5);
    i2c_sda = 0;
    //delay_loop(5);
    i2c_scl = 0;
    //delay_loop(2);
}

void i2c_stop(void) {
    // Stop: posedge of DATA when CLK is high
    
    i2c_scl = 0;
    i2c_sda = 0;
    //delay_loop(4);
    i2c_scl = 1;
    //delay_loop(5);
    i2c_sda = 1;
    //delay_loop(4);
}

bool i2c_wait_ack(void) {
    uint16_t err_count = 0;
    i2c_sda = 1; //delay_loop(1);
    i2c_scl = 1; //delay_loop(1);
    while(i2c_sda) {
        err_count ++;
        if (err_count > 500) {
            i2c_stop();
            return false;
        }
    }
    i2c_scl = 0;
    return true;
}

void i2c_ack(void) {
    i2c_scl = 0;
    
    i2c_sda = 0;
    //delay_loop(2);
    i2c_scl = 1;
    //delay_loop(2);
    i2c_scl = 0;
}

void i2c_nack(void) {
    i2c_scl = 0;
    
    i2c_sda = 1;
    //delay_loop(2);
    i2c_scl = 1;
    //delay_loop(2);
    i2c_scl = 0;
}
		  
bool i2c_send_byte(uint8_t b) {                        
    
    i2c_scl = 0;
    for (int i = 0; i < 8; i++) {
        if (b & 0x80)
            i2c_sda = 1;
        else
            i2c_sda = 0;
        b <<= 1;
        //delay_loop(2);
        i2c_scl = 1;
        //delay_loop(2);
        i2c_scl = 0;
        //delay_loop(2);
    }

    return i2c_wait_ack();
}

uint8_t i2c_read_byte(void) {
    uint8_t rx = 0;

    i2c_sda = 1;
    for (int i = 0; i < 8; i++) {
        i2c_scl = 0;
        //delay_loop(2);
        i2c_scl = 1;
        rx <<= 1;
        rx |= i2c_sda;
        //delay_loop(1);
    }

    return rx;
}

void i2c_send_ack(bool ack) {
    if (ack)
        i2c_ack();
    else
        i2c_nack();
}

bool i2c_read_reg(uint8_t i2c_addr, uint8_t addr, uint8_t *data) {
    bool result;

    i2c_start();
    if ((result = i2c_send_byte(i2c_addr))) {
        i2c_send_byte(addr);
        i2c_start();
        i2c_send_byte(i2c_addr | 0x1);
        *data = i2c_read_byte();
        i2c_send_ack(true);
    }
    i2c_stop();

    return result;
}

bool i2c_write_reg(uint8_t i2c_addr, uint8_t addr, uint8_t data) {
    bool result;

    i2c_start();
    if ((result = i2c_send_byte(i2c_addr))) {
        i2c_send_byte(addr);
        i2c_send_byte(data);
    }
    i2c_stop();

    return result;
}
