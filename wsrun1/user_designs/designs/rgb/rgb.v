// SPDX-FileCopyrightText: © 2025 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module rgb (
    // Switches
    input wire sw0,
    input wire sw1,
    input wire sw2,
    input wire sw3,
  
    // RGB0
    output wire rgb0_r,
    output wire rgb0_g,
    output wire rgb0_b,

    // RGB1
    output wire rgb1_r,
    output wire rgb1_g,
    output wire rgb1_b
);

    wire clk;
    (* keep *) Global_Clock clk_i (.CLK(clk));

    assign rgb0_r = sw0 ^ sw3;
    assign rgb0_g = sw1 ^ sw3;
    assign rgb0_b = sw2 ^ sw3;

    assign rgb1_r = sw0 ^ sw3;
    assign rgb1_g = sw1 ^ sw3;
    assign rgb1_b = sw2 ^ sw3;

endmodule
