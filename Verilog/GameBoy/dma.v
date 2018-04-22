`include "cpu.vh"

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
module dma(/*AUTOARG*/
   // Outputs
   dma_mem_re, dma_mem_we, cpu_mem_disable,
   // Inouts
   addr_ext, data_ext,
   // Inputs
   mem_re, mem_we, clock, reset, dma_chipscope
   );

   // Inputs and Outputs ///////////////////////////////////////////////////////
   
   inout [15:0] addr_ext;
   inout [7:0]  data_ext;

   output reg   dma_mem_re, dma_mem_we;
   output reg   cpu_mem_disable;
   
   input        mem_re, mem_we;
   input        clock, reset;
   output wire [7:0] dma_chipscope;

   // DMA data blocks //////////////////////////////////////////////////////////

   wire [15:0]  temp_addr;
   reg [7:0]   dma_data;
   reg [7:0]    temp_data;
   reg [7:0]    count, next_count;
   wire         dma_sel;
   reg          temp_data_gate, temp_load, temp_addr_rw, temp_addr_gate;

   // Select for DMA output address write, read
   assign temp_addr = (temp_addr_rw) ? {dma_data, count} : {8'hfe, count};
   
   assign dma_sel = (mem_re | mem_we) ? (addr_ext == `MMIO_DMA) : 1'b0;

   tristate #(16) temp_addr_tri(.out(addr_ext),
                                .in(temp_addr),
                                .en(temp_addr_gate));
   
   tristate #(8) dma_data_tri(.out(data_ext),
                              .in(dma_data),
                              .en(dma_sel & mem_re));

   tristate #(8) temp_data_tri(.out(data_ext),
                               .in(temp_data),
                               .en(temp_data_gate));
   

   // DMA transfer logic ///////////////////////////////////////////////////////
   
localparam DMA_WAIT = 'd0;
localparam DMA_TRANSFER_READ_ADDR  = 'd1;
localparam DMA_TRANSFER_READ_DATA  = 'd2;
localparam DMA_TRANSFER_WRITE_DATA = 'd3;
localparam DMA_TRANSFER_WRITE_WAIT = 'd4;
   reg [2:0]    cs, ns;
   
   assign dma_chipscope[7:5] = cs[2:0];
   assign dma_chipscope[4] = (cs[2:0] == DMA_WAIT) ? 1'b0 : 1'b1;

   always @(posedge clock) begin
      //next_count = count;
      //{dma_mem_we, dma_mem_re, cpu_mem_disable} = 3'd0;
      //{temp_addr_rw, temp_data_gate, temp_load, temp_addr_gate} = 4'd0;
      case (cs)
        DMA_WAIT: begin
            dma_mem_we <= 1'b0;
            dma_mem_re <= 1'b0;
            cpu_mem_disable <= 1'b0;
            temp_addr_rw <= 1'b0;
            temp_data_gate <= 1'b0;
            temp_addr_gate <= 1'b0;
            if (dma_sel & mem_we) begin
                // Transfer starts on next cycle
                dma_data <= data_ext;
            end
        end
        DMA_TRANSFER_READ_ADDR: begin
            dma_mem_we <= 1'b0;
            cpu_mem_disable <= 1'b1;
            temp_data_gate <= 1'b0;
            if (count == 8'ha0) begin
                // Finished
                next_count <= 8'h0;
            end else begin
                // Load the temp register with data from memory
                temp_addr_rw <= 1'b1; // Output read address
                temp_addr_gate <= 1'b1;
                dma_mem_re <= 1'b1;
            end
        end
        DMA_TRANSFER_READ_DATA: begin
            cpu_mem_disable <= 1'b1;
            // Basically wait
        end
        DMA_TRANSFER_WRITE_DATA: begin
            // Read data
            cpu_mem_disable <= 1'b1;
            temp_data <= data_ext;
            dma_mem_re <= 1'b0;
            // Write the temp register to memory
            temp_addr_rw <= 1'b0; // Output write address
            temp_addr_gate <= 1'b1;
            temp_data_gate <= 1'b1;
            dma_mem_we <= 1'b1;
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
            if (dma_sel & mem_we) begin
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

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         cs <= DMA_WAIT;
         count <= 8'h0;
      end else begin
         cs <= ns;
         count <= next_count;
      end
   end
   
endmodule // dma

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("./cpu.v")
// End:
