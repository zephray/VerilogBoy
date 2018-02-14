/**
 * A button module.
 * 
 * The module asserts pressed for one clock edge when button_input is asserted,
 * and then refuses to accept additional input from button_input for a period of
 * time specified by delay_seconds.
 * 
 * @parameter delay_cycles The number of cycles to delay before accepting
 *    another button press.
 * @parameter delay_cycles_width [Calculated] The width of the internal cycle
 *    counter.
 * @output pressed Asserted on button down.
 * @input button_input The button signal.
 * @input clock The posedge clock signal.
 * @input reset The posedge reset signal.
 */
module button(/*AUTOARG*/
   // Outputs
   pressed, pressed_disp,
   // Inputs
   button_input, clock, reset
   );
   parameter
     // Inputs
//     frequency_hz = 100000000,
//     delay_seconds = 0.02,
     // Calculated
     delay_cycles = 200000,
     delay_cycles_width = log2(delay_cycles);
   output reg pressed, pressed_disp;
   input      button_input;
   input      clock, reset;

   reg [delay_cycles_width-1:0] count, next_count;
   reg [1:0]                    state, next_state;

   reg                          next_pressed;
   
`define button_idle 2'd0
`define button_down 2'd1
`define button_wait 2'd2

   always @(*) begin
      next_pressed = 1'b0;
      pressed_disp = 1'b0;
      next_count = count;
      next_state = `button_idle;
      case(state)
        `button_idle: begin
           if (button_input) begin
              next_state = `button_down;
              next_pressed = 1'b1;
           end else begin
              next_state = `button_idle;
           end
        end
        `button_down: begin
           pressed_disp = 1'b1;
           if (button_input) begin
              next_state = `button_down;
           end else begin
              next_state = `button_wait;
           end
        end
        `button_wait: begin
           pressed_disp = 1'b1;
           if (count >= delay_cycles[delay_cycles_width-1:0]) begin
              next_state = `button_idle;
              next_count = {delay_cycles_width{1'b0}};
           end else begin
              next_state = `button_wait;
              next_count = count + {{delay_cycles_width-1{1'b0}}, 1'b1};
           end
        end
      endcase
   end
   
   always @(posedge clock or posedge reset) begin
      if (reset) begin
         state <= `button_idle;
         count <= {delay_cycles_width{1'b0}};
         pressed <= 1'b0;
      end else begin
         state <= next_state;
         count <= next_count;
         pressed <= next_pressed;
      end
      
   end

   function integer log2;
      input integer value;
      begin
         value = value-1;
         for (log2 = 0; value > 0; log2 = log2 + 1) begin
           value = value >> 1;
         end
      end
   endfunction
   
endmodule // button
