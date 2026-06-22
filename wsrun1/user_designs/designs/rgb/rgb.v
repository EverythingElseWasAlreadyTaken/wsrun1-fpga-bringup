// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module top(
    input  wire        clk,
    input  wire [`NUM_IO-1:0] io_in,
    output wire [`NUM_IO-1:0] io_out,
    output wire [`NUM_IO-1:0] io_oeb
);

  // Tie low
	assign io_out[13:0] = '0;
	assign io_out[`NUM_IO-1:20] = '0;
	
	// RGB = output, everything else = input
	assign io_oeb[13:0] = '1;
	assign io_oeb[19:14] = '0;
	assign io_oeb[`NUM_IO-1:20] = '1;
	
	wire sw0, sw1, sw2, sw3;
	
	assign sw0 = io_in[2];
  assign sw1 = io_in[3];
  assign sw2 = io_in[4];
  assign sw3 = io_in[5];
	
	wire rgb0_r, rgb0_g, rgb0_b;
	wire rgb1_r, rgb1_g, rgb1_b;
	
	/*always (posedge clk) begin
	    if (rst) begin
	end*/
	
	assign rgb0_r = sw0 ^ sw3;
	assign rgb0_g = sw1 ^ sw3;
	assign rgb0_b = sw2 ^ sw3;
	
	assign rgb1_r = sw0 ^ sw3;
	assign rgb1_g = sw1 ^ sw3;
	assign rgb1_b = sw2 ^ sw3;
	
	// RGB0
	assign io_out[15] = rgb0_r; // R
	assign io_out[16] = rgb0_g; // G
	assign io_out[14] = rgb0_b; // B

	// RGB1
	assign io_out[18] = rgb1_r; // R
	assign io_out[19] = rgb1_g; // G
	assign io_out[17] = rgb1_b; // B

endmodule
