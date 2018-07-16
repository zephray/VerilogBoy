////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    07/15/2018 
// Module Name:    vb_sim
// Project Name:   VerilogBoy
// Description: 
//   Testbench Class Template. Basically feeding the module with clock.
//   Only one single clock is supported.
// Dependencies: 
// 
// Additional Comments: 
//   
////////////////////////////////////////////////////////////////////////////////
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
