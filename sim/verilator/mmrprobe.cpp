/*
 *  VerilogBoy
 *
 *  mmrprobe.cpp: A probe that prints out MMR access logs
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License as
 *  published by the Free Software Foundation, either version 3 of the license,
 *  or (at your option) any later version.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, see <http://www.gnu.org/licenses/> for a copy.
 */
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include "mmrprobe.h"

MMRPROBE::MMRPROBE() {
    last_wr = 0;
    last_rd = 0;
    last_data = 0;
}

MMRPROBE::~MMRPROBE(void) {

}

void MMRPROBE::apply(const DBUSW wr_data, const ABUSW address,
    const uchar wr_enable, const uchar rd_enable, DBUSW &rd_data) {

    // Ignore ROM and HRAM RW
    if (last_wr && !wr_enable) {
        if ((address >= 0x8000)&&(address <= 0xff7f)) {
            printf("BUS W[%04x] = %02x\n", address, last_data);
        }
    }
    else if (last_rd && !rd_enable) {
        if ((address >= 0x8000)&&(address <= 0xff7f)&&(address != 0xff44)) {
            printf("BUS R[%04x] = %02x\n", address, rd_data);
        }
        /*if ((address == 0xff44) && (rd_data == 0x99)) {
            printf("VSYNC\n");
        }*/
    }
    last_rd = rd_enable;
    last_wr = wr_enable;
    last_data = wr_data;
}


