`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:24:55 04/08/2018 
// Design Name: 
// Module Name:    sound_length_ctr 
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
module sound_length_ctr(
    input rst,
    input clk_length_ctr,
    input start,
    input single,
    input [5:0] length,
    output reg enable = 0
    );
    
    reg [5:0] length_left = 0; // Number of cycles to be played

    // Length Control
    always @(posedge clk_length_ctr, posedge start, posedge rst)
    begin
        if (rst) begin
            enable <= 1'b0;
        end
        else if (start) begin
            enable <= 1'b1;
            length_left <= length;
        end
        else begin
            if (single) begin
                if (length_left != 6'b0)
                    length_left <= length_left - 1'b1;
                else
                    enable <= 1'b0;
            end
        end
    end

endmodule
