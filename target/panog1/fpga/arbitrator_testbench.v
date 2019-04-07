`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:24:54 04/04/2019
// Design Name:   rv_vbc_cache_arbiter
// Module Name:   /root/VerilogBoy/target/panog1/fpga/arbitrator_testbench.v
// Project Name:  panog1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rv_vbc_cache_arbiter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module arbitrator_testbench;

    // Inputs
	reg rst;
	reg clkrv;
	reg clkgb;
	reg [24:0] rv_addr;
	reg [31:0] rv_wdata;
	reg [3:0] rv_wstrb;
	reg rv_valid;
	reg [22:0] vb_a;
	reg [7:0] vb_dout;
	reg vb_rd;
	reg vb_wr;

	// Outputs
	wire [31:0] rv_rdata;
	wire rv_ready;
	wire [7:0] vb_din;

    wire [24:0] sys_addr;
	wire [31:0] sys_wdata;
	wire [3:0] sys_wstrb;
	wire sys_valid;
	reg [127:0] mem_rdata;
	reg mem_ready;

	// Outputs
	wire [31:0] sys_rdata;
	wire sys_ready;
	wire [20:0] mem_addr;
	wire [127:0] mem_wdata;
	wire mem_wstrb;
	wire mem_valid;

	ddr_cache cache (
		.clk(clkrv), 
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
    
    // 256 B memory space
    reg [127:0] mem [0: 127];
    reg last_mem_valid;
    reg mem_valid_slow;
    wire mem_valid_gated;
    reg [4:0] mem_valid_counter;
    
    // make this memory slower
    always @(posedge clkrv) begin
        last_mem_valid <= mem_valid;
        if (!last_mem_valid && mem_valid) begin
            mem_valid_counter <= 5'd23;
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

    always @(posedge clkrv) begin
        if (mem_valid_slow) begin
            if (mem_wstrb)
                mem[mem_addr[6:0]] <= mem_wdata;
            else
                mem_rdata <= mem[mem_addr[6:0]];
            mem_ready <= 1'b1;
        end
        else begin
            mem_ready <= 1'b0;
        end
    end
    
    integer i;
    
    reg [7:0] i_in_reg;

	// Instantiate the Unit Under Test (UUT)
	rv_vbc_ddr_arbiter uut (
		.rst(rst), 
		.clkrv(clkrv), 
		.clkgb(clkgb), 
		.rv_addr(rv_addr), 
		.rv_wdata(rv_wdata), 
		.rv_rdata(rv_rdata), 
		.rv_wstrb(rv_wstrb), 
		.rv_valid(rv_valid), 
		.rv_ready(rv_ready), 
		.ddr_addr(sys_addr), 
		.ddr_wdata(sys_wdata), 
		.ddr_rdata(sys_rdata), 
		.ddr_wstrb(sys_wstrb), 
		.ddr_valid(sys_valid), 
		.ddr_ready(sys_ready), 
		.vb_a(vb_a), 
		.vb_din(vb_din), 
		.vb_dout(vb_dout), 
		.vb_rd(vb_rd), 
		.vb_wr(vb_wr)
	);

    reg [7:0]rv_test_addr;
    wire [7:0]rv_test_addr_b = ~rv_test_addr;
    reg rv_test_ready;
    reg [9:0]gb_test_addr;
    wire [9:0]gb_test_addr_b = ~gb_test_addr;
    reg gb_test_ready;
    
	initial begin
		// Initialize Inputs
		rst = 1;
		clkrv = 0;
		clkgb = 0;
		rv_addr = 0;
		rv_wdata = 0;
		rv_wstrb = 0;
		rv_valid = 0;
		vb_a = 0;
		vb_dout = 0;
		vb_rd = 0;
		vb_wr = 0;

        for (i = 0; i < 128; i = i + 1) begin
            mem[i] = 0;
        end
        
        rv_test_addr = 0;
        gb_test_addr = 0;
        rv_test_ready = 0;
        gb_test_ready = 0;

		// Wait 100 ns for global reset to finish
		#100;
        rst = 0;
        
        #15000;
        
		// Add stimulus here
	end
    
    always begin
        #5 clkrv = !clkrv;
    end
    
    always begin
        #125 clkgb = !clkgb;
    end
    
    always begin
        #100
        
        rv_addr = {15'd0, rv_test_addr, 2'd0};
        rv_wdata = {rv_test_addr, rv_test_addr, rv_test_addr, rv_test_addr};
        rv_wstrb = 4'b1111;
        rv_valid = 1;
        rv_valid = 1'b1;
        wait(rv_ready == 1'b1);
        
        rv_valid = 1'b0;
        wait(rv_ready == 1'b0);
    
        #100
    
        rv_addr = {14'd1024, 1'b0, rv_test_addr_b, 2'd0};
        rv_wstrb = 0;
        rv_valid = 1;
        wait(rv_ready == 1'b1);
        
        /*if (rv_rdata != {rv_test_addr_b, rv_test_addr_b, rv_test_addr_b, rv_test_addr_b})
            if (rv_test_ready) begin
                $display("INCORRECT RV DATA!");
                $stop;
            end*/
        
        rv_valid = 1'b0;
        wait(rv_ready == 1'b0);
    
        rv_test_addr = rv_test_addr + 1;
        if ((rv_test_addr == 255) && (rv_test_ready != 1)) begin
            rv_test_ready = 1;
            $display("RV TEST READY");
        end
    end
    
    always begin
        /*#500
    
        vb_a = {13'd1, gb_test_addr};
        vb_dout = gb_test_addr[7:0];
        vb_wr = 1'b1;
        
        #500
        
        vb_wr = 1'b0;*/
        
        #500
    
        vb_a = {12'd1024, 1'b1, gb_test_addr_b};
        vb_rd = 1'b1;
        
        #500 // VB would wait for 500 ns for completion
        
        /*if (vb_din != gb_test_addr_b[7:0])
            if (gb_test_ready)
                $display("INCORRECT VB DATA!");*/
        
        vb_rd = 1'b0;
       
        gb_test_addr = gb_test_addr + 1;
        if ((gb_test_addr == 1023) && (gb_test_ready != 1)) begin
            gb_test_ready = 1;
            $display("VB TEST READY");
        end
    end
      
endmodule

