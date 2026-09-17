// Self-check for the bounce video generator.
//   iverilog -g2005 -o tb tb_bounce.v video_generator_bounce.v && ./tb
`timescale 1ns/1ps

module tb_bounce;
   localparam W = 160, H = 128, STEP = 4;
   // FLIP=1 renders the text rotated 180 degrees, so the 'F' of the text
   // block sits at its bottom-right corner: (text_x+63, text_y+15).
   localparam FCORNER_X = 63, FCORNER_Y = 15;
   localparam [15:0] BLUE = 16'hF800, YELLOW = 16'h07FF;

   reg clk = 0, rst = 1, pixel_request = 0;
   reg [7:0] pixel_x = 0, pixel_y = 0;
   wire [15:0] pixel_data;
   integer errors = 0;

   always #5 clk = ~clk;

   video_generator #(.SCREEN_WIDTH(W), .SCREEN_HEIGHT(H), .STEP(STEP[7:0]))
      dut (.clk(clk), .rst(rst), .pixel_x(pixel_x), .pixel_y(pixel_y),
           .pixel_request(pixel_request), .pixel_data(pixel_data));

   task check_pixel(input [8:0] x, input [8:0] y, input [15:0] want, input [127:0] what);
      begin
         pixel_x = x[7:0]; pixel_y = y[7:0]; #1;
         if (pixel_data !== want) begin
            $display("MISMATCH %0s at (%0d,%0d): got %04h want %04h", what, x, y, pixel_data, want);
            errors = errors + 1;
         end
      end
   endtask

   // One frame boundary: pixel_request pulses at the last pixel and stays
   // high for `hold` clocks, exactly as st7735_controller drives it.
   task frame(input integer hold);
      integer i;
      begin
         pixel_x = W-1; pixel_y = H-1;
         @(negedge clk); pixel_request = 1;
         for (i = 0; i < hold; i = i + 1) @(negedge clk);
         pixel_request = 0;
         @(negedge clk);
      end
   endtask

   integer f;
   initial begin
      repeat (3) @(negedge clk);
      rst = 0;
      @(negedge clk);

      // Start position 10,20, so the rotated 'F' corner is at 73,35.
      check_pixel(10+FCORNER_X, 20+FCORNER_Y, YELLOW, "rotated F corner");
      check_pixel(8'd10, 8'd20, BLUE,   "block corner is now blank glyph row");
      check_pixel(8'd0,  8'd0,  BLUE,   "background");

      // A long pixel_request must advance the position exactly once.
      frame(40);
      check_pixel(14+FCORNER_X, 24+FCORNER_Y, YELLOW, "moved one step");
      check_pixel(10+FCORNER_X, 20+FCORNER_Y, BLUE,   "vacated old spot");

      // 21 more frames: x clamps at the right wall (94+STEP overshoots 96).
      for (f = 0; f < 21; f = f + 1) frame(12);
      check_pixel(96+FCORNER_X, 108+FCORNER_Y, YELLOW, "clamped at right wall");

      // x has turned around; y has clamped at 112 and turned back to 108.
      for (f = 0; f < 2; f = f + 1) frame(12);
      check_pixel(88+FCORNER_X, 108+FCORNER_Y, YELLOW, "bounced back off the wall");
      check_pixel(96+FCORNER_X, 108+FCORNER_Y, BLUE,   "left the wall");

      if (errors == 0) $display("PASS: bounce generator draws and bounces");
      else             $display("FAIL: %0d errors", errors);
      $finish;
   end
endmodule
