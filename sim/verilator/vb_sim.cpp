/*
 *  VerilogBoy
 *
 *  vb_sim.cpp: VerilogBoy main simulation unit
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
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <stdint.h>

#include <SDL2/SDL.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vboy.h"

#include "memsim.h"
#include "dispsim.h"
#include "mmrprobe.h"

#define VVAR(A) boy__DOT_ ## A

// this only applies to quiet mode.
const int CYCLE_LIMIT = 32768;

static bool quiet = false;
static bool verbose = false;
static bool trace = false;
static bool noboot = false;
static bool nostop = false;
static unsigned short breakpoint = 0xff7f;
static char result_file[127];

class TESTBENCH {
    Vboy *m_core;
    VerilatedVcdC* m_trace;
    unsigned long  m_tickcount;
public:
    bool m_done;
    bool m_fault;
    MEMSIM *m_bootrom;
    MEMSIM *m_cartram;
    DISPSIM *m_dispsim;
    MMRPROBE *m_mmrprobe;

    TESTBENCH() {
        m_core = new Vboy;
        Verilated::traceEverOn(true);

        m_done = false;
        m_bootrom = new MEMSIM(0x0000, 32768, 0);
        m_cartram = new MEMSIM(0xa000, 8192, 0);
        m_trace = NULL;

        if (!quiet) {
            m_dispsim = new DISPSIM();
        }
        if (verbose) {
            m_mmrprobe = new MMRPROBE();
        }
    }

    ~TESTBENCH() {
        if (m_trace) m_trace -> close();
        delete m_core;
        m_core = NULL;
        if (!quiet) {
            delete m_dispsim;
        }
        if (verbose) {
            delete m_mmrprobe;
        }
        delete m_bootrom;
        delete m_cartram;
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
        if ((m_tickcount > CYCLE_LIMIT) && (quiet) && (!nostop)) {
                printf("Time Limit Exceeded\n");
                return true;
        }
        if (m_fault)
            return true;
        return m_done && !nostop;
    }

    void set_title(char *title) {
        m_dispsim -> set_title(title);
    }

    virtual void tick(void) {
        m_bootrom->operator()(
            m_core -> dout,
            m_core -> a,
            0,
            //m_core -> wr,
            m_core -> rd,
            m_core -> din);

        m_cartram->operator()(
            m_core -> dout,
            m_core -> a,
            m_core -> wr,
            m_core -> rd,
            m_core -> din);

        if (!quiet) {
            m_dispsim->operator()(
                m_core -> pixel,
                m_core -> hs,
                m_core -> vs,
                m_core -> valid);
        }

        if (verbose) {
            m_mmrprobe->operator()(
                m_core -> boy__DOT__cpu_dout,
                m_core -> boy__DOT__cpu_a,
                m_core -> boy__DOT__cpu_wr,
                m_core -> boy__DOT__cpu_rd,
                m_core -> boy__DOT__cpu_din,
                m_core -> boy__DOT__cpu__DOT__last_pc);
        }

        m_tickcount++;

        // Make sure we have our evaluations straight before the top
        // of the clock.  This is necessary since some of the 
        // connection modules may have made changes, for which some
        // logic depends.  This forces that logic to be recalculated
        // before the top of the clock.
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount-2);
        m_core -> clk = 1;
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount);
        m_core -> clk = 0;
        eval();
        if (m_trace && trace) m_trace->dump(10*m_tickcount+5);

        m_done = m_core -> done;
        m_fault = m_core -> fault;

        // Break point
        if (m_core -> boy__DOT__cpu__DOT__last_pc == breakpoint) {
            m_done = 1;
        }
    }

    void reset(void) {
        m_core -> rst = 1;
        tick();
        m_core -> rst = 0;
        if (noboot) {
            m_core -> boy__DOT__brom_disable = 1; // Disable internal bootROM
        }
    }

    void print_regs(void) {
        if (quiet) {
            // output result to file
            FILE *result;
            result = fopen(result_file, "w+");
            if (result == NULL) return;
            fprintf(result, "AF %02x%02x\r\n",
                    m_core -> boy__DOT__cpu__DOT__acc__DOT__data,
                    m_core -> boy__DOT__cpu__DOT__flags << 4);
            fprintf(result, "BC %02x%02x\r\n",
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[0],
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[1]);
            fprintf(result, "DE %02x%02x\r\n",
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[2],
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[3]);
            fprintf(result, "HL %02x%02x\r\n",
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[4],
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[5]);
            fprintf(result, "SP %02x%02x\r\n",
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[6],
                    m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[7]);
            fprintf(result, "PC %04x\r\n",
                    m_core -> boy__DOT__cpu__DOT__last_pc);
            //fclose(result);
        }
        // print on screen
        printf("PC = %04x, F = %c%c%c%c, A = %02x, SP = %02x%02x\nB = %02x, C = %02x, D = %02x, E = %02x, H = %02x, L = %02x\n",
            m_core -> boy__DOT__cpu__DOT__last_pc,
            ((m_core -> boy__DOT__cpu__DOT__flags) & 0x8) ? 'Z' : '-',
            ((m_core -> boy__DOT__cpu__DOT__flags) & 0x4) ? 'N' : '-',
            ((m_core -> boy__DOT__cpu__DOT__flags) & 0x2) ? 'H' : '-',
            ((m_core -> boy__DOT__cpu__DOT__flags) & 0x1) ? 'C' : '-',
            m_core -> boy__DOT__cpu__DOT__acc__DOT__data,
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[6],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[7],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[0],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[1],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[2],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[3],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[4],
            m_core -> boy__DOT__cpu__DOT__regfile__DOT__regs[5]
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
    puts("USAGE: vb_sim <rom.gb> [--testmode] [--verbose] [--trace] [--noboot]"
            "[--nostop] (verilator paramters...)\n");
}

int main(int argc, char **argv) {
    const char *trace_file = "trace.vcd";
    char window_title[63];

    if (argc < 2) {
        usage();
        exit(EXIT_FAILURE);
    }

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--testmode") == 0) {
            quiet = true;
            strcpy(result_file, argv[1]);
            char *location = strstr(result_file, ".");
            if (location == NULL)
                location = result_file + strlen(result_file);
            strcpy(location, ".actual");
            noboot = true;
        }
        if (strcmp(argv[i], "--noboot") == 0) {
            noboot = true;
        }
        if (strcmp(argv[i], "--verbose") == 0) {
            verbose = true;
        }
        if (strcmp(argv[i], "--trace") == 0) {
            trace = true;
        }
        if (strcmp(argv[i], "--nostop") == 0) {
            nostop = true;
        }
    }

    Verilated::commandArgs(argc, argv);

    tb = new TESTBENCH();
    tb -> load_bootrom(argv[1]);
    tb -> opentrace(trace_file);
    tb -> reset();

    if (!quiet) printf("Initialized\n");

    uint32_t sim_tick = 0;
    uint32_t ms_tick = SDL_GetTicks();
    while (!tb->done()) {
    //while (true) {
        tb -> tick();

        sim_tick++;

        // Get the next event
        if (!quiet & (sim_tick % 4096 == 0)) {
            SDL_Event event;
            if (SDL_PollEvent(&event))
            {
                if (event.type == SDL_QUIT)
                {
                    // Break out of the loop on quit
                    break;
                }
            }
            uint32_t ms_delta = SDL_GetTicks() - ms_tick;
            int sim_freq = sim_tick / ms_delta;
            sim_tick = 0;
            sprintf(window_title, "VerilogBoy Sim (%d kHz)", sim_freq);
            tb -> set_title(window_title);
            ms_tick = SDL_GetTicks();
        }
    }

    if (!quiet) printf("Execution end.\n");
    tb -> print_regs();
    tb -> closetrace();

    exit(EXIT_SUCCESS);
}
