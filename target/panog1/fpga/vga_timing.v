`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:        18:10:40 02/05/2018 
// Design Name: 
// Module Name:        dvi_timing 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module vga_timing(
    input clk,
    input rst,
    output reg hs,
    output reg vs,
    input vsi,
    output [10:0] x,
    output [10:0] y,
    output [7:0] gb_x,
    output [7:0] gb_y,
    output gb_en,
    output gb_grid,
    output reg enable
    //output [19:0] address
    );

    //Horizontal
    parameter H_FRONT   = 26; //Front porch
    parameter H_SYNC    = 96; //Sync
    parameter H_BACK    = 38; //Back porch
    /*parameter H_FRONT   = 16; //Front porch
    parameter H_SYNC    = 96; //Sync
    parameter H_BACK    = 48; //Back porch*/
    parameter H_ACT     = 640;//Active pixels
    parameter H_BLANK = H_FRONT+H_SYNC+H_BACK; //Total blank length
    parameter H_TOTAL = H_FRONT+H_SYNC+H_BACK+H_ACT; //Total line length

    //Vertical
    parameter V_FRONT   = 10; //Front porch
    parameter V_SYNC    = 2;  //Sync
    parameter V_BACK    = 33; //Back porch
    parameter V_ACT     = 480;//Active lines
    parameter V_BLANK = V_FRONT+V_SYNC+V_BACK; //Total blank length
    parameter V_TOTAL = V_FRONT+V_SYNC+V_BACK+V_ACT; //Total field length

    reg [10:0] h_count;
    reg [10:0] v_count;

    reg [2:0] h_div;
    reg [2:0] v_div;

    reg [7:0] gb_x_count;
    reg [7:0] gb_y_count;
    
    reg gb_x_grid;
    reg gb_y_grid;

    reg vsi_last;
    
    wire reset = vsi | rst;
    
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            h_count <= 0;
            h_div <= 0;
            gb_x_count <= 0;
            gb_x_grid <= 0;
        end
        else begin
            if(h_count == H_TOTAL - 1) begin
                h_count <= 0;
                gb_x_count <= 0;
                h_div <= 2'b00;
            end 
            else begin
                h_count <= h_count + 1'b1;
                if (h_div == 2'b10) begin
                    h_div <= 2'b00;
                    gb_x_count <= gb_x_count + 1'b1;
                    gb_x_grid <= 1'b1;
                end
                else begin
                    gb_x_grid <= 1'b0;
                    h_div <= h_div + 1'b1;
                end
            end
        end
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            hs <= 1;
            v_count <= 0;
            v_div <= 2'b01;
            gb_y_count <= 0;
            vs <= 1;
        end
        else begin   
            if(h_count == H_FRONT - 1)
                hs <= 1'b0;
            else 
            if(h_count == H_FRONT + H_SYNC - 1) begin
                hs <= 1'b1;
                if(v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                    gb_y_count <= 0;
                    v_div <= 2'b01;
                end 
                else begin
                    v_count <= v_count + 1'b1;
                    if (v_div == 2'b10) begin
                        v_div <= 2'b00;
                        gb_y_grid <= 1'b1;
                        gb_y_count <= gb_y_count + 1'b1;
                    end
                    else begin
                        gb_y_grid <= 1'b0;
                        v_div <= v_div + 1'b1;
                    end
                end
                if((v_count == V_FRONT - 1))
                    vs <= 1'b0;
                else if((v_count == V_FRONT + V_SYNC - 1))
                    vs <= 1'b1;
            end
        end 
    end

    assign x = (h_count >= H_BLANK) ? (h_count - H_BLANK) : 11'h0;
    assign y = (v_count >= V_BLANK) ? (v_count - V_BLANK) : 11'h0;
    wire gb_x_valid = (x > 11'd80)&&(x <= 11'd560);
    wire gb_y_valid = (y >= 11'd24)&&(y < 11'd456);
    assign gb_en = (gb_x_valid)&&(gb_y_valid);
    assign gb_grid = (gb_x_grid)||(gb_y_grid);
    assign gb_x = (gb_en) ? (gb_x_count - 8'd80) : (8'h0);
    //assign gb_y = (gb_en) ? (gb_y_count - 8'd24) : (8'h0);
    assign gb_y = (gb_y_valid) ? (gb_y_count - 8'd24) : (8'h0); // Y should be always available during the period
    //assign address = y * H_ACT + x;
    wire enable_early = (((h_count >= H_BLANK) && (h_count < H_TOTAL))&&
                                     ((v_count >= V_BLANK) && (v_count < V_TOTAL)));    //One pixel shift
    always @(posedge clk)
        enable <= enable_early;


endmodule
