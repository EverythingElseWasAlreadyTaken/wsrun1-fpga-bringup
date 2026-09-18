// Self-check: rgb1 toggles exactly every 100 rgb0 toggles.
//   iverilog -g2012 -o tb tb_rgb_blink.v rgb_blink.v && ./tb
`timescale 1ns/1ps
// FABulous primitives stubbed (the real ones don't parse in iverilog)
module Global_Clock (output reg CLK);
    initial CLK = 0; always #10 CLK = ~CLK;
endmodule
module WARMBOOT_wrapper (input [3:0] SLOT, input BOOT, output reg RESET);
    initial begin RESET = 1; #55 RESET = 0; end
endmodule

module tb_rgb_blink;
    wire rgb0_r, rgb0_g, rgb0_b, rgb1_r, rgb1_g, rgb1_b, pico0, pico1;
    rgb_blink #(.FAST_BIT(4)) dut (.*);

    integer fast = 0, slow = 0;
    reg pf, ps;
    initial begin
        @(negedge dut.rst); #1 pf = rgb0_r; ps = rgb1_r;
        repeat (16 * 100 * 6 + 16) begin
            @(posedge dut.clk); #1;
            if (rgb0_r !== pf) begin fast = fast + 1; pf = rgb0_r; end
            if (rgb1_r !== ps) begin
                slow = slow + 1; ps = rgb1_r;
                if (fast != 100 * slow) begin $display("FAIL: %0d fast / %0d slow", fast, slow); $finish; end
            end
        end
        if (pico0 !== ~rgb0_r || pico1 !== ~rgb1_r) begin $display("FAIL: pico pins"); $finish; end
        if (slow != 6) begin $display("FAIL: slow toggles = %0d", slow); $finish; end
        $display("PASS");
        $finish;
    end
endmodule
