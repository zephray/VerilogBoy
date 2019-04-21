`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:34:40 04/20/2019 
// Design Name: 
// Module Name:    pwm 
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
module pwm(
    input clk,
    input rst,
    input [7:0] duty,
    output out
    );

    reg [7:0] count;
    assign out = (count > duty) ? 0 : 1;

    always @(posedge clk) begin
        count <= count + 8'd1;
        if (rst) begin
            count <= 1'b0;
        end
    end

endmodule
