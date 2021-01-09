`timescale 1ns / 1ps
module singleport_ram #(
    parameter integer WORDS = 8192,
    parameter ABITS = 13
)(
    input clka,
    input wea,
    input [ABITS - 1:0] addra,
    input [7:0] dina,
    output reg [7:0] douta
);

    reg [7:0] ram [0:WORDS-1];
    
    always@(posedge clka) begin
        if (wea)
            ram[addra] <= dina;
    end
    
    always@(posedge clka) begin
        douta <= ram[addra];
    end

endmodule
