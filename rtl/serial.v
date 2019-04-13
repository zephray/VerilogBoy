`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    13:13:04 04/13/2018 
// Module Name:    serial
// Project Name:   VerilogBoy
// Description: 
//   Dummy serial interface
// Dependencies: 
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module serial(
    input clk,
    input rst,
    input wire [15:0] a,
    output reg [7:0] dout,
    input wire [7:0] din,
    input wire rd,
    input wire wr,
    output reg int_serial_req,
    input wire int_serial_ack
    );
    
    wire clk_spi; //8kHz SPI Clock
    
    clk_div #(.WIDTH(10), .DIV(512)) spi_div(
        .i(clk),
        .o(clk_spi)
    );
	 
    //reg [7:0] reg_sb;
    reg [7:0] reg_sc;
    
    always @(*) begin
        dout = 8'hff;
        if (a == 16'hff01) dout = 8'hff; else
        if (a == 16'hff02) dout = reg_sc;
    end
    
    reg [2:0] count;
    reg last_clk;
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            //reg_sb <= 8'h00;
            reg_sc <= 8'h00;
            int_serial_req <= 1'b0;
            count <= 3'd0;
            last_clk <= 1'b0;
        end
        else begin
            last_clk <= clk_spi;
            //if      (wr && (a == 16'hff01)) reg_sb <= din;
            if (wr && (a == 16'hff02)) begin
                reg_sc <= din;
                if (din[7] && din[0]) count <= 3'd7;
                else count <= 3'd0;
            end
            else begin
                // Dummy serial interface
                if (count != 3'd0) begin
                    if (!last_clk && clk_spi) begin
                        count <= count - 3'd1;
                        if ((count - 3'd1) == 0) begin
                            int_serial_req <= 1'b1;
                        end
                    end
                end
                else begin
                    if ((int_serial_req)&&(int_serial_ack)) begin
                        int_serial_req <= 1'b0;
                    end
                end
            end
        end
    end
    
	 
endmodule
