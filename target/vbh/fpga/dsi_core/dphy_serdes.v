/* 
 * DSI Core
 * Copyright (C) 2013-2014 twl <twlostow@printf.cc>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

`timescale 1ps/1ps

/* dphy_serdes.v - the DSI SerDes, based on Xilinx IOSERDES primitves. */

// Bank0: BUFPLL_X1Y5, BUFPLL_X1Y4
// Bank1: BUFPLL_X2Y2, BUFPLL_X2Y3
// Bank2: BUFPLL_X1Y0, BUFPLL_X1Y1
// Bank3: BUFPLL_X0Y2, BUFPLL_X0Y3

module dphy_serdes_plla (
                        input  clk_phy_i,
                        input  clk_dsi_i,
                        input  rst_n_a_i,

                        input  locked_i,
                        output locked_o,
                        output clk_serdes_o,
                        output serdes_strobe_o );

    (* LOC = "BUFPLL_X0Y3" *)
    BUFPLL
        #(.DIVIDE      (8))
    U_BufPLL
     (.IOCLK        (clk_serdes_o),
      .LOCK         (locked_o),
      .SERDESSTROBE (serdes_strobe_o),
      .GCLK         (clk_dsi_i),
      .LOCKED       (locked_i),
      .PLLIN        (clk_phy_i));

endmodule // dphy_serdes_pll

module dphy_serdes_pllb (
                        input  clk_phy_i,
                        input  clk_dsi_i,
                        input  rst_n_a_i,

                        input  locked_i,
                        output locked_o,
                        output clk_serdes_o,
                        output serdes_strobe_o );

   (* LOC = "BUFPLL_X0Y2" *)
   BUFPLL
     #(.DIVIDE        (8))
   U_BufPLL
     (.IOCLK        (clk_serdes_o),
      .LOCK         (locked_o),
      .SERDESSTROBE (serdes_strobe_o),
      .GCLK         (clk_dsi_i),
      .LOCKED       (locked_i),
      .PLLIN        (clk_phy_i));

endmodule // dphy_serdes_pll



module dphy_serdes #(
                     parameter g_delay = 0)
   (
    input 	clk_serdes_i,
    input 	clk_word_i,
    input 	rst_n_a_i,
    input 	strobe_i,
    input 	oe_i,
   
    input [7:0] d_i,
   
    output 	q_p_o,
    output 	q_n_o,
    
    output  tq_o
    );

   wire 	tq_int;
   wire 	dout_int, dout_predelay;
   wire 	ms_d, ms_t, sm_d, sm_t;
   
   assign   tq_o = tq_int;

   OSERDES2
     #(.DATA_RATE_OQ   ("SDR"),
       .DATA_RATE_OT   ("SDR"),
       .TRAIN_PATTERN  (0),
       .DATA_WIDTH     (8),
       .SERDES_MODE    ("MASTER"),
       .OUTPUT_MODE    ("DIFFERENTIAL"))
   U_Master (
	     .CLK0       (clk_serdes_i),
             .CLK1       (1'b0),
             .CLKDIV     (clk_word_i),
             .D1         (d_i[4]),
             .D2         (d_i[5]),
             .D3         (d_i[6]),
             .D4         (d_i[7]),
             .T1         (oe_i),
             .T2         (oe_i),
             .T3         (oe_i),
             .T4         (oe_i),
             .SHIFTIN1   (1'b1),
             .SHIFTIN2   (1'b1),
             .SHIFTIN3   (sm_d),
             .SHIFTIN4   (sm_t),
             .SHIFTOUT1  (ms_d),
             .SHIFTOUT2  (ms_t),
             .TRAIN      (1'b0),
             .OCE        (1'b1),
             .OQ         (dout_predelay),
             .TQ         (tq_int),
             .IOCE       (strobe_i),
             .TCE        (1'b1),
             .RST        (~rst_n_a_i));


   OSERDES2
     #(.DATA_RATE_OQ   ("SDR"),
       .DATA_RATE_OT   ("SDR"),
       .DATA_WIDTH     (8),
       .SERDES_MODE    ("SLAVE"),
       .TRAIN_PATTERN  (0),
       .OUTPUT_MODE    ("DIFFERENTIAL"))
   U_Slave
     (.CLK0       (clk_serdes_i),
      .CLK1       (1'b0),
      .CLKDIV     (clk_word_i),
      .D1         (d_i[0]),
      .D2         (d_i[1]),
      .D3         (d_i[2]),
      .D4         (d_i[3]),
      .T1         (oe_i),
      .T2         (oe_i),
      .T3         (oe_i),
      .T4         (oe_i),
      .SHIFTIN1   (ms_d),
      .SHIFTIN2   (ms_t),
      .SHIFTIN3   (1'b1),
      .SHIFTIN4   (1'b1),
      .SHIFTOUT3  (sm_d),
      .SHIFTOUT4  (sm_t),
      .TRAIN      (1'b0),
      .OCE        (1'b1),
      .IOCE       (strobe_i),
      .TCE        (1'b1),
      .RST        (~rst_n_a_i));

   

   IODELAY2
     #(.DATA_RATE                  ("SDR"),
       .ODELAY_VALUE               (g_delay),
       .COUNTER_WRAPAROUND         ("STAY_AT_LIMIT"),
       .DELAY_SRC                  ("ODATAIN"),
       .SERDES_MODE                ("NONE"),
       .SIM_TAPDELAY_VALUE         (50))
   U_IODelay
     (
      // required datapath
      .T                      (1'b0),
      .DOUT                   (dout_int),
      .ODATAIN                (dout_predelay),
      // inactive data connections
      .IDATAIN                (1'b0),
      // connect up the clocks
      .IOCLK0                 (1'b0),                 // No calibration needed
      .IOCLK1                 (1'b0),                 // No calibration needed
      // Tie of the variable delay programming
      .CAL                    (1'b0),
      .INC                    (1'b0),
      .CE                     (1'b0),
      .RST                    (~rst_n_a_i));

   OBUFTDS
     #(.IOSTANDARD ("DIFF_HSTL_I_18"))
   U_Tristate
     (.O          (q_p_o),
      .OB         (q_n_o),
      .T          (tq_int),
      .I          (dout_int));

endmodule
