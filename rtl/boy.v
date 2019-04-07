`timescale 1ns / 1ps
`default_nettype wire
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:30:26 02/08/2018 
// Module Name:    boy 
// Project Name:   VerilogBoy
// Description: 
//   VerilogBoy portable top level file. This is the file connect the CPU and 
//   all the peripherals in the LR35902 together.
// Dependencies: 
//   cpu
// Additional Comments: 
//   Hardware specific code should be implemented outside of this file
//   So normally in an implementation, this will not be the top level.
////////////////////////////////////////////////////////////////////////////////

module boy(
    input rst, // Async Reset Input
    input clk, // 4.19MHz Clock Input
    output phi, // 1.05MHz Reference Clock Output
    // Cartridge interface
    output reg [15:0] a, // Address Bus
    output reg [7:0] dout,  // Data Bus
    input  [7:0] din,
    output reg wr, // Write Enable
    output reg rd, // Read Enable
    output reg cs, // External RAM Chip Select
    // Keyboard input
    /* verilator lint_off UNUSED */
    input [7:0] key,
    /* verilator lint_on UNUSED */
    // LCD output
    output hs, // Horizontal Sync Output
    output vs, // Vertical Sync Output
    output cpl, // Pixel Data Latch
    output [1:0] pixel, // Pixel Data
    output valid,
    // Sound output
    output [15:0] left,
    output [15:0] right,
    // Debug interface
    output done,
    output fault
    );
    
    // CPU
    wire        cpu_rd;            // CPU Read Enable
    wire        cpu_wr;            // CPU Write Enable
    reg  [7:0]  cpu_din;           // CPU Data Bus, to CPU
    wire [7:0]  cpu_dout;          // CPU Data Bus, from CPU
    wire [15:0] cpu_a;             // CPU Address Bus
    wire [4:0]  cpu_int_en;        // CPU Interrupt Enable input
    wire [4:0]  cpu_int_flags_in;  // CPU Interrupt Flags input
    wire [4:0]  cpu_int_flags_out; // CPU Interrupt Flags output
    
    cpu cpu(
        .clk(clk),
        .rst(rst),
        .phi(phi),
        .a(cpu_a),
        .dout(cpu_dout),
        .din(cpu_din),
        .rd(cpu_rd),
        .wr(cpu_wr),
        .int_en(cpu_int_en),
        .int_flags_in(cpu_int_flags_in),
        .int_flags_out(cpu_int_flags_out),
        .key_in(key),
        .done(done),
        .fault(fault));
        
    // High RAM
    reg [7:0] high_ram [0:127];
    reg high_ram_rd;
    reg high_ram_wr;
    reg [6:0] high_ram_a;
    reg [7:0] high_ram_din;
    reg [7:0] high_ram_dout;
    always @(posedge clk) begin
        if (high_ram_wr)
            high_ram[high_ram_a] <= high_ram_din;
        else
            high_ram_dout <= (high_ram_rd) ? high_ram[high_ram_a] : 8'bx;
    end

    //DMA
    wire dma_rd; // DMA Memory Write Enable
    wire dma_wr; // DMA Memory Read Enable
    wire [15:0] dma_a; // Main Address Bus
    wire [7:0]  dma_din; // Main Data Bus
    wire [7:0]  dma_dout;
    wire [7:0]  dma_mmio_dout;
    reg dma_mmio_wr; // actually wire
    wire cpu_mem_disable;
    dma dma(
        .clk(clk),
        .rst(rst),
        .dma_rd(dma_rd),
        .dma_wr(dma_wr),
        .dma_a(dma_a),
        .dma_din(dma_din),
        .dma_dout(dma_dout),
        .mmio_wr(dma_mmio_wr),
        .mmio_din(cpu_dout),
        .mmio_dout(dma_mmio_dout),
        .cpu_mem_disable(cpu_mem_disable)
    );

    wire bus_wr; //Bus Master Memory Write Enable
    wire bus_rd; //Bus Master Memory Read Enable
    wire [15:0] bus_a; // Main Address Bus
    reg  [7:0]  bus_din; // Main Data Bus, acutally wire
    wire [7:0]  bus_dout;
    assign bus_wr = (cpu_mem_disable) ? (dma_wr) : (cpu_wr);
    assign bus_rd = (cpu_mem_disable) ? (dma_rd) : (cpu_rd);
    assign bus_a = (cpu_mem_disable) ? (dma_a) : (cpu_a);
    assign dma_din = bus_din;
    assign bus_dout = (cpu_mem_disable) ? (dma_dout) : (cpu_dout);

    // Interrupt
    // int_req is the request signal from peripherals.
    // When an interrupt is generated, the peripheral should send a pulse on
    // the int_req for exactly one clock (using 4MHz clock).
    wire [4:0] int_req;

    wire int_key_req;  
    wire int_tim_req;
    wire int_tim_ack;
    wire int_lcdc_req;
    wire int_lcdc_ack;
    wire int_vblank_req;
    wire int_vblank_ack;

    assign int_req[4] = int_key_req;
    assign int_req[2] = int_tim_req;
    assign int_req[1] = int_lcdc_req;
    assign int_req[0] = int_vblank_req;

    /* -- DEBUG -- */
    //assign int_req = 5'd0;
    //assign int_req[4] = 1'b0;
    assign int_req[3] = 1'b0;

    //reg reg_ie_rd;
    reg reg_ie_wr;
    reg [4:0] reg_ie;
    reg [4:0] reg_ie_din;
    wire [4:0] reg_ie_dout;
    always @(posedge clk) begin
        if (reg_ie_wr)
            reg_ie <= reg_ie_din;
    end

    assign reg_ie_dout = reg_ie;
    assign cpu_int_en = reg_ie_dout;

    // Interrupt may be manually triggered
    // int_req should only stay high for only 1 cycle for each interrupt
    //reg reg_if_rd;
    reg reg_if_wr;
    reg [4:0] reg_if;
    reg [4:0] reg_if_din;
    wire [4:0] reg_if_dout;
    always @(posedge clk) begin
        if (reg_if_wr)
            reg_if <= reg_if_din | int_req;
        else
            reg_if <= cpu_int_flags_out | int_req;
    end
    assign reg_if_dout = reg_if | int_req;
    assign cpu_int_flags_in = reg_if_dout;

    //assign int_key_ack = reg_if[3];
    assign int_tim_ack = reg_if[2];
    assign int_lcdc_ack = reg_if[1];
    assign int_vblank_ack = reg_if[0];

    // PPU
    wire [7:0] ppu_dout;
    reg ppu_wr; // actually wire

    ppu ppu(
        .clk(clk),
        .rst(rst),
        .a(bus_a),
        .dout(ppu_dout), // VRAM & OAM RW goes through PPU
        .din(bus_dout),
        .rd(bus_rd), 
        .wr(ppu_wr),
        .int_vblank_req(int_vblank_req),
        .int_lcdc_req(int_lcdc_req),
        .int_vblank_ack(int_vblank_ack),
        .int_lcdc_ack(int_lcdc_ack),
        .cpl(cpl), // Pixel clock
        .pixel(pixel), // Pixel Data (2bpp)
        .valid(valid),
        .hs(hs), // Horizontal Sync, Low Active
        .vs(vs)  // Vertical Sync, Low Active
    );

    // Timer
    wire [7:0] timer_dout;
    reg timer_wr; // actually wire

    timer timer(
        .clk(clk),
        .rst(rst),
        .a(bus_a),
        .dout(timer_dout),
        .din(bus_dout),
        .rd(bus_rd),
        .wr(timer_wr),
        .int_tim_req(int_tim_req),
        .int_tim_ack(int_tim_ack)
    );

    // Boot ROM Enable Register
    reg brom_disable;
    reg brom_disable_wr; // actually wire
    always @(posedge clk, posedge rst) begin
        if (rst)
            brom_disable <= 1'b0;
        else
            if (brom_disable_wr && (!brom_disable))
                brom_disable <= cpu_dout[0];
    end

    wire [7:0] brom_dout;
    brom brom(
        .a(bus_a[7:0]),
        .d(brom_dout)
    );

    // Work RAM
    wire [7:0] wram_dout;
    reg wram_wr; // actually wire

    singleport_ram #(
        .WORDS(8192)
    ) br_wram (
        .clka(clk),
        .wea(wram_wr),
        .addra(bus_a[12:0]),
        .dina(bus_dout),
        .douta(wram_dout)
    );

    // Keypad
    wire [7:0] keypad_reg;
    reg keypad_reg_wr; // actually wire
    reg [1:0] keypad_high;
    always @(posedge clk, posedge rst) begin
        if (rst)
            keypad_high <= 2'b11;
        else
            if (keypad_reg_wr)
                keypad_high <= bus_dout[5:4];
    end
    assign keypad_reg[7:6] = 2'b11;
    assign keypad_reg[5:4] = keypad_high[1:0];
    assign keypad_reg[3:0] = 
        ~(((keypad_high[1] == 1'b1) ? (key[7:4]) : 4'h0) | 
          ((keypad_high[0] == 1'b1) ? (key[3:0]) : 4'h0)); 
    assign int_key_req = (keypad_reg[3:0] != 4'hf) ? (1'b1) : (1'b0);

    // Bus Multiplexing
    always @(*) begin
        // High RAM is always accessible from CPU
        high_ram_a = cpu_a[6:0];
        if (cpu_a >= 16'hff80) begin
            high_ram_rd = cpu_rd;
            high_ram_wr = cpu_wr;
            high_ram_din = cpu_dout;
            cpu_din = high_ram_dout;
        end
        else begin
            high_ram_rd = 1'b0;
            high_ram_wr = 1'b0;
            high_ram_din = 8'hxx;
            cpu_din = bus_din;
        end
    end

    always @(*) begin
        wr = 1'b0;
        rd = 1'b0;
        a = bus_a; // The address is always exposed
        dout = 8'h00; // But the data will be masked when accessing high page
        bus_din = 8'hxx; // Should not happen
        reg_ie_wr = 1'b0;
        reg_ie_din = 5'hxx;
        reg_if_wr = 1'b0;
        reg_if_din = 5'hxx;
        keypad_reg_wr = 1'b0;
        timer_wr = 1'b0;
        dma_mmio_wr = 1'b0;
        brom_disable_wr = 1'b0;
        ppu_wr = 1'b0;
        wram_wr = 1'b0;
        
        if (bus_a == 16'hffff) begin  // 0xFFFF - IE
            //reg_ie_rd = bus_rd;
            reg_ie_wr = bus_wr;
            reg_ie_din = bus_dout[4:0];
            bus_din = {3'b0, reg_ie_dout};
        end
        else if (bus_a == 16'hff0f) begin // 0xFF0F - IF
            //reg_if_rd = bus_rd;
            reg_if_wr = bus_wr;
            reg_if_din = bus_dout[4:0];
            bus_din = {3'b0, reg_if_dout};
        end
        else if (bus_a == 16'hff00) begin
            keypad_reg_wr = bus_wr;
            bus_din = keypad_reg;
        end
        else if ((bus_a == 16'hff04) || (bus_a == 16'hff05) ||  // Timer
                (bus_a == 16'hff06) || (bus_a == 16'hff07)) begin
            timer_wr = bus_wr;
            bus_din = timer_dout;
        end
        else if (bus_a == 16'hff46) begin // 0xFF46 - DMA
            dma_mmio_wr = bus_wr;
            bus_din = dma_mmio_dout;
        end
        else if (bus_a == 16'hff50) begin // 0xFF50 - BROM DISABLE
            brom_disable_wr = bus_wr;
            bus_din = {7'b0, brom_disable};
        end
        else if ((bus_a >= 16'hff40 && bus_a <= 16'hff4b && bus_a != 16'hff46) ||
            (bus_a >= 16'h8000 && bus_a <= 16'h9fff) ||
            (bus_a >= 16'hfe00 && bus_a <= 16'hfe9f)) begin
            bus_din = ppu_dout;
            ppu_wr = bus_wr;
        end
        else if ((bus_a >= 16'hc000 && bus_a <= 16'hdfff)) begin // WRAM
            bus_din = wram_dout;
            wram_wr = bus_wr;
        end
        else if ((!brom_disable && bus_a <= 16'h00ff)) begin
            bus_din = brom_dout;
        end
        else if (bus_a <= 16'h7fff) begin
            // cartridge, need add CRAM later
            rd = bus_rd;
            wr = bus_wr;
            dout = bus_dout;
            bus_din = din;
        end
        else begin
            // read to unmapped area returns ff
            bus_din = 8'hff;
        end
        cs = wr | rd;
    end

    // Disable unused signals
    assign left = 0;
    assign right = 0;

endmodule
