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
#include "axp.h"
#include "misc.h"

#define axp_set_sda_output() gpio_set_mode(AXP_SDA_PORT, \
    GPIO_MODE_OUTPUT_10_MHZ, GPIO_CNF_OUTPUT_PUSHPULL, AXP_SDA_PIN)
#define axp_set_sda_input() gpio_set_mode(AXP_SDA_PORT, \
    GPIO_MODE_INPUT, GPIO_CNF_INPUT_PULL_UPDOWN, AXP_SDA_PIN)
#define axp_sda_high() gpio_set(AXP_SDA_PORT, AXP_SDA_PIN)
#define axp_sda_low() gpio_clear(AXP_SDA_PORT, AXP_SDA_PIN)
#define axp_scl_high() gpio_set(AXP_SCL_PORT, AXP_SCL_PIN)
#define axp_scl_low() gpio_clear(AXP_SCL_PORT, AXP_SCL_PIN)
#define axp_sda_read() (gpio_get(AXP_SDA_PORT, AXP_SDA_PIN) ? 1 : 0)

float axp_ldo4_lut[16] = {1.25, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9,
    2.0, 2.5, 2.7, 2.8, 3.0, 3.1, 3.2, 3.3};

void axp_twsi_start(void) {
    // Start: negedge of DATA when CLK is high
    axp_set_sda_output();
    axp_sda_high();
    delay_us_loop(1);
    axp_scl_high();
    delay_us_loop(5);
    axp_sda_low();
    delay_us_loop(5);
    axp_scl_low();
    delay_us_loop(2);
}

void axp_twsi_stop(void) {
    // Stop: posedge of DATA when CLK is high
    axp_set_sda_output();
    axp_scl_low();
    axp_sda_low();
    delay_us_loop(4);
    axp_scl_high();
    delay_us_loop(5);
    axp_sda_high();
    delay_us_loop(4);
}

bool axp_twsi_wait_ack(void) {
    uint16_t err_count = 0;
    axp_set_sda_input();
    axp_sda_high(); delay_us_loop(1);
    axp_scl_high(); delay_us_loop(1);
    while(axp_sda_read()) {
        err_count ++;
        if (err_count > 500) {
            axp_twsi_stop();
            return false;
        }
    }
    axp_scl_low();
    return true;
}

void axp_twsi_ack(void) {
    axp_scl_low();
    axp_set_sda_output();
    axp_sda_low();
    delay_us_loop(2);
    axp_scl_high();
    delay_us_loop(2);
    axp_scl_low();
}

void axp_twsi_nack(void) {
    axp_scl_low();
    axp_set_sda_output();
    axp_sda_high();
    delay_us_loop(2);
    axp_scl_high();
    delay_us_loop(2);
    axp_scl_low();
}
		  
bool axp_twsi_send_byte(uint8_t b) {                        
    axp_set_sda_output();
    axp_scl_low();
    for (int i = 0; i < 8; i++) {
        if (b & 0x80)
            axp_sda_high();
        else
            axp_sda_low();
        b <<= 1;
        delay_us_loop(2);
        axp_scl_high();
        delay_us_loop(2);
        axp_scl_low();
        delay_us_loop(2);
    }

    return axp_twsi_wait_ack();
}

uint8_t axp_twsi_read_byte(void) {
    uint8_t rx = 0;

    axp_set_sda_input();
    for (int i = 0; i < 8; i++) {
        axp_scl_low();
        delay_us_loop(2);
        axp_scl_high();
        rx <<= 1;
        rx |= axp_sda_read();
        delay_us_loop(1);
    }

    return rx;
}

void axp_twsi_send_ack(bool ack) {
    if (ack)
        axp_twsi_ack();
    else
        axp_twsi_nack();
}

bool axp_read_reg(uint8_t addr, uint8_t *data) {
    bool result;

    axp_twsi_start();
    if ((result = axp_twsi_send_byte(AXP_WRITE_ADDR))) {
        axp_twsi_send_byte(addr);
        axp_twsi_start();
        axp_twsi_send_byte(AXP_READ_ADDR);
        *data = axp_twsi_read_byte();
        axp_twsi_send_ack(true);
    }
    axp_twsi_stop();

    return result;
}

bool axp_write_reg(uint8_t addr, uint8_t data) {
    bool result;

    axp_twsi_start();
    if ((result = axp_twsi_send_byte(AXP_WRITE_ADDR))) {
        axp_twsi_send_byte(addr);
        axp_twsi_send_byte(data);
    }
    axp_twsi_stop();

    return result;
}

void axp_init(void) {
    uint8_t value;

    rcc_periph_clock_enable(AXP_GPIO_RCC);
    gpio_set_mode(AXP_SCL_PORT, GPIO_MODE_OUTPUT_10_MHZ, 
        GPIO_CNF_OUTPUT_PUSHPULL, AXP_SCL_PIN);

    axp_write_reg(0x23, 20); // Set DCDC2 to 1.2V
    axp_write_reg(0x28, 15); // Set LDO 2 to 1.8V, LDO 4 to 3.3V
    axp_write_reg(0x29, 44); // Set LDO 3 to 1.8V

    if (axp_read_reg(0x00, &value)) {
       printf((value & 0x20) ? "axp: VBUS exist\r\n" : "axp: VBUS doesn't exist\r\n"); 
       printf((value & 0x04) ? "axp: battery charging\r\n" : "axp: battery discharging\r\n"); 
    }
    else goto error;
    if (axp_read_reg(0x01, &value)) {
       printf((value & 0x10) ? "axp: battery connected\r\n" : "axp: battery not connected\r\n"); 
    }
    else goto error;
    if (axp_read_reg(0x12, &value)) {
       printf((value & 0x40) ? "axp: ldo3 on\r\n" : "axp: ldo3 off\r\n");
       printf((value & 0x10) ? "axp: dcdc2 on\r\n" : "axp: dcdc2 off\r\n");
       printf((value & 0x08) ? "axp: ldo4 on\r\n" : "axp: ldo4 off\r\n");
       printf((value & 0x04) ? "axp: ldo2 on\r\n" : "axp: ldo2 off\r\n");
       printf((value & 0x02) ? "axp: dcdc3 on\r\n" : "axp: dcdc3 off\r\n");
       printf((value & 0x01) ? "axp: exten on\r\n" : "axp: exten off\r\n");
    }
    else goto error;
    if (axp_read_reg(0x23, &value)) {
       printf("axp: dcdc2 set to %.3fV\r\n", 0.7 + value * 0.025);
    }
    else goto error;
    if (axp_read_reg(0x27, &value)) {
       printf("axp: dcdc3 set to %.3fV\r\n", 0.7 + value * 0.025);
    }
    else goto error;
    if (axp_read_reg(0x28, &value)) {
       printf("axp: ldo2 set to %.1fV\r\n", 1.8 + (value >> 4) * 0.1);
       printf("axp: ldo4 set to %.2fV\r\n", axp_ldo4_lut[value & 0xF]);
    }
    else goto error;
    if (axp_read_reg(0x29, &value)) {
       if (value & 0x80) {
           printf("axp: ldo3 set to following mode\r\n");
       }
       else {
           printf("axp: ldo3 set to %.3fV\r\n", 0.7 + value * 0.025);
       }
    }
    else goto error;

    return;
error:
    fprintf(stderr, "axp: error while reading register.\r\n");
    return;
}
