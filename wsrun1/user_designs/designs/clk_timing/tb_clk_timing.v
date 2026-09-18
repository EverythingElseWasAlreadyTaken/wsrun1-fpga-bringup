// Functional self-check (zero-delay LUTs): XOR and sticky error stay 0,
// sw0 clears err after a forced error.
//   iverilog -g2012 -o tb tb_clk_timing.v clk_timing.v && ./tb
`timescale 1ns/1ps
module Global_Clock (output reg CLK);
    initial CLK = 0; always #10 CLK = ~CLK;
endmodule
module WARMBOOT_wrapper (input [3:0] SLOT, input BOOT, output reg RESET);
    initial begin RESET = 1; #55 RESET = 0; end
endmodule
module LUT4 #(parameter [15:0] INIT = 0) (output O, input I0, I1, I2, I3);
    assign O = INIT[{I3, I2, I1, I0}];
endmodule

module tb_clk_timing;
    reg sw0 = 1, pico5 = 0; // sw0 idles high
    wire rgb0_r, rgb0_g, rgb0_b, rgb1_r, rgb1_g, rgb1_b, pico0, pico1;
    clk_timing #(.STAGES(8)) dut (.*);

    integer n, toggles = 0;
    initial begin
        @(negedge dut.rst);
        for (n = 0; n < 200; n = n + 1) begin
            @(posedge dut.clk); #1;
            if (pico0 !== 0 || pico1 !== 0) begin $display("FAIL: x=%b err=%b at %0d", pico0, pico1, n); $finish; end
            if (dut.t) toggles = toggles + 1;
        end
        if (toggles != 100) begin $display("FAIL: t not clk/2 (%0d)", toggles); $finish; end
        force dut.l = 1'b1; // s toggles, so s^l hits 1 within two cycles
        repeat (4) @(posedge dut.clk); #1; release dut.l;
        if (pico1 !== 1) begin $display("FAIL: err not set"); $finish; end
        sw0 = 0; @(posedge dut.clk); @(posedge dut.clk); #1; sw0 = 1;
        if (pico1 !== 0) begin $display("FAIL: sw0 did not clear err"); $finish; end
        force dut.l = 1'b1; repeat (4) @(posedge dut.clk); #1; release dut.l;
        pico5 = 1; @(posedge dut.clk); @(posedge dut.clk); #1; pico5 = 0;
        if (pico1 !== 0) begin $display("FAIL: pico5 did not clear err"); $finish; end
        $display("PASS"); $finish;
    end
endmodule
