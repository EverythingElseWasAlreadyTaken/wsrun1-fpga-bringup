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
	
	// RGB0
	assign io_out[15] = 1'b1; // R
	assign io_out[16] = 1'b1; // G
	assign io_out[14] = 1'b1; // B

	// RGB1
	assign io_out[18] = 1'b1; // R
	assign io_out[19] = 1'b1; // G
	assign io_out[17] = 1'b1; // B

endmodule
