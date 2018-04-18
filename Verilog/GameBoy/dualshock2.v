`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    13:13:04 04/13/2018 
// Module Name:    dualshock
// Project Name:   VerilogBoy
// Description: 
//   Interface logic of SONY DualShock controller
// Dependencies: 
//
// Additional Comments: 
//   The PSX controller use a SPI like protocol. ATT is the CS, CMD is the MOSI,
//   and the DAT is the MISO. There is an additional ACK line would be pulled
//   low by the controller indicate the presense of the controller. LSB first.
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
//   This module only implement the Command 0x42.
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
    output key_lstick,
    output key_rstick,
    //debug
    output [7:0] debug1,
    output [7:0] debug2
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
    localparam T_TIMEOUT   = 5'd31; // Timeout for ACK
    localparam T_CD        = 5'd8;  // Cool down before next byte
    
    localparam LENGTH      = 4'd9;  // Transfer size should always be 9 bytes
    
    clk_div #(.WIDTH(4), .DIV(8)) spi_div(
        .i(clk),
        .o(clk_spi)
    );
    
    reg [4:0] state;
    reg [4:0] next_state;
    reg [4:0] state_counter; // Delta clock counter
    
    reg [3:0] bytes_count; // Bytes count
    reg [3:0] bits_count; // Bits count
    reg [7:0] tx_buffer [0:8]; // TX buffer, constant
    reg [7:0] rx_buffer [0:8]; // RX buffer
    reg [7:0] rx_byte;
    reg ready = 0; // Indicate if the data could be sent
    reg [1:0] status;
    
    assign debug1 = rx_buffer[3];
    assign debug2 = rx_buffer[4];
    
    wire [7:0] rx_b0 = rx_buffer[3];
    wire [7:0] rx_b1 = rx_buffer[4];
    wire [7:0] rx_b2 = rx_buffer[5];
    wire [7:0] rx_b3 = rx_buffer[6];
    wire [7:0] rx_b4 = rx_buffer[7];
    wire [7:0] rx_b5 = rx_buffer[8];
    
    assign key_select  = ~rx_b0[0];
    assign key_rstick  = ~rx_b0[1];
    assign key_lstick  = ~rx_b0[2];
    assign key_start   = ~rx_b0[3];
    assign key_up      = ~rx_b0[4];
    assign key_right   = ~rx_b0[5];
    assign key_down    = ~rx_b0[6];
    assign key_left    = ~rx_b0[7];
    assign key_l2      = ~rx_b1[0];
    assign key_r2      = ~rx_b1[1];
    assign key_l1      = ~rx_b1[2];
    assign key_r1      = ~rx_b1[3];
    assign key_triangle= ~rx_b1[4];
    assign key_circle  = ~rx_b1[5];
    assign key_cross   = ~rx_b1[6];
    assign key_square  = ~rx_b1[7];
    assign stick_rx    = ~rx_b2;
    assign stick_ry    = ~rx_b3;
    assign stick_lx    = ~rx_b4;
    assign stick_ly    = ~rx_b5;
    
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
                if (bits_count == 4'd7) next_state = S_EOB; else next_state = S_TX;
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
                next_state = S_IDLE;//Error recovery
        endcase
    end
    
    always @(posedge clk_spi) begin
        if (rst) begin
            state <= S_IDLE;
            state_counter <= 5'd0;
            last_vsync <= 1'b0;
        end
        else begin
            last_vsync <= vsync;
            state <= next_state;
            if (state != next_state)
                state_counter <= 5'd0;
            else
                state_counter <= state_counter + 1'b1;
        end
    end
    
    always @(posedge clk_spi) begin
        if (rst) begin
            // When reset, we want the first command to be 0x44
            bytes_count <= 4'd0;
            bits_count <= 4'd0;
            tx_buffer[0] <= 8'h01;
            tx_buffer[1] <= 8'h42;
            tx_buffer[2] <= 8'hff;
            tx_buffer[3] <= 8'hff;
            tx_buffer[4] <= 8'hff;
            tx_buffer[5] <= 8'hff;
            tx_buffer[6] <= 8'hff;
            tx_buffer[7] <= 8'hff;
            tx_buffer[8] <= 8'hff;
            rx_byte <= 8'hff;
            status <= STATUS_OK;
            ready <= 1;
            ds2_clk <= 1'b1;
            ds2_att <= 1'b1;
            ds2_cmd <= 1'b1;
        end
        else begin
            case (state)
                S_ATT:
                    ds2_att <= 1'b0;
                S_TX: begin
                    ds2_clk <= 1'b0;
                    ds2_cmd <= tx_buffer[bytes_count][bits_count];
                end
                S_RX: begin
                    ds2_clk <= 1'b1;
                    rx_byte[bits_count] <= ds2_dat;
                    bits_count <= bits_count + 1'b1;
                end
                S_EOB: begin
                    bytes_count <= bytes_count + 1'b1;
                    bits_count <= 4'd0;
                    rx_buffer[bytes_count] <= rx_byte;
                end
                //nothing to do for S_ACK_L and S_ACK_H
                S_END: begin
                    bytes_count <= 4'd0;
                    bits_count <= 4'd0;
                    status <= STATUS_OK;
                    ds2_att <= 1'b1;
                end
                S_ERR: begin
                    // Error happens, restart from 0x44
                    bytes_count <= 4'd0;
                    bits_count <= 4'd0;
                    status <= STATUS_ERR;
                    ds2_att <= 1'b1;
                end
            endcase 
        end
    end

endmodule
