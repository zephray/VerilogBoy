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
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>
#include "memsim.h"

MEMSIM::MEMSIM(const unsigned int nwords, const unsigned int delay) {
    m_len = nwords;
    m_mem = new BUSW[m_len];
    m_delay = delay;
    delay_count = 0;
}

MEMSIM::~MEMSIM(void) {
    delete[] m_mem;
}

void MEMSIM::load(const char *fname) {
    FILE *fp;
    unsigned int nr;

    printf("Loading %s\n", fname);

    fp = fopen(fname, "rb");
    if (!fp) {
        fprintf(stderr, "Could not open/load file \'%s\'\n",
            fname);
        perror("O/S Err:");
        fprintf(stderr, "\tInitializing memory with zero instead.\n");
        nr = 0;
    } else {
        nr = fread(m_mem, sizeof(BUSW), m_len, fp);
        fclose(fp);

        if (nr != m_len) {
            fprintf(stderr, "Only read %d of %d words\n",
                nr, m_len);
            fprintf(stderr, "\tFilling the rest with zero.\n");
        }
    }

    printf("%02x\n", m_mem[0]);
    printf("%d\n", nr);

    for(; nr<m_len; nr++)
        m_mem[nr] = 0;

    printf("%02x\n", m_mem[0]);
}

void MEMSIM::load(const unsigned int addr, const char *buf, const size_t len) {
    memcpy(&m_mem[addr], buf, len);
}

void MEMSIM::apply(const BUSW wr_data, const BUSW address, 
    const uchar wr_enable, const uchar rd_enable, BUSW &rd_data) {

    if (delay_count == 0) {
        if (wr_enable) {
            m_mem[address] = wr_data;
            delay_count = m_delay;
#ifdef DEBUG
        printf("MEMBUS W[%04x] = %02x\n",
            address,
            wr_data);
#endif
        } 
        else if (rd_enable) {
            rd_data = m_mem[address];
            delay_count = m_delay;
#ifdef DEBUG
        printf("MEMBUS R[%04x] = %02x\n",
            address,
            rd_data);
#endif
        }
    } 
    else {
        delay_count --;
    }
}


