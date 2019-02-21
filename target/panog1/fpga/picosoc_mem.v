module picosoc_mem #(
    parameter integer WORDS = 512
) (
    input clk,
    input [3:0] wen,
    input [21:0] addr,
    input [31:0] wdata,
    output reg [31:0] rdata
);
    reg [7:0] mem_0 [0:WORDS-1];
    reg [7:0] mem_1 [0:WORDS-1];
    reg [7:0] mem_2 [0:WORDS-1];
    reg [7:0] mem_3 [0:WORDS-1];

    initial begin
        $readmemh("picorv_fw_0.mif", mem_0, 0, WORDS-1);
        $readmemh("picorv_fw_1.mif", mem_1, 0, WORDS-1);
        $readmemh("picorv_fw_2.mif", mem_2, 0, WORDS-1);
        $readmemh("picorv_fw_3.mif", mem_3, 0, WORDS-1);
    end

    always @(posedge clk) begin
        if (wen[0]) mem_0[addr] <= wdata[ 7: 0];
        if (wen[1]) mem_1[addr] <= wdata[15: 8];
        if (wen[2]) mem_2[addr] <= wdata[23:16];
        if (wen[3]) mem_3[addr] <= wdata[31:24];
    end
    
    always @(posedge clk) begin
        rdata[ 7: 0] <= mem_0[addr];
        rdata[15: 8] <= mem_1[addr];
        rdata[23:16] <= mem_2[addr];
        rdata[31:24] <= mem_3[addr];
    end
endmodule
