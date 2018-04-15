`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    12:29:37 04/07/2018 
// Module Name:    sound
// Project Name:   VerilogBoy
// Description: 
//   GameBoy sound unit main file
// Dependencies: 
//
// Additional Comments: 
//   On a real gameboy, audio mixing is done with an OpAmp (I am not sure, but
//   this makes most sense according to the documents we have). I am using adder
//   here to make that happen. Also, audio volume control is probably done with a
//   PGA on a real gameboy, and I am using multiplication to implement that here.
//   So this would synthesis some additional adders and multipliers which should
//   not be part of a Game Boy.
//////////////////////////////////////////////////////////////////////////////////
module sound(
    input clk,
    input clk_audio,
    input rst,
    input [15:0] a,
    output reg [7:0] dout,
    input [7:0] din,
    input rd,
    input wr,
    output [19:0] left,
    output [19:0] right,
    // debug
    output [3:0] ch1_level,
    output [3:0] ch2_level,
    output [3:0] ch3_level,
    output [3:0] ch4_level
    );

    // Sound registers
    reg [7:0] regs [0:31]; 
    wire [7:0] reg_nr10 = regs[00]; // $FF10 Channel 1 Sweep register (RW)
    wire [7:0] reg_nr11 = regs[01]; // $FF11 Channel 1 Sound length/wave patternduty (RW)
    wire [7:0] reg_nr12 = regs[02]; // $FF12 Channel 1 Volume envelope (RW)
    wire [7:0] reg_nr13 = regs[03]; // $FF13 Channel 1 Freqency lo (W)
    wire [7:0] reg_nr14 = regs[04]; // $FF14 Channel 1 Freqency hi (RW)
    wire [7:0] reg_nr21 = regs[06]; // $FF16 Channel 2 Sound length/wave patternduty (RW)
    wire [7:0] reg_nr22 = regs[07]; // $FF17 Channel 2 Volume envelope (RW)
    wire [7:0] reg_nr23 = regs[08]; // $FF18 Channel 2 Freqency lo (W)
    wire [7:0] reg_nr24 = regs[09]; // $FF19 Channel 2 Freqency hi (RW)
    wire [7:0] reg_nr30 = regs[10]; // $FF1A Channel 3 Sound on/off (RW)
    wire [7:0] reg_nr31 = regs[11]; // $FF1B Channel 3 Sound length (?)
    wire [7:0] reg_nr32 = regs[12]; // $FF1C Channel 3 Select output level (RW)
    wire [7:0] reg_nr33 = regs[13]; // $FF1D Channel 3 Frequency lo (W)
    wire [7:0] reg_nr34 = regs[14]; // $FF1E Channel 3 Frequency hi (RW)
    wire [7:0] reg_nr41 = regs[16]; // $FF20 Channel 4 Sound length (RW)
    wire [7:0] reg_nr42 = regs[17]; // $FF21 Channel 4 Volume envelope (RW)
    wire [7:0] reg_nr43 = regs[18]; // $FF22 Channel 4 Polynomial counter (RW)
    wire [7:0] reg_nr44 = regs[19]; // $FF23 Channel 4 Counter/consecutive; Initial(RW)
    wire [7:0] reg_nr50 = regs[20]; // $FF24 Channel contorl / ON-OFF / Volume (RW)
    wire [7:0] reg_nr51 = regs[21]; // $FF25 Selection of Sound output terminal (RW)
    wire [7:0] reg_nr52 = regs[22]; // $FF26 Sound on/off
    wire [4:0] reg_addr = {~a[4], a[3:0]}; // Convert 10-20 to 00-10
    
    wire [2:0]  ch1_sweep_time = reg_nr10[6:4];
    wire        ch1_sweep_decreasing = reg_nr10[3];
    wire [2:0]  ch1_num_sweep_shifts = reg_nr10[2:0];
    wire [1:0]  ch1_wave_duty = reg_nr11[7:6];
    wire [5:0]  ch1_length = reg_nr11[5:0];
    wire [3:0]  ch1_initial_volume = reg_nr12[7:4];
    wire        ch1_envelope_increasing = reg_nr12[3];
    wire [2:0]  ch1_num_envelope_sweeps = reg_nr12[2:0];
    wire        ch1_initialize = reg_nr14[7];
    reg         ch1_start;
    wire        ch1_single = reg_nr14[6];
    wire [10:0] ch1_frequency = {reg_nr14[2:0], reg_nr13[7:0]};
    wire [1:0]  ch2_wave_duty = reg_nr21[7:6];
    wire [5:0]  ch2_length = reg_nr21[5:0];
    wire [3:0]  ch2_initial_volume = reg_nr22[7:4];
    wire        ch2_envelope_increasing = reg_nr22[3];
    wire [2:0]  ch2_num_envelope_sweeps = reg_nr22[2:0];
    wire        ch2_initialize = reg_nr24[7];
    reg         ch2_start;
    wire        ch2_single = reg_nr24[6];
    wire [10:0] ch2_frequency = {reg_nr24[2:0], reg_nr23[7:0]};
    wire [7:0]  ch3_length = reg_nr31[7:0];
    wire        ch3_on = reg_nr30[7];
    wire [1:0]  ch3_volume = reg_nr32[6:5];
    reg         ch3_start;
    wire        ch3_single = reg_nr34[6];
    wire [10:0] ch3_frequency = {reg_nr34[2:0], reg_nr33[7:0]};
    wire [5:0]  ch4_length = reg_nr41[5:0];
    wire [3:0]  ch4_initial_volume = reg_nr42[7:4];
    wire        ch4_envelope_increasing = reg_nr42[3];
    wire [2:0]  ch4_num_envelope_sweeps = reg_nr42[2:0];
    wire [3:0]  ch4_shift_clock_freq = reg_nr43[7:4];
    wire        ch4_counter_width = reg_nr43[3]; // 0 = 15 bits, 1 = 7 bits
    wire [2:0]  ch4_freq_dividing_ratio = reg_nr43[2:0];
    wire        ch4_initialize = reg_nr44[7];
    reg         ch4_start;
    wire        ch4_single = reg_nr44[6];
    wire        s02_vin = reg_nr50[7];
    wire [2:0]  s02_output_level = reg_nr50[6:4];
    wire        s01_vin = reg_nr50[3];
    wire [2:0]  s01_output_level = reg_nr50[2:0];
    wire        s02_ch4_enable = reg_nr51[7];
    wire        s02_ch3_enable = reg_nr51[6];
    wire        s02_ch2_enable = reg_nr51[5];
    wire        s02_ch1_enable = reg_nr51[4];
    wire        s01_ch4_enable = reg_nr51[3];
    wire        s01_ch3_enable = reg_nr51[2];
    wire        s01_ch2_enable = reg_nr51[1];
    wire        s01_ch1_enable = reg_nr51[0];
    wire        sound_enable = reg_nr52[7];
    wire        ch4_on_flag; 
    wire        ch3_on_flag;
    wire        ch2_on_flag;
    wire        ch1_on_flag;
    
    reg [7:0] wave [0:15];
    wire [3:0] wave_addr_ext = a[3:0];
    wire [3:0] wave_addr_int;
    wire [3:0] wave_addr = (ch3_on) ? (wave_addr_int) : (wave_addr_ext);
    wire [7:0] wave_data = wave[wave_addr];
    
    wire addr_in_regs = (a >= 16'hFF10 && a <= 16'hFF2F);
    wire addr_in_wave = (a >= 16'hFF30 && a <= 16'hFF3F);
    
    // Bus RW
    // Bus RW - Combinational Read
    // This is a drawback of ISE XST, one can not use always@(*) and reg array together,
    // so one have to write something (does not need to make sense, just as a place holder)
    // and let the synthesizer to determine the correct sensitvity list. (Or one would have
    // to enumerate EACH item in an array, otherwise it will give an error.
    always @(a)
    begin
        dout = 8'hFF;
        if (addr_in_regs) begin
            if (a == 16'hFF26)
                dout = {sound_enable, 3'b0, ch4_on_flag, ch3_on_flag, ch2_on_flag, ch1_on_flag};
            else
                dout = regs[reg_addr];
        end
        else
        if (addr_in_wave) begin
            dout = wave[wave_addr];
        end
    end
    
    // Bus RW - Sequential Write
    integer i;
    
    always @(posedge clk)
    begin
        if (rst) begin
            for (i = 0; i < 32; i = i+1) begin
                regs[i] <= 8'b0;
            end
            // wave pattern should not be initialized
        end
        else begin
            if (wr) begin
                if (addr_in_regs) begin
                    if (a == 16'hFF26) begin
                        if (din[7] == 0) begin
                            for (i = 0; i < 32; i = i+1) begin
                                regs[i] <= 8'b0;
                            end
                        end
                        else
                            regs[reg_addr] <= din;
                    end
                    else if (sound_enable) begin
                        regs[reg_addr] <= din;
                    end
                end
                else if (addr_in_wave)
                    //wave[wave_addr_ext] <= din; //what if we allow Write any way?
                    wave[wave_addr] <= din; // This is what happens trying to write to wave sample while it is on
            end
            // Initialize signal, should be triggered whenever a 1 is written
            if ((wr)&&(a == 16'hFF14)) ch1_start <= din[7];
                else ch1_start <= 0;
            if ((wr)&&(a == 16'hFF19)) ch2_start <= din[7];
                else ch2_start <= 0;
            if ((wr)&&(a == 16'hFF1E)) ch3_start <= din[7];
                else ch3_start <= 0;
            if ((wr)&&(a == 16'hFF23)) ch4_start <= din[7];
                else ch4_start <= 0;
        end
    end
    
    // Clocks
    wire clk_frame; // 512Hz Base Clock
    wire clk_length_ctr; // 256Hz Length Control Clock
    wire clk_vol_env; // 64Hz Volume Enevelope Clock
    wire clk_sweep; // 128Hz Sweep Clock
    wire clk_freq_div; // 1048576Hz Frequency Division Clock
    
    clk_div #(.WIDTH(15), .DIV(8192)) frame_div(
        .i(clk),
        .o(clk_frame)
    );
    
    reg [2:0] sequencer_state = 3'b0;
    always@(posedge clk_frame)
    begin
        sequencer_state <= sequencer_state + 1'b1;
    end
    
    assign clk_length_ctr = (sequencer_state[0]) ? 1'b0 : 1'b1;
    assign clk_vol_env = (sequencer_state == 3'd7) ? 1'b1 : 1'b0;
    assign clk_sweep = ((sequencer_state == 3'd2) || (sequencer_state == 3'd6)) ? 1'b1 : 1'b0;

    clk_div #(.WIDTH(2), .DIV(2)) freq_div(
        .i(clk),
        .o(clk_freq_div)
    );

    // Channels
    wire [3:0] ch1;
    wire [3:0] ch2;
    wire [3:0] ch3;
    wire [3:0] ch4;
    
    sound_square sound_ch1(
        .rst(~sound_enable),
        .clk(clk),
        .clk_length_ctr(clk_length_ctr),
        .clk_vol_env(clk_vol_env),
        .clk_sweep(clk_sweep),
        .clk_freq_div(clk_freq_div),
        .sweep_time(ch1_sweep_time),
        .sweep_decreasing(ch1_sweep_decreasing),
        .num_sweep_shifts(ch1_num_sweep_shifts),
        .wave_duty(ch1_wave_duty),
        .length(ch1_length),
        .initial_volume(ch1_initial_volume),
        .envelope_increasing(ch1_envelope_increasing),
        .num_envelope_sweeps(ch1_num_envelope_sweeps),
        .start(ch1_start),
        .single(ch1_single),
        .frequency(ch1_frequency),
        .level(ch1),
        .enable(ch1_on_flag)
    );
    
    sound_square sound_ch2(
        .rst(~sound_enable),
        .clk(clk),
        .clk_length_ctr(clk_length_ctr),
        .clk_vol_env(clk_vol_env),
        .clk_sweep(clk_sweep),
        .clk_freq_div(clk_freq_div),
        .sweep_time(3'b0),
        .sweep_decreasing(1'b0),
        .num_sweep_shifts(3'b0),
        .wave_duty(ch2_wave_duty),
        .length(ch2_length),
        .initial_volume(ch2_initial_volume),
        .envelope_increasing(ch2_envelope_increasing),
        .num_envelope_sweeps(ch2_num_envelope_sweeps),
        .start(ch2_start),
        .single(ch2_single),
        .frequency(ch2_frequency),
        .level(ch2),
        .enable(ch2_on_flag)
    );
        
    sound_wave sound_ch3(
        .rst(~sound_enable),
        .clk(clk),
        .clk_length_ctr(clk_length_ctr),
        .length(ch3_length),
        .volume(ch3_volume),
        .on(ch3_on),
        .single(ch3_single),
        .start(ch3_start),
        .frequency(ch3_frequency),
        .wave_a(wave_addr_int),
        .wave_d(wave_data),
        .level(ch3),
        .enable(ch3_on_flag)
    );
    
    sound_noise sound_ch4(
        .rst(~sound_enable),
        .clk(clk),
        .clk_length_ctr(clk_length_ctr),
        .clk_vol_env(clk_vol_env),
        .length(ch4_length),
        .initial_volume(ch4_initial_volume), 
        .envelope_increasing(ch4_envelope_increasing),
        .num_envelope_sweeps(ch4_num_envelope_sweeps),
        .shift_clock_freq(ch4_shift_clock_freq), 
        .counter_width(ch4_counter_width), 
        .freq_dividing_ratio(ch4_freq_dividing_ratio), 
        .start(ch4_start), 
        .single(ch4_single), 
        .level(ch4),
        .enable(ch4_on_flag)
    );
    
    // Mixer
    
    /*
    // Signed mixer
    wire [5:0] sign_extend_ch1 = {{3{ch1[3]}}, ch1[2:0]};
    wire [5:0] sign_extend_ch2 = {{3{ch2[3]}}, ch2[2:0]};
    wire [5:0] sign_extend_ch3 = {{3{ch3[3]}}, ch3[2:0]};
    wire [5:0] sign_extend_ch4 = {{3{ch4[3]}}, ch4[2:0]};
    reg [5:0] mixed_s01;
    reg [5:0] mixed_s02;

    always @(*)
    begin
        mixed_s01 = 6'd0;
        mixed_s02 = 6'd0;
        if (s01_ch1_enable) mixed_s01 = mixed_s01 + sign_extend_ch1;
        if (s01_ch2_enable) mixed_s01 = mixed_s01 + sign_extend_ch2;
        if (s01_ch3_enable) mixed_s01 = mixed_s01 + sign_extend_ch3;
        if (s01_ch4_enable) mixed_s01 = mixed_s01 + sign_extend_ch4;
        if (s02_ch1_enable) mixed_s02 = mixed_s02 + sign_extend_ch1;
        if (s02_ch2_enable) mixed_s02 = mixed_s02 + sign_extend_ch2;
        if (s02_ch3_enable) mixed_s02 = mixed_s02 + sign_extend_ch3;
        if (s02_ch4_enable) mixed_s02 = mixed_s02 + sign_extend_ch4;
    end
    
    assign left  = (sound_enable) ? {mixed_s01[5:0], 14'b0} : 20'b0;
    assign right = (sound_enable) ? {mixed_s02[5:0], 14'b0} : 20'b0; 
    */
    
    // Unsigned mixer
    reg [5:0] added_s01;
    reg [5:0] added_s02;
    always @(*)
    begin
        added_s01 = 6'd0;
        added_s02 = 6'd0;
        if (s01_ch1_enable) added_s01 = added_s01 + ch1;
        if (s01_ch2_enable) added_s01 = added_s01 + ch2;
        if (s01_ch3_enable) added_s01 = added_s01 + ch3;
        if (s01_ch4_enable) added_s01 = added_s01 + ch4;
        if (s02_ch1_enable) added_s02 = added_s02 + ch1;
        if (s02_ch2_enable) added_s02 = added_s02 + ch2;
        if (s02_ch3_enable) added_s02 = added_s02 + ch3;
        if (s02_ch4_enable) added_s02 = added_s02 + ch4;
    end
    
    wire [8:0] mixed_s01 = added_s01 * s01_output_level;
    wire [8:0] mixed_s02 = added_s02 * s02_output_level;
    
    assign left  = (sound_enable) ? {1'b0, mixed_s01[8:0], 10'b0} : 20'b0;
    assign right = (sound_enable) ? {1'b0, mixed_s02[8:0], 10'b0} : 20'b0; 
    
    // Debug Output
    assign ch1_level = ch1;
    assign ch2_level = ch2;
    assign ch3_level = ch3;
    assign ch4_level = ch4;

endmodule
