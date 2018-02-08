`timescale 1 ns / 100 ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: The Fighting Meerkat
// 
// Create Date:    12:30:35 11/11/2013 
// Design Name: 
// Module Name:    iic_init 
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
module iic_init(//Outputs
					 Done,
					 //Inouts
					 SDA, SCL,
					 //Inputs
					 Clk, Reset, Pixel_clk_greater_than_65Mhz);
	//Outputs
	output Done;

	//Inouts
	inout SDA, SCL;

	//Inputs                 
	input Clk, Reset, Pixel_clk_greater_than_65Mhz;

	parameter CLK_RATE_MHZ = 200,
				 SCK_PERIOD_US = 30,
				 TRANSITION_CYCLE = (CLK_RATE_MHZ * SCK_PERIOD_US) / 2,
				 TRANSITION_CYCLE_MSB = 11;
            
	localparam IDLE = 3'd0,
				  INIT = 3'd1,
				  START = 3'd2,
				  CLK_FALL = 3'd3,
				  SETUP = 3'd4,
				  CLK_RISE = 3'd5,
				  WAIT = 3'd6,
				  START_BIT = 1'b1,
				  SLAVE_ADDR= 7'b1110110,
				  ACK = 1'b1,
				  WRITE = 1'b0,
				  REG_ADDR0 = 8'h49,
				  REG_ADDR1 = 8'h21,
				  REG_ADDR2 = 8'h33,
				  REG_ADDR3 = 8'h34,
				  REG_ADDR4 = 8'h36,
				  DATA0 = 8'hC0,			  
				  DATA1 = 8'h09,
				  DATA2a = 8'h06,
				  DATA3a = 8'h26,
				  DATA4a = 8'hA0,
				  DATA2b = 8'h08,
				  DATA3b = 8'h16,
				  DATA4b = 8'h60,
				  STOP_BIT=1'b0,
				  SDA_BUFFER_MSB=27;

	reg SDA_out;
	reg SCL_out;
	reg [TRANSITION_CYCLE_MSB:0] cycle_count;
	reg [2:0] c_state;
	reg [2:0] n_state;
	reg Done;
	reg [2:0] write_count;
	reg [31:0] bit_count;
	reg [SDA_BUFFER_MSB:0] SDA_BUFFER;
	wire transition;
	
	always @ (posedge Clk) begin
		if (Reset||c_state==IDLE ) begin
			SDA_out <= 1'b1;
			SCL_out <=1'b1;
		end
		else if (c_state==INIT && transition) //begin
			SDA_out <=1'b0;
		//end
		else if (c_state==SETUP) //begin
			SDA_out <=SDA_BUFFER[SDA_BUFFER_MSB];
		//end
		else if (c_state==CLK_RISE && 
					cycle_count==TRANSITION_CYCLE/2 && 
					bit_count==SDA_BUFFER_MSB) //begin
			SDA_out <= 1'b1;
		//end
		else if (c_state==CLK_FALL) //begin
			SCL_out <=1'b0;
		//end
    
		else if (c_state==CLK_RISE) //begin
			SCL_out <=1'b1;
		//end
	end

//OBUFT_LVCMOS33 sda0(.O(SDA), .I(1'b0), .T(SDA_out));
//OBUFT_LVCMOS33 scl0(.O(SCL), .I(1'b0), .T(SCL_out));
	assign SDA = SDA_out;
	assign SCL = SCL_out;
 
	always @ (posedge Clk) begin
		//reset or end condition
		if(Reset) begin
			SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR0,ACK,DATA0,ACK,STOP_BIT};
			cycle_count<=0;
		end
		//setup sda for sck rise
		else if ( c_state==SETUP && cycle_count==TRANSITION_CYCLE)begin
			SDA_BUFFER <= {SDA_BUFFER[SDA_BUFFER_MSB-1:0],1'b0};
			cycle_count<=0;
		end
		//reset count at end of state
		else if ( cycle_count==TRANSITION_CYCLE)
			cycle_count<=0;
		//reset sda_buffer
		else if (c_state==WAIT && Pixel_clk_greater_than_65Mhz )begin
			case(write_count)
				0:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR1,ACK,DATA1,ACK,STOP_BIT};
				1:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR2,ACK,DATA2a,ACK,STOP_BIT};
				2:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR3,ACK,DATA3a,ACK,STOP_BIT};
				3:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR4,ACK,DATA4a,ACK,STOP_BIT};
				default: SDA_BUFFER <=28'dx;
			endcase
			cycle_count<=cycle_count+1;
		end
		else if (c_state==WAIT && ~Pixel_clk_greater_than_65Mhz )begin
			case(write_count)
				0:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR1,ACK,DATA1,ACK,STOP_BIT};
				1:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR2,ACK,DATA2b,ACK,STOP_BIT};
				2:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR3,ACK,DATA3b,ACK,STOP_BIT};
				3:SDA_BUFFER <= {SLAVE_ADDR,WRITE,ACK,REG_ADDR4,ACK,DATA4b,ACK,STOP_BIT};
				default: SDA_BUFFER <=28'dx;
			endcase
			cycle_count<=cycle_count+1;
		end
		else
			cycle_count<=cycle_count+1;
	end

	always @ (posedge Clk) begin
		if(Reset)
			write_count<=3'd0;
		else if (c_state==WAIT && cycle_count==TRANSITION_CYCLE)
			write_count<=write_count+1;
	end
  
	always @ (posedge Clk) begin
		if(Reset)
			Done<=1'b0;
		else if (c_state==IDLE)
			Done<=1'b1;
	end
           
	always @ (posedge Clk) begin
		if(Reset||(c_state==WAIT))
			bit_count<=0;
		else if ( c_state==CLK_RISE && cycle_count==TRANSITION_CYCLE)
			bit_count<=bit_count+1;
	end

	always @ (posedge Clk) begin
		if(Reset)
			c_state<=INIT;
		else
			c_state<=n_state;
	end

	assign transition = (cycle_count==TRANSITION_CYCLE);
              
	//Next state
	always @ (*) begin
		case(c_state)
			IDLE: begin
				if(Reset) n_state = INIT;
				else n_state = IDLE;
			end
			INIT: begin
				if (transition) n_state = START;
				else n_state = INIT;
			end
			START: begin
				if(Reset) n_state = INIT;
				else if( transition) n_state = CLK_FALL;
				else n_state = START;
			end
			CLK_FALL: begin
				if(Reset) n_state = INIT;
				else if( transition) n_state = SETUP;
				else n_state = CLK_FALL;
			end
			SETUP: begin
				if(Reset) n_state = INIT;
				else if( transition) n_state = CLK_RISE;
				else n_state = SETUP;
			end
			CLK_RISE: begin
				if(Reset) n_state = INIT;
				else if( transition && bit_count==SDA_BUFFER_MSB)
					n_state = WAIT;
				else if (transition ) n_state = CLK_FALL;
				else n_state = CLK_RISE;
			end
			WAIT: begin
				if(Reset|(transition && write_count!=3'd4))
					n_state = INIT;
				else if (transition ) n_state = IDLE;
				else n_state = WAIT;
			end
			default: n_state = IDLE;
		endcase
	end

endmodule
