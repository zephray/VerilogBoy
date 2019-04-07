`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    17:12:01 04/13/2018 
// Module Name:    timer 
// Project Name:   VerilogBoy
// Description: 
//   GameBoy internal timer
// Dependencies: 
//
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module timer(
    input wire clk,
    input wire rst,
    input wire [15:0] a,
    output reg [7:0] dout,
    input wire [7:0] din,
    input wire rd,
    input wire wr,
    output reg int_tim_req,
    input wire int_tim_ack
    );
    
    wire [7:0] reg_div; // Divider Register
    reg [7:0] reg_tima; // Timer counter
    reg [7:0] reg_tma; // Timer modulo
    reg [7:0] reg_tac; // Timer control
    
    wire addr_in_timer = ((a == 16'hFF04) ||
                          (a == 16'hFF05) ||
                          (a == 16'hFF06) ||
                          (a == 16'hFF07)) ? 1'b1 : 1'b0;
    
    reg [15:0] div;
    
    wire reg_timer_enable = reg_tac[2];
    wire [1:0] reg_clock_sel = reg_tac[1:0];
    
    assign reg_div[7:0] = div[15:8];
    wire clk_4khz = div[9];
    wire clk_256khz = div[3];
    wire clk_64khz = div[5];
    wire clk_16khz = div[7];
    wire clk_tim;
    assign clk_tim = (reg_timer_enable) ? (
        (reg_clock_sel == 2'b00) ? (clk_4khz) : (
        (reg_clock_sel == 2'b01) ? (clk_256khz) : (
        (reg_clock_sel == 2'b00) ? (clk_64khz) : 
                                   (clk_16khz)))) : (1'b0);
    
    reg last_clk_tim;
    reg carry;
    
    // Bus RW
    // Bus RW - Combinational Read
    always @(*)
    begin
        dout = 8'hFF;
        if (a == 16'hFF04) dout = reg_div; else
        if (a == 16'hFF05) dout = reg_tima; else
        if (a == 16'hFF06) dout = reg_tma; else
        if (a == 16'hFF07) dout = reg_tac;
    end
    
    // Bus RW - Sequential Write
    always @(posedge clk)
    begin
        last_clk_tim <= clk_tim;
    end
    
    always @(posedge clk, posedge rst)
    begin
        if (rst) begin
            //reg_div <= 0;
            reg_tima <= 0;
            reg_tma <= 0;
            reg_tac <= 0;
            div <= 0;
            int_tim_req <= 0;
        end
        else begin
            div <= div + 1'b1;
            if ((wr)&&(addr_in_timer)) begin
                if (a == 16'hFF04) div <= 0; else
                if (a == 16'hFF05) reg_tima <= din; else
                if (a == 16'hFF06) reg_tma <= din; else
                if (a == 16'hFF07) reg_tac <= din;
            end
            else begin
                if ((last_clk_tim == 1'b0)&&(clk_tim == 1'b1)) begin
                    {carry, reg_tima} <= reg_tima + 1'b1;
                end
                else begin
                    //Overflow is delayed by 1 CYCLE (4 clocks), not quite implemented yet due to CPU limitation
                    if (carry) begin
                        reg_tima <= reg_tma;
                        carry <= 1'b0;
                        int_tim_req <= 1'b1;
                    end
                    else begin
                        if ((int_tim_req)&&(int_tim_ack)) begin
                            int_tim_req <= 1'b0;
                        end
                    end
                end
            end
        end
    end

endmodule
