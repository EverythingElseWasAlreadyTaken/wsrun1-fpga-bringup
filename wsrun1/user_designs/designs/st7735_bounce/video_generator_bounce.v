// "FABulous" in yellow bouncing on a blue background: a 64x16 text block
// (8x8 glyphs, 2x vertical scale) moving STEP pixels per frame.

module video_generator #(
    parameter SCREEN_WIDTH  = 160,
    parameter SCREEN_HEIGHT = 128,
    parameter [7:0] STEP    = 8'd4,
    // Rotate 180 degrees here rather than with the panel's MADCTL (see the
    // MADCTL note in st7735_controller.v).
    parameter FLIP          = 1
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  pixel_x,
    input  wire [7:0]  pixel_y,
    input  wire        pixel_request,
    output reg  [15:0] pixel_data
);

    // BGR565 (the MADCTL has BGR set).
    localparam [15:0] COLOR_BLUE   = 16'hF800;
    localparam [15:0] COLOR_YELLOW = 16'h07FF;

    localparam TEXT_W     = 64; // 8 chars x 8 px
    localparam TEXT_H     = 16; // 8 rows x 2 (vertical scale)
    localparam TEXT_MAX_X = SCREEN_WIDTH  - TEXT_W;
    localparam TEXT_MAX_Y = SCREEN_HEIGHT - TEXT_H;

    // Bounce direction: 1 = right/down, 0 = left/up.
    reg [7:0] text_x;
    reg [7:0] text_y;
    reg       vel_x_dir;
    reg       vel_y_dir;

    // pixel_request stays high for many clocks, so edge-detect it to step
    // once per frame.
    reg  pixel_request_d;
    always @(posedge clk) pixel_request_d <= rst ? 1'b0 : pixel_request;
    wire frame_done = pixel_request && !pixel_request_d &&
                      pixel_x >= SCREEN_WIDTH-1 && pixel_y >= SCREEN_HEIGHT-1;

    always @(posedge clk) begin
        if (rst) begin
            text_x <= 8'd10;
            text_y <= 8'd20;
            vel_x_dir <= 1'b1;
            vel_y_dir <= 1'b1;
        end else if (frame_done) begin
            if (vel_x_dir) begin
                if (text_x + STEP >= TEXT_MAX_X) begin vel_x_dir <= 0; text_x <= TEXT_MAX_X; end
                else                                   text_x <= text_x + STEP;
            end else begin
                if (text_x <= STEP)             begin vel_x_dir <= 1; text_x <= 8'd0; end
                else                                   text_x <= text_x - STEP;
            end

            if (vel_y_dir) begin
                if (text_y + STEP >= TEXT_MAX_Y) begin vel_y_dir <= 0; text_y <= TEXT_MAX_Y; end
                else                                   text_y <= text_y + STEP;
            end else begin
                if (text_y <= STEP)             begin vel_y_dir <= 1; text_y <= 8'd0; end
                else                                   text_y <= text_y - STEP;
            end
        end
    end

    // 9-bit adds avoid overflow when text_x = TEXT_MAX_X.
    wire in_text = ({1'b0, pixel_x} >= {1'b0, text_x})           &&
                   ({1'b0, pixel_x} <  {1'b0, text_x} + 9'd64)   &&
                   ({1'b0, pixel_y} >= {1'b0, text_y})            &&
                   ({1'b0, pixel_y} <  {1'b0, text_y} + 9'd16);

    wire [5:0] rel_x = pixel_x - text_x;
    wire [3:0] rel_y = pixel_y - text_y;

    // FLIP rotates the text 180 degrees: reverse the character order and each
    // glyph's row and column - three bit inversions, free in the LUTs.
    wire [2:0] char_idx = FLIP ? ~rel_x[5:3] : rel_x[5:3];
    wire [2:0] col_idx  = FLIP ? ~rel_x[2:0] : rel_x[2:0];
    wire [2:0] row_idx  = FLIP ? ~rel_y[3:1] : rel_y[3:1];

    // Font rows for "FABulous", MSB-first (bit 7 = leftmost column).
    reg [7:0] font_row;
    always @(*) begin
        case ({char_idx, row_idx})
            6'd0:  font_row = 8'hFE;
            6'd1:  font_row = 8'h80;
            6'd2:  font_row = 8'hF0;
            6'd3:  font_row = 8'h80;
            6'd4:  font_row = 8'h80;
            6'd5:  font_row = 8'h80;
            6'd6:  font_row = 8'h80;
            6'd7:  font_row = 8'h00;
            6'd8:  font_row = 8'h18;
            6'd9:  font_row = 8'h3C;
            6'd10: font_row = 8'h66;
            6'd11: font_row = 8'h66;
            6'd12: font_row = 8'h7E;
            6'd13: font_row = 8'h66;
            6'd14: font_row = 8'h66;
            6'd15: font_row = 8'h00;
            6'd16: font_row = 8'hFC;
            6'd17: font_row = 8'h42;
            6'd18: font_row = 8'h42;
            6'd19: font_row = 8'h7C;
            6'd20: font_row = 8'h42;
            6'd21: font_row = 8'h42;
            6'd22: font_row = 8'hFC;
            6'd23: font_row = 8'h00;
            6'd24: font_row = 8'h00;
            6'd25: font_row = 8'h00;
            6'd26: font_row = 8'h42;
            6'd27: font_row = 8'h42;
            6'd28: font_row = 8'h42;
            6'd29: font_row = 8'h42;
            6'd30: font_row = 8'h7E;
            6'd31: font_row = 8'h00;
            6'd32: font_row = 8'h18;
            6'd33: font_row = 8'h08;
            6'd34: font_row = 8'h08;
            6'd35: font_row = 8'h08;
            6'd36: font_row = 8'h08;
            6'd37: font_row = 8'h08;
            6'd38: font_row = 8'h3E;
            6'd39: font_row = 8'h00;
            6'd40: font_row = 8'h00;
            6'd41: font_row = 8'h00;
            6'd42: font_row = 8'h3C;
            6'd43: font_row = 8'h42;
            6'd44: font_row = 8'h42;
            6'd45: font_row = 8'h42;
            6'd46: font_row = 8'h3C;
            6'd47: font_row = 8'h00;
            6'd48: font_row = 8'h00;
            6'd49: font_row = 8'h00;
            6'd50: font_row = 8'h42;
            6'd51: font_row = 8'h42;
            6'd52: font_row = 8'h42;
            6'd53: font_row = 8'h42;
            6'd54: font_row = 8'h7E;
            6'd55: font_row = 8'h00;
            6'd56: font_row = 8'h00;
            6'd57: font_row = 8'h00;
            6'd58: font_row = 8'h3C;
            6'd59: font_row = 8'h60;
            6'd60: font_row = 8'h3C;
            6'd61: font_row = 8'h06;
            6'd62: font_row = 8'h3C;
            6'd63: font_row = 8'h00;
            default: font_row = 8'h00;
        endcase
    end

    wire font_bit = font_row[7 - col_idx];

    always @(*) begin
        if (in_text && font_bit)
            pixel_data = COLOR_YELLOW;
        else
            pixel_data = COLOR_BLUE;
    end

endmodule
