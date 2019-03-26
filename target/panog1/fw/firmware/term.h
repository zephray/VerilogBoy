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
#ifndef __TERM_H__
#define __TERM_H__

#include <stdint.h>

void term_clear();
void term_goto(uint8_t x, uint8_t y);
void term_putchar(char p);
int term_print(const char *format, ...);
void term_print_string(const char *p);
void term_print_hex(uint32_t v, int digits);
//void term_print_dec(uint32_t v);

#endif
