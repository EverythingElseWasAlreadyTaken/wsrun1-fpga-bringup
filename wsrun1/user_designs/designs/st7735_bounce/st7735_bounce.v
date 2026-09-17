// "FABulous" bouncing on an ST7735 SPI display, on the wsrun1 FABulous fabric.
// Pin names match fabulous/constraints.pcf.

module st7735_bounce (
    input wire sw0,             // reset button
    output wire tft2_sclk,      // ST7735 SPI display, bank 3 header (gpio[34:41])
    output wire tft2_mosi,
    output wire tft2_cs,
    output wire tft2_dc,
    output wire tft2_rst,
    output wire rgb0_r,         // RGB LEDs, active low
    output wire rgb0_g,
    output wire rgb0_b,
    output wire rgb1_r,
    output wire rgb1_g,
    output wire rgb1_b
);
    // 5 MHz project clock, SPI divider 1. A frame is 368640 SPI clocks, so at
    // 2.5 MHz SPI each FSM step gets one SPI period (400 ns) to settle. 10 MHz
    // is known not to work on this fabric.
    localparam FREQ_MAIN_HZ = 5_000_000;
    localparam FREQ_SPI_HZ  = 2_500_000; // (FREQ_MAIN_HZ/FREQ_SPI_HZ)/2 must be 1..15

    localparam SCREEN_WIDTH  = 160;
    localparam SCREEN_HEIGHT = 128;

    wire clk;
    (* keep *) Global_Clock clk_i (.CLK(clk));

    // sw0 idles high and goes low when pressed, so SW_RESET_ACTIVE is 0.
    localparam SW_RESET_ACTIVE = 1'b0;

    wire por_rst;
    reg [1:0] sw0_sync;
    always @(posedge clk) sw0_sync <= {sw0_sync[0], sw0};

    wire rst = por_rst | (sw0_sync[1] == SW_RESET_ACTIVE);

    (* keep *)
    WARMBOOT warmboot_i (
        .SLOT0 (1'b0),
        .SLOT1 (1'b0),
        .SLOT2 (1'b0),
        .SLOT3 (1'b0),
        .BOOT  (1'b0),
        .RESET (por_rst)
    );

    wire [15:0] pixel_data;
    wire [7:0]  pixel_x;
    wire [7:0]  pixel_y;
    wire        pixel_request;

    video_generator #(
        .SCREEN_WIDTH  (SCREEN_WIDTH),
        .SCREEN_HEIGHT (SCREEN_HEIGHT),
        .STEP          (8'd2),         // pixels per frame
        .FLIP          (1)             // rotate 180, the panel is mounted upside down
    ) u_video_gen (
        .clk           (clk),
        .rst           (rst),
        .pixel_x       (pixel_x),
        .pixel_y       (pixel_y),
        .pixel_request (pixel_request),
        .pixel_data    (pixel_data)
    );

    st7735_controller #(
        .FREQ_MAIN_HZ       (FREQ_MAIN_HZ),
        .FREQ_TARGET_SPI_HZ (FREQ_SPI_HZ),
        .SCREEN_WIDTH       (SCREEN_WIDTH),
        .SCREEN_HEIGHT      (SCREEN_HEIGHT),
        .RST_RELEASE        (FREQ_MAIN_HZ/100), // 10 ms tft_rst low
        .RST_DONE           (FREQ_MAIN_HZ/5)    // 200 ms before first command (datasheet: >= 120 ms)
    ) u_controller (
        .clk           (clk),
        .rst           (rst),
        .pixel_data    (pixel_data),
        .pixel_x       (pixel_x),
        .pixel_y       (pixel_y),
        .pixel_request (pixel_request),
        .spi_clk       (tft2_sclk),
        .spi_mosi      (tft2_mosi),
        .spi_dc        (tft2_dc),
        .spi_cs        (tft2_cs),
        .tft_rst       (tft2_rst)
    );

    // RGB0 steady blue; RGB1 blinks each 8 frames (~1.2 s), counting frame
    // edges rather than clocks to save cells.
    reg       pixel_y_msb_d;
    reg [3:0] frame_count;
    always @(posedge clk) begin
        if (rst) begin
            pixel_y_msb_d <= 1'b0;
            frame_count   <= 0;
        end else begin
            pixel_y_msb_d <= pixel_y[6];
            if (pixel_y[6] && !pixel_y_msb_d) frame_count <= frame_count + 1;
        end
    end
    wire slow = frame_count[3];

    assign rgb0_r = 1'b1;
    assign rgb0_g = 1'b1;
    assign rgb0_b = 1'b0;

    assign rgb1_r = ~slow;
    assign rgb1_g = ~slow;
    assign rgb1_b = 1'b1;

endmodule
