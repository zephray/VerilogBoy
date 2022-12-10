//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// memsim.cpp: An async memory simulation model
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
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include "memsim.h"

MEMSIM::MEMSIM(uint16_t base, size_t len) {
    this->base = base;
    this->len = len;
    mem = (uint8_t *)malloc(len);
}

MEMSIM::~MEMSIM(void) {
    free(mem);
}

void MEMSIM::load(char *fname) {
    FILE *fp;

    fp = fopen(fname, "rb");
    assert(fp);
    fseek(fp, 0, SEEK_END);
    size_t fsize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    size_t result = fread((void *)mem, fsize, 1, fp);
    assert(result == 1);
    fclose(fp);
}

void MEMSIM::apply(uint8_t wr_data, uint16_t address, 
    uint8_t wr, uint8_t rd, uint8_t &rd_data) {

    if ((address >= base) && (address < (base + len))) {
        if (wr) {
            mem[address - base] = wr_data;
#ifdef __DEBUG
        printf("MEMBUS W[%04x] = %02x\n",
            address,
            wr_data);
#endif
        } 
        else if (rd) {
            rd_data = mem[address - base];
#ifdef __DEBUG
        printf("MEMBUS R[%04x] = %02x\n",
            address,
            rd_data);
#endif
        }
    }
}


