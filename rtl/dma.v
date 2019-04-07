/**
 * Block transfer unit for the GB80 CPU.
 * 
 * Author: Joseph Carlos (jdcarlos1@gmail.com)
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
    input  wire        rst,
    output reg         dma_rd,
    output reg         dma_wr,
    //output wire        dma_rd_comb,
    //output wire        dma_wr_comb,
    output wire [15:0] dma_a,
    input  wire [7:0]  dma_din,
    output reg  [7:0]  dma_dout,
    input  wire        mmio_wr,
    input  wire [7:0]  mmio_din,
    output wire [7:0]  mmio_dout,
    output reg         cpu_mem_disable
    );

    // DMA data blocks /////////////////////////////////////////////////////////

    reg [7:0]    dma_start_addr;
    reg [7:0]    count, next_count;
    reg          dma_a_rw;

    // Select for DMA output address write, read
    assign dma_a = (dma_a_rw) ? {dma_start_addr, count} : {8'hfe, count};

    assign mmio_dout = dma_start_addr;

   // DMA transfer logic //////////////////////////////////////////////////////
   
    localparam DMA_WAIT = 'd0;
    localparam DMA_TRANSFER_READ_ADDR  = 'd1;
    localparam DMA_TRANSFER_READ_DATA  = 'd2;
    localparam DMA_TRANSFER_WRITE_DATA = 'd3;
    localparam DMA_TRANSFER_WRITE_WAIT = 'd4;
    reg [2:0]    cs, ns;

    always @(posedge clk) begin
        case (cs)
        DMA_WAIT: begin
            dma_wr <= 1'b0;
            dma_rd <= 1'b0;
            cpu_mem_disable <= 1'b0;
            dma_a_rw <= 1'b0;
            if (mmio_wr) begin
                // Transfer starts on next cycle
                dma_start_addr <= mmio_din;
            end
        end
        DMA_TRANSFER_READ_ADDR: begin
            dma_wr <= 1'b0;
            cpu_mem_disable <= 1'b1;
            if (count == 8'ha0) begin
                // Finished
                next_count <= 8'h0;
            end else begin
                // Load the temp register with data from memory
                dma_a_rw <= 1'b1; // Output read address
                dma_rd <= 1'b1;
            end
        end
        DMA_TRANSFER_READ_DATA: begin
            cpu_mem_disable <= 1'b1;
            // Basically wait
        end
        DMA_TRANSFER_WRITE_DATA: begin
            // Read data
            cpu_mem_disable <= 1'b1;
            dma_dout <= dma_din;
            dma_rd <= 1'b0;
            // Write the temp register to memory
            dma_a_rw <= 1'b0; // Output write address
            dma_wr <= 1'b1;
        end
        DMA_TRANSFER_WRITE_WAIT: begin
            next_count <= count + 8'd1;
        end
        default: begin
        end
        endcase
    end

    always @(*) begin
        case (cs)
        DMA_WAIT: 
            if (mmio_wr) begin
                ns = DMA_TRANSFER_READ_ADDR;
            end else begin
                ns = DMA_WAIT;
            end
        DMA_TRANSFER_READ_ADDR: 
            if (count == 8'ha0) begin
                ns = DMA_WAIT;
            end else begin
                ns = DMA_TRANSFER_READ_DATA;
            end
        DMA_TRANSFER_READ_DATA:  ns = DMA_TRANSFER_WRITE_DATA;
        DMA_TRANSFER_WRITE_DATA: ns = DMA_TRANSFER_WRITE_WAIT;
        DMA_TRANSFER_WRITE_WAIT: ns = DMA_TRANSFER_READ_ADDR; 
        default: ns = DMA_WAIT;
      endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cs <= DMA_WAIT;
            count <= 8'h0;
        end else begin
            cs <= ns;
            count <= next_count;
        end
   end
   
endmodule // dma
