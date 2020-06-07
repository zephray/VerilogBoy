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
#ifndef MBCSIM_H
#define MBCSIM_H

#define MBC_RAM_SIZE (128*1024)
#define MBC_ROM_SIZE (8*1024*1024)

class MBCSIM {
public:
    typedef unsigned char DBUSW;
    typedef unsigned short ABUSW;
    typedef unsigned char uchar;

    typedef enum {
        MBCNONE,
        MBC1,
        MBC2,
        MBC3,
        MBC5,
        MBCUNKNOWN
    } MBCTYPE;

    DBUSW *m_rom;
    DBUSW *m_ram;
    uchar last_wr;
    uchar last_rd;
    DBUSW last_data;
    MBCTYPE mbc_type;
    char ram_enable;
    char mbc_mode;
    unsigned int rom_bank;
    unsigned int ram_bank;

    MBCSIM(void);
    ~MBCSIM(void);
    void load(const char *fname);
    void apply(const DBUSW wr_data, const ABUSW address, const uchar wr_enable,
        const uchar rd_enable, DBUSW &rd_data);
    void operator()(const DBUSW wr_data, const ABUSW address,
        const uchar wr_enable, const uchar rd_enable, DBUSW &rd_data) {
        apply(wr_data, address, wr_enable, rd_enable, rd_data);
    }
};

#endif
