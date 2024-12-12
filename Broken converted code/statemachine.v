module states (
    input clk,                     // Clock signal
    input rst,                     // Reset signal
    input start,                   // Start computation signal

    input completed_iterations,     // Indicates pixel iteration completion
    input needed_iterations,         // Indicates if more iterations are needed
    input x_pixel_done,                   // Horizontal pixel processing complete
    input y_pixel_done,                   // Vertical pixel processing complete
    input esc_condition,        // Escape condition met

    output reg en_x,                // en_able `x` register
    output reg en_y,                // en_able `y` register
    output reg en_a,                // en_able `a` register
    output reg en_b,                // en_able `b` register
    output reg en_iteration,                // en_able iteration count register (`n`)
    output reg en_x_pixel,                // en_able horizontal pixel index register (`i`)
    output reg en_y_pixel,                // en_able vertical pixel index register (`j`)

    output reg initx,              // Initialize `x` register
    output reg inity,              // Initialize `y` register
    output reg inita,              // Initialize `a` register
    output reg initb,              // Initialize `b` register
    output reg initn,              // Initialize iteration counter (`n`)
    output reg initi,              // Initialize horizontal pixel index (`i`)
    output reg initj,              // Initialize vertical pixel index (`j`)

    output reg plot,               // Pixel plotting signal
    output reg done                // Computation completion signal
);

// State encoding using parameter for better readability and mainten_ance
parameter IDLE     = 3'b000, // Idle: Waiting for start signal
          INIT     = 3'b001, // Initialize registers
          JLOOP    = 3'b010, // Vertical pixel loop
          ILOOP    = 3'b011, // Horizontal pixel loop
          ITERLOOP = 3'b100, // Perform Mandelbrot iterations
          PLOT     = 3'b101, // Output pixel to VGA
          ENDLOOP  = 3'b110, // End of vertical loop
          DONE     = 3'b111; // Indicate computation is complete

reg [2:0] current; // Holds the current state
reg [2:0] next;    // Holds the next state

// Next state logic
always @(*) begin
    case (current)
        IDLE:    next = start ? INIT : IDLE;  // Wait for start signal to transition to INIT
        INIT:    next = JLOOP;               // Initialize and transition to JLOOP
        JLOOP:   next = ILOOP;               // Start horizontal loop
        ILOOP:   next = ITERLOOP;            // Begin Mandelbrot iterations
        ITERLOOP: next = (esc_condition || ~needed_iterations) ? PLOT : ITERLOOP;
                  // Transition to PLOT if escape or max iterations reached; otherwise, continue
        PLOT:    next = x_pixel_done ? ENDLOOP : ILOOP; // Transition to ENDLOOP if row complete; otherwise, continue ILOOP
        ENDLOOP: next = y_pixel_done ? DONE : JLOOP;    // Transition to DONE if all rows complete; otherwise, next row
        DONE:    next = DONE;                   // Stay in DONE state indefinitely
        default: next = IDLE;                   // Safety fallback to IDLE
    endcase
end

// State transition logic
always @(posedge clk or negedge rst) begin
    if (!rst)
        current <= IDLE;  // Reset to IDLE when rst is low
    else
        current <= next;  // Transition to next state on clock edge
end

// Output logic
// Sets control signals based on the current state
always @(*) begin
    // Default values for all control signals
    en_x = 1'b0; en_y = 1'b0; en_a = 1'b0; en_b = 1'b0;
    en_iteration = 1'b0; en_x_pixel = 1'b0; en_y_pixel = 1'b0;
    initx = 1'b0; inity = 1'b0; inita = 1'b0; initb = 1'b0;
    initn = 1'b0; initi = 1'b0; initj = 1'b0;
    plot = 1'b0; done = 1'b0;

    // State-specific assignments
    case (current)
        INIT: begin
            inity = 1'b1; en_y = 1'b1;   // Reset and en_able y register
            initj = 1'b1; en_y_pixel = 1'b1;   // Reset and en_able vertical index (j)
        end

        JLOOP: begin
            initx = 1'b1; en_x = 1'b1;   // Reset and en_able x register
            initi = 1'b1; en_x_pixel = 1'b1;   // Reset and en_able horizontal index (i)
        end

        ILOOP: begin
            inita = 1'b1; en_a = 1'b1;   // Reset and en_able `a` register
            initb = 1'b1; en_b = 1'b1;   // Reset and en_able `b` register
            initn = 1'b1; en_iteration = 1'b1;   // Reset and en_able iteration counter (n)
        end

        ITERLOOP: begin
            en_a = 1'b1; en_b = 1'b1;     // en_able updates for `a` and `b` registers
            en_iteration = ~esc_condition;    // Increment iteration count if within escape radius
        end

        PLOT: begin
            en_x = 1'b1; en_x_pixel = 1'b1;     // en_able updates for x and horizontal index (i)
            plot = 1'b1;                // en_able VGA plotting
        end

        ENDLOOP: begin
            en_y = 1'b1; en_y_pixel = 1'b1;     // en_able updates for y and vertical index (j)
        end

        DONE: begin
            done = 1'b1;                // Indicate computation completion
        end
    endcase
end

endmodule
