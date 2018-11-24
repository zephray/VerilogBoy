/*******************************************************************************

    This program is free software (firmware): you can redistribute it and/or
    modify it under the terms of  the GNU General Public License as published
    by the Free Software Foundation, either version 3 of the License, or (at
    your option) any later version.
   
    This program is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTIBILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.
   
    You should have received a copy of the GNU General Public License along
    with this program.  If not, see <http://www.gnu.org/licenses/> for a copy.

    Description: Miscellaneous functions

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __MISC_H__
#define __MISC_H__

#include "inc.h"

void rcc_clock_setup_in_hse_24mhz_out_72mhz(void);
void delay_setup(void);
void delay_us(uint32_t us);
void delay_us_loop(uint32_t t);
void delay_ms(uint32_t ms);

#endif