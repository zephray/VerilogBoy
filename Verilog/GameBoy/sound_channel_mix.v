`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    22:29:14 04/08/2018 
// Design Name: 
// Module Name:    sound_channel_mix 
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
module sound_channel_mix(
    input enable,
    input modulate,
    input [3:0] target_vol,
    output [3:0] level
    );

    /*// Converting Volume envelope to 2s compliment number
    reg [3:0] target_vol_low;
    wire [3:0] target_vol_high;
    always@(target_vol)
    begin
        case (target_vol)
            4'b0000: target_vol_low = 4'b0000;
            4'b0001: target_vol_low = 4'b1111;
            4'b0010: target_vol_low = 4'b1111;
            4'b0011: target_vol_low = 4'b1110;
            4'b0100: target_vol_low = 4'b1110;
            4'b0101: target_vol_low = 4'b1101;
            4'b0110: target_vol_low = 4'b1101;
            4'b0111: target_vol_low = 4'b1100;
            4'b1000: target_vol_low = 4'b1100;
            4'b1001: target_vol_low = 4'b1011;
            4'b1010: target_vol_low = 4'b1011;
            4'b1011: target_vol_low = 4'b1010;
            4'b1100: target_vol_low = 4'b1010;
            4'b1101: target_vol_low = 4'b1001;
            4'b1110: target_vol_low = 4'b1001;
            4'b1111: target_vol_low = 4'b1000;
        endcase
    end
    assign target_vol_high = {1'b0, target_vol[3:1]};
                                
    assign level = (enable) ? ((modulate) ? (target_vol_high) : (target_vol_low)) : (4'b0000);*/
    
    assign level = (enable) ? ((modulate) ? (target_vol) : (4'b0000)) : (4'b0000);
    
endmodule
