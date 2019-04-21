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
#include <stdio.h>
#include <stdbool.h>
#include "axp.h"
#include "misc.h"
#include "i2c.h"

int axp_ldo4_lut[16] = {1250, 1300, 1400, 1500, 1600, 1700, 1800, 1900,
    2000, 2500, 2700, 2800, 3000, 3100, 3200, 3300};

bool axp_read_reg(uint8_t addr, uint8_t *data) {
    bool result;

    i2c_start();
    if ((result = i2c_send_byte(AXP_WRITE_ADDR))) {
        i2c_send_byte(addr);
        i2c_start();
        i2c_send_byte(AXP_READ_ADDR);
        *data = i2c_read_byte();
        i2c_send_ack(true);
    }
    i2c_stop();

    return result;
}

bool axp_write_reg(uint8_t addr, uint8_t data) {
    bool result;

    i2c_start();
    if ((result = i2c_send_byte(AXP_WRITE_ADDR))) {
        i2c_send_byte(addr);
        i2c_send_byte(data);
    }
    i2c_stop();

    return result;
}

void axp_init(void) {
    axp_write_reg(0x23, 20); // Set DCDC2 to 1.2V
    axp_write_reg(0x28, 15); // Set LDO 2 to 1.8V, LDO 4 to 3.3V
    axp_write_reg(0x29, 44); // Set LDO 3 to 1.8V
    axp_write_reg(0x32, 0x18); // Set CHGLED Blinking
}

void axp_printinfo(void) {
    uint8_t value;

    if (axp_read_reg(0x00, &value)) {
       printf((value & 0x20) ? "axp: VBUS exist\n" : "axp: VBUS doesn't exist\n"); 
       printf((value & 0x04) ? "axp: battery charging\n" : "axp: battery discharging\n"); 
    }
    else goto error;
    if (axp_read_reg(0x01, &value)) {
       printf((value & 0x10) ? "axp: battery connected\n" : "axp: battery not connected\n"); 
    }
    else goto error;
    if (axp_read_reg(0x12, &value)) {
       printf((value & 0x40) ? "axp: ldo3 on\n" : "axp: ldo3 off\n");
       printf((value & 0x10) ? "axp: dcdc2 on\n" : "axp: dcdc2 off\n");
       printf((value & 0x08) ? "axp: ldo4 on\n" : "axp: ldo4 off\n");
       printf((value & 0x04) ? "axp: ldo2 on\n" : "axp: ldo2 off\n");
       printf((value & 0x02) ? "axp: dcdc3 on\n" : "axp: dcdc3 off\n");
       printf((value & 0x01) ? "axp: exten on\n" : "axp: exten off\n");
    }
    else goto error;
    if (axp_read_reg(0x23, &value)) {
       printf("axp: dcdc2 set to %d mV\n", 700 + value * 25);
    }
    else goto error;
    if (axp_read_reg(0x27, &value)) {
       printf("axp: dcdc3 set to %d mV\n", 700 + value * 25);
    }
    else goto error;
    if (axp_read_reg(0x28, &value)) {
       printf("axp: ldo2 set to %d mV\n", 1800 + (value >> 4) * 100);
       printf("axp: ldo4 set to %d mV\n", axp_ldo4_lut[value & 0xF]);
    }
    else goto error;
    if (axp_read_reg(0x29, &value)) {
       if (value & 0x80) {
           printf("axp: ldo3 set to following mode\n");
       }
       else {
           printf("axp: ldo3 set to %d mV\n", 700 + value * 25);
       }
    }
    else goto error;

    return;
error:
    printf("axp: error while reading register.\n");
    return;
}
