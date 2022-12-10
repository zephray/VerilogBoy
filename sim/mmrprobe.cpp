//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// mmrprobe.cpp: A probe that prints out MMR access logs
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
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

void MMRPROBE::apply(uint8_t wr_data, uint16_t address,
    uint8_t wr_enable, uint8_t rd_enable, uint8_t &rd_data, uint16_t pc) {

    // Ignore ROM and HRAM RW
    if (last_wr && !wr_enable) {
        if ((address >= 0x8000)&&(address <= 0xff7f)) {
            printf("PC %04x: BUS W[%04x] = %02x\n", pc, address, last_data);
        }
    }
    else if (last_rd && !rd_enable) {
        if ((address >= 0x8000)&&(address <= 0xff7f)&&(address != 0xff44)) {
            printf("PC %04x: BUS R[%04x] = %02x\n", pc, address, rd_data);
        }
        /*if ((address == 0xff44) && (rd_data == 0x99)) {
            printf("VSYNC\n");
        }*/
    }
    last_rd = rd_enable;
    last_wr = wr_enable;
    last_data = wr_data;
}


