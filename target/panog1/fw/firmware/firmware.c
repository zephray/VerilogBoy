/*
 *  VerilogBoy
 *
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *
 *  This file is partially derived from PicoRV32 project:
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
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
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include "misc.h"
#include "term.h"
#include "part.h"
#include "usb.h"
#include "usb_gamepad.h"
#include "ff.h"
#include "wm8750.h"

#define dly_tap *((volatile uint32_t *)0x03000000)
#define led_grn *((volatile uint32_t *)0x03000004)
#define led_red *((volatile uint32_t *)0x03000008)
#define vb_key  *((volatile uint32_t *)0x03000010)
#define vb_rst  *((volatile uint32_t *)0x0300000c)

static int keycode_down;
static int keycode_up;
static int keycode_left;
static int keycode_right;
static int keycode_start;
static int keycode_select;
static int keycode_b;
static int keycode_a;

void irq_handler(uint32_t pc) {
    term_print_string("HARD FAULT PC = ");
    term_print_hex(pc, 8);
    while (1);
}

void ui_printframe() {
    term_clear();
    term_goto(31, 0);
    printf("VerilogBoy Pano G1");
    term_goto(0, 1);
    for (int i = 0; i < 80; i++) term_putchar('-');
    term_goto(0, 28);
    for (int i = 0; i < 80; i++) term_putchar('-');
}

// keycode is the shift from right
int task_getkey() {
    usb_event_poll();
    term_goto(0, 0);
    term_print_hex(gp_buttons, 8);
    for (int i = 0; i < 32; i++) {
        if (gp_buttons & (1 << i)) return i;
    }
    delay_ms(30);
    return -1;
}

int task_remap_gamepad() {
    struct usb_device *dev;

    ui_printframe();
    if (gp_devindex != -1) {
        dev = usb_get_dev_index(gp_devindex);
        if((dev->devnum == -1)) {
            goto task_remap_no_gamepad;
        }
    }
    else {
        goto task_remap_no_gamepad;
    }

    term_goto(4, 3);
    printf("Mapping gamepad buttons. Current detected gamepad:");
    term_goto(8, 4);
    printf("%s %s", dev->mf, dev->prod);
    term_goto(4, 6);
    printf("Please press [        ] on your gamepad.");
    term_goto(9, 10);
    printf(" ___________________________________________________________ ");
    term_goto(9, 11);
    printf("|                                                           |");
    term_goto(9, 12);
    printf("|        ____                                               |");
    term_goto(9, 13);
    printf("|       |    |                                              |");
    term_goto(9, 14);
    printf("|    ___|    |___     SELECT     START      ___      ___    |");
    term_goto(9, 15);
    printf("|   |            |    ______     ______    /   \\    /   \\   |");
    term_goto(9, 16);
    printf("|   |___      ___|   |______|   |______|  (  B  )  (  A  )  |");
    term_goto(9, 17);
    printf("|       |    |                             \\___/    \\___/   |");
    term_goto(9, 18);
    printf("|       |____|                                              |");
    term_goto(9, 19);
    printf("|                                                           |");
    term_goto(9, 20);
    printf("|                                                           |");
    term_goto(9, 21);
    printf("|___________________________________________________________|");

    term_goto(19, 6);
    printf(" DOWN ");
    while ((keycode_down = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf("  UP  ");
    while ((keycode_up = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf(" LEFT ");
    while ((keycode_left = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf(" RIGHT");
    while ((keycode_right = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf(" START");
    while ((keycode_start = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf("SELECT");
    while ((keycode_select = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf("   B  ");
    while ((keycode_b = task_getkey()) == -1);
    while (task_getkey() != -1);
    term_goto(19, 6);
    printf("   A  ");
    while ((keycode_a = task_getkey()) == -1);
    while (task_getkey() != -1);

    ui_printframe();
    term_goto(4, 3);
    printf("Finished, press A to accept, anything else to start over.");
    term_goto(4, 5);
    int keycode;
    while ((keycode = task_getkey()) == -1);
    while (task_getkey() != -1);
    if (keycode == keycode_a) return 0;
    else return -1;

task_remap_no_gamepad:
    term_goto(10, 14);
    printf("No gamepad detected. Please plug in a controller and reset.");
    while(1);

}

void main() {
    FATFS FatFs;				/* File system object for each logical drive */
    FIL File[2];				/* File objects */
    DIR Dir;					/* Directory object */
    FILINFO Finfo;
    FRESULT res;
    int result;

    dly_tap = 0x03;
    led_red = 0;
    led_grn = 1;

    // Set interrupt mask to zero (enable all interrupts)
    // This is a PicoRV32 custom instruction 
    asm(".word 0x0600000b");

    term_clear();
    term_goto(0,0);
    printf("Pano Logic G1, PicoRV32 @ 25MHz, LPDDR @ 100MHz.\n");
    usb_init();
    term_clear();

    wm8750_init();

    term_enable_uart(false);

    // Map joystick
    do {
        task_remap_gamepad();
    } while (result != 0);

    res = f_mount(&FatFs, "", 1);
    if (res != FR_OK) {
        printf("Unable to mount filesystem: %d\n", (int)res);
        goto error;
    }

    const char root[] = "USB:/";
    char directory[18] = "";
    char filename[32] = "0:/";

    while (1) {
        // Main loop

        // Clear screen
        ui_printframe();
        term_goto(4, 3);
        printf("Select game:");
        term_goto(8, 5);
        printf("Current directory: %s%s", root, directory);
        term_goto(12, 7);
        printf("Filename");
        term_goto(28, 7);
        printf("Size");
        term_goto(40, 7);
        printf("Attrib");
        term_goto(52, 7);
        printf("Last modified");

        // First list all files
        res = f_opendir(&Dir, directory);
        if (res != FR_OK) {
            printf("Unable to open directory: %d\n", (int)res);
            goto error;
        }
        uint32_t filecount = 0;
        uint32_t dircount = 0;
        uint32_t line = 8;
        for(;;) {
            res = f_readdir(&Dir, &Finfo);
            if ((res != FR_OK) || !Finfo.fname[0]) break;
            if (Finfo.fattrib & AM_DIR) {
                dircount++;
            } else {
                filecount++;
            }

            term_goto(12, line);
            printf("%s", Finfo.fname);
            term_goto(28, line);
            printf("%d", Finfo.fsize);
            term_goto(40, line);
            printf("%c%c%c%c%c",
                    (Finfo.fattrib & AM_DIR) ? 'D' : '-',
                    (Finfo.fattrib & AM_RDO) ? 'R' : '-',
                    (Finfo.fattrib & AM_HID) ? 'H' : '-',
                    (Finfo.fattrib & AM_SYS) ? 'S' : '-',
                    (Finfo.fattrib & AM_ARC) ? 'A' : '-');
            term_goto(52, line);
            printf("0000/00/00 00:00");
            term_goto(52, line);
            printf("%d", (Finfo.fdate >> 9) + 1980);
            term_goto(57, line);
            printf("%d", (Finfo.fdate >> 5) & 15);
            term_goto(60, line);
            printf("%d", (Finfo.fdate & 31));
            term_goto(63, line);
            printf("%d", (Finfo.ftime >> 11));
            term_goto(66, line);
            printf("%d", (Finfo.ftime >> 5) & 63);
            line++;
        }

        int keycode;
        int selection = 0;
        term_goto(8, 8+selection);
        term_putchar('>');
        do {
            while ((keycode = task_getkey()) == -1);
            if ((keycode == keycode_up) && (selection != 0)) {
                term_goto(8, 8+selection);
                term_putchar(' ');
                selection --;
                term_goto(8, 8+selection);
                term_putchar('>');
            }
            else if ((keycode == keycode_down) && (selection != line - 1)) {
                term_goto(8, 8+selection);
                term_putchar(' ');
                selection ++;
                term_goto(8, 8+selection);
                term_putchar('>');
            }
            while (task_getkey() != -1);
        } while (keycode != keycode_a);

        term_goto(17, 10);
        for (int i = 0; i < 46; i++) term_putchar('_');
        for (int i = 11; i < 16; i++) {
            term_goto(16, i); 
            term_putchar('|');
            for (int i = 0; i < 46; i++) term_putchar(' ');
            term_putchar('|');
        }
        term_goto(17, 15);
        for (int i = 0; i < 46; i++) term_putchar('_');
        term_goto(37, 11);
        printf("Notice");
        term_goto(20, 12);

        line = 0;
        res = f_opendir(&Dir, directory);
        if (res != FR_OK) {
            printf("Unable to open directory: %d\n", (int)res);
            goto error;
        }
        do {
            res = f_readdir(&Dir, &Finfo);
            if ((res != FR_OK) || !Finfo.fname[0]) break; // what if it breaks?
            line ++;
        } while ((line - 1) != selection);
        strcpy(filename + 3, Finfo.fname);
        
        res = f_open(&File[0], filename, FA_OPEN_EXISTING | FA_READ);
        if (res) {
            printf("Unable to open game file.\n");
            while(1);
        }

        int actual;
        printf("Game loading in progress. Please wait...");
        term_goto(21, 14);
        f_read(&File[0], (void *)(0x0c800000), 32*1024, &actual);
        if (actual != 32768) {
            printf("Unable to read game file (%d bytes read).\n", actual);
            while(1);
        }

        volatile uint8_t *romptr, *base;
        base = (uint8_t *)0x0c800000;
        uint32_t sum = 0;
        for (int i = 0; i < 32*1024; i++) {
            romptr = base + i;
            if (i != 0x14E && i != 0x14F) {
                sum += *romptr;
            }
        }
        sum &= 0xffff;
        uint32_t romsum;
        romptr = base + 0x14e;
        romsum = (*romptr)&0xff;
        romsum = romsum << 8;
        romptr = base + 0x14f;
        romsum = romsum | ((*romptr)&0xff);
        if (sum != romsum) {
            term_goto(20, 13);
            printf("     Checksum error: %04x (expected %04x)     ", sum, romsum);
            term_goto(20, 14);
            printf(" Press A to ignore, any other key to go back. ");
            while ((keycode = task_getkey()) == -1);
            if (keycode != keycode_a) continue; 
        }

        vb_rst = 0;

        uint8_t vb_keyin;
        while (1) {
            led_grn = 1;
            delay_ms(15);
            led_grn = 0;
            delay_ms(15);
            usb_event_poll();
            vb_keyin = 0;
            term_goto(0, 0);
            if (gp_buttons & (1 << keycode_down))   vb_keyin |= 0x80;
            if (gp_buttons & (1 << keycode_up))     vb_keyin |= 0x40;
            if (gp_buttons & (1 << keycode_left))   vb_keyin |= 0x20;
            if (gp_buttons & (1 << keycode_right))  vb_keyin |= 0x10;
            if (gp_buttons & (1 << keycode_start))  vb_keyin |= 0x08;
            if (gp_buttons & (1 << keycode_select)) vb_keyin |= 0x04;
            if (gp_buttons & (1 << keycode_b))      vb_keyin |= 0x02;
            if (gp_buttons & (1 << keycode_a))      vb_keyin |= 0x01;
            term_print_hex(vb_keyin, 2);
            vb_key = vb_keyin;
            // TODO: Add exit condition
        }
    }

error:
    led_red = 1;
    while(1);

}
