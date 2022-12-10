//
// VerilogBoy simulator
// Copyright 2022 Wenting Zhang
//
// main.cpp: VerilogBoy main simulation unit
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include <time.h>
#include <vector>

#include <SDL.h>

#include "verilated.h"
#include "verilated_vcd_c.h"
#include "Vboy___024root.h"
#include "Vboy.h"

#include "memsim.h"
#include "mbcsim.h"
#include "dispsim.h"
#include "mmrprobe.h"
#include "audiosim.h"

#define CLK_PERIOD_PS 250000

#define RAM_BASE 0x80000000
#define RAM_SIZE 1*1024*1024

#define CON_BASE 0x20000000

// Verilator related
Vboy *core;
VerilatedVcdC *trace;

#define CONCAT(a,b) a##b
#define SIGNAL(x) CONCAT(core->rootp->boy__DOT__,x)

// this only applies to quiet mode.
const uint64_t CYCLE_LIMIT = 32768;

static bool quiet = false;
static bool verbose = false;
static bool enable_trace = false;
static bool noboot = false;
static bool nostop = false;
static bool itrace = false;
static bool usembc = false;
static bool enable_audio = false;
static unsigned short breakpoint = 0xff7f;
static char result_file[127];

// Software simulated peripherals
MEMSIM *cartrom;
MEMSIM *cartram;
MBCSIM *mbc;
DISPSIM *dispsim;
MMRPROBE *mmrprobe;
AUDIOSIM *audiosim;
FILE *it;

// State
uint64_t tickcount;

double sc_time_stamp() {
    // This is in pS. Currently we use a 10ns (100MHz) clock signal.
    return (double)tickcount * (double)CLK_PERIOD_PS;
}

void tick() {
    if (usembc) {
        mbc->apply(
            core->dout,
            core->a,
            core->wr,
            core->rd,
            core->din);
    }
    else {
        cartrom->apply(
            core->dout,
            core->a,
            0,
            //core->wr,
            core->rd,
            core->din);

        cartram->apply(
            core->dout,
            core->a,
            core->wr,
            core->rd,
            core->din);
    }

    if (!quiet) {
        dispsim->apply(
            core->pixel,
            core->hs,
            core->vs,
            core->valid);
    }

    if (enable_audio) {
        audiosim->apply(
            core->left,
            core->right);
    }

    if (verbose) {
        mmrprobe->apply(
            SIGNAL(cpu_dout),
            SIGNAL(cpu_a),
            SIGNAL(cpu_wr),
            SIGNAL(cpu_rd),
            SIGNAL(cpu_din),
            SIGNAL(cpu__DOT__last_pc));
    }

    tickcount++;

    core->eval();
    if (enable_trace) trace->dump(tickcount * CLK_PERIOD_PS - CLK_PERIOD_PS / 4);
    core->clk = 1;
    core->eval();
    if (enable_trace) trace->dump(tickcount * CLK_PERIOD_PS);
    core->clk = 0;
    core->eval();
    if (enable_trace) trace->dump(tickcount * CLK_PERIOD_PS + CLK_PERIOD_PS / 2);

    if (itrace) {
        if ((SIGNAL(cpu__DOT__ct_state == 3)) && 
            (SIGNAL(cpu__DOT__next == 0))) {
            // Instruction just finished executing
            fprintf(it, "Time %ld\nPC = %04x, F = %c%c%c%c, A = %02x, SP = %02x%02x\nB = %02x, C = %02x, D = %02x, E = %02x, H = %02x, L = %02x\n",
                10 * (tickcount - 1), // Make timing compatible with old traces
                SIGNAL(cpu__DOT__pc),
                ((SIGNAL(cpu__DOT__flags)) & 0x8) ? 'Z' : '-',
                ((SIGNAL(cpu__DOT__flags)) & 0x4) ? 'N' : '-',
                ((SIGNAL(cpu__DOT__flags)) & 0x2) ? 'H' : '-',
                ((SIGNAL(cpu__DOT__flags)) & 0x1) ? 'C' : '-',
                SIGNAL(cpu__DOT__acc__DOT__data),
                SIGNAL(cpu__DOT__regfile__DOT__regs[6]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[7]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[0]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[1]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[2]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[3]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[4]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[5]));
        }
    }
}

void reset() {
    core->rst = 0;
    tick();
    core->rst = 1;
    tick();
    core->rst = 0;
    if (noboot) {
        SIGNAL(brom_disable) = 1;
    }
}

int main(int argc, char *argv[]) {

    // Initialize testbench
    Verilated::commandArgs(argc, argv);

    core = new Vboy;
    Verilated::traceEverOn(true);

    if (argc < 2) {
        puts("USAGE: vb_sim <rom.gb> [--testmode] [--verbose] [--trace] [--noboot]"
            "[--nostop] [--itrace] [--mbc] (verilator paramters...)\n");
        exit(0);
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
        // Skip boot ROM
        if (strcmp(argv[i], "--noboot") == 0) {
            noboot = true;
        }
        // Enable MMR probe
        if (strcmp(argv[i], "--verbose") == 0) {
            verbose = true;
        }
        // Enable waveform trace
        if (strcmp(argv[i], "--trace") == 0) {
            enable_trace = true;
        }
        // Does not stop on STOP/HALT
        if (strcmp(argv[i], "--nostop") == 0) {
            nostop = true;
        }
        // Enable instruction level trace
        if (strcmp(argv[i], "--itrace") == 0) {
            itrace = true;
        }
        // Enable MBC emulation
        if (strcmp(argv[i], "--mbc") == 0) {
            usembc = true;
        }
        // Enable audio capture
        if (strcmp(argv[i], "--audio") == 0) {
            enable_audio = true;
        }
    }

    if (enable_trace) {
        trace = new VerilatedVcdC;
        core->trace(trace, 99);
        trace->open("trace.vcd");
    }

    if (usembc) {
        mbc = new MBCSIM();
    }
    else {
        cartrom = new MEMSIM(0x0000, 32768);
        cartram = new MEMSIM(0xa000, 8192);
    }

    if (!quiet) {
        dispsim = new DISPSIM();
    }
    if (verbose) {
        mmrprobe = new MMRPROBE();
    }
    if (itrace) {
        it = fopen("itrace.txt", "w");
        if (!it) {
            itrace = false;
            fprintf(stderr, "Fail to open output file for itrace.\n");
        }
    }

    if (usembc)
        mbc->load(argv[1]);
    else
        cartrom->load(argv[1]);

    if (enable_audio) {
        audiosim = new AUDIOSIM();
    }

    // Start simulation
    if (verbose)
        printf("Simulation start.\n");

    reset();

    uint32_t sim_tick = 0;
    uint32_t ms_tick = SDL_GetTicks();
    char window_title[63];
    bool running = true;
    while (running) {
        tick();
        
        sim_tick++;

        // Check end condition
        if (SIGNAL(cpu__DOT__last_pc) == breakpoint) {
            printf("Hit breakpoint\n");
            running = false;
        }

        if ((tickcount > CYCLE_LIMIT) && (quiet) && (!nostop)) {
            printf("Time Limit Exceeded\n");
            running = false;
        }

        if (core->fault) {
            printf("Core fault condition\n");
            running = false;
        }

        if (core->done && !nostop)
            running = false;

        // Get the next event
        if (!quiet & (sim_tick % 4096 == 0)) {
            SDL_Event event;
            if (SDL_PollEvent(&event)) {
                if (event.type == SDL_QUIT) {
                    // Break out of the loop on quit
                    running = false;
                }
                else if ((event.type == SDL_KEYDOWN) || (event.type == SDL_KEYUP)) {
                    uint8_t keycode = 0;
                    switch (event.key.keysym.sym){
                        case SDLK_DOWN:
                            keycode = 0x80;
                            break;
                        case SDLK_UP:
                            keycode = 0x40;
                            break;
                        case SDLK_LEFT:
                            keycode = 0x20;
                            break;
                        case SDLK_RIGHT:
                            keycode = 0x10;
                            break;
                        case SDLK_z:
                            keycode = 0x08;
                            break;
                        case SDLK_x:
                            keycode = 0x04;
                            break;
                        case SDLK_a:
                            keycode = 0x02;
                            break;
                        case SDLK_s:
                            keycode = 0x01;
                            break;
                        default:
                            break;
                    }
                    if (event.type == SDL_KEYDOWN) {
                        core->key |= keycode;
                    }
                    else {
                        core->key &= ~keycode;
                    }
                }
            }
            uint32_t ms_delta = SDL_GetTicks() - ms_tick;
            int sim_freq = sim_tick / ms_delta;
            sim_tick = 0;
            sprintf(window_title, "VerilogBoy Sim (%d kHz)", sim_freq);
            dispsim->set_title(window_title);
            ms_tick = SDL_GetTicks();
        }
    }

    if (quiet) {
        // output result to file
        FILE *result;
        result = fopen(result_file, "w+");
        assert(result);
        fprintf(result, "AF %02x%02x\r\n",
                SIGNAL(cpu__DOT__acc__DOT__data),
                SIGNAL(cpu__DOT__flags) << 4);
        fprintf(result, "BC %02x%02x\r\n",
                SIGNAL(cpu__DOT__regfile__DOT__regs[0]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[1]));
        fprintf(result, "DE %02x%02x\r\n",
                SIGNAL(cpu__DOT__regfile__DOT__regs[2]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[3]));
        fprintf(result, "HL %02x%02x\r\n",
                SIGNAL(cpu__DOT__regfile__DOT__regs[4]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[5]));
        fprintf(result, "SP %02x%02x\r\n",
                SIGNAL(cpu__DOT__regfile__DOT__regs[6]),
                SIGNAL(cpu__DOT__regfile__DOT__regs[7]));
        fprintf(result, "PC %04x\r\n",
                SIGNAL(cpu__DOT__pc));
        fclose(result);
    }
    // print on screen
    printf("PC = %04x, F = %c%c%c%c, A = %02x, SP = %02x%02x\nB = %02x, C = %02x, D = %02x, E = %02x, H = %02x, L = %02x\n",
        SIGNAL(cpu__DOT__pc),
        ((SIGNAL(cpu__DOT__flags)) & 0x8) ? 'Z' : '-',
        ((SIGNAL(cpu__DOT__flags)) & 0x4) ? 'N' : '-',
        ((SIGNAL(cpu__DOT__flags)) & 0x2) ? 'H' : '-',
        ((SIGNAL(cpu__DOT__flags)) & 0x1) ? 'C' : '-',
        SIGNAL(cpu__DOT__acc__DOT__data),
        SIGNAL(cpu__DOT__regfile__DOT__regs[6]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[7]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[0]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[1]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[2]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[3]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[4]),
        SIGNAL(cpu__DOT__regfile__DOT__regs[5])
    );

    if (enable_trace) {
        trace->close();
    }

    delete core;
    if (!quiet) {
        delete dispsim;
    }
    if (verbose) {
        delete mmrprobe;
    }
    if (it) {
        fclose(it);
    }
    if (usembc) {
        delete mbc;
    }
    else {
        delete cartrom;
        delete cartram;
    }
    if (enable_audio) {
        audiosim->save("audio.wav");
        delete audiosim;
    }

    return 0;
}
