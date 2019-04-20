`timescale 1ns / 1ps
//`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:46:14 02/24/2019 
// Design Name: 
// Module Name:    cache 
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
module cache(
    input wire clk,
    input wire rst, 
    input wire [16:0] sys_addr, // byte address
    output reg [31:0] sys_rdata,
    input wire sys_valid,
    output reg sys_ready,
    output reg [16:0] mem_addr,
    input wire [31:0] mem_rdata,
    output reg mem_valid,
    input wire mem_ready
    );

    // 2-way set associative cache with LRU replacement
    // Input address is byte address, maximum addressable range 128KB
    // Cache works with 32b word address, 2 LSB will be disgarded
    // cache line length 2 word (n = 1)
    // 2 ways (k = 1)
    // each set consists of 256 lines (s = 8)
    // total size = 2 * 8 * 256 = 4 KB 
    // tag length = 15 - 8 - 1 = 6 bits
    // replacement: LRU
    // line length: valid(1) + tag(6) + data(64) = 71 bits
    // LRU bit is inside the top bit of the way 0 (72th bit)
    
    // READ ONLY
    
    // Performance (from request to data valid)
    //   Read, cache hit: 2 cycles
    //   Read, cache miss: 4 cycles + memory read latency
    //   Read, cache miss + flush: 12 cycles + 2x memory read latency

    // If 3_CYCLE_CACHE is defined, add 1 to all the above.
    
    //`define USE_3_CYCLE_CACHE 1
    
    // If RV is running at lower speed than the cache, longer SYS_READY pulse would be required
    //`define USE_LONGER_PULSE 1
    
    // Parameters are for descriptive purposes, they are non-adjustable.
    localparam CACHE_WAY = 2; 
    localparam CACHE_WAY_BITS = 1;
    localparam CACHE_LINE = 256; // Line number inside each way
    localparam CACHE_LINE_BITS = 8;
    localparam CACHE_LEN = 2; // Word number inside each line
    localparam CACHE_LEN_ABITS = 1; // Bits needed to address word inside line
    localparam CACHE_LEN_DBITS = 64; // Bits number inside each line
    localparam CACHE_ADDR_BITS = 15; // Input word address bits
    localparam CACHE_TAG_BITS = CACHE_ADDR_BITS - CACHE_LINE_BITS - CACHE_LEN_ABITS;
    localparam CACHE_VALID_BITS = 1; // This shouldn't be changed
    localparam CACHE_LRU_BITS = 1;
    localparam CACHE_LEN_TOTAL = CACHE_LEN_DBITS + CACHE_TAG_BITS + CACHE_VALID_BITS + CACHE_LRU_BITS;
    
    localparam BIT_TAG_START = 64;
    localparam BIT_TAG_END = 64 + 6 - 1;
    localparam BIT_LRU = 71;
    localparam BIT_VALID = 70;
    
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
    
    // 2 SelectRAM 18K
    bram_256_72 cache_way_0(clk, rst, addr_line_mux, ~rst, cache_way_we_0, cache_way_rd_0, cache_way_wr_0);
    bram_256_72 cache_way_1(clk, rst, addr_line_mux, ~rst, cache_way_we_1, cache_way_rd_1, cache_way_wr_1);
    
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
        (addr_word == 1'b0) ? (cache_way_rd_0[31:0]) :
                              (cache_way_rd_0[63:32]);
    wire [31: 0] cache_way_1_output_mux = 
        (addr_word == 1'b0) ? (cache_way_rd_1[31:0]) :
                              (cache_way_rd_1[63:32]);
    
    
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

    wire [71: 0] cache_way_0_input_overlay;
    wire [71: 0] cache_way_1_input_overlay;

    // Other remain same, LRU bit updated
    assign cache_way_0_input_overlay[BIT_TAG_END: 0] = cache_way_rd_0[BIT_TAG_END: 0];
    assign cache_way_1_input_overlay[BIT_TAG_END: 0] = cache_way_rd_1[BIT_TAG_END: 0];
    assign cache_way_0_input_overlay[BIT_LRU: BIT_VALID] = {cache_way_rd_1[BIT_LRU], 1'b1};
    assign cache_way_1_input_overlay[BIT_LRU: BIT_VALID] = {!cache_way_rd_0[BIT_LRU], 1'b1};
                             
    reg [1:0] cache_line_wb_src; // 00 - flush, 01 - cache_rdata with input overlay, 10 - mem_rdata at high, 11 - mem_rdata at low
    assign cache_way_wr_0 = 
        (cache_line_wb_src == 2'b00) ? ({!cache_way_rd_1[BIT_LRU], 71'd0}) : 
        (cache_line_wb_src == 2'b01) ? (cache_way_0_input_overlay) : 
        (cache_line_wb_src == 2'b10) ? ({cache_way_rd_1[BIT_LRU], 1'b1, addr_tag, cache_way_rd_0[63:32], mem_rdata}) :
                                       ({cache_way_rd_1[BIT_LRU], 1'b1, addr_tag, mem_rdata, cache_way_rd_0[31:0]});
    assign cache_way_wr_1 = 
        (cache_line_wb_src == 2'b00) ? ({!cache_way_rd_0[BIT_LRU], 71'd0}) : 
        (cache_line_wb_src == 2'b01) ? (cache_way_1_input_overlay) : 
        (cache_line_wb_src == 2'b10) ? ({cache_way_rd_0[BIT_LRU], 1'b1, addr_tag, cache_way_rd_1[63:32], mem_rdata}) :
                                       ({cache_way_rd_0[BIT_LRU], 1'b1, addr_tag, mem_rdata, cache_way_rd_1[31:0]});
    
    reg [2: 0] cache_state;
    
    // Cache hit takes 2 cycles
    localparam STATE_RESET = 3'd0;      // State after reset
    localparam STATE_IDLE = 3'd1;
    localparam STATE_RW_COMPARE = 3'd2;
    localparam STATE_RW_CHECK = 3'd3;
    localparam STATE_RW_MISS_1 = 3'd4;
    localparam STATE_RW_MISS_2 = 3'd5;
    localparam STATE_RW_MISS_3 = 3'd6;
    localparam STATE_WAIT = 3'd7;
    
    reg [CACHE_LINE_BITS - 1: 0] invalidate_counter;
    assign addr_line_mux = (addr_line_sel) ? invalidate_counter : addr_line;
    reg cache_way; // used to keep way number when cache miss happens
    
    always@(posedge clk) begin
        if (rst) begin
            cache_state <= STATE_RESET;
            sys_ready <= 1'b0;
            mem_valid <= 1'b0;
            cache_way_we_0 <= 1'b0;
            cache_way_we_1 <= 1'b0;
            cache_line_wb_src <= 2'b00;
            invalidate_counter <= 8'hFF;
            addr_line_sel <= 1'b1;
        end
        else begin
            case (cache_state)
                STATE_RESET: begin
                    cache_way_we_0 <= 1'b1;
                    cache_way_we_1 <= 1'b1;
                    invalidate_counter <= invalidate_counter - 1;
                    if (invalidate_counter == 8'd0) begin
                        cache_state <= STATE_IDLE;
                        $display("cache ready");
                    end
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
                        // For read, only valid bit and LRU bit will be updated
                        cache_way_we_0 <= 1'b1;
                        cache_way_we_1 <= 1'b0;
                        cache_line_wb_src <= 2'b01;
                        cache_state <= STATE_WAIT;
                        //$display("Cache hit in way 0.");
                    end
                    else if (cache_comparator_1) begin
                        sys_rdata <= cache_way_1_output_mux;
                        sys_ready <= 1'b1;
                        cache_way_we_0 <= 1'b0;
                        cache_way_we_1 <= 1'b1;
                        cache_line_wb_src <= 2'b01;
                        cache_state <= STATE_WAIT;
                        //$display("Cache hit in way 1.");
                    end
                    else begin
                        // Cache miss
                        mem_addr <= {sys_addr[CACHE_ADDR_BITS + 1: 3], !addr_word, 2'b00};
                        mem_valid <= 1'b1;
                        cache_state <= STATE_RW_MISS_1;
                        cache_way <= cache_lru_way_1_newer;
                        //$display("Cache miss.");
                    end
                end
                STATE_RW_MISS_1: begin
                    if (mem_ready) begin
                        // Write data into cache line
                        cache_line_wb_src <= {1'b1, !addr_word};
                        if (cache_way)
                            cache_way_we_0 <= 1'b1;
                        else
                            cache_way_we_1 <= 1'b1;
                        mem_valid <= 1'b0;
                        cache_state <= STATE_RW_MISS_2;
                    end
                end
                STATE_RW_MISS_2: begin
                    cache_way_we_0 <= 1'b0;
                    cache_way_we_1 <= 1'b0;
                    if (!mem_ready) begin
                        mem_addr <= {sys_addr[CACHE_ADDR_BITS + 1: 3], addr_word, 2'b00};
                        mem_valid <= 1'b1;
                        cache_state <= STATE_RW_MISS_3;
                    end
                end
                STATE_RW_MISS_3: begin
                    if (mem_ready) begin
                        // Write data into cache line
                        // Note after previous write, LRU word *may* have changed
                        cache_line_wb_src <= {2'b1, addr_word};
                        if (cache_way)
                            cache_way_we_0 <= 1'b1;
                        else
                            cache_way_we_1 <= 1'b1;
                        sys_ready <= 1'b1;
                        sys_rdata <= mem_rdata;
                        cache_state <= STATE_WAIT;
                    end
                end
                STATE_WAIT: begin
                    cache_way_we_0 <= 1'b0;
                    cache_way_we_1 <= 1'b0;
                    mem_valid <= 1'b0;
                    `ifdef USE_LONGER_PULSE
                    sys_ready <= 1'b1;
                    if (!sys_valid) begin
                        cache_state <= STATE_IDLE;
                    end
                    `else
                    sys_ready <= 1'b0;
                    cache_state <= STATE_IDLE;
                    `endif
                end
            endcase
        end
    end
    

endmodule
