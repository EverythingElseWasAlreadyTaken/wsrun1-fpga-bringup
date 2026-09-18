// SPDX-License-Identifier: Apache-2.0
//
// Clock timing test. A clk/2 toggle is sampled by two flip-flops: one directly
// (short path) and one through a chain of STAGES pass-through LUT4s that are
// placed at the fabric corners (see Makefile / clk_timing.pcf) so the route is
// as long as possible. Both samples are XORed: 0 while timing holds, 1 once the
// long path exceeds one clock period. Sweep the clock (clk.py) and watch:
//   rgb0 red / pico0 : live XOR          rgb1 red / pico1 : sticky error
// The sticky error is cleared by sw0 or by pico5 (driven by the Pico, see utils.find_fmax).

`default_nettype none

`ifndef STAGES
`define STAGES 32
`endif

module clk_timing #(
    parameter STAGES = `STAGES
)(
    input  wire sw0,

    output wire rgb0_r, rgb0_g, rgb0_b,
    output wire rgb1_r, rgb1_g, rgb1_b,

    output wire pico0,
    output wire pico1,
    input  wire pico5
);

    wire clk;
    (* keep *) Global_Clock clk_i (.CLK(clk));

    wire rst;
    WARMBOOT_wrapper WARMBOOT_wrapper (.SLOT(4'd0), .BOOT(1'b0), .RESET(rst));

    // clk/2 source
    reg t;
    always @(posedge clk) t <= rst ? 1'b0 : ~t;

    // long path: STAGES LUT4 buffers (INIT AAAA => O = I0), kept and placed by pcf
    wire [STAGES:0] c;
    assign c[0] = t;
    genvar i;
    generate for (i = 0; i < STAGES; i = i + 1) begin : chain
        (* keep *) LUT4 #(.INIT(16'hAAAA)) lut (.I0(c[i]), .I1(1'b0), .I2(1'b0), .I3(1'b0), .O(c[i+1]));
    end endgenerate

    reg s, l, x, err;
    always @(posedge clk) begin
        s   <= t;           // short path
        l   <= c[STAGES];   // long path
        x   <= s ^ l;
        err <= (rst | ~sw0 | pico5) ? 1'b0 : (err | x); // sw0 idles high, pressed = 0
    end

    // LEDs active low
    assign {rgb0_r, rgb0_g, rgb0_b} = {~x,   1'b1, 1'b1};
    assign {rgb1_r, rgb1_g, rgb1_b} = {~err, 1'b1, 1'b1};
    assign pico0 = x;
    assign pico1 = err;

endmodule
