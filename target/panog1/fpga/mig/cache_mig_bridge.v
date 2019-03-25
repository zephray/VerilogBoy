`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:04:03 02/24/2019 
// Design Name: 
// Module Name:    cache_mig_bridge 
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
module cache_mig_bridge(
    input wire clk0,
    input wire clk90,
    input wire sys_rst180,
    input wire [20:0] cache_addr,
    input wire [127:0] cache_wdata,
    output wire [127:0] cache_rdata,
    input wire cache_wstrb,
    input wire cache_valid,
    output reg cache_ready,
    input wire auto_refresh_req,
    output reg [63:0] user_input_data,
    input wire [63:0] user_output_data,
    input wire user_data_valid,
    output reg [22:0] user_input_address,
    output reg [2:0] user_command_register,
    input wire user_cmd_ack,
    output wire [7:0] user_data_mask,
    output reg burst_done,
    input wire init_done,
    input wire ar_done
    );

    reg [3:0] bridge_state;
    reg [1:0] wait_counter;
    reg [63:0] user_input_data_int;
    reg cache_ready_int;
    
    localparam BSTATE_STARTUP = 4'd0;
    localparam BSTATE_WAIT_INIT = 4'd1;
    localparam BSTATE_IDLE = 4'd2;
    localparam BSTATE_WAIT_REFRESH = 4'd3;
    localparam BSTATE_WRITE_CMD = 4'd4;
    localparam BSTATE_WRITE_WAIT = 4'd5;
    localparam BSTATE_WRITE_DONE = 4'd6;
    localparam BSTATE_READ_CMD = 4'd7;
    localparam BSTATE_READ_WAIT_1 = 4'd8;
    localparam BSTATE_READ_WAIT_2 = 4'd9;
    localparam BSTATE_READ_DONE = 4'd10;
    localparam BSTATE_WAIT = 4'd11;
    
    // Burst length is fixed to 4, and each read or write consists of 1 burst.
    // Means each time it will read/ write 4 32bit words, but only 1 is valid 
    //   if there is no cache.
    
    // MIG wants negedge
    always @(negedge clk0) begin
        if (sys_rst180) begin
            bridge_state <= BSTATE_STARTUP;
            user_input_address <= 23'b0;
            burst_done <= 1'b0;
            cache_ready_int <= 1'b0;
            user_command_register <= 3'b000;
        end
        else begin
            case (bridge_state)
                BSTATE_STARTUP: begin
                    if (!init_done) begin
                        user_command_register <= 3'b010;
                        bridge_state <= BSTATE_WAIT_INIT;
                    end
                    else begin
                        bridge_state <= BSTATE_IDLE;
                    end
                    cache_ready_int <= 1'b0;
                end
                BSTATE_WAIT_INIT: begin
                    user_command_register <= 3'b000;
                    if (init_done)
                        bridge_state <= BSTATE_IDLE;
                end
                BSTATE_IDLE: begin
                    if (auto_refresh_req) begin
                        bridge_state <= BSTATE_WAIT_REFRESH;
                    end
                    else if (cache_valid) begin
                        cache_ready_int <= 1'b0;
                        if (!user_cmd_ack) begin
                            if (cache_wstrb != 0) begin
                                user_command_register <= 3'b100;
                                bridge_state <= BSTATE_WRITE_CMD;
                            end
                            else begin
                                user_command_register <= 3'b110;
                                bridge_state <= BSTATE_READ_CMD;
                            end
                            // last 2 bits always 0: aligned access
                            user_input_address <= {cache_addr[20:0], 2'b00}; 
                        end
                    end
                    else begin
                        cache_ready_int <= 1'b0;
                    end
                end
                BSTATE_WAIT_REFRESH: begin
                    if (ar_done)
                        bridge_state <= BSTATE_IDLE;
                    if (cache_valid)
                        cache_ready_int <= 1'b0;
                end
                BSTATE_WRITE_CMD: begin
                    if (user_cmd_ack) begin
                        wait_counter <= 2'd3;
                        bridge_state <= BSTATE_WRITE_WAIT;
                    end
                end
                BSTATE_WRITE_WAIT: begin
                    if (wait_counter == 2'd1) begin
                        burst_done <= 1'b1;
                        wait_counter <= 2'd2;
                        bridge_state <= BSTATE_WRITE_DONE;
                    end
                    else
                        wait_counter <= wait_counter - 2'd1;
                end
                BSTATE_WRITE_DONE: begin
                    user_command_register <= 3'b000;
                    if (wait_counter == 2'd1) begin
                        burst_done <= 1'b0;
                        cache_ready_int <= 1'b1;
                        bridge_state <= BSTATE_WAIT;
                    end
                    else
                        wait_counter <= wait_counter - 2'd1;
                end
                BSTATE_READ_CMD: begin
                    if (user_cmd_ack) begin
                        wait_counter <= 2'd3;
                        bridge_state <= BSTATE_READ_WAIT_1;
                    end
                end
                BSTATE_READ_WAIT_1: begin
                    if (wait_counter == 2'd1) begin
                        burst_done <= 1'b1;
                        wait_counter <= 2'd2;
                        bridge_state <= BSTATE_READ_WAIT_2;
                    end
                    else
                        wait_counter <= wait_counter - 2'd1;
                end
                BSTATE_READ_WAIT_2: begin
                    user_command_register <= 3'b000;
                    if (wait_counter == 2'd1) begin
                        burst_done <= 1'b0;
                        if (user_data_valid) begin
                            bridge_state <= BSTATE_READ_DONE;
                        end
                    end
                    else
                        wait_counter <= wait_counter - 2'd1;
                end
                BSTATE_READ_DONE: begin
                    user_command_register <= 3'b000;
                    cache_ready_int <= 1'b1;
                    bridge_state <= BSTATE_WAIT;
                end
                BSTATE_WAIT: begin
                    cache_ready_int <= 1'b0;
                    if (!cache_valid)
                        bridge_state <= BSTATE_IDLE;

                end
            endcase
        end
    end
    
    always @(posedge clk0) begin
        cache_ready <= cache_ready_int;
    end
    
    reg [3:0] datapath_state;
    localparam DSTATE_IDLE = 4'd0;
    localparam DSTATE_WRITE = 4'd1;
    localparam DSTATE_READ_WAIT = 4'd2;
    localparam DSTATE_READ = 4'd3;
    localparam DSTATE_WAIT = 4'd4;
    reg [127:0] rd_buffer;
    assign cache_rdata = rd_buffer;
    assign user_data_mask = 8'd0;
    
    always @(posedge clk0) begin
        if (!init_done) begin
            datapath_state <= DSTATE_IDLE;
        end
        else begin
            case (datapath_state)
                DSTATE_IDLE: begin
                    if (user_cmd_ack) begin
                        if (user_command_register == 3'b100) begin
                            datapath_state <= DSTATE_WRITE;
                            user_input_data_int <= cache_wdata[127:64];
                        end
                        else if (user_command_register == 3'b110) begin
                            datapath_state <= DSTATE_READ_WAIT;
                        end
                    end
                end
                DSTATE_WRITE: begin
                    datapath_state <= DSTATE_WAIT;
                    // Write second word
                    user_input_data_int <= cache_wdata[63:0];
                end
                DSTATE_READ_WAIT: begin
                    if (user_data_valid) begin
                        datapath_state <= DSTATE_READ;
                        rd_buffer[127:64] <= user_output_data;
                    end
                end
                DSTATE_READ: begin
                    datapath_state <= DSTATE_WAIT;
                    rd_buffer[63:0] <= user_output_data;
                end
                DSTATE_WAIT: begin
                    if (!user_cmd_ack)
                        datapath_state <= DSTATE_IDLE;
                end
            endcase
        end
    end
    
    always @(posedge clk90) begin
        user_input_data <= user_input_data_int;
    end

endmodule
