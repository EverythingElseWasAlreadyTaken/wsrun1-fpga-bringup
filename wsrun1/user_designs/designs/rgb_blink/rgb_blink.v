// SPDX-License-Identifier: Apache-2.0
//
// Clock-sweep test: rgb0 (green) toggles every 2**FAST_BIT clocks,
// rgb1 (green) toggles exactly 100x slower. At 1 MHz: ~7.6 Hz / ~0.076 Hz blink.

`default_nettype none

module rgb_blink #(
    parameter FAST_BIT = 16
)(
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

    wire rst;
    WARMBOOT_wrapper WARMBOOT_wrapper (
        .SLOT   (4'd0),
        .BOOT   (1'b0),
        .RESET  (rst)
    );

    reg [FAST_BIT:0] cnt;
    reg [6:0] slow_cnt;
    reg slow;

    wire tick = &cnt[FAST_BIT-1:0]; // fast LED toggles on the next cycle

    always @(posedge clk) begin
        if (rst) begin
            cnt      <= '0;
            slow_cnt <= '0;
            slow     <= 1'b0;
        end else begin
            cnt <= cnt + 1;
            if (tick) begin
                if (slow_cnt >= 7'd99) begin // >= so a random power-up value can't stall it
                    slow_cnt <= '0;
                    slow     <= ~slow;
                end else begin
                    slow_cnt <= slow_cnt + 1;
                end
            end
        end
    end

    // LEDs are active low
    assign rgb0_r = ~cnt[FAST_BIT];
    assign rgb0_g = 1'b1;
    assign rgb0_b = 1'b1;

    assign rgb1_r = ~slow;
    assign rgb1_g = 1'b1;
    assign rgb1_b = 1'b1;

endmodule
