`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    15:06:53 04/09/2018 
// Module Name:    sound_wave 
// Project Name:   VerilogBoy
// Description: 
//   Sound wave player for channel 3
// Dependencies: 
//   clk_div, sound_length_ctr
// Additional Comments: 
//   If Ch3 bugs are to be implemented, they should be probably implemented
//   outside of this file. This file does not handle of RW to wave RAM
//////////////////////////////////////////////////////////////////////////////////
module sound_wave(
    input rst, // Async reset 
    input clk, // Main CPU clock
    input clk_length_ctr, // Length control clock
    input [7:0] length, // Length = (256-t1)*(1/256) second, used iff single is set
    input [1:0] volume,
    input on,
    input single,
    input start,
    input [10:0] frequency,
    output [3:0] wave_a,
    input [7:0] wave_d,
    output [3:0] level,
    output enable
    );
    
    // Freq = 64kHz / (2048 - frequency)
    
    wire [3:0] current_sample;
    
    reg [4:0] current_pointer = 5'b0;
    
    assign wave_a[3:0] = current_pointer[4:1];
    assign current_sample[3:0] = (current_pointer[0]) ?
        (wave_d[3:0]) : (wave_d[7:4]);
    
    wire clk_wave_base; // 128kHz base clock
    clk_div #(.WIDTH(6), .DIV(32)) freq_div(
        .i(clk),
        .o(clk_wave_base)
    );
    
    reg clk_pointer_inc = 1'b0; // Clock for pointer to increment
    reg [11:0] divider = 12'b0;
    always @(posedge clk_wave_base, posedge start)
    begin
        if (start) begin
            divider <= frequency;
        end
        else begin
            if (divider == 12'd2047) begin
                clk_pointer_inc <= ~clk_pointer_inc;
                divider <= frequency;
            end
            else begin
                divider <= divider + 1'b1;
            end
        end
    end
        
    always @(clk_pointer_inc, posedge start)
    begin
        if (start) begin
            current_pointer <= 5'b0;
        end
        else begin
            if (on)
                current_pointer <= current_pointer + 1'b1;
        end
    end
    
    sound_length_ctr #(8) sound_length_ctr(
        .rst(rst),
        .clk_length_ctr(clk_length_ctr),
        .start(start),
        .single(single),
        .length(length),
        .enable(enable)
    );
    
    assign level = 
        (volume == 2'b00) ? (4'b0000) : (
        (volume == 2'b01) ? (current_sample[3:0]) : (
        (volume == 2'b10) ? ({1'b0, current_sample[3:1]}) : (
                            ({2'b0, current_sample[3:2]}))));


endmodule
