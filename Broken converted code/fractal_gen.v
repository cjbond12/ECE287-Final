// FIXED POINT CONVENTION (32 bits)
// | 10 integer bits | 22 fraction bits |
// Splits the 32-bit number into 10 bits for the integer part 
// and 22 bits for the fractional part.
`define INT(n) n[31:22]  // Integer part of the fixed-point number
`define FRAC(n) n[21:0]  // Fractional part of the fixed-point number

// Define resolution
`define HIGH_RES
`ifdef HIGH_RES
	`define WIDTH 16'd320  // High resolution width
	`define HEIGHT 16'd240 // High resolution height
`else
	`define WIDTH 16'd160  // Low resolution width
	`define HEIGHT 16'd120 // Low resolution height
`endif

module fractal_gen(
	input clk,                // Clock signal
	input rstn,               // Active-low reset
	input start,              // Start signal
	output done,              // Indicates computation is complete

	// Zoom and position control
	input [2:0] zoom_level,       // Zoom level
	input [2:0] h_offset_level,   // Horizontal offset
	input [2:0] v_offset_level,   // Vertical offset

	// VGA output
	output [`WIDTH-1:0] vga_x,    // Horizontal coordinate
	output [`HEIGHT-1:0] vga_y,   // Vertical coordinate
	output [2:0] vga_colour,      // Pixel color
	output vga_plot_pixels        // Pixel plot signal
);

// ======= [ Parameters ] =======
parameter SCALE_FACTOR_075 = {10'b0, 2'b11, 20'b0};
parameter SCALE_FACTOR_STEP_X = {10'b0, 22'b0000000011001100110011};
parameter SCALE_FACTOR_STEP_Y = {10'b0, 22'b0000000100010001000100};

// ======= [ Wires and Registers ] =======
wire signed [31:0] w, h, xmin, xmax, ymin, ymax, dx, dy;
wire signed [31:0] h_offset, v_offset;
reg signed [31:0] w_reg, h_offset_reg, v_offset_reg;

// ======= [ Width and Height Calculations ] =======
always @(*) begin
	case (zoom_level)
		3'b000: w_reg = {10'd10, 22'b0};
		3'b001: w_reg = {10'd4, 22'b0};
		3'b010: w_reg = {10'd2, 22'b0};
		3'b011: w_reg = {10'd1, 22'b0};
		3'b100: w_reg = {10'b0, 2'b11, 20'b0};
		3'b101: w_reg = {10'b0, 1'b1, 21'b0};
		3'b110: w_reg = {10'b0, 3'b011, 19'b0};
		3'b111: w_reg = {10'b0, 2'b01, 20'b0};
	endcase
end
assign w = w_reg;

multiplier WIDTH_TO_HEIGHT(
	.a(w),
	.b(SCALE_FACTOR_075),
	.out(h)
);

// ======= [ Offset Calculations ] =======
always @(*) begin
	case (h_offset_level)
		3'b000: h_offset_reg = {10'd3, 1'b1, 21'b0};
		3'b001: h_offset_reg = {10'd2, 2'b11, 20'b0};
		3'b010: h_offset_reg = {10'd2, 22'b0};
		3'b011: h_offset_reg = {10'd1, 1'b1, 22'b0};
		3'b100: h_offset_reg = {10'd1, 22'b0};
		3'b101: h_offset_reg = {10'd0, 2'b01, 20'b0};
		3'b110: h_offset_reg = {10'd0, 22'b0};
		3'b111: h_offset_reg = {10'b1111111111, 1'b1, 21'b0};
	endcase
end
assign h_offset = h_offset_reg;

always @(*) begin
	case (v_offset_level)
		3'b000: v_offset_reg = {10'd2, 22'b0};
		3'b001: v_offset_reg = {10'd1, 1'b1, 21'b0};
		3'b010: v_offset_reg = {10'd1, 22'b0};
		3'b011: v_offset_reg = {10'd0, 1'b1, 22'b0};
		3'b100: v_offset_reg = {10'd0, 22'b0};
		3'b101: v_offset_reg = {10'b1111111111, 1'b1, 21'b0};
		3'b110: v_offset_reg = {10'b1111111111, 22'b0};
		3'b111: v_offset_reg = {10'b1111111110, 1'b1, 21'b0};
	endcase
end
assign v_offset = v_offset_reg;

// ======= [ Coordinate Calculations ] =======
assign xmin = ((w + h_offset) >> 1) * ~(32'b0);
assign xmax = xmin + w;
assign ymin = ((h + v_offset) >> 1) * ~(32'b0);
assign ymax = ymin + h;

math X_STEP_SIZE(
	.a(xmax - xmin),
	.b(SCALE_FACTOR_STEP_X),
	.out(dx)
);

math Y_STEP_SIZE(
	.a(ymax - ymin),
	.b(SCALE_FACTOR_STEP_Y),
	.out(dy)
);

// ======= [ Constants for Computation ] =======
wire [15:0] iterations = 16'd32;
wire signed [31:0] max_distance = {10'd16, 22'b0};

// ======= [ Registers and Signals ] =======
wire en_x, en_y, en_a, en_b, en_iteration, en_x_pixel, en_y_pixel;
wire signed [31:0] x, y, a, b;
wire signed [31:0] x_new, y_new, a_new, b_new;
wire [15:0] n, x2, y2;
wire [15:0] n_new, i_new, j_new;

// ======= [ Register Instantiation ] =======
register REG_X(.d(x_new), .q(x), .en(en_x), .clk(clk));
register REG_Y(.d(y_new), .q(y), .en(en_y), .clk(clk));
register REG_A(.d(a_new), .q(a), .en(en_a), .clk(clk));
register REG_B(.d(b_new), .q(b), .en(en_b), .clk(clk));
register #(16) REG_N(.d(n_new), .q(n), .en(en_iteration), .clk(clk));
register #(16) REG_I(.d(i_new), .q(x2), .en(en_x_pixel), .clk(clk));
register #(16) REG_J(.d(j_new), .q(y2), .en(en_y_pixel), .clk(clk));

// ====== [ LOOP INTERMEDIATE CALC ] =======
wire signed [31:0] aa, bb, ab;
multiplier M_AA(.a(a), .b(a), .out(aa));
multiplier M_BB(.a(b), .b(b), .out(bb));
multiplier M_AB(.a(a), .b(b), .out(ab));

wire signed [31:0] twoab = ab + ab;
wire signed [31:0] distance = aa + bb;

// ====== [ COMBINATIONAL NEXT VALUE LOGIC ] =======
assign x_new = init_x ? xmin : (x + dx);
assign y_new = init_y ? ymin : (y + dy);
assign a_new = init_a ? x : (aa - bb + x);
assign b_new = init_b ? y : (twoab + y);
assign n_new = init_iteration_c ? 16'd0 : (n + 16'd1);
assign i_new = init_x_pixel ? 16'd0 : (x2 + 16'd1);
assign j_new = init_y_pixel ? 16'd0 : (y2 + 16'd1);

// ====== [ BOOLEAN STATE MACHINE INPUT ] =======
wire completed_iterations = (n_new == iterations);
wire needed_iterations = (n_new < iterations);
wire x_pixel_done = (i_new == `WIDTH);
wire y_pixel_done = (j_new == `HEIGHT);
wire esc_condition = (distance > max_distance);

// ====== [ STATE MACHINE ] =======
state SM(
	.clk(clk), .rst(rstn), .start(start),
	.completed_iterations(completed_iterations), .needed_iterations(needed_iterations),
	.x_pixel_done(x_pixel_done), .y_pixel_done(y_pixel_done), .esc_condition(esc_condition),
	.en_x(en_x), .en_y(en_y), .en_a(en_a), .en_b(en_b), .en_iteration(en_iteration),
	.en_x_pixel(en_x_pixel), .en_y_pixel(en_y_pixel),
	.init_x(init_x), .init_y(init_y), .init_a(init_a), .init_b(init_b),
	.init_iteration_c(init_iteration_c), .init_x_pixel(init_x_pixel), .init_y_pixel(init_y_pixel),
	.plot_pixels(vga_plot_pixels),
	.done(done)
);

// ====== [ VGA OUTPUT ] =======
assign vga_x = x2[`ifdef HIGH_RES 8:0 `else 7:0 `endif];
assign vga_y = y2[`ifdef HIGH_RES 7:0 `else 6:0 `endif];

// ====== [ VGA COLOR OUTPUT ] =======
assign vga_colour = 
    (n < 5)  ? 3'b000 :  // Black
    (n < 7)  ? 3'b001 :  // Blue
    (n < 12) ? 3'b010 :  // Green
    (n < 24) ? 3'b011 :  // Cyan
               3'b111;   // Yellow

endmodule
