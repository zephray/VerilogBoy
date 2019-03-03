/*
 *  VerilogBoy
 *
 *  This source code is from: 
 *    PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

#include <stdint.h>
#include <stdbool.h>

// For VRAM, only the lowest byte in each 32bit word is used
#define vram ((volatile uint32_t *)0x08000000)

#define led_grn *((volatile uint32_t *)0x03000004)
#define led_red *((volatile uint32_t *)0x03000008)

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

volatile uint32_t *vram_ptr;

// Virtual Terminal
// Currently no scrolling is implemented
// Probably later incorperate the HW scrolling
// Volatile here to workaround the data region being RW, means variable with
// initialization value couldn't be used
volatile int term_x;
volatile int term_y;

void term_clear() {
    vram_ptr = vram;
    for (int i = 0; i < 80 * 30; i++) {
        *vram_ptr++ = 0x20;
    }
}

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
}

void term_putchar(char c)
{
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
}

void term_print(const char *p)
{
	while (*p)
		term_putchar(*(p++));
}

void term_print_hex(uint32_t v, int digits)
{
	for (int i = 7; i >= 0; i--) {
		char c = "0123456789abcdef"[(v >> (4*i)) & 15];
		if (c == '0' && i >= digits) continue;
		term_putchar(c);
		digits = i;
	}
}

void term_print_dec(uint32_t v)
{
	int mul_index;
	int cmp;
	int i;
	int match;
	const int cmp_start[5] = {90000, 9000, 900, 90, 9};
	const int cmp_dec[5] = {10000, 1000, 100, 10, 1};
	if (v >= 100000) {
		term_print(">=100000");
		return;
	}
	for (mul_index = 0; mul_index < 5; mul_index++) {
		cmp = cmp_start[mul_index];
		match = 0;
		for (i = 0; i < 9; i += 1) {
			if (v >= cmp) {
				term_putchar('9' - i);
				v -= cmp;
				match = 1;
				break;
			}
			cmp -= cmp_dec[mul_index];
		}
		if (!match) term_putchar('0');
	}
}

void main()
{
    led_red = 1;
    term_clear();
	term_goto(0,0);
	term_print("Pano Logic G1, ");
	term_print("PicoRV32 @ 100MHz, ");
	term_print("LPDDR @ 100MHz.");
	while (1);
}
