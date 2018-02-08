`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    18:10:40 02/05/2018 
// Design Name: 
// Module Name:    dvi_timing 
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
module dvi_timing(
    input clk,
    input rst,
    output reg hs,
    output reg vs,
    output [10:0] x,
    output [10:0] y,
    output enable,
    output [19:0] address
    );

//水平
parameter H_FRONT = 16; //前肩
parameter H_SYNC  = 96; //同步
parameter H_BACK  = 48; //后肩
parameter H_ACT   = 640;//有效像素
parameter H_BLANK = H_FRONT+H_SYNC+H_BACK; //总空白
parameter H_TOTAL = H_FRONT+H_SYNC+H_BACK+H_ACT; //总行长

//垂直
parameter V_FRONT = 11; //前肩 
parameter V_SYNC  = 2;  //同步
parameter V_BACK  = 31; //后肩
parameter V_ACT   = 480;//有效像素
parameter V_BLANK = V_FRONT+V_SYNC+V_BACK; //总空白
parameter V_TOTAL = V_FRONT+V_SYNC+V_BACK+V_ACT; //总场长

reg [10:0] h_count;
reg [10:0] v_count;

always @(posedge clk or posedge rst)
begin
  if(rst)
  begin
    h_count <= 0;
    hs <= 1;
  end
  else
  begin
    if(h_count < H_TOTAL)
      h_count <= h_count + 1'b1;
    else
      h_count <= 0;
    if(h_count == H_FRONT - 1)
      hs <= 1'b0;
    if(h_count == H_FRONT + H_SYNC - 1)
      hs <= 1'b1;
  end 
end

always@(posedge hs or posedge rst)
begin
  if(rst)
  begin
    v_count <= 0;
    vs <= 1;
  end
  else
  begin
    if(v_count < V_TOTAL)
      v_count <= v_count + 1'b1;
    else
      v_count <= 0;
    if(v_count == V_FRONT - 1)
      vs <= 1'b0;
    if(v_count == V_FRONT + V_SYNC - 1)
      vs <= 1'b1;
  end
end

assign x = (h_count >= H_BLANK) ? (h_count - H_BLANK) : 11'h0;
assign y = (v_count >= V_BLANK) ? (v_count - V_BLANK) : 11'h0;
assign address = y * H_ACT + x;
assign enable = (((h_count >  H_BLANK) && (h_count <= H_TOTAL))&&
                 ((v_count >= V_BLANK) && (v_count < V_TOTAL)));  //One pixel shift


endmodule
