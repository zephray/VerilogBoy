/*
 *  VerilogBoy
 *  
 *  mmrprobe.h: A probe that prints out MMR access logs
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
#ifndef MMRPROBE_H
#define MMRPROBE_H

class MMRPROBE {
public: 
    typedef unsigned char DBUSW;
    typedef unsigned short ABUSW;
    typedef unsigned char uchar;

    uchar last_wr;
    uchar last_rd;
    DBUSW last_data;
    
    MMRPROBE(void);
    ~MMRPROBE(void);
    void apply(const DBUSW wr_data, const ABUSW address, const uchar wr_enable, 
        const uchar rd_enable, DBUSW &rd_data, ABUSW pc);
    void operator()(const DBUSW wr_data, const ABUSW address, 
        const uchar wr_enable, const uchar rd_enable, DBUSW &rd_data, ABUSW pc) {
        apply(wr_data, address, wr_enable, rd_enable, rd_data, pc);
    }
};

#endif
