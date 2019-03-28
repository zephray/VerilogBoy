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
#ifndef __USB_GAMEPAD_H__
#define __USB_GAMEPAD_H__

// Note: These setting may only affect the descriptor parser, 
//       but not actual report formatter.
#define MAX_DPAD    1
#define MAX_BUTTON  16
#define MAX_ANALOG  4
#define MAX_BITS    64

extern uint32_t gp_num_buttons;
extern uint32_t gp_buttons;
extern uint32_t gp_num_analogs;
extern uint8_t  gp_analog[MAX_ANALOG];

#endif