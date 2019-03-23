`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:39:21 03/03/2019 
// Design Name: 
// Module Name:    usb_picorv_bridge 
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
module usb_picorv_bridge(
    input wire clk,
    input wire rst,
    input wire [18:0] sys_addr,
    output reg [31:0] sys_rdata,
    input wire [31:0] sys_wdata,
    input wire [3:0] sys_wstrb,
    input wire sys_valid,
    output reg sys_ready,
    output reg usb_csn,
    output reg usb_rdn,
    output reg usb_wrn,
    output reg [17:1] usb_a,
    output reg [15:0] usb_dout,
    input wire [15:0] usb_din,
    output reg bus_dir
    );
    
    reg [2:0] state;
    reg [2:0] counter;
    
    localparam STATE_IDLE = 3'd0;
    localparam STATE_WRITE = 3'd1;
    localparam STATE_READ = 3'd2;
    localparam STATE_LATCH = 3'd3;

    always@(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            usb_csn <= 1'b1;
            bus_dir <= 1'b1;
            sys_ready <= 1'b0;
        end
        else begin
            case (state)
                STATE_IDLE: begin
                    if (sys_valid) begin
                        if (sys_wstrb != 0) begin
                            usb_csn <= 1'b0;
                            usb_rdn <= 1'b1;
                            usb_wrn <= 1'b0;
                            usb_dout <= sys_wdata[15:0];
                            usb_a[17:1] <= sys_addr[18:2];
                            bus_dir <= 1'b0;
                            sys_ready <= 1'b1;
                            state <= STATE_WRITE;
                            counter <= 3'd4;
                        end
                        else begin
                            usb_csn <= 1'b0;
                            usb_rdn <= 1'b0;
                            usb_wrn <= 1'b1;
                            usb_a[17:1] <= sys_addr[18:2];
                            state <= STATE_READ;
                            counter <= 3'd4;
                        end
                    end
                    else begin
                        usb_csn <= 1'b1;
                        usb_rdn <= 1'b1;
                        usb_wrn <= 1'b1;
                        bus_dir <= 1'b1;
                    end
                end
                STATE_WRITE: begin
                    sys_ready <= 1'b0;
                    counter <= counter - 1;
                    if (counter == 1) begin
                        usb_wrn <= 1'b1; // To meet CS and DATA hold requirement
                    end
                    else if (counter == 0) begin
                        usb_csn <= 1'b1;
                        bus_dir <= 1'b1;
                        state <= STATE_IDLE;
                    end
                end
                STATE_READ: begin
                    sys_ready <= 1'b0;
                    counter <= counter - 1;
                    if (counter == 0) begin
                        sys_rdata <= {16'd0, usb_din};
                        sys_ready <= 1'b1;
                        usb_csn <= 1'b1;
                        usb_rdn <= 1'b1;
                        usb_wrn <= 1'b1;
                        state <= STATE_LATCH;
                    end
                end
                STATE_LATCH: begin
                    sys_ready <= 1'b0;
                    state <= STATE_IDLE;
                end
            endcase
        end
    
    end


endmodule
