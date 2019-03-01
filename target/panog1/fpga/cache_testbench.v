`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:15:59 02/28/2019
// Design Name:   ddr_cache
// Module Name:   C:/Users/Wenting/Documents/GitHub/VerilogBoy/target/panog1/fpga/cache_testbench.v
// Project Name:  panog1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ddr_cache
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module cache_testbench;

	// Inputs
	reg clk;
	reg rst;
	reg [24:0] sys_addr;
	reg [31:0] sys_wdata;
	reg [3:0] sys_wstrb;
	reg sys_valid;
	reg [127:0] mem_rdata;
	reg mem_ready;

	// Outputs
	wire [31:0] sys_rdata;
	wire sys_ready;
	wire [20:0] mem_addr;
	wire [127:0] mem_wdata;
	wire mem_wstrb;
	wire mem_valid;

	// Instantiate the Unit Under Test (UUT)
	ddr_cache uut (
		.clk(clk), 
		.rst(rst), 
		.sys_addr(sys_addr), 
		.sys_wdata(sys_wdata), 
		.sys_rdata(sys_rdata), 
		.sys_wstrb(sys_wstrb), 
		.sys_valid(sys_valid), 
		.sys_ready(sys_ready), 
		.mem_addr(mem_addr), 
		.mem_wdata(mem_wdata), 
		.mem_rdata(mem_rdata), 
		.mem_wstrb(mem_wstrb), 
		.mem_valid(mem_valid), 
		.mem_ready(mem_ready)
	);
    
    // Clock
    always
        #5 clk = !clk;
    
    // 256 B memory space
    reg [127:0] mem [0: 127];
    reg last_mem_valid;
    reg mem_valid_slow;
    wire mem_valid_gated;
    reg [2:0] mem_valid_counter;
    
    // make this memory slower
    always @(posedge clk) begin
        last_mem_valid <= mem_valid;
        if (!last_mem_valid && mem_valid) begin
            mem_valid_counter <= 3'd7;
        end
        else if (!mem_valid) begin
            mem_valid_slow <= 1'b0;
            mem_valid_counter <= 1'b0; // disable
        end
        else if ((mem_valid_counter != 0)&&(mem_valid_counter != 1)) begin
            mem_valid_counter <= mem_valid_counter - 1;
        end
        else if (mem_valid_counter == 1) begin
            mem_valid_slow <= 1'b1;
        end
    end
    
    assign mem_valid_gated = mem_valid_slow & mem_valid;

    always @(posedge clk) begin
        if (mem_valid_slow) begin
            if (mem_wstrb)
                mem[mem_addr] <= mem_wdata;
            else
                mem_rdata <= mem[mem_addr];
            mem_ready <= 1'b1;
        end
        else begin
            mem_ready <= 1'b0;
        end
    end
    
    integer i;
    
    reg [7:0] i_in_reg;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
		sys_addr = 0;
		sys_wdata = 0;
		sys_wstrb = 0;
		sys_valid = 0;
		mem_rdata = 0;
		mem_ready = 0;

        for (i = 0; i < 128; i = i + 1) begin
            mem[i] = 0;
        end

		// Wait 100 ns for global reset to finish
		#100;
        rst = 0;
        
		// Add stimulus here
        sys_addr = 25'h000000;
        sys_wdata = 32'h12345678;
        sys_wstrb = 4'b1111;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        sys_addr = 25'h000000;
        sys_wstrb = 4'b0000;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        if (sys_rdata != 32'h12345678)
            $display("TB: Value error");
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        // Word write test
        
        // Should not actaully cause any flush
        for (i = 0; i < 128; i = i + 1) begin
            i_in_reg = i;
            sys_addr = {15'd0, i_in_reg, 2'd0};
            sys_wdata = {i_in_reg[2:0], i_in_reg[7:3], i_in_reg[1:0], i_in_reg[7:2], i_in_reg[0], i_in_reg[7:1], i_in_reg[7:0]};
            sys_wstrb = 4'b1111;
            sys_valid = 1'b1;
            wait(sys_ready == 1'b1);
            
            sys_valid = 1'b0;
            wait(sys_ready == 1'b0);
        end
        
        for (i = 0; i < 128; i = i + 1) begin
            i_in_reg = i;
            sys_addr = {15'd0, i_in_reg, 2'd0};
            sys_wstrb = 4'b0000;
            sys_valid = 1'b1;
            wait(sys_ready == 1'b1);
            
            if (sys_rdata != {i_in_reg[2:0], i_in_reg[7:3], i_in_reg[1:0], i_in_reg[7:2], i_in_reg[0], i_in_reg[7:1], i_in_reg[7:0]})
                $display("TB: Value error");

            sys_valid = 1'b0;
            wait(sys_ready == 1'b0);
        end
        
        // Should miss
        $display("TB: Expect a cache miss");
        sys_addr = {13'd1, 8'h0, 2'd0, 2'd0};
        sys_wdata = 32'h11451419;
        sys_wstrb = 4'b1111;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        // Should flush
        $display("TB: Expect a cache flush");
        sys_addr = {13'd2, 8'h0, 2'd0, 2'd0};
        sys_wdata = 32'h12458848;
        sys_wstrb = 4'b1111;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        // Should flush
        $display("TB: Expect a cache flush");
        sys_addr = {13'd0, 8'h0, 2'd0, 2'd0};
        sys_wstrb = 4'b0000;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        // Should miss
        $display("TB: Expect a cache miss");
        sys_addr = {13'd1, 8'h40, 2'd0, 2'd0};
        sys_wstrb = 4'b0000;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        // Should miss
        $display("TB: Expect a cache miss");
        sys_addr = {13'd1, 8'h60, 2'd0, 2'd0};
        sys_wstrb = 4'b0000;
        sys_valid = 1'b1;
        wait(sys_ready == 1'b1);
        
        sys_valid = 1'b0;
        wait(sys_ready == 1'b0);
        
        $finish;
	end
      
endmodule

