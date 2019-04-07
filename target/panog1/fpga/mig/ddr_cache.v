`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:46:14 02/24/2019 
// Design Name: 
// Module Name:    ddr_cache 
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
module ddr_cache(
    input wire clk,
    input wire rst, 
    input wire [24:0] sys_addr, // byte address
    input wire [31:0] sys_wdata,
    output reg [31:0] sys_rdata,
    input wire [3:0] sys_wstrb,
    input wire sys_valid,
    output reg sys_ready,
    output reg [20:0] mem_addr,
    output wire [127:0] mem_wdata,
    input wire [127:0] mem_rdata,
    output reg mem_wstrb,
    output reg mem_valid,
    input wire mem_ready
    );

    // 2-way set associative cache with LRU replacement
    // Input address is byte address
    // Cache works with 32b word address, 2 LSB will be disgarded
    // cache line length 4 words (n = 2)
    // 2 ways (k = 1)
    // each set consists of 256 lines (s = 8)
    // total size = 2 * 16 * 256 = 8 KB 
    // tag length = 23 - 8 - 2 = 13 bits
    // replacement: LRU
    // line length: valid(1) + dirty(1) + tag(13) + data(128) = 143 bits
    // LRU bit is inside the top bit of the way 0 (144th bit)
    
    // Performance (from request to data valid)
    //   Read, cache hit: 2 cycles
    //   Read, cache miss: 4 cycles + memory read latency
    //   Read, cache miss + flush: 12 cycles + 2x memory read latency
    //   Write, cache hit: 2 cycles
    //   Write, cache miss: 5 cylces + memory read latency
    //   Write, cache miss + flush: 13 cycles + 2x memory read latency
    
    // If 3_CYCLE_CACHE is defined, add 1 to all the above.
    
    `define USE_3_CYCLE_CACHE 1
    
    // If RV is running at lower speed than the cache, longer SYS_READY pulse would be required
    `define USE_LONGER_PULSE 1
    
    // Parameters are for descriptive purposes, they are non-adjustable.
    localparam CACHE_WAY = 2; 
    localparam CACHE_WAY_BITS = 1;
    localparam CACHE_LINE = 256; // Line number inside each way
    localparam CACHE_LINE_BITS = 8;
    localparam CACHE_LEN = 4; // Word number inside each line
    localparam CACHE_LEN_ABITS = 2; // Bits needed to address byte inside line
    localparam CACHE_LEN_DBITS = 128; // Bits number inside each line
    localparam CACHE_ADDR_BITS = 23; // Input word address bits
    localparam CACHE_TAG_BITS = CACHE_ADDR_BITS - CACHE_LINE_BITS - CACHE_LEN_ABITS;
    localparam CACHE_VALID_BITS = 1; // This shouldn't be changed
    localparam CACHE_DIRTY_BITS = 1; // This shouldn't be changed
    localparam CACHE_LRU_BITS = 1;
    localparam CACHE_LEN_TOTAL = CACHE_LEN_DBITS + CACHE_TAG_BITS + CACHE_VALID_BITS + CACHE_DIRTY_BITS + CACHE_LRU_BITS;
    
    localparam BIT_TAG_START = 128;
    localparam BIT_TAG_END = 128 + 13 - 1;
    localparam BIT_LRU = 143;
    localparam BIT_VALID = 142;
    localparam BIT_DIRTY = 141;
    
    wire [CACHE_ADDR_BITS - 1: 0] sys_word_addr = sys_addr[CACHE_ADDR_BITS + 1: 2];
    
    wire [CACHE_LEN_ABITS - 1: 0] addr_word = sys_word_addr[CACHE_LEN_ABITS - 1: 0];
    wire [CACHE_LINE_BITS - 1: 0] addr_line = sys_word_addr[CACHE_LINE_BITS + CACHE_LEN_ABITS - 1: CACHE_LEN_ABITS];
    wire [CACHE_TAG_BITS - 1: 0]  addr_tag  = sys_word_addr[CACHE_ADDR_BITS - 1: CACHE_LINE_BITS + CACHE_LEN_ABITS];
    
    wire [CACHE_LEN_TOTAL - 1: 0] cache_way_rd_0;
    wire [CACHE_LEN_TOTAL - 1: 0] cache_way_rd_1;
    wire [CACHE_LEN_TOTAL - 1: 0] cache_way_wr_0;
    wire [CACHE_LEN_TOTAL - 1: 0] cache_way_wr_1;
    reg                           cache_way_we_0;
    reg                           cache_way_we_1;
    
    wire [CACHE_LINE_BITS - 1: 0] addr_line_mux;
    reg addr_line_sel;
    
    // 4 SelectRAM 18K
    bram_256_72 cache_way_0_high(clk, rst, addr_line_mux, ~rst, cache_way_we_0, {cache_way_rd_0[143: 136], cache_way_rd_0[127:64]}, {cache_way_wr_0[143: 136], cache_way_wr_0[127:64]});
    bram_256_72 cache_way_0_low (clk, rst, addr_line_mux, ~rst, cache_way_we_0, {cache_way_rd_0[135: 128], cache_way_rd_0[63:0]},   {cache_way_wr_0[135: 128], cache_way_wr_0[63:0]});
    bram_256_72 cache_way_1_high(clk, rst, addr_line_mux, ~rst, cache_way_we_1, {cache_way_rd_1[143: 136], cache_way_rd_1[127:64]}, {cache_way_wr_1[143: 136], cache_way_wr_1[127:64]});
    bram_256_72 cache_way_1_low (clk, rst, addr_line_mux, ~rst, cache_way_we_1, {cache_way_rd_1[135: 128], cache_way_rd_1[63:0]},   {cache_way_wr_1[135: 128], cache_way_wr_1[63:0]});
    
    wire cache_comparator_0_comb = ((addr_tag == cache_way_rd_0[BIT_TAG_END: BIT_TAG_START]) && (cache_way_rd_0[BIT_VALID])) ? 1'b1 : 1'b0;
    wire cache_comparator_1_comb = ((addr_tag == cache_way_rd_1[BIT_TAG_END: BIT_TAG_START]) && (cache_way_rd_1[BIT_VALID])) ? 1'b1 : 1'b0;
`ifdef USE_3_CYCLE_CACHE
    reg cache_comparator_0;
    reg cache_comparator_1;
    
    always@(posedge clk) begin
        cache_comparator_0 <= cache_comparator_0_comb;
        cache_comparator_1 <= cache_comparator_1_comb;
    end
`else
    wire cache_comparator_0 = cache_comparator_0_comb;
    wire cache_comparator_1 = cache_comparator_1_comb;
`endif

    wire [31: 0] cache_way_0_output_mux = 
        (addr_word == 2'b00) ? (cache_way_rd_0[31:0]) :
        (addr_word == 2'b01) ? (cache_way_rd_0[63:32]) :
        (addr_word == 2'b10) ? (cache_way_rd_0[95:64]) :
                               (cache_way_rd_0[127:96]);
    wire [31: 0] cache_way_1_output_mux = 
        (addr_word == 2'b00) ? (cache_way_rd_1[31:0]) :
        (addr_word == 2'b01) ? (cache_way_rd_1[63:32]) :
        (addr_word == 2'b10) ? (cache_way_rd_1[95:64]) :
                               (cache_way_rd_1[127:96]);
    wire [31: 0] mem_rd_output_mux = 
        (addr_word == 2'b00) ? (mem_rdata[31:0]) :
        (addr_word == 2'b01) ? (mem_rdata[63:32]) :
        (addr_word == 2'b10) ? (mem_rdata[95:64]) :
                               (mem_rdata[127:96]);
    
    reg mem_w_src;
    wire [127:0] mem_wdata_comb = (mem_w_src == 1'b0) ? (cache_way_rd_0) : (cache_way_rd_1);
    
    /*always@(posedge clk) begin
        mem_wdata <= mem_wdata_comb;
    end*/
    assign mem_wdata = mem_wdata_comb;
    
    // LRU policy:
    // For every line, both way have its own LRU bit. Both bits are read out everytime, but only one will be written back.
    // It is encoded as such:
    // W0 W1
    // 0  0 - Way 0 is newer
    // 0  1 - Way 1 is newer
    // 1  0 - Way 1 is newer
    // 1  1 - Way 0 is newer
    // When way 0 need to be newer, it set itself to be the same as way 1's LRU bit 
    // When way 1 need to be newer, it set itself to be different as way 0's LRU bit
    
    wire cache_lru_bit_0 = cache_way_rd_0[BIT_LRU];
    wire cache_lru_bit_1 = cache_way_rd_1[BIT_LRU];
    wire cache_lru_way_0_newer = (cache_lru_bit_0 == cache_lru_bit_1) ? 1 : 0;
    wire cache_lru_way_1_newer = !cache_lru_way_0_newer;
    
    reg sys_byte_strobe [0: 15];
    integer i;
    integer j;
    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                sys_byte_strobe[i * 4 + j] = (addr_word == i) && (sys_wstrb[j]);
            end
        end
    end
    
    // These two are not reg, they are wires.
    wire [143: 0] cache_way_0_input_overlay;
    wire [143: 0] cache_way_1_input_overlay;

    assign cache_way_0_input_overlay[8 - 1: 0] = (sys_byte_strobe[0]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_0[8 - 1: 0]);
    assign cache_way_1_input_overlay[8 - 1: 0] = (sys_byte_strobe[0]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_1[8 - 1: 0]);
    assign cache_way_0_input_overlay[16 - 1: 8] = (sys_byte_strobe[1]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_0[16 - 1: 8]);
    assign cache_way_1_input_overlay[16 - 1: 8] = (sys_byte_strobe[1]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_1[16 - 1: 8]);
    assign cache_way_0_input_overlay[24 - 1: 16] = (sys_byte_strobe[2]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_0[24 - 1: 16]);
    assign cache_way_1_input_overlay[24 - 1: 16] = (sys_byte_strobe[2]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_1[24 - 1: 16]);
    assign cache_way_0_input_overlay[32 - 1: 24] = (sys_byte_strobe[3]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_0[32 - 1: 24]);
    assign cache_way_1_input_overlay[32 - 1: 24] = (sys_byte_strobe[3]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_1[32 - 1: 24]);
    assign cache_way_0_input_overlay[40 - 1: 32] = (sys_byte_strobe[4]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_0[40 - 1: 32]);
    assign cache_way_1_input_overlay[40 - 1: 32] = (sys_byte_strobe[4]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_1[40 - 1: 32]);
    assign cache_way_0_input_overlay[48 - 1: 40] = (sys_byte_strobe[5]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_0[48 - 1: 40]);
    assign cache_way_1_input_overlay[48 - 1: 40] = (sys_byte_strobe[5]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_1[48 - 1: 40]);
    assign cache_way_0_input_overlay[56 - 1: 48] = (sys_byte_strobe[6]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_0[56 - 1: 48]);
    assign cache_way_1_input_overlay[56 - 1: 48] = (sys_byte_strobe[6]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_1[56 - 1: 48]);
    assign cache_way_0_input_overlay[64 - 1: 56] = (sys_byte_strobe[7]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_0[64 - 1: 56]);
    assign cache_way_1_input_overlay[64 - 1: 56] = (sys_byte_strobe[7]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_1[64 - 1: 56]);
    assign cache_way_0_input_overlay[72 - 1: 64] = (sys_byte_strobe[8]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_0[72 - 1: 64]);
    assign cache_way_1_input_overlay[72 - 1: 64] = (sys_byte_strobe[8]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_1[72 - 1: 64]);
    assign cache_way_0_input_overlay[80 - 1: 72] = (sys_byte_strobe[9]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_0[80 - 1: 72]);
    assign cache_way_1_input_overlay[80 - 1: 72] = (sys_byte_strobe[9]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_1[80 - 1: 72]);
    assign cache_way_0_input_overlay[88 - 1: 80] = (sys_byte_strobe[10]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_0[88 - 1: 80]);
    assign cache_way_1_input_overlay[88 - 1: 80] = (sys_byte_strobe[10]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_1[88 - 1: 80]);
    assign cache_way_0_input_overlay[96 - 1: 88] = (sys_byte_strobe[11]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_0[96 - 1: 88]);
    assign cache_way_1_input_overlay[96 - 1: 88] = (sys_byte_strobe[11]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_1[96 - 1: 88]);
    assign cache_way_0_input_overlay[104 - 1: 96] = (sys_byte_strobe[12]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_0[104 - 1: 96]);
    assign cache_way_1_input_overlay[104 - 1: 96] = (sys_byte_strobe[12]) ? (sys_wdata[8 - 1: 0]) : (cache_way_rd_1[104 - 1: 96]);
    assign cache_way_0_input_overlay[112 - 1: 104] = (sys_byte_strobe[13]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_0[112 - 1: 104]);
    assign cache_way_1_input_overlay[112 - 1: 104] = (sys_byte_strobe[13]) ? (sys_wdata[16 - 1: 8]) : (cache_way_rd_1[112 - 1: 104]);
    assign cache_way_0_input_overlay[120 - 1: 112] = (sys_byte_strobe[14]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_0[120 - 1: 112]);
    assign cache_way_1_input_overlay[120 - 1: 112] = (sys_byte_strobe[14]) ? (sys_wdata[24 - 1: 16]) : (cache_way_rd_1[120 - 1: 112]);
    assign cache_way_0_input_overlay[128 - 1: 120] = (sys_byte_strobe[15]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_0[128 - 1: 120]);
    assign cache_way_1_input_overlay[128 - 1: 120] = (sys_byte_strobe[15]) ? (sys_wdata[32 - 1: 24]) : (cache_way_rd_1[128 - 1: 120]);
    
    // Tag lines remain same, valid set, and dirty bits from dirty_wr, LRU bit updated
    assign cache_way_0_input_overlay[140: 128] = cache_way_rd_0[BIT_TAG_END: BIT_TAG_START];
    assign cache_way_1_input_overlay[140: 128] = cache_way_rd_1[BIT_TAG_END: BIT_TAG_START];
    assign cache_way_0_input_overlay[143: 141] = {cache_way_rd_1[BIT_LRU], 1'b1, ((sys_wstrb != 0) || (cache_way_rd_0[BIT_DIRTY])) ? 1'b1 : 1'b0};
    assign cache_way_1_input_overlay[143: 141] = {!cache_way_rd_0[BIT_LRU], 1'b1, ((sys_wstrb != 0) || (cache_way_rd_1[BIT_DIRTY])) ? 1'b1 : 1'b0};
                             
    reg [1:0] cache_line_wb_src; // 0 - cache_rdata with input overlay, 1 - mem_rdata, 10/11 - flush
    assign cache_way_wr_0 = 
        (cache_line_wb_src == 2'b01) ? ({cache_way_rd_1[143], 2'b10, addr_tag, mem_rdata}) : 
        (cache_line_wb_src == 2'b00) ? (cache_way_0_input_overlay) : ({!cache_way_rd_1[BIT_LRU], 143'd0});
    assign cache_way_wr_1 = 
        (cache_line_wb_src == 2'b01) ? ({!cache_way_rd_0[143], 2'b10, addr_tag, mem_rdata}) : 
        (cache_line_wb_src == 2'b00) ? (cache_way_1_input_overlay) : ({cache_way_rd_0[BIT_LRU], 143'd0});
    
    reg [3: 0] cache_state;
    
    // Cache hit takes 2 cycles
    localparam STATE_RESET = 4'd0;      // State after reset
    localparam STATE_IDLE = 4'd1;
    localparam STATE_RW_COMPARE = 4'd2;
    localparam STATE_RW_CHECK = 4'd3;
    localparam STATE_RW_MISS = 4'd4;
    localparam STATE_RW_DONE = 4'd5;
    localparam STATE_RW_FLUSH = 4'd6;
    localparam STATE_RW_FLUSH_WAIT = 4'd7;
    localparam STATE_WRITE_MISS_APPLY = 4'd8;
    localparam STATE_WAIT = 4'd15;
    
    reg [CACHE_LINE_BITS - 1: 0] invalidate_counter;
    assign addr_line_mux = (addr_line_sel) ? invalidate_counter : addr_line;
    
    always@(posedge clk) begin
        if (rst) begin
            cache_state <= STATE_RESET;
            sys_ready <= 1'b0;
            mem_valid <= 1'b0;
            cache_way_we_0 <= 1'b0;
            cache_way_we_1 <= 1'b0;
            cache_line_wb_src <= 2'b10;
            invalidate_counter <= 8'hFF;
            addr_line_sel <= 1'b1;
        end
        else begin
            case (cache_state)
                STATE_RESET: begin
                    cache_way_we_0 <= 1'b1;
                    cache_way_we_1 <= 1'b1;
                    invalidate_counter <= invalidate_counter - 1;
                    if (invalidate_counter == 8'd0)
                        cache_state <= STATE_IDLE;
                end
                STATE_IDLE: begin
                    addr_line_sel <= 1'b0;
                    cache_way_we_0 <= 1'b0;
                    cache_way_we_1 <= 1'b0;
                    sys_ready <= 1'b0;
                    if (sys_valid) begin
                    `ifdef USE_3_CYCLE_CACHE
                        cache_state <= STATE_RW_COMPARE;
                    `else
                        cache_state <= STATE_RW_CHECK;
                    `endif
                    end
                end
                STATE_RW_COMPARE: begin
                    // Block RAM is so slow
                    cache_state <= STATE_RW_CHECK;
                end
                STATE_RW_CHECK: begin
                    if (cache_comparator_0) begin
                        // Useful only when RD, ignored when WR
                        sys_rdata <= cache_way_0_output_mux;
                        sys_ready <= 1'b1;
                        // For write, data bytes will be updated.
                        // For read, only valid bit and LRU bit will be updated
                        cache_way_we_0 <= 1'b1;
                        cache_way_we_1 <= 1'b0;
                        cache_line_wb_src <= 2'b00;
                        cache_state <= STATE_WAIT;
                        //$display("Cache hit in way 0.");
                    end
                    else if (cache_comparator_1) begin
                        sys_rdata <= cache_way_1_output_mux;
                        sys_ready <= 1'b1;
                        cache_way_we_0 <= 1'b0;
                        cache_way_we_1 <= 1'b1;
                        cache_line_wb_src <= 2'b00;
                        cache_state <= STATE_WAIT;
                        //$display("Cache hit in way 1.");
                    end
                    else begin
                        // Cache miss
                        // Check if the cache line needed to be flushed before RW
                        if (cache_lru_way_1_newer) begin
                            if (cache_way_rd_0[BIT_VALID] && cache_way_rd_0[BIT_DIRTY]) begin
                                // flush is required before overwritting
                                mem_addr <= {cache_way_rd_0[BIT_TAG_END: BIT_TAG_START], addr_line};
                                mem_w_src <= 1'b0;
                                mem_wstrb <= 1'b1;
                                mem_valid <= 1'b1;
                                cache_state <= STATE_RW_FLUSH;
                                //$display("Cache miss, way 0 flush.");
                                //$stop;
                            end
                            else begin
                                // flush is not required
                                mem_addr <= sys_addr[24:4];
                                mem_wstrb <= 1'b0;
                                mem_valid <= 1'b1;
                                cache_state <= STATE_RW_MISS;
                                //$display("Cache miss, way 0 load.");
                            end
                        end
                        else begin
                            if (cache_way_rd_1[BIT_VALID] && cache_way_rd_1[BIT_DIRTY]) begin
                                // flush is required before overwritting
                                mem_addr <= {cache_way_rd_1[BIT_TAG_END: BIT_TAG_START], addr_line};
                                mem_w_src <= 1'b1;
                                mem_wstrb <= 1'b1;
                                mem_valid <= 1'b1;
                                cache_state <= STATE_RW_FLUSH;
                                //$display("Cache miss, way 1 flush.");
                                //$stop;
                            end
                            else begin
                                // flush is not required
                                mem_addr <= sys_addr[24:4];
                                mem_wstrb <= 1'b0;
                                mem_valid <= 1'b1;
                                cache_state <= STATE_RW_MISS;
                                //$display("Cache miss, way 1 load.");
                            end
                        end
                    end
                end
                STATE_RW_MISS: begin
                    if (mem_ready) begin
                        // Write data into cache line
                        cache_line_wb_src <= 2'b01;
                        if (cache_lru_way_1_newer) begin
                            cache_way_we_0 <= 1'b1;
                        end
                        else begin
                            cache_way_we_1 <= 1'b1;
                        end
                        if (sys_wstrb == 0) begin
                            sys_rdata <= mem_rd_output_mux;
                            sys_ready <= 1'b1;
                            cache_state <= STATE_WAIT;
                        end
                        else begin
                            // need to wait 1 cycle for data from RAM to write
                            cache_state <= STATE_WRITE_MISS_APPLY;
                        end
                    end
                end
                STATE_RW_FLUSH: begin
                    if (mem_ready) begin
                        mem_valid <= 1'b0;
                        cache_line_wb_src <= 2'b10;
                        if (cache_lru_way_1_newer) begin
                            cache_way_we_0 <= 1'b1;
                        end
                        else begin
                            cache_way_we_1 <= 1'b1;
                        end
                        cache_state <= STATE_RW_FLUSH_WAIT;
                    end
                end
                STATE_RW_FLUSH_WAIT: begin
                    cache_way_we_0 <= 1'b0;
                    cache_way_we_1 <= 1'b0;
                    if (!mem_ready) begin
                        cache_state <= STATE_RW_CHECK;
                    end
                end
                STATE_WRITE_MISS_APPLY: begin
                    cache_line_wb_src <= 2'b00;
                    sys_ready <= 1'b1;
                    cache_state <= STATE_WAIT;
                end
                STATE_WAIT: begin
                    cache_way_we_0 <= 1'b0;
                    cache_way_we_1 <= 1'b0;
                    mem_valid <= 1'b0;
                    `ifdef USE_LONGER_PULSE
                    sys_ready <= 1'b1;
                    `else
                    sys_ready <= 1'b0;
                    `endif
                    if (!sys_valid) begin
                        cache_state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end
    

endmodule
