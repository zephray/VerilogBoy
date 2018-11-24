`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    12:27:38 11/23/2018 
// Design Name: 
// Module Name:    mcu_if 
// Project Name:   VerilogBoy
// Description: 
//   SPI bus slave
// Dependencies: 
// 
// Additional Comments: 
//   See doc/vbh_ref_man.md for descriptions
////////////////////////////////////////////////////////////////////////////////
module mcu_if(
    input clk,
    input rst,
    input mcu_cs,
    input mcu_sck,
    output mcu_miso,
    input mcu_mosi,
    output mcu_irq,
    output reg [7:0] bm_a,
    input [7:0] bm_din,
    output reg [7:0] bm_dout,
    output reg bm_wr,
    output reg bm_rd
    );

    // sync SCK
    reg [2:0] sck_sync;
    always @(posedge clk) sck_sync <= {sck_sync[1:0], mcu_sck};
    wire sck_posedge = (sck_sync[2:1] == 2'b01);
    wire sck_negedge = (sck_sync[2:1] == 2'b10);

    // sync CS
    reg [2:0] cs_sync;
    always @(posedge clk) cs_sync <= {cs_sync[1:0], mcu_cs};
    wire cs_posedge = (cs_sync[2:1] == 2'b01);
    wire cs_negedge = (cs_sync[2:1] == 2'b10);
    wire cs_active = !cs_sync[1];

    // sync MOSI
    reg [1:0] mosi_sync;
    always @(posedge clk) mosi_sync <= {mosi_sync[0], mcu_mosi};
    wire mosi_data = mosi_sync[1];

    // single write can be 16-bit or 8-bit, 16-bit means write, 8-bit means read
    reg [2:0] bit_count;
    reg       byte_count;
    reg [7:0] addr_buf;
    reg [7:0] data_buf_in;
    reg [7:0] data_buf_in_sr; // Shift Register
    reg [7:0] data_buf_out;

    reg       read_cycle;  // Indicate a read cycle
    reg       ignore_cycle;// Cycle after a read is ignored
    reg       write_cycle; // Indicate a write cycle

    // handle SPI signals
    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 3'd0; 
            byte_count <= 1'd0;
            read_cycle <= 1'b0;
            write_cycle <= 1'b0;
            ignore_cycle <= 1'b0;
        end
        else begin
            if (!cs_active) begin
                bit_count <= 3'd0;
                byte_count <= 1'd0;
                if (cs_posedge) begin
                    read_cycle <= (ignore_cycle) ? (1'b0) : ((byte_count == 1'b1) ? (1'b1) : (1'b0));
                    write_cycle <= (ignore_cycle) ? (1'b0) : ((byte_count == 1'b1) ? (1'b0) : (1'b1));
                    ignore_cycle <= (ignore_cycle) ? (1'b0) : ((byte_count == 1'b1) ? (1'b1) : (1'b0));
                end
                else begin
                    read_cycle <= 1'b0;
                    write_cycle <= 1'b0;
                end
                data_buf_in_sr <= data_buf_in;
            end
            else begin
                if (sck_posedge) begin
                    bit_count <= bit_count + 3'd1;
                    if (byte_count == 1'd0)
                        addr_buf <= {addr_buf[6:0], mosi_data};
                    else
                        data_buf_out <= {data_buf_out[6:0], mosi_data};
                    if (bit_count == 3'd7)
                        byte_count <= !byte_count;
                end
                else if (sck_negedge) begin
                    data_buf_in_sr <= {data_buf_in_sr[6:0], 1'b0};
                end
            end
        end
    end

    assign mcu_miso = data_buf_in_sr[7];

    // generate bus master signal
    reg [1:0] state;

    localparam S_IDLE = 2'd0;
    localparam S_WAITR = 2'd1;
    localparam S_READ = 2'd2;
    localparam S_WAITW = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            bm_rd <= 1'b0;
            bm_wr <= 1'b0;
        end    
        else begin
            case (state)
            S_IDLE: begin
                if (read_cycle) begin
                    bm_a <= addr_buf;
                    bm_rd <= 1'b1;
                    bm_wr <= 1'b0;
                    state <= S_WAITR;
                end
                else if (write_cycle) begin
                    bm_a <= addr_buf;
                    bm_dout <= data_buf_out;
                    bm_rd <= 1'b0;
                    bm_wr <= 1'b1;
                    state <= S_WAITW;
                end
                else begin
                    bm_rd <= 1'b0;
                    bm_wr <= 1'b0;
                end
            end
            S_WAITR: begin
                state <= S_READ;
            end
            S_WAITW: begin
                //bm_wr <= 1'b0;
                state <= S_IDLE;
            end
            S_READ: begin
                data_buf_in <= bm_din;
                bm_rd <= 1'b0;
                state <= S_IDLE;
            end
            endcase
        end
    end
    
    // IRQ?
    assign mcu_irq = 1'b0;

endmodule
