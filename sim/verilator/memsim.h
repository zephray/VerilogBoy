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
    with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
    target there if the PDF file isn't present.)  If not, see
    <http://www.gnu.org/licenses/> for a copy.

    Description: A memory simulation model with simple delay control

    Copyright (C) 2018 Wenting Zhang
    Copyright (C) 2015,2017, Gisselquist Technology, LLC

*******************************************************************************/
#ifndef MEMSIM_H
#define MEMSIM_H

#define DEBUG

class MEMSIM {
public: 
    typedef unsigned char DBUSW;
    typedef unsigned short ABUSW;
    typedef unsigned char uchar;

    DBUSW *m_mem;
    ABUSW m_len;
    int m_delay;
    int delay_count;
    uchar last_wr;
    uchar last_rd;
    DBUSW last_data;
    
    MEMSIM(const unsigned int nwords, const unsigned int delay=27);
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
