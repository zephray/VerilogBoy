module simple_uart(
    input wire clk,
    input wire rst,
    input wire wstrb,
    output reg ready,
    input wire [7:0] dat,
    output wire txd
    );

    // 100MHz 115200 / 50MHz 57600: 868 - 1
    //localparam UART_DIV = 10'd867;
    
    // 100MHz 230400 / 50MHz 115200: 434 - 1
    //localparam UART_DIV = 10'd433;

    // 50MHz 230400 / 25MHz 115200: 217 - 1
    localparam UART_DIV = 10'd216;

    reg [9:0] counter;
    reg [3:0] tx_count;
    reg last_wstrb;
    reg [10:0] shift_reg;
    always@(posedge clk) begin
        if (rst) begin
            counter <= UART_DIV;
            tx_count <= 0;
            ready <= 1'b0;
            shift_reg <= 11'b11111111111;
        end
        else
            if (counter != 10'd0) begin
                counter <= counter - 1;
                last_wstrb <= wstrb;
                ready <= 1'b0;
                if (!last_wstrb && wstrb) begin
                              // Stop, Data, Start, Idle
                    shift_reg <= {1'b1, dat, 1'b0, 1'b1};
                    tx_count <= 4'd11;
                end
            end
            else begin
                shift_reg <= {1'b1, shift_reg[10:1]};
                counter <= UART_DIV;
                if (tx_count != 0)
                    tx_count <= tx_count - 1;
                if (tx_count == 1)
                    ready <= 1'b1; // ready only pulse 1 clock
            end
    end
    
    assign txd = shift_reg[0];

endmodule
