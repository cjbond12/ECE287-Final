// FIXED POINT CONVENTION (32 bits)
// | 10 integer bits | 22 fraction bits |
// Splits the 32-bit number into 10 bits for the integer part 
// and 22 bits for the fractional part.
`define INT(n) n[31:22]  			// Integer part of the fixed-point number
`define FRAC(n) n[21:0]  			// Fractional part of the fixed-point number

// Define resolution
`define HIGH_RES 						// Enable high-resolution mode
`ifdef HIGH_RES
	`define WIDTH 16'd320  			// Width of the display for high resolution
	`define HEIGHT 16'd240 			// Height of the display for high resolution
`else
	`define WIDTH 16'd160  			// Width of the display for low resolution
	`define HEIGHT 16'd120 			// Height of the display for low resolution
`endif

module fractal_gen(
	input clk,                		// Clock signal
   input rstn,               		// Active-low reset signal
   input start,              		// Start computation signal
   output done,              		// Signal indicating computation is complete

   // Zoom and position control inputs
   input [2:0] zoom_level,      	// Zoom level selector
   input [2:0] h_offset_level,	// Horizontal offset selector
   input [2:0] v_offset_level,	// Vertical offset selector

   // VGA output signals
   output [`WIDTH-1:0] vga_x, 	// Horizontal pixel coordinate for VGA
   output [`HEIGHT-1:0] vga_y,	// Vertical pixel coordinate for VGA
   output [2:0] vga_colour,  		// Pixel color for VGA display
   output vga_plot_pixels   		// Signal to plot pixels on VGA
);

// ======= [ Parameters ] =======
// Fixed-point scaling factors for fractal dimensions and steps
parameter SCALE_FACTOR_075 = {10'b0, 2'b11, 20'b0};             		// Represents 0.75 in 10.22 fixed-point format for height scaling
parameter SCALE_FACTOR_STEP_X = {10'b0, 22'b0000000011001100110011}; // X-axis step size scaling factor (1/320 for high resolution)
parameter SCALE_FACTOR_STEP_Y = {10'b0, 22'b0000000100010001000100}; // Y-axis step size scaling factor (1/240 for high resolution)

// ======= [ Wires and Registers ] =======
// Wires for fractal dimensions, offsets, and steps
wire signed [31:0] w, h, xmin, xmax, ymin, ymax, dx, dy; 
wire signed [31:0] h_offset, v_offset; 						// Horizontal and vertical offsets
reg signed [31:0] w_reg, h_offset_reg, v_offset_reg; 		// Registers for zoom and offset calculations

// ======= [ Width and Height Calculations ] =======
// Calculate the width of the fractal based on the zoom level
always @(*) begin
	case (zoom_level)
		3'b000: w_reg = {10'd10, 22'b0};  			// Zoom level 0: Width = 10
		3'b001: w_reg = {10'd4, 22'b0};   			// Zoom level 1: Width = 4
      3'b010: w_reg = {10'd2, 22'b0};   			// Zoom level 2: Width = 2
      3'b011: w_reg = {10'd1, 22'b0};   			// Zoom level 3: Width = 1
      3'b100: w_reg = {10'b0, 2'b11, 20'b0}; 	// Zoom level 4: Width = 0.75
      3'b101: w_reg = {10'b0, 1'b1, 21'b0};  	// Zoom level 5: Width = 0.5
      3'b110: w_reg = {10'b0, 3'b011, 19'b0};	// Zoom level 6: Width = 0.375
      3'b111: w_reg = {10'b0, 2'b01, 20'b0};  	// Zoom level 7: Width = 0.25
	endcase
end
assign w = w_reg; // Assign calculated width to the wire

// Calculate the height as 0.75 times the width using a multiplier
multiplier WIDTH_TO_HEIGHT(
	.a(w),                     // Input: Width
   .b(SCALE_FACTOR_075),		// Scaling factor for height
   .out(h)                   	// Output: Height
);

// ======= [ Offset Calculations ] =======
// Calculate the horizontal offset based on the offset level
always @(*) begin
	case (h_offset_level)
		3'b000: h_offset_reg = {10'd3, 1'b1, 21'b0};  			// Horizontal offset = 3.5
      3'b001: h_offset_reg = {10'd2, 2'b11, 20'b0}; 			// Horizontal offset = 2.75
      3'b010: h_offset_reg = {10'd2, 22'b0};        			// Horizontal offset = 2.0
      3'b011: h_offset_reg = {10'd1, 1'b1, 22'b0};  			// Horizontal offset = 1.5
      3'b100: h_offset_reg = {10'd1, 22'b0};        			// Horizontal offset = 1.0
      3'b101: h_offset_reg = {10'd0, 2'b01, 20'b0}; 			// Horizontal offset = 0.25
      3'b110: h_offset_reg = {10'd0, 22'b0};        			// Horizontal offset = 0.0
      3'b111: h_offset_reg = {10'b1111111111, 1'b1, 21'b0}; // Horizontal offset = -0.5
	endcase
end
assign h_offset = h_offset_reg; // Assign horizontal offset to the wire

// Calculate the vertical offset based on the offset level
always @(*) begin
	case (v_offset_level)
		3'b000: v_offset_reg = {10'd2, 22'b0};        			// Vertical offset = 2.0
      3'b001: v_offset_reg = {10'd1, 1'b1, 21'b0};  			// Vertical offset = 1.5
      3'b010: v_offset_reg = {10'd1, 22'b0};        			// Vertical offset = 1.0
      3'b011: v_offset_reg = {10'd0, 1'b1, 22'b0};  			// Vertical offset = 0.5
      3'b100: v_offset_reg = {10'd0, 22'b0};        			// Vertical offset = 0.0
      3'b101: v_offset_reg = {10'b1111111111, 1'b1, 21'b0}; // Vertical offset = -0.5
      3'b110: v_offset_reg = {10'b1111111111, 22'b0};       // Vertical offset = -1.0
      3'b111: v_offset_reg = {10'b1111111110, 1'b1, 21'b0}; // Vertical offset = -1.5
	endcase
end
assign v_offset = v_offset_reg; // Assign vertical offset to the wire

// ======= [ Coordinate Calculations ] =======
// Compute the bounds for the fractal's x and y coordinates
assign xmin = ((w + h_offset) >> 1) * ~(32'b0); 			// Minimum x-coordinate (center minus half-width)
assign xmax = xmin + w;                         			// Maximum x-coordinate (xmin + width)
assign ymin = ((h + v_offset) >> 1) * ~(32'b0); 			// Minimum y-coordinate (center minus half-height)
assign ymax = ymin + h;                         			// Maximum y-coordinate (ymin + height)

// Compute the step sizes for the x and y coordinates
math X_STEP_SIZE(
	.a(xmax - xmin),                    // Input: Range of x-coordinates
   .b(SCALE_FACTOR_STEP_X),            // Input: Scaling factor for X-axis step size
   .out(dx)                            // Output: Step size for X-axis
);

math Y_STEP_SIZE(
   .a(ymax - ymin),                    // Input: Range of y-coordinates
   .b(SCALE_FACTOR_STEP_Y),            // Input: Scaling factor for Y-axis step size
   .out(dy)                            // Output: Step size for Y-axis
);

// ======= [ Constants for Computation ] =======
// Define constants for fractal computation
wire [15:0] iterations = 16'd32;                	// Maximum number of iterations per pixel
wire signed [31:0] max_distance = {10'd16, 22'b0}; // Escape radius squared (16.0 in fixed-point format)

// ======= [ Registers and Signals ] =======
// Signals and registers for fractal computation and state management
wire en_x, en_y, en_a, en_b, en_iteration, en_x_pixel, en_y_pixel; 	// Enable signals for updating registers
wire signed [31:0] x, y, a, b;                  							// Current pixel coordinates and complex number values
wire signed [31:0] x_new, y_new, a_new, b_new;  							// Updated values for pixel coordinates and complex numbers
wire [15:0] n, x2, y2;                          							// Iteration counter and pixel indices
wire [15:0] n_new, i_new, j_new;                							// Updated iteration count and pixel indices

// ======= [ Register Instantiation ] =======
// Instantiate registers to store intermediate and final fractal calculations.

register REG_X(.d(x_new), .q(x), .en(en_x), .clk(clk));        			// Register for the x-coordinate of the current pixel
register REG_Y(.d(y_new), .q(y), .en(en_y), .clk(clk));        			// Register for the y-coordinate of the current pixel
register REG_A(.d(a_new), .q(a), .en(en_a), .clk(clk));        			// Register for the real part (a) of the complex number
register REG_B(.d(b_new), .q(b), .en(en_b), .clk(clk));        			// Register for the imaginary part (b) of the complex number
register #(16) REG_N(.d(n_new), .q(n), .en(en_iteration), .clk(clk)); 	// Register for the iteration counter
register #(16) REG_I(.d(i_new), .q(x2), .en(en_x_pixel), .clk(clk));  	// Register for the horizontal pixel index
register #(16) REG_J(.d(j_new), .q(y2), .en(en_y_pixel), .clk(clk));  	// Register for the vertical pixel index

// ====== [ LOOP INTERMEDIATE CALC ] =======
// Compute intermediate values required for the Mandelbrot iteration formula.

wire signed [31:0] aa, bb, ab;        		// Temporary wires to hold intermediate values
multiplier M_AA(.a(a), .b(a), .out(aa)); 	// Compute a^2 (square of the real component)
multiplier M_BB(.a(b), .b(b), .out(bb)); 	// Compute b^2 (square of the imaginary component)
multiplier M_AB(.a(a), .b(b), .out(ab)); 	// Compute a*b (product of real and imaginary components)

wire signed [31:0] twoab = ab + ab;   	// Compute 2 * a * b (real part of the product)
wire signed [31:0] distance = aa + bb; // Compute |z|^2 = a^2 + b^2 (escape condition)

// ====== [ COMBINATIONAL NEXT VALUE LOGIC ] =======
// Calculate the next values for the Mandelbrot iteration.

assign x_new = init_x ? xmin : (x + dx);         			// Update x-coordinate, reset to xmin if init_x is high
assign y_new = init_y ? ymin : (y + dy);         			// Update y-coordinate, reset to ymin if init_y is high
assign a_new = init_a ? x : (aa - bb + x);       			// Compute new real part: a = a^2 - b^2 + x
assign b_new = init_b ? y : (twoab + y);         			// Compute new imaginary part: b = 2*a*b + y
assign n_new = init_iteration_c ? 16'd0 : (n + 16'd1); 	// Increment iteration counter, reset if init_iteration_c is high
assign i_new = init_x_pixel ? 16'd0 : (x2 + 16'd1);    	// Increment horizontal pixel index, reset if init_x_pixel is high
assign j_new = init_y_pixel ? 16'd0 : (y2 + 16'd1);    	// Increment vertical pixel index, reset if init_y_pixel is high

// ====== [ BOOLEAN STATE MACHINE INPUT ] =======
// Signals used by the state machine to control the computation.

wire completed_iterations = (n_new == iterations);   // Check if maximum iterations are reached for the current pixel
wire needed_iterations = (n_new < iterations);       // Check if iterations are still needed for the current pixel
wire x_pixel_done = (i_new == `WIDTH);               // Check if all horizontal pixels are processed
wire y_pixel_done = (j_new == `HEIGHT);              // Check if all vertical pixels are processed
wire esc_condition = (distance > max_distance);      // Check if the escape condition is met (|z|^2 > 4)

// ====== [ STATE MACHINE ] =======
// State machine to control the fractal computation and pixel plotting.
state SM(
	.clk(clk), .rst(rstn), .start(start),
   .completed_iterations(completed_iterations), .needed_iterations(needed_iterations),
   .x_pixel_done(x_pixel_done), .y_pixel_done(y_pixel_done), .esc_condition(esc_condition),
   .en_x(en_x), .en_y(en_y), .en_a(en_a), .en_b(en_b), .en_iteration(en_iteration),
   .en_x_pixel(en_x_pixel), .en_y_pixel(en_y_pixel),
   .init_x(init_x), .init_y(init_y), .init_a(init_a), .init_b(init_b),
   .init_iteration_c(init_iteration_c), .init_x_pixel(init_x_pixel), .init_y_pixel(init_y_pixel),
   .plot_pixels(vga_plot_pixels),                   // Signal to plot the pixel on the VGA display
   .done(done)                                      // Signal to indicate that computation is complete
);

// ====== [ VGA OUTPUT ] =======
// Assign the pixel coordinates for the VGA display.

assign vga_x = x2[`ifdef HIGH_RES 8:0 `else 7:0 `endif]; // Horizontal coordinate for VGA
assign vga_y = y2[`ifdef HIGH_RES 7:0 `else 6:0 `endif]; // Vertical coordinate for VGA

// ====== [ VGA COLOR OUTPUT ] =======
// Assign colors based on the iteration count to create a gradient for the fractal visualization.
// With resolution constraints it only goes to roughly 30 iterations before its just white
assign vga_colour = 
    (n < 5)  ? 3'b000 :  // Black for very low iteration counts
    (n < 7)  ? 3'b001 :  // Blue for slightly higher iteration counts
    (n < 12) ? 3'b010 :  // Green for moderate iteration counts
    (n < 24) ? 3'b011 :  // Cyan for high iteration counts
	 (n < 34) ? 3'b101 :  // ? color
               3'b111 ;  // White for very high iteration counts

endmodule
