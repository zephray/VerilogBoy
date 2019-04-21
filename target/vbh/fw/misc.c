/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License,
 *  version 2, as published by the Free Software Foundation.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin St - Fifth Floor, Boston, MA 02110-1301 USA.
 */
#include "misc.h"

uint32_t time() {
	uint32_t cycles;
	asm volatile ("rdcycle %0" : "=r"(cycles));
	return cycles;
}

uint32_t ticks_us() {
    return time() / CYCLE_PER_US;
}

uint32_t ticks_ms() {
    return time() / CYCLE_PER_US / 1000;
}

void delay_us(uint32_t us) {
    uint32_t start = time(); 
    while (time() - start < CYCLE_PER_US * us);
}

void delay_ms(uint32_t ms) {
    while (ms--) { delay_us(1000); }
}

void delay_loop(uint32_t t) {
	volatile int i;
	while(t--) {
		for (i=0;i<20;i++);
	}
}

// Additional library functions

void * memscan(void * addr, int c, uint32_t size)
{
	unsigned char * p = (unsigned char *) addr;

	while (size) {
		if (*p == c)
			return (void *) p;
		p++;
		size--;
	}
	return (void *) p;
}