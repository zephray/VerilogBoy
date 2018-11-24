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

    Description: FPGA communication functions

    Copyright (C) 2018 Wenting Zhang

*******************************************************************************/
#ifndef __FPGA_H__
#define __FPGA_H__

#include "inc.h"

void fpga_setup(void);
void fpga_write_reg(uint8_t addr, uint8_t data);
uint8_t fpga_read_reg(uint8_t addr);
void fpga_init(void);

#endif