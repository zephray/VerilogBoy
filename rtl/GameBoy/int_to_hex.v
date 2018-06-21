`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:13:59 02/10/2018 
// Design Name: 
// Module Name:    int_to_hex 
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
module int_to_hex(
    input [3:0] i,
    output reg [7:0] h
);

    always@(*)
    begin
        case (i)
            4'h0: h = "0";
            4'h1: h = "1";
            4'h2: h = "2";
            4'h3: h = "3";
            4'h4: h = "4";
            4'h5: h = "5";
            4'h6: h = "6";
            4'h7: h = "7";
            4'h8: h = "8";
            4'h9: h = "9";
            4'hA: h = "A";
            4'hB: h = "B";
            4'hC: h = "C";
            4'hD: h = "D";
            4'hE: h = "E";
            4'hF: h = "F";
        endcase
    end

endmodule
