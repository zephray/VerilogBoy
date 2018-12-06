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
#include "dsi.h"
#include "fpga_if.h"
#include "misc.h"
#include "usb_cdc.h"

uint8_t dsic_ctl;

/* Calculates a parity bit for value d (1 = odd, 0 = even) */
uint8_t parity(uint32_t d) {
    int i, p = 0;

    for (i = 0; i < 32; i++)
        p ^= d & (1 << i) ? 1 : 0;
    return p;
}


static uint8_t reverse_bits(uint8_t x)
{
    uint8_t r = 0;
    int     i;

    for (i = 0; i < 8; i++)
        if (x & (1 << i)) r |= (1 << (7 - i));
    return r;
}

/* calculates DSI packet header ECC checksum */
uint8_t dsi_ecc(uint32_t data) {
    uint8_t ecc = 0;
    int     i;
    static const uint32_t masks[] =
    { 0xf12cb7, 0xf2555b, 0x749a6d, 0xb8e38e, 0xdf03f0, 0xeffc00 };

    for (i = 0; i < 6; i++)
        if (parity(data & masks[i]))
            ecc |= (1 << i);

    return ecc;
}

uint16_t dsi_crc(const uint8_t *d, int n) {
    uint16_t poly = 0x8408;

    int byte_counter;
    int bit_counter;
    uint8_t  current_data;
    uint16_t result = 0xffff;

    for (byte_counter = 0; byte_counter < n; byte_counter++) {
        current_data = d[byte_counter];

        for (bit_counter = 0; bit_counter < 8; bit_counter++)
        {
            if (((result & 0x0001) ^ ((current_data) & 0x0001)))
                result = ((result >> 1) & 0x7fff) ^ poly;
            else
                result = ((result >> 1) & 0x7fff);
            current_data = (current_data >> 1); // & 0x7F;
        }
    }
    return result;
}

void dsi_lp_write_byte(uint8_t value) {
    // Request to switch to LP mode
    //fpga_write_reg(REG_DSIC_CTL, dsic_ctl | 2);
    // Wait til LP mode ready
    //while (!(fpga_read_reg(REG_DSIC_CTL) & 2));
    // Send byte
    fpga_write_reg(REG_DSIC_TXDR, value);
    // Wait til transmission finish
    //while (!(fpga_read_reg(REG_DSIC_CTL) & 2));
}

void dsi_lp_write_short(uint8_t ptype, uint8_t w0, uint8_t w1) {
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl | 2);
    dsi_lp_write_byte(0xe1);
    dsi_lp_write_byte(reverse_bits(ptype));
    dsi_lp_write_byte(reverse_bits(w0));
    dsi_lp_write_byte(reverse_bits(w1));
    dsi_lp_write_byte(reverse_bits(dsi_ecc(ptype |
        (((uint32_t)w0) << 8) | (((uint32_t)w1) << 16))));
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl);
}

void dsi_lp_write_long(int is_dcs, const unsigned char *data, int length) {
    uint8_t w1 = 0;
    uint8_t w0 = length;

    uint8_t ptype = is_dcs ? 0x39 : 0x29;

    fpga_write_reg(REG_DSIC_CTL, dsic_ctl | 2);
    dsi_lp_write_byte(0xe1);
    dsi_lp_write_byte(reverse_bits(ptype));
    dsi_lp_write_byte(reverse_bits(w0));
    dsi_lp_write_byte(reverse_bits(w1));
    dsi_lp_write_byte(reverse_bits(dsi_ecc(ptype |
        (((uint32_t)w0) << 8) | (((uint32_t)w1) << 16))));

    int i;

    for (i = 0; i < length; i++)
        dsi_lp_write_byte(reverse_bits(data[i]));

    uint16_t crc = dsi_crc(data, length);

    crc = 0x0000; // The screen ignore the CRC

    dsi_lp_write_byte(reverse_bits(crc & 0xff));
    dsi_lp_write_byte(reverse_bits(crc >> 8));
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl);
}

void dsi_init(void) {
    unsigned char long_packet_buffer[15];
    printf("dsi: start initialize process.\r\n");
    
    fpga_write_reg(REG_DSIC_CTL, 0); //Disable dsicore
    fpga_write_reg(REG_DSIC_TICK, 3); // Set LP mode tick = 3

    // Reset the LCD
    fpga_write_reg(REG_DSIC_CTL, BIT_RST_OUT); // RST = 1
    delay_ms(50);
    fpga_write_reg(REG_DSIC_CTL, 0); // RST = 0
    delay_ms(50);
    fpga_write_reg(REG_DSIC_CTL, BIT_RST_OUT); // RST = 1
    delay_ms(50);

    // Send DCS NOP
    //dsi_lp_write_short(0x05, 0x00, 0x00);
    //delay_ms(10);

    // Enable DSI clock
    //dsic_ctl = BIT_RST_OUT | BIT_CLK_EN;
    // Don't enable DSI clock
    dsic_ctl = BIT_RST_OUT;
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl);
    delay_ms(50);

    // Memory data access control: Reverse X, BGR
    dsi_lp_write_short(0x15, 0x36, 0x48); 
    // Interface pixel format: 16.7M Color (not defined in DS???)
	dsi_lp_write_short(0x15, 0x3A, 0x77); // 0x77 for 16.7M
    // Command Set Control: Enable Command 2 Part I
    dsi_lp_write_short(0x15, 0xF0, 0xC3);
    // Command Set Control: Enable Command 2 Part II
    dsi_lp_write_short(0x15, 0xF0, 0x96);
    // Frame Rate Control
    long_packet_buffer[0] = 0xB1; 
    long_packet_buffer[1] = 0xA0; // FRS = 10 DIVA = 0 RTNA = 32
    long_packet_buffer[2] = 0x10; // FR = 10^7 / ((168+RTNA+32x(15-FRS))(320+VFP+VBP))
    dsi_lp_write_long(1, long_packet_buffer, 3);
    // Display Inversion Control: 00: Column INV, 01: 1-Dot INV, 10: 2-Dot INV
    dsi_lp_write_short(0x15, 0xB4, 0x00);
    // Blacking Porch Control
    long_packet_buffer[0] = 0xB5;
    long_packet_buffer[1] = 0x40; // VFP = 64
    long_packet_buffer[2] = 0x40; // VBP = 64
    long_packet_buffer[3] = 0x00; // Reserved
    long_packet_buffer[4] = 0x04; // HBP = 4
    dsi_lp_write_long(1, long_packet_buffer, 5);
	// Display Function Control
    long_packet_buffer[0] = 0xB6;
    
    long_packet_buffer[1] = 0x0A; // Use RAM, DE mode
    long_packet_buffer[2] = 0x07; // Non inverting
    long_packet_buffer[3] = 0x27; 

    /*long_packet_buffer[1] = 0x8A; // Bypass RAM, DE mode
    long_packet_buffer[2] = 0x07; // Non inverting
    long_packet_buffer[3] = 0x27; // 8*(0x27+1) = 320 lines*/
    dsi_lp_write_long(1, long_packet_buffer, 4);
    // There is no B9 in datasheet
    dsi_lp_write_short(0x15, 0xB9, 0x02);
	// VCOM Control: 1.450V
    dsi_lp_write_short(0x15, 0xC5, 0x2E);
    // Display Output
	long_packet_buffer[0] = 0xE8;
    long_packet_buffer[1] = 0x40;
    long_packet_buffer[2] = 0x8A;
    long_packet_buffer[3] = 0x00;
    long_packet_buffer[4] = 0x00;
    long_packet_buffer[5] = 0x29;
    long_packet_buffer[6] = 0x19;
    long_packet_buffer[7] = 0xA5;
    long_packet_buffer[8] = 0x93;
    dsi_lp_write_long(1, long_packet_buffer, 9);
    // Positive Gamma Control
    long_packet_buffer[0]  = 0xe0;
	long_packet_buffer[1]  = 0xf0;
	long_packet_buffer[2]  = 0x07;
	long_packet_buffer[3]  = 0x0e;
	long_packet_buffer[4]  = 0x0a;
	long_packet_buffer[5]  = 0x08;
	long_packet_buffer[6]  = 0x25;
	long_packet_buffer[7]  = 0x38;
	long_packet_buffer[8]  = 0x43;
	long_packet_buffer[9]  = 0x51;
	long_packet_buffer[10] = 0x38;
	long_packet_buffer[11] = 0x14;
	long_packet_buffer[12] = 0x12;
	long_packet_buffer[13] = 0x32;
	long_packet_buffer[14] = 0x3f;
    dsi_lp_write_long(1, long_packet_buffer, 15);
    // Negative Gamma Control
	long_packet_buffer[0]  = 0xe1; 
	long_packet_buffer[1]  = 0xf0; 
	long_packet_buffer[2]  = 0x08; 
	long_packet_buffer[3]  = 0x0d; 
	long_packet_buffer[4]  = 0x09; 
	long_packet_buffer[5]  = 0x09; 
	long_packet_buffer[6]  = 0x26; 
	long_packet_buffer[7]  = 0x39; 
	long_packet_buffer[8]  = 0x45; 
	long_packet_buffer[9]  = 0x52; 
	long_packet_buffer[10] = 0x07; 
	long_packet_buffer[11] = 0x13; 
	long_packet_buffer[12] = 0x16; 
	long_packet_buffer[13] = 0x32; 
	long_packet_buffer[14] = 0x3f; 
    dsi_lp_write_long(1, long_packet_buffer, 15);
	// Command Set Control: Disable Command 2 Part I
    dsi_lp_write_short(0x15, 0xF0, 0x3C);
    // Command Set Control: Disable Command 2 Part II
    dsi_lp_write_short(0x05, 0xF0, 0x69);
    // Sleep Out
    dsi_lp_write_short(0x05, 0x11, 0x00);
    // Display ON
    dsi_lp_write_short(0x05, 0x29, 0x00);
    // Display Inversion ON
    dsi_lp_write_short(0x05, 0x21, 0x00);

    printf("dsi: LP mode initialization complete.\r\n");

    fpga_write_reg(REG_DSIC_HFP,   0x00);
    fpga_write_reg(REG_DSIC_HBP,   0x04);
    fpga_write_reg(REG_DSIC_HACTL, 0x40);
    fpga_write_reg(REG_DSIC_HTL,   0x44);
    fpga_write_reg(REG_DSIC_HATH,  0x11);
    fpga_write_reg(REG_DSIC_VFP,   0x40);
    fpga_write_reg(REG_DSIC_VBP,   0x40);
    fpga_write_reg(REG_DSIC_VACTL, 0x40);
    fpga_write_reg(REG_DSIC_VTL,   0xC0);
    fpga_write_reg(REG_DSIC_VATH,  0x11);

    // Set column address
    long_packet_buffer[0] = 0x2A;
    long_packet_buffer[1] = 0x00;
    long_packet_buffer[2] = 0x00;
    long_packet_buffer[3] = 0x01;
    long_packet_buffer[4] = 0x3F;
    dsi_lp_write_long(1, long_packet_buffer, 5);

    // Set row address
    long_packet_buffer[0] = 0x2B;
    long_packet_buffer[1] = 0x00;
    long_packet_buffer[2] = 0x00;
    long_packet_buffer[3] = 0x01;
    long_packet_buffer[4] = 0x3F;
    dsi_lp_write_long(1, long_packet_buffer, 5);

    /*// Start HS clock
    dsic_ctl = BIT_RST_OUT | BIT_CLK_EN;
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl);

    // Start display refresh
    dsic_ctl |= BIT_TIM_EN;
    fpga_write_reg(REG_DSIC_CTL, dsic_ctl);*/
    printf("dsi: lcd on.\r\n");

}
