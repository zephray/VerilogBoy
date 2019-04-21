/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This file is partially derived from PicoRV32 project:
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
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
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "misc.h"
#include "term.h"
#include "axp.h"
#include "dsi.h"

#define psram_master_sel  *((volatile uint32_t *)0x03000000)
#define vb_rst            *((volatile uint32_t *)0x0300000c)

void irq_handler(uint32_t pc) {
    term_print_string("HARD FAULT PC = ");
    term_print_hex(pc, 8);
    while (1);
}

#define GAME_SIZE 262144

void main() {
    // Set interrupt mask to zero (enable all interrupts)
    // This is a PicoRV32 custom instruction 
    asm(".word 0x0600000b");

    term_clear();
    term_goto(0,0);
    printf("VerilogBoy Handheld\n");

    dsi_init();

    axp_init();
    axp_printinfo();

    uint32_t *srcptr = (volatile uint32_t *)0x0f100000;
    uint32_t *dstptr = (volatile uint32_t *)0x0c000000;
    uint32_t qword;

    for (int i = 0; i < GAME_SIZE; i+=4) {
        qword = *srcptr++;
        *dstptr++ = (qword) & 0xff;
        *dstptr++ = (qword >> 8) & 0xff;
        *dstptr++ = (qword >> 16) & 0xff;
        *dstptr++ = (qword >> 24) & 0xff;
    }

    psram_master_sel = 0;
    vb_rst = 0;

    while (1) {

    }

error:
    while(1);

}
