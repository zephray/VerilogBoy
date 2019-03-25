/*
 *  VerilogBoy
 *  
 *  tb.h: Testbench Class Template. Basically feeding the module with clock.
 *        Only one single clock is supported.
 * 
 *  Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
 *  Copyright (C) 2015,2017, Gisselquist Technology, LLC
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms and conditions of the GNU General Public License as 
 *  published by the Free Software Foundation, either version 3 of the license,
 *  or (at your option) any later version.
 *
 *  This program is distributed in the hope it will be useful, but WITHOUT
 *  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 *  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 *  more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, see <http://www.gnu.org/licenses/> for a copy.
 */
#include <stdio.h>
#include <stdint.h>
#include <verilated_vcd_c.h>

// Testbench Class Template
template <class Module> class TestBench {
    unsigned long long ticks;
    VerilatedVcdC* trace;
    Module *dut;
    
    TestBench(void) : trace(NULL), ticks(1) {
        dut = new Module;
        Verilated::traceEverOn(true);
        dut -> clk = 0;
        eval();
    }
    
    virtual ~TestBench(void) {
        if (trace) trace -> close();
        delete dut;
        dut = NULL;
    }

    virtual void open_trace(const char * vcdname) {
        if (!trace) {
            trace = new VerilatedVcdC;
            dut -> trace(trace, 99);
            trace -> open(vcdname);
        }
    }
    
    virtual void close_trace(void) {
        if (trace) {
            trace -> close();
            trace = NULL;
        }
    }
    
    virtual void eval(void) {
        dut -> eval();
    }
    
    virtual void tick(void) {
        // External signals might have changed
        eval();
        ticks++;
        if (trace) trace -> dump(ticks);
        
        dut->clk = 1;
        eval();
        ticks++;
        if (trace) trace -> dump(ticks);
        
        dut->clk = 0;
        eval();
        ticks++;
        if (trace) trace -> dump(ticks);
        
        if (trace) trace -> flush();
    }
    
    virtual void reset(void) {
        dut -> rst = 1;
        tick();
        dut -> rst = 0;
    }
}
