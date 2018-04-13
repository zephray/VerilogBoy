`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    13:13:04 04/13/2018 
// Module Name:    dualshock2 
// Project Name:   VerilogBoy
// Description: 
//   Interface logic of SONY DualShock 2 controller
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//   The PSX controller use a SPI like protocol. ATT is the CS, CMD is the MOSI,
//   and the DAT is the MISO. There is an additional ACK line would be pulled
//   low by the controller indicate the presense of the controller.
//
//   Clock is Idle High, Data are put on to bus during the leading edge, and
//   pulled from bus during the trailing edge.
//
//   The whole frame can be divided into two parts: the handshake part and the
//   data transmission part.
//
//   The handshake part is always 3 bytes long. Below is the definition:
//      | Byte | TX                | RX                   |
//      |------|-------------------|----------------------|
//      |  00  | Always 01         | Always FF            |
//      |  01  | The command byte  | Mode and ID          |
//      |  02  | Always 00         | Always 5A (padding)  |
//
//   Specifically, it has 3 mode:
//      * 0x04: Digital mode
//      * 0x07: Analog mode
//      * 0x0F: Escape mode
//
//   This module only implement the Command 0x42 and Command 0x44.
//
//   Command 0x42 Polling keys:
//      | Byte | BIT0  | BIT1  | BIT2  | BIT3  | BIT4  | BIT5  | BIT6  | BIT7  |
//      |------|-------|-------|-------|-------|-------|-------|-------|-------|
//      |  01  | SEL   | JOYR  | JOYL  | START | UP    | RIGHT | DOWN  | LEFT  |
//      |  02  | L2    | R2    | L1    | L1    | TRIAN | CIRCL | CROSS | SQUAR |
//      |  03  | Right Joystick X       0x00 = Left      0xFF = Right          |
//      |  04  | Right Joystick Y       0x00 = Up        0xFF = Down           |
//      |  05  | Left Joystick X        0x00 = Left      0xFF = Right          |
//      |  06  | Left Joystick Y        0x00 = Up        0xFF = Down           |
//
//   Command 0x44 Set major mode (Digital/ Analog)
//      | Byte | TX                          | RX         |
//      |------|-----------------------------|------------|
//      |  01  | 01 - Analog / 00 - Digital  | 00         |
//      |  02  | 03                          | 00         |
//      |  03  | 00                          | 00         |  
//      |  04  | 00                          | 00         |  
//      |  05  | 00                          | 00         |  
//      |  06  | 00                          | 00         |           
//////////////////////////////////////////////////////////////////////////////////
module dualshock2(
    input clk,
    input rst,
    input vsync, // Vsync, should be high active, read back happen during Vsync
    input ds2_dat,
    output reg ds2_cmd,
    output reg ds2_att,
    output reg ds2_clk,
    input ds2_ack,
    output [7:0] stick_lx,
    output [7:0] stick_ly,
    output [7:0] stick_rx,
    output [7:0] stick_ry,
    output key_up,
    output key_down,
    output key_left,
    output key_right,
    output key_l1,
    output key_l2,
    output key_r1,
    output key_r2,
    output key_triangle,
    output key_square,
    output key_circle,
    output key_cross,
    output key_start,
    output key_select,
    output key_analog,
    output key_l3,
    output key_r3
    );
    
    wire clk_spi; //500kHz SPI Clock
    
    localparam S_IDLE      = 5'd0;
    localparam S_ATT       = 5'd1;
    localparam S_TX        = 5'd2;
    localparam S_RX        = 5'd3;
    localparam S_EOB       = 5'd4;
    localparam S_ACK_L     = 5'd5;
    localparam S_ACK_H     = 5'd6;
    localparam S_END       = 5'd7;
    localparam S_ERR       = 5'd8;
    
    localparam STATUS_OK   = 2'd0;
    localparam STATUS_ERR  = 2'd1;
    localparam STATUS_TR   = 2'd2;
    
    localparam T_ATT       = 5'd4;  // Wait 2 clocks before start
    localparam T_BITS      = 5'd8;  // Word size: 8 bits
    localparam T_TIMEOUT   = 5'd32; // Timeout for ACK
    localparam T_CD        = 5'd8;  // Cool down before next byte
    
    localparam LENGTH      = 4'd9;  // Transfer size should always be 9 bytes
    
    clk_div #(.WIDTH(4), .DIV(8)) frame_div(
        .i(clk),
        .o(clk_spi)
    );
    
    reg [4:0] state;
    wire [4:0] next_state;
    reg [4:0] state_counter; // Delta clock counter
    
    reg [3:0] bytes_count; // Bytes left
    reg [3:0] bits_left; // Bit count
    reg [7:0] tx_buffer [0:8]; // TX buffer, constant
    reg [7:0] rx_buffer [0:8]; // RX buffer
    reg ready = 0; // Indicate if the data could be sent
    reg [1:0] status;
    
    reg last_vsync = 0;
    
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:
                if ((last_vsync == 0)&&(vsync == 1)) next_state = S_ATT;
            S_ATT:
                if (state_counter == T_ATT) next_state = S_TX;
            S_TX:
                next_state = S_RX;
            S_RX:
                if (state_counter == T_BITS) next_state = S_EOB;
            S_EOB:
                if (bytes_count == LENGTH) next_state = S_END; else next_state = S_ACK_L;
            S_ACK_L:
                if (ds2_ack == 1'b0) next_state = S_ACK_H; else
                if (state_counter == T_TIMEOUT) next_state = S_ERR;
            S_ACK_H:
                if ((ds2_ack == 1'b1)&&(state_counter == T_CD)) next_state = S_TX;
            S_END:
                next_state = S_IDLE;
            S_ERR:
                next_state = S_ERR;
        endcase
    end
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            // When reset, we want the first command to be 0x44
            bytes_count <= 4'd0;
            bits_left <= 4'd7;
            tx_buffer[0] <= 8'h01;
            tx_buffer[1] <= 8'h42;
            tx_buffer[2] <= 8'hff;
            tx_buffer[3] <= 8'hff;
            tx_buffer[4] <= 8'hff;
            tx_buffer[5] <= 8'hff;
            tx_buffer[6] <= 8'hff;
            tx_buffer[7] <= 8'hff;
            tx_buffer[8] <= 8'hff;
            status <= STATUS_OK;
            ready <= 1;
        end
        else begin
            case (state)
                S_IDLE:
                    // Do nothing!
                S_ATT:
                    ds2_att <= 1'b0;
                S_TX:
                    ds2_cmd <= tx_buffer[bytes_count][bits_left];
                //S_RX:
                    
                //S_EOB:
                    
                //S_ACK_L:

                //S_ACK_H:
               
                S_END: begin
                    bytes_count <= 4'd0;
                    bits_left <= 4'd7;
                    tx_buffer[0] <= 8'h01;
                    tx_buffer[1] <= 8'h42;
                    tx_buffer[2] <= 8'hff;
                    tx_buffer[3] <= 8'hff;
                    tx_buffer[4] <= 8'hff;
                    tx_buffer[5] <= 8'hff;
                    tx_buffer[6] <= 8'hff;
                    tx_buffer[7] <= 8'hff;
                    tx_buffer[8] <= 8'hff;
                    status <= STATUS_OK;
                    ds2_att <= 1'b1;
                end
                S_ERR: begin
                    // Error happens, restart from 0x44
                    bytes_count <= 4'd0;
                    bits_left <= 4'd7;
                    tx_buffer[0] <= 8'h01;
                    tx_buffer[1] <= 8'h44;
                    tx_buffer[2] <= 8'hff;
                    tx_buffer[3] <= 8'h01;
                    tx_buffer[4] <= 8'h03;
                    tx_buffer[5] <= 8'hff;
                    tx_buffer[6] <= 8'hff;
                    tx_buffer[7] <= 8'hff;
                    tx_buffer[8] <= 8'hff;
                    status <= STATUS_ERR;
                    ds2_att <= 1'b1;
                end
            endcase 
        end
    end

endmodule
