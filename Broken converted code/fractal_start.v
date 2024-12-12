`define HIGH_RES

module fractal_start(
	input CLOCK_50,    	// System clock input
   input [3:0] KEY,    	// Keys for reset and control
   input [9:0] SW,    	// Switches for zoom, offset, and other configurations

   output [9:0] LEDR,  	// LEDs for debugging outputs
   output [9:0] VGA_R, 	// VGA Red signal output
   output [9:0] VGA_G, 	// VGA Green signal output
   output [9:0] VGA_B, 	// VGA Blue signal output
   output VGA_HS,     	// VGA Horizontal sync signal
   output VGA_VS,    	// VGA Vertical sync signal
   output VGA_BLANK,  	// VGA Blanking signal
   output VGA_SYNC,  	// VGA Sync signal
   output VGA_CLK     	// VGA Clock signal
);

   // Internal signals
	wire reset = KEY[3];   		// Reset signal (active-high, triggered by KEY[3])
   wire start_signal = 1'b1;  // Always-on start signal to init_x_pixelate computation
   wire plot_pixels;     		// Signal to en_able pixel plot_pixelsting
   wire done;                 // Signal to indicate fractal computation completion
   wire [2:0] color;          // VGA color signal for each pixel

	// Define resolution-dependent coordinates for the VGA output
   `ifdef HIGH_RES
		wire [8:0] x;          	// Horizontal coordinate for high resolution (9 bits)
      wire [7:0] y;          	// Vertical coordinate for high resolution (8 bits)
   `else
		wire [7:0] x;          	// Horizontal coordinate for low resolution (8 bits)
      wire [6:0] y;          	// Vertical coordinate for low resolution (7 bits)
   `endif
   // Reset and start signals
   assign reset = KEY[3];  	// Reset signal, active when KEY[3] is pressed
   assign start = 1'b1;    	// Start signal, always en_abled

   // VGA Adapter instance with resolution-dependent parameters
   `ifdef HIGH_RES
   vga_adapter #(.RESOLUTION("320x240")) VGA_ADAPTER (
   `else
   vga_adapter #(.RESOLUTION("160x120")) VGA_ADAPTER (
   `endif
		.resetn(reset),       			// Active-low reset signal
      .clock(CLOCK_50),     			// 50 MHz clock input
      .colour(color),       			// VGA pixel color input
      .x(x),                			// VGA horizontal coordinate
      .y(y),                			// VGA vertical coordinate
      .plot_pixels(plot_pixels),  	// Signal to en_able pixel plot_pixelsting
      .VGA_R(VGA_R),        			// VGA Red signal
      .VGA_G(VGA_G),        			// VGA Green signal
      .VGA_B(VGA_B),        			// VGA Blue signal
      .VGA_HS(VGA_HS),      			// VGA Horizontal sync signal
      .VGA_VS(VGA_VS),      			// VGA Vertical sync signal
      .VGA_BLANK(VGA_BLANK),			// VGA blanking signal
      .VGA_SYNC(VGA_SYNC),  			// VGA sync signal
      .VGA_CLK(VGA_CLK)     			// VGA clock signal
    );
	 
    // Mandelbrot module instance
    fractal_gen MB(
      .clk(CLOCK_50),              // System clock (50 MHz)
      .rstn(reset),                // Active-low reset signal
      .start(start),               // Start signal to begin Mandelbrot computation
      .done(done),                 // Signal indicating computation completion

      // Inputs for zoom and offset levels
      .zoom_level(SW[2:0]),        // Zoom level controlled by switches [2:0]
      .h_offset_level(SW[5:3]),    // Horizontal offset level (switches [5:3])
      .v_offset_level(SW[8:6]),    // Vertical offset level (switches [8:6])

      // Outputs for VGA display
      .vga_x(x),                   // Horizontal pixel coordinate for VGA
      .vga_y(y),                   // Vertical pixel coordinate for VGA
      .vga_colour(color),          // Color data for the current pixel
      .vga_plot_pixels(plot_pixels)// Signal to en_able plot_pixelsting to VGA
    );

    // Debugging LEDs
    `ifdef HIGH_RES
    assign LEDR[7:0] = y;         	// Show 8-bit vertical coordinate on LEDs in high-resolution mode
    `else
    assign LEDR[6:0] = y;         	// Show 7-bit vertical coordinate on LEDs in low-resolution mode
    `endif

    assign LEDR[8] = plot_pixels;  	// LED 8 lights up when plot_pixelsting is active
    assign LEDR[9] = done;        	// LED 9 lights up when computation is complete

endmodule

