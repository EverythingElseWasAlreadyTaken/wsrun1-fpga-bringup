// ST7735 init sequence (SWRESET, SLPOUT, MADCTL, COLMOD, CASET, RASET,
// DISPON) then pixel streaming, bit-banged SPI mode 3.

module st7735_controller #(
    parameter FREQ_MAIN_HZ       = 25000000,
    parameter FREQ_TARGET_SPI_HZ = 4000000,
    parameter SCREEN_WIDTH       = 160,
    parameter SCREEN_HEIGHT      = 128,
    parameter RST_RELEASE = 100000,  // cycles tft_rst is held low
    parameter RST_DONE    = 1000000, // cycles before the first command
    // MADCTL: keep the BGR bit set and MV=1 (landscape 160x128). Leave this
    // at 8'h68 - the 180 degree value 8'hA8 blanked this panel, so rotate
    // with the FLIP parameter of the video generator instead.
    parameter [7:0] MADCTL = 8'h68
)(
    input  wire        clk,
    input  wire        rst,             // active high reset
    input  wire [15:0] pixel_data,      // RGB565 pixel from the generator
    output reg  [7:0]  pixel_x,         // pixel the generator must supply next
    output reg  [7:0]  pixel_y,
    output reg         pixel_request,   // high while pixel_data is sampled

    output reg         spi_clk,
    output reg         spi_mosi,
    output reg         spi_dc,
    output reg         spi_cs,
    output wire        tft_rst
);

   parameter HALF_SPI_PERIOD = (FREQ_MAIN_HZ / FREQ_TARGET_SPI_HZ) / 2;

   reg [3:0]  clk_counter_tx;
   // Counter widths are derived ($clog2) from what they must count to; with >=
   // compares a counter one bit too narrow can never reach its target.
   // +2 not +1: a fast testbench can make INTERVAL_MAX 0, and $clog2(1) = 0 is
   // not a legal width.
   localparam INTERVAL_MAX = FREQ_TARGET_SPI_HZ/4;
   reg [$clog2(INTERVAL_MAX+2)-1:0] counter_send_interval;
   reg [1:0]  counter_current_param;

   reg [4:0]  current_byte_pos;
   reg [15:0] pixel_buffer;
   reg [$clog2(RST_DONE+2)-1:0] delay_counter;

   reg [4:0] state;
   parameter STATE_SEND_SWRESET=0,     STATE_INTERVAL_SWRESET=1,
             STATE_SEND_SLPOUT=2,      STATE_INTERVAL_SLPOUT=3,
             STATE_SEND_CMD_MADCTL=4,  STATE_SEND_MADCTL_PARAM=5,
             STATE_SEND_CMD_COLMOD=6,  STATE_SEND_COLMOD_PARAM=7,
             STATE_SEND_CMD_CASET=8,   STATE_SEND_CASET_PARAMS=9,
             STATE_SEND_CMD_RASET=10,  STATE_SEND_RASET_PARAMS=11,
             STATE_SEND_DISPON=12,     STATE_INTERVAL_DISPON=13,
             STATE_SEND_RAMWR=14,
             STATE_WAITING_PIXEL=15,   STATE_LATCH_PIXEL=16,
             STATE_FRAME=17;

   // ST7735 command bytes
   parameter [7:0] CMD_SWRESET = 8'h01;
   parameter [7:0] CMD_SLPOUT  = 8'h11;
   parameter [7:0] CMD_MADCTL  = 8'h36;
   parameter [7:0] CMD_PARAM_MADCTL = MADCTL;
   parameter [7:0] CMD_COLMOD  = 8'h3A;
   parameter [7:0] CMD_PARAM_COLMOD = 8'h05; // 16-bit/pixel

   // CASET/RASET cover 0..SCREEN_WIDTH-1 / 0..SCREEN_HEIGHT-1 (MV swaps them).
   parameter [7:0] CMD_CASET   = 8'h2A;
   parameter [7:0] CMD_PARAM4_CASET = SCREEN_WIDTH - 1;
   parameter [7:0] CMD_RASET   = 8'h2B;
   parameter [7:0] CMD_PARAM4_RASET = SCREEN_HEIGHT - 1;

   parameter [7:0] CMD_DISPON = 8'h29;
   parameter [7:0] CMD_RAMWR  = 8'h2C;

   wire enable  = (delay_counter >= RST_DONE);
   assign tft_rst = (delay_counter >= RST_RELEASE);

   wire [7:0] window_param = (state == STATE_SEND_RASET_PARAMS) ? CMD_PARAM4_RASET
                                                                : CMD_PARAM4_CASET;

   reg spi_clk_prev;
   wire spi_clk_negedge;
   assign spi_clk_negedge = (spi_clk_prev && !spi_clk);

   // Hardware reset delay, SPI clock generation and SPI edge detection
   always @(posedge clk) begin
      if (rst) begin
         delay_counter <= 0;
      end else if (delay_counter < RST_DONE) begin
         delay_counter <= delay_counter + 1;
      end
   end

   always @(posedge clk) begin
      if (rst) begin
         clk_counter_tx <= 0;
         spi_clk <= 1;
         spi_clk_prev <= 1;
      end else begin
         if (enable) begin
            if (clk_counter_tx == HALF_SPI_PERIOD - 1) begin
               clk_counter_tx <= 0;
               spi_clk <= ~spi_clk;
            end else begin
               clk_counter_tx <= clk_counter_tx + 1;
            end
         end
         spi_clk_prev <= spi_clk;
      end
   end

   // SPI state machine (SPI mode 3, stepped on the spi_clk falling edge)
   always @(posedge clk) begin
      if (rst) begin
         spi_mosi <= 0;
         spi_dc <= 0;
         spi_cs <= 1;
         pixel_request <= 0;
         pixel_x <= 0;
         pixel_y <= 0;
         current_byte_pos <= 7;
         counter_send_interval <= 0;
         counter_current_param <= 0;
         pixel_buffer <= 0;
         state <= STATE_SEND_SWRESET;
      end else if (spi_clk_negedge && enable) begin
         // Defaults re-applied on every SPI step; the states below override.
         spi_dc <= 0;
         spi_cs <= 1;
         pixel_request <= 0;
         current_byte_pos <= current_byte_pos - 1;

      case (state)
      STATE_SEND_SWRESET: begin
         spi_mosi <= CMD_SWRESET[current_byte_pos];
         spi_cs   <= 0;
         if (current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SWRESET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SWRESET: begin
         counter_send_interval <= counter_send_interval + 1;
         // /4: the datasheet wants ~120 ms after SWRESET, scaled to the SPI rate.
         if (counter_send_interval >= (FREQ_TARGET_SPI_HZ/4)) begin
            state <= STATE_SEND_SLPOUT;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_SLPOUT: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_SLPOUT[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_INTERVAL_SLPOUT;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_SLPOUT: begin
         counter_send_interval <= counter_send_interval + 1;
         if (counter_send_interval >= (FREQ_TARGET_SPI_HZ/4)) begin
            state <= STATE_SEND_CMD_MADCTL;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      STATE_SEND_CMD_MADCTL: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_MADCTL[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_MADCTL_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_MADCTL_PARAM: begin
         spi_cs   <= 0;
         spi_dc   <= 1;
         spi_mosi <= CMD_PARAM_MADCTL[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_COLMOD;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_COLMOD: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_COLMOD[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_COLMOD_PARAM;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_COLMOD_PARAM: begin
         spi_cs   <= 0;
         spi_dc   <= 1;
         spi_mosi <= CMD_PARAM_COLMOD[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_CMD_CASET;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_CASET: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_CASET[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_CASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      // Window start is 0, so only the final (end) parameter is non-zero.
      STATE_SEND_CASET_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1;
         spi_mosi <= (counter_current_param == 3) ? window_param[current_byte_pos] : 1'b0;
         if (current_byte_pos == 0) begin
            counter_current_param <= counter_current_param + 1;
            if (counter_current_param == 3) begin
               counter_current_param <= 0;
               state <= STATE_SEND_CMD_RASET;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_CMD_RASET: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_RASET[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_SEND_RASET_PARAMS;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
            counter_current_param <= 0;
         end
      end
      STATE_SEND_RASET_PARAMS: begin
         spi_cs <= 0;
         spi_dc <= 1;
         spi_mosi <= (counter_current_param == 3) ? window_param[current_byte_pos] : 1'b0;
         if (current_byte_pos == 0) begin
            counter_current_param <= counter_current_param + 1;
            if (counter_current_param == 3) begin
               counter_current_param <= 0;
               state <= STATE_SEND_DISPON;
            end
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_SEND_DISPON: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_DISPON[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_INTERVAL_DISPON;
            current_byte_pos <= 7;
            counter_send_interval <= 0;
         end
      end
      STATE_INTERVAL_DISPON: begin
         counter_send_interval <= counter_send_interval + 1;
         if (counter_send_interval >= (FREQ_TARGET_SPI_HZ/20)) begin
            state <= STATE_SEND_RAMWR;
            counter_current_param <= 0;
            current_byte_pos <= 7;
         end
      end
      // RAMWR resets the panel's write pointer, so one per frame is enough.
      STATE_SEND_RAMWR: begin
         spi_cs   <= 0;
         spi_mosi <= CMD_RAMWR[current_byte_pos];
         if (current_byte_pos == 0) begin
            state <= STATE_WAITING_PIXEL;
            current_byte_pos <= 15;
            counter_send_interval <= 0;
         end
      end
      // Two-step handshake: request the next pixel, latch it one step later.
      STATE_WAITING_PIXEL: begin
         spi_cs <= 1;
         pixel_request <= 1;
         state <= STATE_LATCH_PIXEL;
         current_byte_pos <= 15;
      end
      STATE_LATCH_PIXEL: begin
         spi_cs <= 1;
         pixel_request <= 0;
         pixel_buffer <= pixel_data;
         state <= STATE_FRAME;
         current_byte_pos <= 15;
      end
      STATE_FRAME: begin
         spi_cs   <= 0;
         spi_dc   <= 1;
         spi_mosi <= pixel_buffer[current_byte_pos];
         if (current_byte_pos == 0) begin
            current_byte_pos <= 15;
            state <= STATE_WAITING_PIXEL;

            if (pixel_x >= SCREEN_WIDTH - 1) begin
               pixel_x <= 0;
               if (pixel_y >= SCREEN_HEIGHT - 1) begin
                  pixel_y <= 0;
                  state <= STATE_SEND_RAMWR;
               end else begin
                  pixel_y <= pixel_y + 1;
               end
            end else begin
               pixel_x <= pixel_x + 1;
            end
         end
      end
      default: state <= STATE_SEND_SWRESET;
      endcase
      end
   end

endmodule
