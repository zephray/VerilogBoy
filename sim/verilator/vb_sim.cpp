////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    07/15/2018 
// Module Name:    vb_sim
// Project Name:   VerilogBoy
// Description: 
//   The main verilator simulation unit.
// Dependencies: 
// 
// Additional Comments: 
//   
////////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <time.h>
#include <unistd.h>
#include <stdint.h>

#include "verilated.h"
#include "Vgameboy.h"

// Testbench Class Template
template<>

int main(int argc, char **argv) {
    // Initialize Verilator variables
    Verilated::commandArgs(argc, argv);

    // Create an instance of the main GameBoy
    Vgameboy *tb = new Vgameboy;

    // Main loop
    while (!Verilated::gotFinish()) {
        tb -> clk = 0;
        tb -> eval();
        tb -> clk = 1;
        tb -> eval();
    }

    exit(EXIT_SUCCESS);
}
