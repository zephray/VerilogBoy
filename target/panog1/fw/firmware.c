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

#define MEM_TOTAL 0x800     // 2 KB
#define DDR_TOTAL 0x2000000 // 32 MB

// a pointer to this is a null pointer, but the compiler does not
// know that because "sram" is a linker symbol from sections.lds.
extern uint32_t sram;

// For VRAM, only the lowest byte in each 32bit word is used
#define vram ((volatile uint32_t *)0x08000000)
#define ddr ((volatile uint32_t *)0x0C000000)

volatile uint32_t *vram_ptr;
volatile uint32_t *ddr_ptr;

// Virtual Terminal
// Currently no scrolling is implemented
// Probably later incorperate the HW scrolling
// Volatile here to workaround the data region being RW, means variable with
// initialization value couldn't be used
volatile int term_x;
volatile int term_y;

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

uint32_t generate_test_word_C(uint32_t input) {
	return (input << 23) | input;
}

void ddr_memtest()
{
	volatile uint32_t *ptr;
	volatile uint8_t *base_byte = (uint8_t *)ddr;

	int counter;
	ptr = ddr;
	counter = 0;
	for (int i = 0; i < (DDR_TOTAL/1024); i++) {
		//ptr = ddr + i * (1024/4); 
		for (int j = 0; j < (1024/4); j++) {
			*ptr++ = generate_test_word_C(counter);
			counter ++;
		}
		term_x = 3;
		term_print_dec(i + 1);
		term_print(" KB testing...");
	}
	ptr = ddr;
	counter = 0;
	for (int i = 0; i < (DDR_TOTAL/1024); i++) { // (DDR_TOTAL/1024)
		for (int j = 0; j < (1024/4); j++) { // (1024/4)
			uint32_t dat = *ptr;
			if (dat != generate_test_word_C(counter)) {
				term_print("Failed at word ");
				term_print_hex((uint32_t)ptr, 8);
				term_print(": ");
				term_print_hex((uint32_t)(dat), 8);
				term_print(" Expected: ");
				term_print_hex((uint32_t)(generate_test_word_C(counter)), 8);
				return;
			}
			ptr++;
			counter++;
		}
		term_x = 3;
		term_print_dec(i + 1);
		term_print(" KB passed.   ");
	}
}

// --------------------------------------------------------
/*
void cmd_read_flash_id()
{
	uint8_t buffer[17] = { 0x9F };
	flashio(buffer, 17, 0);

	for (int i = 1; i <= 16; i++) {
		putchar(' ');
		print_hex(buffer[i], 2);
	}
	putchar('\n');
}
*/
// --------------------------------------------------------

// --------------------------------------------------------
/*
uint32_t cmd_benchmark(bool verbose, uint32_t *instns_p)
{
	uint8_t data[256];
	uint32_t *words = (void*)data;

	uint32_t x32 = 314159265;

	uint32_t cycles_begin, cycles_end;
	uint32_t instns_begin, instns_end;
	__asm__ volatile ("rdcycle %0" : "=r"(cycles_begin));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_begin));

	for (int i = 0; i < 20; i++)
	{
		for (int k = 0; k < 256; k++)
		{
			x32 ^= x32 << 13;
			x32 ^= x32 >> 17;
			x32 ^= x32 << 5;
			data[k] = x32;
		}

		for (int k = 0, p = 0; k < 256; k++)
		{
			if (data[k])
				data[p++] = k;
		}

		for (int k = 0, p = 0; k < 64; k++)
		{
			x32 = x32 ^ words[k];
		}
	}

	__asm__ volatile ("rdcycle %0" : "=r"(cycles_end));
	__asm__ volatile ("rdinstret %0" : "=r"(instns_end));

	if (verbose)
	{
		print("Cycles: 0x");
		print_hex(cycles_end - cycles_begin, 8);
		putchar('\n');

		print("Instns: 0x");
		print_hex(instns_end - instns_begin, 8);
		putchar('\n');

		print("Chksum: 0x");
		print_hex(x32, 8);
		putchar('\n');
	}

	if (instns_p)
		*instns_p = instns_end - instns_begin;

	return cycles_end - cycles_begin;
}
*/
// --------------------------------------------------------

void main()
{
	term_goto(0,0);
	term_print("Pano Logic G1, ");
	term_print("PicoRV32 @ 100MHz, ");
	term_print("LPDDR @ 100MHz, det delay = ");
	term_print_hex(*((uint8_t *)0x03000000), 2);
	term_print("\n");
	for (int i = 0; i < 29; i++) {
		*((uint8_t *)0x03000000) = i;
		term_print_hex(i, 2);
		term_print(" ");
		ddr_memtest();
		term_newline();
	}
	while (1);
}
