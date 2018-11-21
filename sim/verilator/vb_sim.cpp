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
    with this program.  (It's in the $(ROOT)/doc directory.  Run make with no
    target there if the PDF file isn't present.)  If not, see
    <http://www.gnu.org/licenses/> for a copy.

    Description: VerilogBoy main simulation unit

    Copyright (C) 2018 Wenting Zhang
    Copyright (C) 2015,2017, Gisselquist Technology, LLC

*******************************************************************************/
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <stdint.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vgameboy.h"

#include "memsim.h"

#define VVAR(A) gameboy__DOT_ ## A

class TESTBENCH {
    Vgameboy *m_core;
    VerilatedVcdC* m_trace;
    unsigned long  m_tickcount;
public:
    bool m_done;
    MEMSIM *m_bootrom;

    TESTBENCH() {
        m_core = new Vgameboy;
        Verilated::traceEverOn(true);

        m_done = false;
        m_bootrom = new MEMSIM(128, 0);
    }

    ~TESTBENCH() {
        if (m_trace) m_trace -> close();
        delete m_core;
        m_core = NULL;
    }

    void opentrace(const char *vcdname) {
        if (!m_trace) {
            m_trace = new VerilatedVcdC;
            m_core -> trace(m_trace, 99);
            m_trace -> open(vcdname);
        }
    }

    void closetrace(void) {
        if (m_trace) {
            m_trace -> close();
            m_trace = NULL;
        }
    }

    void eval(void) {
        m_core -> eval();
    }

    void load_bootrom(const char *fname) {
        m_bootrom -> load(fname);
    }

    void close(void) {
        m_done = true;
    }

    bool done(void) {
        return m_done;
    }

    virtual void tick(void) {
        m_bootrom->operator()(
            m_core -> dout,
            m_core -> a,
            m_core -> wr,
            m_core -> rd,
            m_core -> din);

        m_tickcount++;

        // Make sure we have our evaluations straight before the top
        // of the clock.  This is necessary since some of the 
        // connection modules may have made changes, for which some
        // logic depends.  This forces that logic to be recalculated
        // before the top of the clock.
        eval();
        if (m_trace) m_trace->dump(10*m_tickcount-2);
        m_core -> clk = 1;
        eval();
        if (m_trace) m_trace->dump(10*m_tickcount);
        m_core -> clk = 0;
        eval();
        if (m_trace) m_trace->dump(10*m_tickcount+5);

        m_done = m_core -> done;
    }

    void reset(void) {
        m_core -> rst = 1;
        tick();
        m_core -> rst = 0;
    }

    void print_regs(void) {
        printf("PC = %04x, F = %c%c%c%c, A = %02x\nB = %02x, C = %02x, D = %02x, E = %02x, H = %02x, L = %02x\n",
            m_core -> gameboy__DOT__cpu__DOT__pc,
            ((m_core -> gameboy__DOT__cpu__DOT__flags__DOT__data) & 0x8) ? 'Z' : '-',
            ((m_core -> gameboy__DOT__cpu__DOT__flags__DOT__data) & 0x4) ? 'N' : '-',
            ((m_core -> gameboy__DOT__cpu__DOT__flags__DOT__data) & 0x2) ? 'H' : '-',
            ((m_core -> gameboy__DOT__cpu__DOT__flags__DOT__data) & 0x1) ? 'C' : '-',
            m_core -> gameboy__DOT__cpu__DOT__acc__DOT__data,
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[0],
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[1],
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[2],
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[3],
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[4],
            m_core -> gameboy__DOT__cpu__DOT__regfile__DOT__regs[5]
        );
    }
};

TESTBENCH *tb;

void vb_kill(int v) {
    tb -> close();
    fprintf(stderr, "KILLED!!\n");
    exit(EXIT_SUCCESS);
}

void usage(void) {
    puts("USAGE: vb_sim <rom_file> (verilator paramters...)\n");
}

int main(int argc, char **argv) {
    const char *trace_file = "trace.vcd";

    printf("VerilogBoy Simulator\n");

    if (argc < 2) {
        usage();
        exit(EXIT_FAILURE);
    }

    Verilated::commandArgs(argc, argv);

    tb = new TESTBENCH();
    tb -> load_bootrom(argv[1]);
    tb -> opentrace(trace_file);
    tb -> reset();

    printf("Initialized\n");

    while (!tb->done()) {
        tb -> tick();
    }

    printf("Execution end.\n");
    tb -> print_regs();

    tb -> closetrace();

    exit(EXIT_SUCCESS);
}
