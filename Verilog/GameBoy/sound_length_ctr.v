`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    22:24:55 04/08/2018 
// Module Name:    sound_length_ctr 
// Project Name:   VerilogBoy
// Description: 
//   Sound length control for all channels 
// Dependencies: 
//   none
// Additional Comments: 
//   Channel 3 has a different length
//////////////////////////////////////////////////////////////////////////////////
module sound_length_ctr(rst, clk_length_ctr, start, single, length, enable);
    parameter WIDTH = 6; // 6bit for Ch124, 8bit for Ch3
    
    input rst;
    input clk_length_ctr;
    input start;
    input single;
    input [WIDTH-1:0] length;
    output reg enable = 0;
    
    reg [WIDTH-1:0] length_left = {WIDTH{1'b1}}; // Upcounter from length to 255

    // Length Control
    always @(posedge clk_length_ctr, posedge start, posedge rst)
    begin
        if (rst) begin
            enable <= 1'b0;
        end
        else if (start) begin
            enable <= 1'b1;
            length_left <= (length == 0) ? ({WIDTH{1'b1}}) : (length);
        end
        else begin
            if (single) begin
                if (length_left != {WIDTH{1'b1}})
                    length_left <= length_left + 1'b1;
                else
                    enable <= 1'b0;
            end
        end
    end

endmodule
