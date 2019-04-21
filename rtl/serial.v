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
    
    reg clk_spi; //8kHz SPI Clock
    
    /*clk_div #(.WIDTH(10), .DIV(512)) spi_div(
        .i(clk),
        .o(clk_spi)
    );*/

    reg [8:0] counter;
    
    always @(posedge clk, posedge rst)
    begin
        if (rst) begin
            counter <= 9'h72;
            clk_spi <= 1'b0;
        end 
        else begin
            if (counter == (512 / 2 - 1)) begin
                clk_spi <= ~clk_spi;
                counter <= 0;
            end
            else
                counter <= counter + 1'b1;
        end
    end
	 
    //reg [7:0] reg_sb;
    reg reg_sc_start;
    reg reg_sc_int;
    
    always @(*) begin
        dout = 8'hff;
        if (a == 16'hff01) dout = 8'hff; else
        if (a == 16'hff02) dout = {reg_sc_start, 6'b111111, reg_sc_int};
    end
    
    reg [3:0] count;
    reg last_clk;
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            //reg_sb <= 8'h00;
            reg_sc_start <= 1'b0;
            reg_sc_int <= 1'b0;
            int_serial_req <= 1'b0;
            count <= 4'd0;
            last_clk <= 1'b0;
        end
        else begin
            last_clk <= clk_spi;
            //if      (wr && (a == 16'hff01)) reg_sb <= din;
            if (wr && (a == 16'hff02)) begin
                reg_sc_start <= din[7];
                reg_sc_int <= din[0];
                if (din[7] && din[0]) count <= 4'd8;
                else count <= 4'd0;
            end
            else begin
                // Dummy serial interface
                if (count != 4'd0) begin
                    if (!last_clk && clk_spi) begin
                        count <= count - 4'd1;
                        if ((count - 4'd1) == 0) begin
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
