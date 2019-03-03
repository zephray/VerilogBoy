`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:40:28 02/18/2019 
// Design Name: 
// Module Name:    mig_picorv_bridge 
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
module mig_picorv_bridge(
    input wire clk0,
    input wire clk90,
    input wire sys_rst180,
    input wire [24:0] ddr_addr,
    input wire [31:0] ddr_wdata,
    output wire [31:0] ddr_rdata,
    input wire [3:0] ddr_wstrb,
    input wire ddr_valid,
    output wire ddr_ready,
    input wire auto_refresh_req,
    output wire [63:0] user_input_data,
    input wire [63:0] user_output_data,
    input wire user_data_valid,
    output wire [22:0] user_input_address,
    output wire [2:0] user_command_register,
    input wire user_cmd_ack,
    output wire [7:0] user_data_mask,
    output wire burst_done,
    input wire init_done,
    input wire ar_done
    );

    wire [20:0] cache_addr;
    wire [127:0] cache_wdata;
    wire [127:0] cache_rdata;
    wire cache_valid;
    wire cache_ready;
    wire cache_wstrb;
    
    ddr_cache ddr_cache(
        .clk(clk0),
        .rst(sys_rst180),
        .sys_addr(ddr_addr),
        .sys_wdata(ddr_wdata),
        .sys_rdata(ddr_rdata),
        .sys_wstrb(ddr_wstrb),
        .sys_valid(ddr_valid),
        .sys_ready(ddr_ready),
        .mem_addr (cache_addr),
        .mem_wdata(cache_wdata),
        .mem_rdata(cache_rdata),
        .mem_wstrb(cache_wstrb),
        .mem_valid(cache_valid),
        .mem_ready(cache_ready)
    );

    cache_mig_bridge cache_mig_bridge(
        .clk0(clk0),
        .clk90(clk90),
        .sys_rst180(sys_rst180),
        .cache_addr(cache_addr),
        .cache_wdata(cache_wdata),
        .cache_rdata(cache_rdata),
        .cache_wstrb(cache_wstrb),
        .cache_valid(cache_valid),
        .cache_ready(cache_ready),
        .auto_refresh_req(auto_refresh_req),
        .user_input_data(user_input_data),
        .user_output_data(user_output_data),
        .user_data_valid(user_data_valid),
        .user_input_address(user_input_address),
        .user_command_register(user_command_register),
        .user_cmd_ack(user_cmd_ack),
        .user_data_mask(user_data_mask),
        .burst_done(burst_done),
        .init_done(init_done),
        .ar_done(ar_done)
    );

endmodule
