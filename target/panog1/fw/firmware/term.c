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
#include <stdarg.h>
#include "term.h"
#include "misc.h"

#define vram ((volatile uint32_t *)0x08000000)
#define uart ((volatile uint32_t *)0x03000100)

volatile uint32_t *vram_ptr;
volatile uint32_t *uart_ptr = uart;

bool uart_en = true;
int term_x = 0;
int term_y = 0;

void term_goto(uint8_t x, uint8_t y) {
    term_x = x;
    term_y = y;
}

void term_newline() {
    term_x = 0;
    if (term_y == 30 - 1) {
        term_y = 0;
    }
    else {
        term_y ++;
    }
	// Clear next line
	vram_ptr = vram + term_y * 80 + term_x;
	for (int i = 0; i < 80; i++) {
		*vram_ptr++ = 0x20;
	}
}

void term_clear() {
    vram_ptr = vram;
    for (int i = 0; i < 80 * 30; i++) {
        *vram_ptr++ = 0x20;
    }
    vram_ptr = vram;
}

void term_enable_uart(bool en) {
	uart_en = en;
}

void term_putchar(char c) {
	if (uart_en)
    	*uart_ptr = (uint32_t)c;
    if (c == '\n') {
        term_newline();
    }
    else {
        vram_ptr = vram + term_y * 80 + term_x;
        *vram_ptr = (uint32_t)c;
        if (term_x == 80 - 1) {
            term_newline();
        }
        else {
            term_x ++;
        }
    }
    //delay_us(200);
}

void term_print_string(const char *p) {
    while ((*p) && (*p != 0xFF))
        term_putchar(*p++);
}

void term_print_hex(uint32_t v, int digits) {
    for (int i = 7; i >= 0; i--) {
        char c = "0123456789abcdef"[(v >> (4*i)) & 15];
        if (c == '0' && i >= digits) continue;
        term_putchar(c);
        digits = i;
    }
}

static void printf_d(int val) {
	char buffer[32];
	char *p = buffer;
	if (val < 0) {
		term_putchar('-');
		val = -val;
	}
	while (val || p == buffer) {
		*(p++) = '0' + val % 10;
		val = val / 10;
	}
	while (p != buffer)
		term_putchar(*(--p));
}

int printf(const char *format, ...) {
	int i;
	va_list ap;

	va_start(ap, format);

	for (i = 0; format[i]; i++)
		if (format[i] == '%') {
			while (format[++i]) {
				if (format[i] == 'c') {
					term_putchar(va_arg(ap,int));
					break;
				}
				if (format[i] == 's') {
					term_print_string(va_arg(ap,char*));
					break;
				}
				if (format[i] == 'd') {
					printf_d(va_arg(ap,int));
					break;
				}
				if (format[i] == 'x') {
					term_print_hex(va_arg(ap,int), 4);
					break;
				}
			}
		} else
			term_putchar(format[i]);

	va_end(ap);
}


