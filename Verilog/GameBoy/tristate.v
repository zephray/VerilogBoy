`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:33:49 02/09/2018 
// Design Name: 
// Module Name:    tristate 
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
/**
 * A tristate buffer (because you can't assign multiple times to a single bus).
 * 
 * @parameter width The width of the input and output.
 * @output out The bus to output to.
 * @input in The input signal.
 * @en out is driven to in if en == 1, z's otherwise.
 */
module tristate(/*AUTOARG*/
   // Outputs
   out,
   // Inputs
   in, en
   );
   parameter
     width = 1;
   output wire [width-1:0] out;
   input [width-1:0]       in;
   input                   en;

   assign out = (en) ? in : {width{1'bz}};
   
endmodule // tristate
