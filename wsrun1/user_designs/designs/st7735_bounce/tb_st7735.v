// Self-check: decode the SPI stream and compare it against the expected init
// bytes plus the first pixels.
//   iverilog -g2005 -o tb tb_st7735.v st7735_controller.v video_generator_bounce.v && ./tb
`timescale 1ns/1ps

module tb_st7735;
   reg clk = 0, rst = 1;
   always #5 clk = ~clk;

   wire [15:0] pixel_data;
   wire [7:0]  pixel_x, pixel_y;
   wire        pixel_request;
   wire        spi_clk, spi_mosi, spi_dc, spi_cs, tft_rst;

   video_generator #(.SCREEN_WIDTH(160), .SCREEN_HEIGHT(128)) u_gen (
      .clk(clk), .rst(rst), .pixel_x(pixel_x), .pixel_y(pixel_y),
      .pixel_request(pixel_request), .pixel_data(pixel_data));

   // Tiny timing parameters so the init intervals pass in a few hundred cycles
   st7735_controller #(
      .FREQ_MAIN_HZ(2), .FREQ_TARGET_SPI_HZ(1),
      .SCREEN_WIDTH(160), .SCREEN_HEIGHT(128),
      .RST_RELEASE(18'd2), .RST_DONE(18'd4)
   ) u_ctrl (
      .clk(clk), .rst(rst), .pixel_data(pixel_data),
      .pixel_x(pixel_x), .pixel_y(pixel_y), .pixel_request(pixel_request),
      .spi_clk(spi_clk), .spi_mosi(spi_mosi), .spi_dc(spi_dc),
      .spi_cs(spi_cs), .tft_rst(tft_rst));

   // Expected: {dc, byte}. dc=0 command, dc=1 data.
   localparam N = 24;
   reg [8:0] expected [0:N-1];
   initial begin
      expected[0]  = 9'h001; // SWRESET
      expected[1]  = 9'h011; // SLPOUT
      expected[2]  = 9'h036; // MADCTL
      expected[3]  = 9'h168;  // MADCTL: landscape (rotation is done by FLIP)
      expected[4]  = 9'h03A; // COLMOD
      expected[5]  = 9'h105;
      expected[6]  = 9'h02A; // CASET
      expected[7]  = 9'h100;
      expected[8]  = 9'h100;
      expected[9]  = 9'h100;
      expected[10] = 9'h19F; // 160-1
      expected[11] = 9'h02B; // RASET
      expected[12] = 9'h100;
      expected[13] = 9'h100;
      expected[14] = 9'h100;
      expected[15] = 9'h17F; // 128-1
      expected[16] = 9'h029; // DISPON
      expected[17] = 9'h02C; // RAMWR
      // FLIP rotates the pattern, so the first pixel sent is the far end of
      // the bar order: magenta, 16'hF81F.
      // Pixel (0,0) is background in the bounce generator: blue, 16'hF800.
      expected[18] = 9'h1F8; // pixel 0 high byte
      expected[19] = 9'h100; // pixel 0 low byte
      expected[20] = 9'h1F8;
      expected[21] = 9'h100;
      expected[22] = 9'h1F8;
      expected[23] = 9'h100;
   end

   integer bit_cnt = 0, byte_cnt = 0, errors = 0;
   reg [7:0] shreg;
   reg       dc_seen;

   always @(posedge spi_clk) begin
      if (!spi_cs) begin
         if (bit_cnt == 0) dc_seen <= spi_dc;
         shreg   <= {shreg[6:0], spi_mosi};
         bit_cnt <= bit_cnt + 1;
         if (bit_cnt == 7) begin
            bit_cnt <= 0;
            if (byte_cnt < N) begin
               if ({dc_seen, shreg[6:0], spi_mosi} !== expected[byte_cnt]) begin
                  $display("MISMATCH byte %0d: got dc=%b 0x%02h, expected dc=%b 0x%02h",
                           byte_cnt, dc_seen, {shreg[6:0], spi_mosi},
                           expected[byte_cnt][8], expected[byte_cnt][7:0]);
                  errors = errors + 1;
               end
            end
            byte_cnt <= byte_cnt + 1;
         end
      end else begin
         bit_cnt <= 0;
      end
   end

   initial begin
      #100 rst = 0;
      #200000;
      if (tft_rst !== 1'b1) begin
         $display("MISMATCH: tft_rst never released");
         errors = errors + 1;
      end
      if (byte_cnt < N) begin
         $display("MISMATCH: only %0d of %0d bytes sent", byte_cnt, N);
         errors = errors + 1;
      end
      if (errors == 0) $display("PASS: %0d bytes match the ST7735 init sequence", N);
      else             $display("FAIL: %0d errors", errors);
      $finish;
   end
endmodule
