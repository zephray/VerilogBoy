`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:38:54 03/02/2019
// Design Name:   mig_picorv_bridge
// Module Name:   C:/Users/Wenting/Documents/GitHub/VerilogBoy/target/panog1/fpga/cache_testbench_with_rv.v
// Project Name:  panog1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: mig_picorv_bridge
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module cache_testbench_with_rv;

// Inputs
	reg clk;
	reg rst;
	//reg [24:0] sys_addr;
	//reg [31:0] sys_wdata;
	//reg [3:0] sys_wstrb;
	//reg sys_valid;
	wire [127:0] mem_rdata;
	reg mem_ready;

	// Outputs
	//wire [31:0] sys_rdata;
	wire ddr_ready;
	wire [20:0] mem_addr;
	wire [127:0] mem_wdata;
	wire mem_wstrb;
	wire mem_valid;
    wire [24:0] ddr_addr;
    
    wire sys_valid;
    wire sys_instr;
    wire sys_ready;
    wire [31:0] sys_addr;
    wire [31:0] sys_wdata;
    wire [3:0] sys_wstrb;
    wire [31:0] sys_rdata;
    wire [31:0] ddr_rdata;
    wire [31:0] sys_la_addr;
    wire ddr_valid;

	// Instantiate the Unit Under Test (UUT)
	ddr_cache uut (
		.clk(clk), 
		.rst(rst), 
		.sys_addr(ddr_addr), 
		.sys_wdata(sys_wdata), 
		.sys_rdata(ddr_rdata), 
		.sys_wstrb(sys_wstrb), 
		.sys_valid(ddr_valid), 
		.sys_ready(ddr_ready), 
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
    
    // 4 KB memory space
    reg [127:0] mem [0: 255];
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
    reg [127:0] mem_rdata_tr;
    wire [127:0] mem_wdata_tr = 
        {mem_wdata[7:0], mem_wdata[15:8], mem_wdata[23:16], mem_wdata[31:24], 
        mem_wdata[39:32], mem_wdata[47:40], mem_wdata[55:48], mem_wdata[63:56],
        mem_wdata[71:64], mem_wdata[79:72], mem_wdata[87:80], mem_wdata[95:88], 
        mem_wdata[103:96], mem_wdata[111:104], mem_wdata[119:112], mem_wdata[127:120]};
    assign mem_rdata = 
        {mem_rdata_tr[7:0], mem_rdata_tr[15:8], mem_rdata_tr[23:16], mem_rdata_tr[31:24], 
        mem_rdata_tr[39:32], mem_rdata_tr[47:40], mem_rdata_tr[55:48], mem_rdata_tr[63:56],
        mem_rdata_tr[71:64], mem_rdata_tr[79:72], mem_rdata_tr[87:80], mem_rdata_tr[95:88], 
        mem_rdata_tr[103:96], mem_rdata_tr[111:104], mem_rdata_tr[119:112], mem_rdata_tr[127:120]};

    always @(posedge clk) begin
        if (mem_valid_slow) begin
            if (mem_wstrb)
                mem[mem_addr] <= mem_wdata_tr;
            else
                mem_rdata_tr <= mem[mem_addr];
            mem_ready <= 1'b1;
        end
        else begin
            mem_ready <= 1'b0;
        end
    end
    
    // ----------------------------------------------------------------------
    // PicoRV32
    
    // Memory Map
    // 00000000 - 000007FF Internal RAM  (2KB)
    // 01000000 - 0103FFFF SPI Flash ROM (256KB)
    // 03000000 - 03000100 GPIO          See description below
    // 08000000 - 08000FFF Video RAM     (4KB)
    // 0C000000 - 0BFFFFFF LPDDR SDRAM   (32MB)
    parameter integer MEM_WORDS = 1024;
    parameter [31:0] STACKADDR = (4*MEM_WORDS);      // end of memory
    parameter [31:0] PROGADDR_RESET = 32'h0C000000; // start of the DDR
    
    wire la_addr_in_ram = (sys_la_addr < 4*MEM_WORDS);
    wire la_addr_in_vram = (sys_la_addr >= 32'h08000000) && (sys_la_addr < 32'h08004000);
    wire la_addr_in_gpio = (sys_la_addr >= 32'h03000000) && (sys_la_addr < 32'h03000100);
    wire la_addr_in_ddr = (sys_la_addr >= 32'h0C000000) && (sys_la_addr < 32'h0E000000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_gpio;
    reg addr_in_ddr;
    
    always@(posedge clk) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_ddr <= la_addr_in_ddr;
    end
    
    reg default_ready;
    
    always @(posedge clk) begin
        default_ready <= sys_valid;
    end
    
    assign sys_ready = (addr_in_ddr) ? (ddr_ready) : (default_ready);
    
    wire ram_valid = (sys_valid) && (!sys_ready) && (addr_in_ram);
    wire vram_valid = (sys_valid) && (!sys_ready) && (addr_in_vram);
    wire gpio_valid = (sys_valid) && (!sys_ready) && (addr_in_gpio);
    assign ddr_valid = (sys_valid) && (addr_in_ddr);
    
    assign ddr_addr = sys_addr[24:0];
    
    wire rst_rv_pre = rst;
    reg rst_rv;
    reg [3:0] rst_counter;
    
    always @(posedge clk)
    begin
        if (rst_rv_pre) begin
            rst_rv <= 0;
            rst_counter <= 4'd0;
        end
        else begin
            if (rst_counter == 4'd15)
                rst_rv <= 1;
            else
                rst_counter <= rst_counter + 1;
        end
    end
    
    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET)
    ) cpu (
        .clk(clk),
        .resetn(rst_rv),
        .mem_valid(sys_valid),
        .mem_instr(sys_instr),
        .mem_ready(sys_ready),
        .mem_addr(sys_addr),
        .mem_wdata(sys_wdata),
        .mem_wstrb(sys_wstrb),
        .mem_rdata(sys_rdata),
        .mem_la_addr(sys_la_addr),
        .irq({32'b0})
    );
    
    // Internal RAM & Boot ROM
    wire [31:0] ram_rdata;
    picosoc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk),
        .wen(ram_valid ? sys_wstrb : 4'b0),
        .addr(sys_addr[23:2]),
        .wdata(sys_wdata),
        .rdata(ram_rdata)
    );
    
    // GPIO
    // 03000000 (0) - R: delay_sel_det / W: delay_sel_val
    // 03000004 (1) - W: led_green
    // 03000008 (2) - W: led_red
    // 0300000c (3) - W: spi_cs_n
    // 03000010 (4) - W: spi_clk
    // 03000014 (5) - W: spi_do
    // 03000018 (6) - R: spi_di
    // 0300001c (7) - W: usb_rst_n
    
    reg [31:0] gpio_rdata;
    reg led_green;
    reg led_red;
    reg spi_csn;
    reg spi_clk;
    reg spi_do;
    reg usb_rstn;
    
    always@(posedge clk) begin
        if (!rst_rv) begin
            led_green <= 1'b0;
            led_red <= 1'b0;
            spi_csn <= 1'b1;
        end
        else if (gpio_valid)
             if (mem_wstrb != 0) begin
                case (mem_addr[4:2])
                    3'd1: led_green <= mem_wdata[0];
                    3'd2: led_red <= mem_wdata[0];
                    3'd3: spi_csn <= mem_wdata[0];
                    3'd4: spi_clk <= mem_wdata[0];
                    3'd5: spi_do <= mem_wdata[0];
                    3'd7: usb_rstn <= mem_wdata[0];
                endcase
             end
    end
    
    assign sys_rdata = (addr_in_ram) ? (ram_rdata) : ((addr_in_ddr) ? (ddr_rdata) : ((addr_in_gpio) ? (gpio_rdata) : (32'hFFFFFFFF)));

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
        
        $readmemh("picorv_fw.mif", mem, 0, 256-1);

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        rst = 0;
	end
      
endmodule

