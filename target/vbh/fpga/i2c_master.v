`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    11:26:58 11/24/2018 
// Design Name: 
// Module Name:    i2c_master 
// Project Name:   VerilogBoy
// Description: 
//   I2C bus master mapped on MMP bus
// Dependencies: 
// 
// Additional Comments: 
//   See doc/vbh_ref_man.md for descriptions
////////////////////////////////////////////////////////////////////////////////
module i2c_master(
    input clk,
    input rst,
    input [2:0] mmp_a,
    input [7:0] mmp_din,
    output [7:0] mmp_dout,
    input mmp_wr,
    input mmp_rd,
    input i2c_scl_in,
    output i2c_scl_out,
    output i2c_scl_dir,
    input i2c_sda_in,
    output i2c_sda_out,
    output i2c_sda_dir
    );


endmodule
