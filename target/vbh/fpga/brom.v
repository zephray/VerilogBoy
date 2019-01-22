`timescale 1ns / 1ps
`default_nettype wire
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
    input clk,
    input [12:0] a,
    output reg [7:0] d
    );
    
    reg [7:0] brom [0:8192-1]; // 8 KBytes BROM array
   
    initial begin
        $readmemh("bootrom.mif", brom, 0, 8192-1);
    end
    
    always @(posedge clk)
        d <= brom[a];

endmodule
