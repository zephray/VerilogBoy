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
	wire [127:0] fakeddr_rdata;
	reg fakeddr_ready;

	// Outputs
	//wire [31:0] sys_rdata;
	wire ddr_ready;
	wire [20:0] fakeddr_addr;
	wire [127:0] fakeddr_wdata;
	wire fakeddr_wstrb;
	wire fakeddr_valid;
    wire [24:0] ddr_addr;
    
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire [31:0] ddr_rdata;
    wire [31:0] mem_la_addr;
    wire ddr_valid;

	// Instantiate the Unit Under Test (UUT)
	ddr_cache uut (
		.clk(clk), 
		.rst(rst), 
		.sys_addr(ddr_addr), 
		.sys_wdata(mem_wdata), 
		.sys_rdata(ddr_rdata), 
		.sys_wstrb(mem_wstrb), 
		.sys_valid(ddr_valid), 
		.sys_ready(ddr_ready), 
		.mem_addr(fakeddr_addr), 
		.mem_wdata(fakeddr_wdata), 
		.mem_rdata(fakeddr_rdata), 
		.mem_wstrb(fakeddr_wstrb), 
		.mem_valid(fakeddr_valid), 
		.mem_ready(fakeddr_ready)
	);
    
    // Clock
    always
        #5 clk = !clk;
    
    // 8 KB fakeddr memory space
    reg [127:0] fakeddr [0: 131072 - 1];
    reg last_fakeddr_valid;
    reg fakeddr_valid_slow;
    wire fakeddr_valid_gated;
    reg [2:0] fakeddr_valid_counter;
    
    // make this memory slower
    always @(posedge clk) begin
        last_fakeddr_valid <= fakeddr_valid;
        if (!last_fakeddr_valid && fakeddr_valid) begin
            fakeddr_valid_counter <= 3'd7;
        end
        else if (!fakeddr_valid) begin
            fakeddr_valid_slow <= 1'b0;
            fakeddr_valid_counter <= 1'b0; // disable
        end
        else if ((fakeddr_valid_counter != 0)&&(fakeddr_valid_counter != 1)) begin
            fakeddr_valid_counter <= fakeddr_valid_counter - 1;
        end
        else if (fakeddr_valid_counter == 1) begin
            fakeddr_valid_slow <= 1'b1;
        end
    end
    
    assign fakeddr_valid_gated = fakeddr_valid_slow & fakeddr_valid;
    reg [127:0] fakeddr_rdata_tr;
    wire [127:0] fakeddr_wdata_tr = 
        {fakeddr_wdata[7:0], fakeddr_wdata[15:8], fakeddr_wdata[23:16], fakeddr_wdata[31:24], 
        fakeddr_wdata[39:32], fakeddr_wdata[47:40], fakeddr_wdata[55:48], fakeddr_wdata[63:56],
        fakeddr_wdata[71:64], fakeddr_wdata[79:72], fakeddr_wdata[87:80], fakeddr_wdata[95:88], 
        fakeddr_wdata[103:96], fakeddr_wdata[111:104], fakeddr_wdata[119:112], fakeddr_wdata[127:120]};
    assign fakeddr_rdata = 
        {fakeddr_rdata_tr[7:0], fakeddr_rdata_tr[15:8], fakeddr_rdata_tr[23:16], fakeddr_rdata_tr[31:24], 
        fakeddr_rdata_tr[39:32], fakeddr_rdata_tr[47:40], fakeddr_rdata_tr[55:48], fakeddr_rdata_tr[63:56],
        fakeddr_rdata_tr[71:64], fakeddr_rdata_tr[79:72], fakeddr_rdata_tr[87:80], fakeddr_rdata_tr[95:88], 
        fakeddr_rdata_tr[103:96], fakeddr_rdata_tr[111:104], fakeddr_rdata_tr[119:112], fakeddr_rdata_tr[127:120]};

    always @(posedge clk) begin
        if (fakeddr_valid_slow) begin
            if (fakeddr_wstrb)
                fakeddr[fakeddr_addr] <= fakeddr_wdata_tr;
            else
                fakeddr_rdata_tr <= fakeddr[fakeddr_addr];
            fakeddr_ready <= 1'b1;
        end
        else begin
            fakeddr_ready <= 1'b0;
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
    parameter [31:0] STACKADDR = 32'hfffffffc;
    parameter [31:0] PROGADDR_IRQ = 32'hffff0010;
    parameter [31:0] PROGADDR_RESET = 32'h0c000000;  // start of the DDR
    
    reg cpu_irq;
    
    wire la_addr_in_ram = (mem_la_addr >= 32'hFFFF0000);
    wire la_addr_in_vram = (mem_la_addr >= 32'h08000000) && (mem_la_addr < 32'h08004000);
    wire la_addr_in_gpio = (mem_la_addr >= 32'h03000000) && (mem_la_addr < 32'h03000100);
    wire la_addr_in_ddr = (mem_la_addr >= 32'h0C000000) && (mem_la_addr < 32'h0E000000);
    wire la_addr_in_uart = (mem_la_addr == 32'h03000100);
    wire la_addr_in_usb = (mem_la_addr >= 32'h04000000) && (mem_la_addr < 32'h04080000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_gpio;
    reg addr_in_ddr;
    reg addr_in_usb;
    reg addr_in_uart;
    
    always@(posedge clk) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_uart <= la_addr_in_uart;
        addr_in_usb <= la_addr_in_usb;
        addr_in_ddr <= la_addr_in_ddr;
    end
    
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire vram_valid = (mem_valid) && (!mem_ready) && (addr_in_vram);
    wire gpio_valid = (mem_valid) && (!mem_ready) && (addr_in_gpio);
    wire uart_valid = (mem_valid) && (!mem_ready) && (addr_in_uart);
    wire usb_valid = (mem_valid) && (!mem_ready) && (addr_in_usb);
    assign ddr_valid = (mem_valid) && (addr_in_ddr);
    wire general_valid = (mem_valid) && (!mem_ready) && (!addr_in_ddr);
    
    assign ddr_addr = mem_addr[24:0];
    
    reg default_ready;
    
    always @(posedge clk) begin
        //default_ready <= ram_valid || vram_valid || gpio_valid || usb_valid || uart_valid;
        default_ready <= general_valid;
    end
    
    always @(posedge clk) begin
        if (uart_valid && mem_wstrb)
            $display("%c", mem_wdata[7:0]);
    end
    
    reg mem_valid_last;
    always @(posedge clk) begin
        if (rst)
            cpu_irq <= 1'b0;
        else begin
            mem_valid_last <= mem_valid;
            if (mem_valid && !mem_valid_last && !(ram_valid || vram_valid || gpio_valid || usb_valid || uart_valid || ddr_valid))
                cpu_irq <= 1'b1;
            //else
            //    cpu_irq <= 1'b0;
        end
    end
    
    wire uart_ready;
    assign mem_ready = ddr_ready || default_ready;
    
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
        .PROGADDR_RESET(PROGADDR_RESET),
        .REGS_INIT_ZERO(1),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .MASKED_IRQ(32'hfffffffe),
        .LATCHED_IRQ(32'hffffffff)
    ) cpu (
        .clk(clk),
        .resetn(rst_rv),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_addr(mem_la_addr),
        .irq({31'b0, cpu_irq})
    );
    
    // Internal RAM & Boot ROM
    wire [31:0] ram_rdata;
    picosoc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk),
        .wen(ram_valid ? mem_wstrb : 4'b0),
        .addr({12'b0, mem_addr[11:2]}),
        .wdata(mem_wdata),
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
            led_red <= 1'b1;
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
    
    assign mem_rdata = (addr_in_ram) ? (ram_rdata) : ((addr_in_ddr) ? (ddr_rdata) : ((addr_in_gpio) ? (gpio_rdata) : (32'hFFFFFFFF)));

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;
        
        $readmemh("picorv_fw.mif", fakeddr, 0, 131072-1);

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
        rst = 0;
	end
      
endmodule

