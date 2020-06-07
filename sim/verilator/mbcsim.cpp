/*
 *  VerilogBoy
 *
 *  memsim.cpp: A memory simulation model with simple delay control
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *  Copyright (C) 2015,2017, Gisselquist Technology, LLC
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
#include "mbcsim.h"

MBCSIM::MBCSIM(void) {
    m_ram = new DBUSW[MBC_RAM_SIZE];
    m_rom = new DBUSW[MBC_ROM_SIZE];
    ram_enable = 0; // Disable by default
    mbc_mode = 0; // Banking mode for MBC1
    rom_bank = 1;
    ram_bank = 0;
    last_wr = 0;
    last_rd = 0;
    last_data = 0;
}

MBCSIM::~MBCSIM(void) {
    delete[] m_ram;
    delete[] m_rom;
}

void MBCSIM::load(const char *fname) {
    FILE *fp;
    unsigned int nr;

    //printf("Loading %s\n", fname);

    fp = fopen(fname, "rb");
    if (!fp) {
        fprintf(stderr, "Could not open/load file \'%s\'\n",
            fname);
        perror("O/S Err:");
        fprintf(stderr, "\tInitializing memory with ff instead.\n");
        nr = 0xff;
    } else {
        // Read low 32KB, all ROMs should be at least 32KB
        nr = fread(m_rom, 1, 32768, fp);

        char title[17];
        title[16] = 0;
        memcpy(title, m_rom + 0x134, 16);

        printf("ROM Title: %s\n", title);

        char ctype = m_rom[0x147];
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

        int rom_size = m_rom[0x148];
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

        int ram_size = m_rom[0x149];
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

        // Load the remaining of the ROM
        fseek(fp, 0, SEEK_SET);
        nr = fread(m_rom, 1, rom_size * 1024, fp);
        printf("%d bytes loaded.\n", nr);
        fclose(fp);
    }

    for(; nr<MBC_ROM_SIZE; nr++)
        m_rom[nr] = 0xff;
    for(nr = 0; nr<MBC_RAM_SIZE; nr++)
        m_ram[nr] = 0xff;
}

void MBCSIM::apply(const DBUSW wr_data, const ABUSW address, 
    const uchar wr_enable, const uchar rd_enable, DBUSW &rd_data) {

    // Address within ROM window or RAM window
    if ((address <= 0x8000) || ((address >= 0xa000) && (address < 0xc000))) {
        if (last_wr && !wr_enable) {
            if (address >= 0xa000) {
                // Write to RAM
                if (ram_enable == 0x0a) {
                    if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                        m_ram[address - 0xa000] = last_data;
                    }
                    else {
                        m_ram[address - 0xa000 + ram_bank * 0x2000] = last_data;
                    }
                }
            }
            else if (address < 0x2000) {
                // RAM Enable (MBC1/3/5)
                ram_enable = last_data;
            }
            else if (address < 0x4000) {
                // ROM Bank (MBC1/3/5)
                if (mbc_type == MBC1) {
                    rom_bank &= ~0x1f;
                    rom_bank = (unsigned int)last_data & 0x1f;
                    if (last_data == 0)
                        rom_bank |= 0x01;
                }
                else if (mbc_type == MBC3) {
                    rom_bank &= ~0x7f;
                    rom_bank = (unsigned int)last_data & 0x7f;
                    if (last_data == 0)
                        rom_bank |= 0x01;
                }
                else if (mbc_type == MBC5) {
                    if (address < 0x3000) {
                        rom_bank &= ~0xff;
                        rom_bank |= (unsigned int)last_data & 0xff;
                    }
                    else {
                        rom_bank &= ~0x100;
                        rom_bank |= ((unsigned int)last_data & 0x01) << 8;
                    }
                }
                //printf("[MBC] Rom bank %d (%04x=%02x)\n", rom_bank, address, last_data);
            }
            else if (address < 0x6000) {
                if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                    // High ROM Bank
                    rom_bank &= ~0xe0;
                    rom_bank |= ((unsigned int)last_data & 0x03) << 5;
                    //printf("[MBC] Rom bank %d (%04x=%02x)\n", rom_bank, address, last_data);
                }
                else {
                    // RAM Bank
                    ram_bank = last_data;
                    //printf("[MBC] Ram bank %d (%04x=%02x)\n", ram_bank, address, last_data);
                }
            }
            else if (address < 0x8000) {
                mbc_mode = last_data;
            }
        } 
        else if (!last_rd && rd_enable) {
            if (address < 0x4000) {
                // LoROM
                rd_data = m_rom[address];
            }
            else if (address < 0x8000) {
                // HiROM
                rd_data = m_rom[address - 0x4000 + rom_bank * 0x4000];
                //printf("[MBC] Read from bank %d, %04x (%06x) = %02x\n", rom_bank, address, address - 0x4000 + rom_bank * 0x4000, rd_data);
            }
            else {
                if ((mbc_type == MBC1) && (mbc_mode == 0)) {
                    rd_data = m_ram[address - 0xa000];
                }
                else {
                    rd_data = m_ram[address - 0xa000 + ram_bank * 0x2000];
                }
            }
        }
    }
    last_rd = rd_enable;
    last_wr = wr_enable;
    last_data = wr_data;
}


