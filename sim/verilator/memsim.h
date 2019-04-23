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
#ifndef MEMSIM_H
#define MEMSIM_H

class MEMSIM {
public:
    typedef unsigned char DBUSW;
    typedef unsigned short ABUSW;
    typedef unsigned char uchar;

    ABUSW m_base;
    DBUSW *m_mem;
    ABUSW m_len;
    int m_delay;
    int delay_count;
    uchar last_wr;
    uchar last_rd;
    DBUSW last_data;

    MEMSIM(const ABUSW base, const unsigned int nwords, 
        const unsigned int delay);
    ~MEMSIM(void);
    void load(const char *fname);
    void load(const unsigned int addr, const char *buf,const size_t len);
    void apply(const DBUSW wr_data, const ABUSW address, const uchar wr_enable,
        const uchar rd_enable, DBUSW &rd_data);
    void operator()(const DBUSW wr_data, const ABUSW address,
        const uchar wr_enable, const uchar rd_enable, DBUSW &rd_data) {
        apply(wr_data, address, wr_enable, rd_enable, rd_data);
    }
    DBUSW &operator[](const ABUSW addr) { return m_mem[addr]; }
};

#endif
