//*****************************************************************************
// DISCLAIMER OF LIABILITY
//
// This file contains proprietary and confidential information of
// Xilinx, Inc. ("Xilinx"), that is distributed under a license
// from Xilinx, and may be used, copied and/or disclosed only
// pursuant to the terms of a valid license agreement with Xilinx.
//
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION
// ("MATERIALS") "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
// EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING WITHOUT
// LIMITATION, ANY WARRANTY WITH RESPECT TO NONINFRINGEMENT,
// MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. Xilinx
// does not warrant that functions included in the Materials will
// meet the requirements of Licensee, or that the operation of the
// Materials will be uninterrupted or error-free, or that defects
// in the Materials will be corrected. Furthermore, Xilinx does
// not warrant or make any representations regarding use, or the
// results of the use, of the Materials in terms of correctness,
// accuracy, reliability or otherwise.
//
// Xilinx products are not designed or intended to be fail-safe,
// or for use in any application requiring fail-safe performance,
// such as life-support or safety devices or systems, Class III
// medical devices, nuclear facilities, applications related to
// the deployment of airbags, or any other applications that could
// lead to death, personal injury or severe property or
// environmental damage (individually and collectively, "critical
// applications"). Customer assumes the sole risk and liability
// of any use of Xilinx products in critical applications,
// subject only to applicable laws and regulations governing
// limitations on product liability.
//
// Copyright 2005, 2006, 2007 Xilinx, Inc.
// All rights reserved.
//
// This disclaimer and copyright notice must be retained as part
// of this file at all times.
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor             : Xilinx
// \   \   \/    Version            : 3.6.1
//  \   \        Application	    : MIG
//  /   /        Filename           : mig_ram8d_0.v
// /___/   /\    Date Last Modified : $Date: 2010/11/26 18:25:43 $
// \   \  /  \   Date Created       : Mon May 2 2005
//  \___\/\___\
// Device       : Spartan-3/3E/3A/3A-DSP
// Design Name  : DDR SDRAM
// Purpose      : This module instantiates RAM16X1 premitives.
//                There will be 8 or 4 RAM16X1 instances depending on the number
//                of data bits per strobe.
//*****************************************************************************

`timescale 1ns/100ps
`include "mig_parameters_0.v"

module mig_ram8d_0
  (
   output wire [(`DATABITSPERREADCLOCK -1):0] dout,
   input wire [3:0]                           waddr,
   input wire [(`DATABITSPERREADCLOCK -1):0]  din,
   input wire [3:0]                           raddr,
   input wire                                 wclk0,
   input wire                                 wclk1,
   input wire                                 we
   );


   RAM16X1D fifo_bit0
     (
      .DPO   (dout[0]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[0]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk1),
      .WE    (we)
      );

   RAM16X1D fifo_bit1
     (
      .DPO   (dout[1]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[1]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk0),
      .WE    (we)
      );

   RAM16X1D fifo_bit2
     (
      .DPO   (dout[2]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[2]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk1),
      .WE    (we)
      ); 

   RAM16X1D fifo_bit3
     (
      .DPO   (dout[3]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[3]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk0),
      .WE    (we)
      );

   RAM16X1D fifo_bit4
     (
      .DPO   (dout[4]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[4]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk1),
      .WE    (we)
      );

   RAM16X1D fifo_bit5
     (
      .DPO   (dout[5]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[5]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk0),
      .WE    (we)
      );

   RAM16X1D fifo_bit6
     (
      .DPO   (dout[6]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[6]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk1),
      .WE    (we)
      );

   RAM16X1D fifo_bit7
     (
      .DPO   (dout[7]),
      .A0    (waddr[0]),
      .A1    (waddr[1]),
      .A2    (waddr[2]),
      .A3    (waddr[3]),
      .D     (din[7]),
      .DPRA0 (raddr[0]),
      .DPRA1 (raddr[1]),
      .DPRA2 (raddr[2]),
      .DPRA3 (raddr[3]),
      .SPO   (),
      .WCLK  (wclk0),
      .WE    (we)
      );

endmodule
