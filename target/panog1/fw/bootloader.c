/*
 *  VerilogBoy
 *
 *  This source code is adapted from: 
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

// This is the bootloader for the PicoRV32 core inside Pano G1
// It will copy 256KB data from SPI Flash to the LPDDR RAM, and jump to the RAM

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

#define led_grn *((volatile uint32_t *)0x03000004)
#define led_red *((volatile uint32_t *)0x03000008)

#define dly_tap *((volatile uint32_t *)0x03000000)

#define spi_csn *((volatile uint32_t *)0x0300000C)
#define spi_clk *((volatile uint32_t *)0x03000010)
#define spi_do  *((volatile uint32_t *)0x03000014)
#define spi_di  *((volatile uint32_t *)0x03000018)

#define spi_select() spi_csn = 0
#define spi_deselect() spi_csn = 1

volatile uint32_t *vram_ptr;
volatile uint32_t *ddr_ptr;

void term_clear() {
    vram_ptr = vram;
    for (int i = 0; i < 80 * 30; i++) {
        *vram_ptr++ = 0x20;
    }
    vram_ptr = vram;
}

void term_putchar(char p)
{
    *vram_ptr++ = p;
}

void term_print(const char *p)
{
    while (*p)
        *vram_ptr++ = *p++;
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

uint32_t ddr_generate_test_word(uint32_t input) {
	return (input << 24) | (input << 12) | input;
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
			*ptr++ = ddr_generate_test_word(counter);
			counter ++;
		}
		vram_ptr = vram + 80;
		term_print_dec(i + 1);
		term_print(" KB testing...");
	}
	ptr = ddr;
	counter = 0;
	for (int i = 0; i < (DDR_TOTAL/1024); i++) { // (DDR_TOTAL/1024)
		for (int j = 0; j < (1024/4); j++) { // (1024/4)
			uint32_t dat = *ptr;
			if (dat != ddr_generate_test_word(counter)) {
				term_print("Failed at word ");
				term_print_hex((uint32_t)ptr, 8);
				term_print(": ");
				term_print_hex((uint32_t)(dat), 8);
				term_print(" Expected: ");
				term_print_hex((uint32_t)(ddr_generate_test_word(counter)), 8);
				return;
			}
			ptr++;
			counter++;
		}
		vram_ptr = vram + 80;
		term_print_dec(i + 1);
		term_print(" KB passed.   ");
	}
    vram_ptr = vram + 160;
}

void spi_send_byte(unsigned char b) {
    spi_clk = 1;
    for (int i = 0; i < 8; i++) {
        spi_clk = 0;
        spi_do = b >> 7;
        b = b << 1;
        spi_clk = 1;
    }
}

unsigned char spi_recv_byte() {
    unsigned char b = 0;
    for (int i = 0; i < 8; i++) {
        spi_clk = 0;
        b = b << 1;
        spi_clk = 1;
        b |= spi_di;
    }
    return b;
}

void check_id() {
    term_print("SPI Memory ID: ");
    // read SPI flash device id
    spi_select();
    spi_send_byte(0x9f);
    uint8_t mem_mfg = spi_recv_byte();
    uint8_t mem_typ = spi_recv_byte();
    uint8_t mem_cap = spi_recv_byte();
    spi_deselect();
    term_print_hex(mem_mfg, 2);
    term_print_hex(mem_typ, 2);
    term_print_hex(mem_cap, 2);
    if ((mem_mfg == 0x20) && (mem_typ == 0x20) && (mem_cap == 0x14))
        term_print(" Check passed.");
    else
        term_print(" Check failed.");
    // goto line 2
    vram_ptr = vram + 80;
}

void copy_loop() {
    ddr_ptr = ddr;  
    unsigned long address;
    term_print("Loading application... ");
    // interesting
    for (int i = 0; i < 256; i++) {
        address = i * 1024 + 0xC0000;
        spi_select();
        spi_send_byte(0x03);
        spi_send_byte((address >> 16)&0xFF);
        spi_send_byte((address >> 8)&0xFF);
        spi_send_byte((address)&0xFF);
        for (int j = 0; j < 1024/4; j++) {
            unsigned long b1 = (unsigned long)spi_recv_byte();
            unsigned long b2 = (unsigned long)spi_recv_byte();
            unsigned long b3 = (unsigned long)spi_recv_byte();
            unsigned long b4 = (unsigned long)spi_recv_byte();
            *ddr_ptr++ = (b4 << 24) | (b3 << 16) | (b2 << 8) | b1;
        }
        spi_deselect();
    }
    term_print("done.");
}

void check_bytes() {
    ddr_ptr = ((volatile uint32_t *)0x0C000400);
    for (int i = 0; i < 8; i++) {
        vram_ptr = vram + 80 * (i + 3);
        for (int j = 0; j < 8; j++) {
            unsigned long db = *ddr_ptr++;
            term_print_hex(db, 8);
        }
    }
}

void main()
{
    dly_tap = 0x03;
    spi_clk = 1;
    spi_csn = 1;
    led_grn = 1;
    vram_ptr = vram;
    term_clear();
    check_id();
    ddr_memtest();
    copy_loop();
    //check_bytes();
    led_grn = 0;
    led_red = 1;
}
