`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:10:17 02/09/2018 
// Design Name: 
// Module Name:    brom 
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
module brom(
    input [7:0] a,
    output [7:0] d
    );
    
    reg [7:0] brom [0:255]; // 256 Bytes BROM array
   
    initial begin
        $readmemh("brom.mif", brom, 0, 255);
    end
    
    assign d = brom[a];

endmodule
