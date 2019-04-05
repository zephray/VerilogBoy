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

#define led_grn *((volatile uint32_t *)0x03000004)
#define led_red *((volatile uint32_t *)0x03000008)
#define vb_key  *((volatile uint32_t *)0x03000020)
#define vb_rst  *((volatile uint32_t *)0x03000024)

void main()
{
    FATFS FatFs;				/* File system object for each logical drive */
    FIL File[2];				/* File objects */
    DIR Dir;					/* Directory object */
    FILINFO Finfo;
    FRESULT res;
    long p1, p2, p3;
    unsigned int s1, s2;

    led_red = 0;

    // Set interrupt mask to zero (enable all interrupts)
    // This is a PicoRV32 custom instruction 
    asm(".word 0x0600000b");

    term_goto(0,4);
    printf("Pano Logic G1, PicoRV32 @ 100MHz, LPDDR @ 100MHz.\n");
    usb_init();
    term_clear();
    
    res = f_mount(&FatFs, "", 1);
    if (res != FR_OK) {
        printf("Unable to mount filesystem: %d\n", (int)res);
        goto error;
    }

    res = f_opendir(&Dir, "");
    if (res != FR_OK) {
        printf("Unable to open directory: %d\n", (int)res);
        goto error;
    }
    p1 = s1 = s2 = 0;
    for(;;) {
        res = f_readdir(&Dir, &Finfo);
        if ((res != FR_OK) || !Finfo.fname[0]) break;
        if (Finfo.fattrib & AM_DIR) {
            s2++;
        } else {
            s1++; p1 += Finfo.fsize;
        }
        printf("%c%c%c%c%c %u/%02u/%02u %02u:%02u %9lu  %s\n",
                (Finfo.fattrib & AM_DIR) ? 'D' : '-',
                (Finfo.fattrib & AM_RDO) ? 'R' : '-',
                (Finfo.fattrib & AM_HID) ? 'H' : '-',
                (Finfo.fattrib & AM_SYS) ? 'S' : '-',
                (Finfo.fattrib & AM_ARC) ? 'A' : '-',
                (Finfo.fdate >> 9) + 1980, (Finfo.fdate >> 5) & 15, Finfo.fdate & 31,
                (Finfo.ftime >> 11), (Finfo.ftime >> 5) & 63,
                (DWORD)Finfo.fsize, Finfo.fname);
    }
    printf("%4u File(s),%10lu bytes total\n%4u Dir(s)", s1, p1, s2);
    /*res = f_getfree(ptr, (DWORD*)&p1, &fs);
    if (res == FR_OK)
        printf(", %10lu bytes free\n", p1 * fs->csize * 512);
    else
        printf("Unable to get free space: %d\n", (int)res);*/
    
    res = f_open(&File[0], "0:/TETRIS.GB", FA_OPEN_EXISTING | FA_READ);
    if (res) {
        printf("Unable to open game file.\n");
        while(1);
    }

    int actual;
    f_read(&File[0], (void *)(0x0c800000), 32*1024, &actual);
    if (actual != 32768) {
        printf("Unable to read game file (%d bytes read).\n", actual);
        while(1);
    }
    printf("Game loaded\n");
    vb_rst = 0;
    printf("Reset released\n");

	while (1) {
        led_grn = 1;
        delay_ms(10);
        led_grn = 0;
        delay_ms(10);
        /*usb_event_poll();
        term_goto(0,0);
        printf("%04x, %d, %d, %d, %d\n", gp_buttons, gp_analog[0], gp_analog[1], gp_analog[2], gp_analog[3]);*/
    }

error:
    led_red = 1;
    while(1);

}
