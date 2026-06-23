// SPDX-FileCopyrightText: © 2026 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module up_down_counter #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] INIT_VAL = '0,
    parameter [0:0] INIT_DIR = 1'b0
)(
    input wire clk,
    input wire rst,
    input wire en,
    output wire [WIDTH-1:0] out
);
    reg [WIDTH-1:0] count;
    reg dir;

    always @(posedge clk) begin
	    if (rst) begin
	      count <= INIT_VAL;
	      dir <= INIT_DIR;
	    end else begin
	      if (en) begin
	          if (dir == 1'b0) begin
              count <= count + 1;
              
    	          if (count == (2**WIDTH)-2) begin
                dir <= 1'b1;
              end
	          end else begin
              count <= count - 1;
              
              if (count == 1) begin
                dir <= 1'b0;
              end
	          end
	      end
	    end
	  end
	  
	  assign out = count;
endmodule

module rgb_pwm (
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

    reg [7:0] counter;
    reg [7:0] big_counter;

    wire rst;
    WARMBOOT_wrapper WARMBOOT_wrapper (
        .SLOT   (4'd0),
        .BOOT   (1'b0),
        .RESET  (rst)
    );

    always @(posedge clk) begin
        if (rst) begin
          counter <= '0;
        end else begin
	          counter <= counter + 1;
        end
    end

    reg enable;
    always @(posedge clk) begin
        if (rst) begin
          big_counter <= '0;
          enable <= 1'b0;
        end else begin
	          big_counter <= big_counter + 1;
            enable <= &big_counter;
        end
    end

    wire [7:0] pwm0;
    up_down_counter #(
        .INIT_VAL(8'd0)
    ) counter_0 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm0)
    );

    wire [7:0] pwm1;
    up_down_counter #(
        .INIT_VAL(8'd171)
    ) counter_1 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm1)
    );

    wire [7:0] pwm2;
    up_down_counter #(
        .INIT_VAL(8'd168),
        .INIT_DIR(1'b1)
    ) counter_2 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm2)
    );

    wire [9:0] pwm3;
    up_down_counter #(
        .WIDTH(10),
        .INIT_VAL(86*4),
        .INIT_DIR(1'b0)
    ) counter_3 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm3)
    );

    wire [9:0] pwm4;
    up_down_counter #(
        .WIDTH(10),
        .INIT_VAL(255*4),
        .INIT_DIR(1'b1)
    ) counter_4 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm4)
    );

    wire [9:0] pwm5;
    up_down_counter #(
        .WIDTH(10),
        .INIT_VAL(83*4),
        .INIT_DIR(1'b1)
    ) counter_5 (
        .clk  (clk),
        .rst  (rst),
        .en   (enable),
        .out  (pwm5)
    );

    reg rgb0_rd, rgb0_gd, rgb0_bd;
    reg rgb1_rd, rgb1_gd, rgb1_bd;

    always @(posedge clk) begin
        if (rst) begin
          rgb0_rd <= 1'b1;
          rgb0_gd <= 1'b1;
          rgb0_bd <= 1'b1;

          rgb1_rd <= 1'b1;
          rgb1_gd <= 1'b1;
          rgb1_bd <= 1'b1;
        end else begin
          rgb0_rd <=  (counter < pwm0 ? 1'b0 : 1'b1);
          rgb0_gd <=  (counter < pwm1 ? 1'b0 : 1'b1);
          rgb0_bd <=  (counter < pwm2 ? 1'b0 : 1'b1);

          rgb1_rd <=  (counter < pwm1 ? 1'b0 : 1'b1);
          rgb1_gd <=  (counter < pwm2 ? 1'b0 : 1'b1);
          rgb1_bd <=  (counter < pwm0 ? 1'b0 : 1'b1);
        end
    end

    assign rgb0_r = rgb0_rd;
    assign rgb0_g = rgb0_gd;
    assign rgb0_b = rgb0_bd;

    assign rgb1_r = rgb1_rd;
    assign rgb1_g = rgb1_gd;
    assign rgb1_b = rgb1_bd;

endmodule
