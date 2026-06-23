// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module rgb_off (
    // RGB0
    output wire rgb0_r,
    output wire rgb0_g,
    output wire rgb0_b,

    // RGB1
    output wire rgb1_r,
    output wire rgb1_g,
    output wire rgb1_b
);

	// RGB0
	assign rgb0_r = 1'b1; // R
	assign rgb0_g = 1'b1; // G
	assign rgb0_b = 1'b1; // B

	// RGB1
	assign rgb1_r = 1'b1; // R
	assign rgb1_g = 1'b1; // G
	assign rgb1_b = 1'b1; // B

endmodule
