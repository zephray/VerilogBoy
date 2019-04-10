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
#ifndef __MISC_H__
#define __MISC_H__

#include <stdint.h>

#define true 1
#define false 0

#define CYCLE_PER_US  25

// ticks wraps around every 43s
uint32_t time();
uint32_t ticks_us();
uint32_t ticks_ms();
void delay_us(uint32_t us);
void delay_ms(uint32_t ms);
void delay_loop(uint32_t t);

extern long insn();

extern int printf(const char *format, ...);

extern void *memcpy(void *dest, const void *src, long n);
extern char *strcpy(char *dest, const char *src);
extern void memset(void *s, int c, long n);
extern int strcmp(const char *s1, const char *s2);

extern int isprint(int c);

void * memscan(void * addr, int c, uint32_t size);

#endif
