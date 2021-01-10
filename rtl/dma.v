`timescale 1ns / 1ps
/**
 * Block transfer unit for the GB80 CPU.
 * 
 * Original Author: Joseph Carlos (jdcarlos1@gmail.com)
 * Modified: Wenting Zhang (zephray@outlook.com)
 */

/**
 * The DMA unit.
 * 
 * Contains the DMA register and performs DMA transfers when the register is
 * written to. Each transfer takes 320 cycles rather than the canon 640, this
 * is because there's no reason to take 640.
 * 
 * @inout addr_ext The address bus.
 * @inout data_ext The data bus.
 * @output dma_transfer 1 if a transfer is occurring, 0 otherwise.
 * @input mem_re 1 if the processor is reading from memory.
 * @input mem_we 1 if the processor is writing to memory.
 * @input clock The CPU clock.
 * @input reset The CPU reset.
 */
module dma(
    input  wire        clk,
    //input  wire        phi,
    input  wire        rst,
    output reg         dma_rd,
    output reg         dma_wr,
    //output wire        dma_rd_comb,
    //output wire        dma_wr_comb,
    output reg  [15:0] dma_a,
    input  wire [7:0]  dma_din,
    output reg  [7:0]  dma_dout,
    input  wire        mmio_wr,
    input  wire [7:0]  mmio_din,
    output wire [7:0]  mmio_dout,
    output wire        dma_occupy_extbus,
    output wire        dma_occupy_vidbus,
    output wire        dma_occupy_oambus
    );

    // DMA data blocks /////////////////////////////////////////////////////////

    reg [7:0]    dma_start_addr;
    reg [7:0]    count;

    assign mmio_dout = dma_start_addr;

    reg cpu_mem_disable;

    assign dma_occupy_extbus = cpu_mem_disable & 
            ((dma_start_addr <= 8'h7f) || (dma_start_addr >= 8'ha0));
    assign dma_occupy_vidbus = cpu_mem_disable &
            ((dma_start_addr >= 8'h80) && (dma_start_addr <= 8'h9f));
    assign dma_occupy_oambus = cpu_mem_disable;

   // DMA transfer logic //////////////////////////////////////////////////////
   
    localparam DMA_IDLE = 'd0;
    localparam DMA_TRANSFER_READ_ADDR  = 'd1;
    localparam DMA_TRANSFER_READ_DATA  = 'd2;
    localparam DMA_TRANSFER_WRITE_DATA = 'd3;
    localparam DMA_TRANSFER_WRITE_WAIT = 'd4;
    localparam DMA_DELAY = 'd5;
    
    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            dma_start_addr <= 8'h00;
        end
        else begin
            if (mmio_wr) begin
                // Writing is always valid regardless of the state
                dma_start_addr <= mmio_din;
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= DMA_IDLE;
            count <= 8'd0;
            dma_wr <= 1'b0;
            dma_rd <= 1'b0;
            cpu_mem_disable <= 1'b0;
        end
        else begin
            case (state)
            DMA_IDLE: begin
                dma_wr <= 1'b0;
                dma_rd <= 1'b0;
                cpu_mem_disable <= 1'b0;
                if (mmio_wr) begin
                    // Transfer starts on next cycle
                    state <= DMA_DELAY;
                    count <= 8'd3; // Delay before start
                end
                else
                    count <= 8'd0;
            end
            DMA_DELAY: begin
                if (count != 8'd0) begin
                    count <= count - 1;
                end
                else begin
                    state <= DMA_TRANSFER_READ_ADDR;
                end
            end
            DMA_TRANSFER_READ_ADDR: begin
                dma_wr <= 1'b0;
                cpu_mem_disable <= 1'b1;
                // Load the temp register with data from memory
                dma_a <= {dma_start_addr, count}; // Output read address
                dma_rd <= 1'b1;
                if (mmio_wr) begin // Allow re-triggering
                    state <= DMA_DELAY;
                    count <= 8'd3; // Delay before start
                end
                else
                    state <= DMA_TRANSFER_READ_DATA;
            end
            DMA_TRANSFER_READ_DATA: begin
                state <= DMA_TRANSFER_WRITE_DATA;
                // Basically wait
            end
            DMA_TRANSFER_WRITE_DATA: begin
                // Read data
                dma_dout <= dma_din;
                dma_rd <= 1'b0;
                // Write the temp register to memory
                dma_a <= {8'hfe, count}; // Output write address
                dma_wr <= 1'b1;
                if (mmio_wr) begin // Allow re-triggering
                    state <= DMA_DELAY;
                    count <= 8'd3; // Delay before start
                end
                else
                    state <= DMA_TRANSFER_WRITE_WAIT;
            end
            DMA_TRANSFER_WRITE_WAIT: begin
                // Wait
                if (mmio_wr) begin // Allow re-triggering
                    state <= DMA_DELAY;
                    count <= 8'd3; // Delay before start
                end
                else
                if (count == 8'h9f) begin
                    state <= DMA_IDLE;
                    count <= 8'd0;
                end
                else begin
                    state <= DMA_TRANSFER_READ_ADDR;
                    count <= count + 8'd1;
                end
            end
            default: begin
            end
            endcase
        end
    end
   
endmodule // dma
