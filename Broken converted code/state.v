// Registers to hold the current and next states
module state (
	input clk,                 	// Clock signal
	input rst,                 	// Reset signal
	input start,               	// Start computation signal

	input completed_iterations,	// Indicates pixel iteration completion
	input needed_iterations,   	// Indicates if more iterations are needed
	input x_pixel_done,       		// Horizontal pixel processing complete
	input y_pixel_done,        	// Vertical pixel processing complete
	input esc_condition,        	// Escape condition met

	output reg en_x,           	// enable `x` register
	output reg en_y,           	// enable `y` register
	output reg en_a,            	// enable `a` register
	output reg en_b,            	// enable `b` register
	output reg en_iteration,   	// enable iteration count register
	output reg en_x_pixel,      	// enable horizontal pixel index register
	output reg en_y_pixel,       	// enable vertical pixel index register

	output reg init_x,           	// initialize `x` register
	output reg init_y,           	// initialize `y` register
	output reg init_a,          	// initialize `a` register
	output reg init_b,           	// initialize `b` register
	output reg init_iteration_c,	// initialize iteration counter
	output reg init_x_pixel, 		// initialize horizontal pixel index
	output reg init_y_pixel,  		// initialize vertical pixel index

	output reg plot_pixels,   		// Pixel plotting signal
	output reg done             	// Computation completion signal
);

parameter 	IDLE     = 3'b000, 	// Idle: Waiting for start signal
				INIT     = 3'b001, 	// Initialize registers
				JLOOP    = 3'b010, 	// Vertical pixel loop
				ILOOP    = 3'b011, 	// Horizontal pixel loop
				ITERLOOP = 3'b100, 	// Perform Mandelbrot iterations
				PLOT     = 3'b101, 	// Output pixel to VGA
				ENDLOOP  = 3'b110, 	// End of vertical loop
				DONE     = 3'b111; 	// Indicate computation is complete

reg [2:0] current; // Holds the current state
reg [2:0] next;    // Holds the next state

// State transition logic
always @(posedge clk or negedge rst) begin
	if (!rst)
		current <= IDLE;  // Reset to IDLE when rst is low
	else
		current <= next;  // Transition to next state on clock edge
end

// Next state logic
always @(*) begin
	case (current)
		IDLE:    next = start ? INIT : IDLE;  					// Wait for start signal to transition to INIT
		INIT:    next = JLOOP;               					// Initialize and transition to JLOOP
		JLOOP:   next = ILOOP;               					// Start horizontal loop
		ILOOP:   next = ITERLOOP;            					// Begin Mandelbrot iterations
		ITERLOOP:next = (esc_condition || ~needed_iterations) ? PLOT : ITERLOOP;
		  
		// Transition to PLOT if escape or max iterations reached; otherwise, continue
		PLOT:    next = x_pixel_done ? ENDLOOP : ILOOP;		// Transition to ENDLOOP if row complete; otherwise, continue ILOOP
		ENDLOOP: next = y_pixel_done ? DONE : JLOOP;    	// Transition to DONE if all rows complete; otherwise, next row
		DONE:    next = DONE;                   				// Stay in DONE state indefinitely
		default: next = IDLE;                   				// Safety fallback to IDLE
	endcase
end

// Output logic
always @(*) begin
	// Default values for all control signals
	en_x = 1'b0; 					en_y = 1'b0; 			en_a = 1'b0; 			en_b = 1'b0;
	en_iteration = 1'b0; 		en_x_pixel = 1'b0; 	en_y_pixel = 1'b0;
	init_x = 1'b0; 				init_y = 1'b0; 		init_a = 1'b0; 		init_b = 1'b0;
	init_iteration_c = 1'b0; 	init_x_pixel = 1'b0; init_y_pixel = 1'b0;
	plot_pixels = 1'b0; 			done = 1'b0;

	// State-specific assignments
	case (current)
		INIT: begin
			init_y = 1'b1; en_y = 1'b1;   						// Reset and enable y register
			init_y_pixel = 1'b1; en_y_pixel = 1'b1;   		// Reset and enable vertical index
		end

		JLOOP: begin
			init_x = 1'b1; en_x = 1'b1;   						// Reset and enable x register
			init_x_pixel = 1'b1; en_x_pixel = 1'b1;  			// Reset and enable horizontal
		end

		ILOOP: begin
			init_a = 1'b1; en_a = 1'b1;   						// Reset and enable `a` register
			init_b = 1'b1; en_b = 1'b1;   						// Reset and enable `b` register
			init_iteration_c = 1'b1; en_iteration = 1'b1;	// Reset and enable iteration counter
		end

		ITERLOOP: begin
			en_a = 1'b1; en_b = 1'b1;     						// Enable updates for `a` and `b` registers
			en_iteration = ~esc_condition;    					// Increment iteration count if within escape radius
		end

		PLOT: begin
			en_x = 1'b1; en_x_pixel = 1'b1;     				// Enable updates for x and horizontal index
			plot_pixels = 1'b1;                					// Enable VGA plotting
		end

		ENDLOOP: begin
			en_y = 1'b1; en_y_pixel = 1'b1;     				// Enable updates for y and vertical index
		end

		DONE: begin
			done = 1'b1;                							// Completion
		end
	endcase
end

endmodule
