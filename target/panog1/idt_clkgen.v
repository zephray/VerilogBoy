module idt_clkgen(
    input wire      clk,
    input wire      rst,

    output wire     idt_iclk,

    output reg      idt_sclk,     
    output reg      idt_data,     
    output reg      idt_strobe,
    
    output reg      idt_ready
    );

    reg [6:0] idt_cntr;
    always @(posedge clk, posedge rst) begin
        if (rst)
            idt_cntr <= 0;
        else begin
            if (&idt_cntr != 1'b1) begin
                idt_cntr <= idt_cntr + 1;
            end
        end
    end

    localparam idt_v   = 9'd335;
    localparam idt_r   = 7'd107;

    localparam idt_s   = 3'b110;    // CLK1 output divide = 3

    localparam idt_f   = 2'b10;     // CLK2 = OFF
    localparam idt_ttl = 1'b1;      // Measure duty cycles at VDD/2
    localparam idt_c   = 2'b00;     // Use clock as ref instead of Xtal

    wire [23:0] idt_config;
    assign idt_config = { idt_c, idt_ttl, idt_f, idt_s, idt_v, idt_r };

    reg [23:0] idt_config_reverse;
    integer i;
    always @(*)
        for(i=0;i<24;i=i+1)
            idt_config_reverse[23-i] = idt_config[i];

    always @(posedge clk, posedge rst) 
    begin
        if (rst) begin
            idt_sclk    <= 1'b0;
            idt_data    <= 1'b0;
            idt_strobe  <= 1'b0;
        end
        else begin
            idt_sclk    <= (idt_cntr < 48) & idt_cntr[0];
            idt_data    <= idt_cntr < 48 ? idt_config_reverse[idt_cntr[5:1]] : 1'b0;
            idt_strobe  <= idt_cntr[5:1] == 31;
        end
    end
    
    reg [15:0] rdy_counter;
    
    always @(posedge clk, posedge rst)
    begin
        if (rst) begin
            idt_ready <= 0;
            rdy_counter <= 16'd0;
        end
        else if (&idt_cntr == 1'b1) begin
            if (rdy_counter == 16'd50000)
                idt_ready <= 1;
            else
                rdy_counter <= rdy_counter + 1;
        end
    end

    assign idt_iclk = clk;

endmodule
