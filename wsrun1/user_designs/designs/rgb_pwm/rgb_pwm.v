// SPDX-FileCopyrightText: © 2026 Leo Moser <leo.moser@pm.me>
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

module up_down_counter #(
    parameter WIDTH = 8,
    parameter [WIDTH-1:0] INIT = '0
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
	      count <= INIT;
	      dir <= 1'b0;
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

module top(
    input  wire        clk,
    input  wire [`NUM_IO-1:0] io_in,
    output wire [`NUM_IO-1:0] io_out,
    output wire [`NUM_IO-1:0] io_oeb
);

  // Tie low
	assign io_out[13:0] = '0;
	assign io_out[`NUM_IO-1:20] = '0;
	
	// RGB = output, everything else = input
	assign io_oeb[13:0] = '1;
	assign io_oeb[19:14] = '0;
	assign io_oeb[`NUM_IO-1:20] = '1;
	
	wire sw0, sw1, sw2, sw3;
	
	assign sw0 = io_in[2];
  assign sw1 = io_in[3];
  assign sw2 = io_in[4];
  assign sw3 = io_in[5];
	

	
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
      .INIT(8'd0)
  ) counter_0 (
      .clk  (clk),
      .rst  (rst),
      .en   (enable),
      .out  (pwm0)
  );
	
	wire [7:0] pwm1;
	up_down_counter #(
      .INIT(8'd50)
  ) counter_1 (
      .clk  (clk),
      .rst  (rst),
      .en   (enable),
      .out  (pwm1)
  );
  
  	wire [7:0] pwm2;
	up_down_counter #(
      .INIT(8'd120)
  ) counter_2 (
      .clk  (clk),
      .rst  (rst),
      .en   (enable),
      .out  (pwm2)
  );
  
  	wire [7:0] pwm3;
	up_down_counter #(
      .INIT(8'd200)
  ) counter_3 (
      .clk  (clk),
      .rst  (rst),
      .en   (enable),
      .out  (pwm3)
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

        rgb1_rd <=  (counter < pwm3 ? 1'b0 : 1'b1);
        rgb1_gd <=  (counter < pwm2 ? 1'b0 : 1'b1);
        rgb1_bd <=  (counter < pwm1 ? 1'b0 : 1'b1);
	    end
	end

	wire rgb0_r, rgb0_g, rgb0_b;
	wire rgb1_r, rgb1_g, rgb1_b;

	assign rgb0_r = rgb0_rd;
	assign rgb0_g = rgb0_gd;
	assign rgb0_b = rgb0_bd;
	
	assign rgb1_r = rgb1_rd;
	assign rgb1_g = rgb1_gd;
	assign rgb1_b = rgb1_bd;
	
	// RGB0
	assign io_out[15] = rgb0_r; // R
	assign io_out[16] = rgb0_g; // G
	assign io_out[14] = rgb0_b; // B

	// RGB1
	assign io_out[18] = rgb1_r; // R
	assign io_out[19] = rgb1_g; // G
	assign io_out[17] = rgb1_b; // B

endmodule
