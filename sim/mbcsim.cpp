//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// memsim.cpp: Cartridge with memory bank controller (MBC) simulation
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
#include "mbcsim.h"

MBCSIM::MBCSIM(void) {
    ram = new uint8_t[MBC_RAM_SIZE];
    rom = new uint8_t[MBC_ROM_SIZE];
    ram_enable = 0; // Disable by default
    mbc_mode = 0; // Banking mode for MBC1
    rom_bank = 1;
    ram_bank = 0;
}

MBCSIM::~MBCSIM(void) {
    delete[] ram;
    delete[] rom;
}

void MBCSIM::load(const char *fname) {
    FILE *fp;

    fp = fopen(fname, "rb");
    assert(fp);
    fseek(fp, 0, SEEK_END);
    size_t fsize = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    size_t result = fread((void *)rom, fsize, 1, fp);
    assert(result == 1);
    fclose(fp);

    char title[17];
    title[16] = 0;
    memcpy(title, rom + 0x134, 16);

    printf("ROM Title: %s\n", title);

    char ctype = rom[0x147];
    if ((ctype == 0x00) || (ctype == 0x08) || (ctype == 0x09)) {
        mbc_type = MBCNONE;
        printf("MBC Type: None\n");
    }
    else if ((ctype >= 0x01)&&(ctype <= 0x03)) {
        mbc_type = MBC1;
        printf("MBC Type: MBC1\n");
    }
    else if ((ctype >= 0x05)&&(ctype <= 0x06)) {
        mbc_type = MBC2;
        printf("MBC Type: MBC2\n");
    }
    else if ((ctype >= 0x0f)&&(ctype <= 0x13)) {
        mbc_type = MBC3;
        printf("MBC Type: MBC3\n");
    }
    else if ((ctype >= 0x19)&&(ctype <= 0x1e)) {
        mbc_type = MBC5;
        printf("MBC Type: MBC5\n");
    }
    else {
        mbc_type = MBCUNKNOWN;
        printf("Unsupported Cartridge Type: %d\n", ctype);
    }

    int rom_size = rom[0x148];
    if (rom_size <= 0x08)
        rom_size = (1 << rom_size) * 32;
    else if (rom_size == 0x52)
        rom_size = 72*16; // 72 banks
    else if (rom_size == 0x53)
        rom_size = 80*16;
    else if (rom_size == 0x54)
        rom_size = 96*16;
    else
        rom_size = 32; // Fallback to 32KB
    printf("ROM Size: %d KB\n", rom_size);

    int ram_size = rom[0x149];
    if (ram_size == 0x00)
        ram_size = 0;
    else if (ram_size == 0x01)
        ram_size = 2;
    else if (ram_size == 0x02)
        ram_size = 8;
    else if (ram_size == 0x03)
        ram_size = 32;
    else if (ram_size == 0x04)
        ram_size = 128;
    else if (ram_size == 0x05)
        ram_size = 64;
    else
        ram_size = 0;
    printf("RAM Size: %d KB\n", ram_size);

    memset(ram, 0xff, MBC_RAM_SIZE);
}

void MBCSIM::apply(const uint8_t wr_data, const uint16_t address, 
    const uint8_t wr, const uint8_t rd, uint8_t &rd_data) {

    // Address within ROM window or RAM window
    if ((address <= 0x8000) || ((address >= 0xa000) && (address < 0xc000))) {
        if (wr) {
            if (address >= 0xa000) {
                // Write to RAM
                if (ram_enable == 0x0a) {
                    if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                        ram[address - 0xa000] = wr_data;
                    }
                    else {
                        ram[address - 0xa000 + ram_bank * 0x2000] = wr_data;
                    }
                }
            }
            else if (address < 0x2000) {
                // RAM Enable (MBC1/3/5)
                ram_enable = wr_data;
            }
            else if (address < 0x4000) {
                // ROM Bank (MBC1/3/5)
                if (mbc_type == MBC1) {
                    rom_bank &= ~0x1f;
                    rom_bank = (unsigned int)wr_data & 0x1f;
                    if (wr_data == 0)
                        rom_bank |= 0x01;
                }
                else if (mbc_type == MBC3) {
                    rom_bank &= ~0x7f;
                    rom_bank = (unsigned int)wr_data & 0x7f;
                    if (wr_data == 0)
                        rom_bank |= 0x01;
                }
                else if (mbc_type == MBC5) {
                    if (address < 0x3000) {
                        rom_bank &= ~0xff;
                        rom_bank |= (unsigned int)wr_data & 0xff;
                    }
                    else {
                        rom_bank &= ~0x100;
                        rom_bank |= ((unsigned int)wr_data & 0x01) << 8;
                    }
                }
                //printf("[MBC] Rom bank %d (%04x=%02x)\n", rom_bank, address, last_data);
            }
            else if (address < 0x6000) {
                if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                    // High ROM Bank
                    rom_bank &= ~0xe0;
                    rom_bank |= ((unsigned int)wr_data & 0x03) << 5;
                    //printf("[MBC] Rom bank %d (%04x=%02x)\n", rom_bank, address, last_data);
                }
                else {
                    // RAM Bank
                    ram_bank = wr_data;
                    //printf("[MBC] Ram bank %d (%04x=%02x)\n", ram_bank, address, last_data);
                }
            }
            else if (address < 0x8000) {
                mbc_mode = wr_data;
            }
        } 
        else if (rd) {
            if (address < 0x4000) {
                // LoROM
                rd_data = rom[address];
            }
            else if (address < 0x8000) {
                // HiROM
                rd_data = rom[address - 0x4000 + rom_bank * 0x4000];
                //printf("[MBC] Read from bank %d, %04x (%06x) = %02x\n", rom_bank, address, address - 0x4000 + rom_bank * 0x4000, rd_data);
            }
            else {
                if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                    rd_data = ram[address - 0xa000];
                }
                else {
                    rd_data = ram[address - 0xa000 + ram_bank * 0x2000];
                }
            }
        }
    }
}


