`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:19:04 04/08/2018 
// Design Name: 
// Module Name:    sound_noise 
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
module sound_noise(
    input rst, // Async reset
    input clk, // CPU Clock
    input clk_length_ctr, // Length control clock
    input clk_vol_env, // Volume Envelope clock
    input [5:0] length, // Length = (64-t1)*(1/256) second, used iff single is set
    input [3:0] initial_volume, // Initial volume of envelope 0 = no sound
    input envelope_increasing, // 0 = decrease, 1 = increase
    input [2:0] num_envelope_sweeps, // number of envelope sweep 0 = stop
    input [3:0] shift_clock_freq, // shift clock prescaler
    input counter_width, // 0 = 15 bits, 1 = 7 bits
    input [2:0] freq_dividing_ratio, // shift clock divider 0 -> 1MHz, 1 -> 512kHz
    input start, // Restart sound
    input single, // If set, output would stop upon reaching the length specified
    output [3:0] level
    );
    
    wire [3:0] target_vol;
    wire enable;
    
    reg clk_div = 0;
    wire clk_shift;
    
    reg [3:0] clk_divider = 4'b0; // First stage divider
    always @(posedge clk)
    begin
        if (clk_divider == (freq_dividing_ratio + 1)) begin
            clk_div <= ~clk_div;
            clk_divider <= 0;
        end
        else
            clk_divider <= clk_divider + 1'b1;
    end
    
    reg [15:0] clk_shifter = 15'b0;
    always @(posedge clk_div)
    begin
        clk_shifter <= clk_shifter + 1'b1;
    end
    
    assign clk_shift = clk_shifter[shift_clock_freq];
    
    reg [14:0] lfsr = {15{1'b1}};
    wire target_freq_out = lfsr[0];
    
    wire [14:0] lfsr_next =
        (counter_width == 0) ? ({(lfsr[0] ^ lfsr[1]), lfsr[14:1]}) :
                               ({8'b0, (lfsr[0] ^ lfsr[1]), lfsr[6:1]});
    
    always@(posedge clk_shift, posedge rst)
    begin
        if (rst) begin
            lfsr <= {15{1'b1}};
        end
        else begin
            lfsr <= lfsr_next;
        end    
    end
    
    sound_vol_env sound_vol_env(
        .clk_vol_env(clk_vol_env),
        .start(start),
        .initial_volume(initial_volume),
        .envelope_increasing(envelope_increasing),
        .num_envelope_sweeps(num_envelope_sweeps),
        .target_vol(target_vol)
    );

    sound_length_ctr sound_length_ctr(
        .rst(rst),
        .clk_length_ctr(clk_length_ctr),
        .start(start),
        .single(single),
        .length(length),
        .enable(enable)
    );
    
    sound_channel_mix sound_channel_mix(
        .enable(enable),
        .modulate(target_freq_out),
        .target_vol(target_vol),
        .level(level)
    );
    
endmodule
