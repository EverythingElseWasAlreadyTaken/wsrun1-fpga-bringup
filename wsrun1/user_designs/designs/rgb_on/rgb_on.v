// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module rgb_on (
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
	assign rgb0_r = 1'b0; // R
	assign rgb0_g = 1'b0; // G
	assign rgb0_b = 1'b0; // B

	// RGB1
	assign rgb1_r = 1'b0; // R
	assign rgb1_g = 1'b0; // G
	assign rgb1_b = 1'b0; // B

endmodule
