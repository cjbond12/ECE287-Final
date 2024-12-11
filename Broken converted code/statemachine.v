module statemachine (
    input clk,                     // Clock signal
    input rst,                     // Reset signal
    input start,                   // Start computation signal

    input n_equals_iterations,     // Indicates pixel iteration completion
    input n_lt_iterations,         // Indicates if more iterations are needed
    input donei,                   // Horizontal pixel processing complete
    input donej,                   // Vertical pixel processing complete
    input dist_gt_max_dist,        // Escape condition met

    output reg enx,                // Enable `x` register
    output reg eny,                // Enable `y` register
    output reg ena,                // Enable `a` register
    output reg enb,                // Enable `b` register
    output reg enn,                // Enable iteration count register (`n`)
    output reg eni,                // Enable horizontal pixel index register (`i`)
    output reg enj,                // Enable vertical pixel index register (`j`)

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

// State encoding using parameter for better readability and maintenance
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
        ITERLOOP: next = (dist_gt_max_dist || ~n_lt_iterations) ? PLOT : ITERLOOP;
                  // Transition to PLOT if escape or max iterations reached; otherwise, continue
        PLOT:    next = donei ? ENDLOOP : ILOOP; // Transition to ENDLOOP if row complete; otherwise, continue ILOOP
        ENDLOOP: next = donej ? DONE : JLOOP;    // Transition to DONE if all rows complete; otherwise, next row
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
    enx = 1'b0; eny = 1'b0; ena = 1'b0; enb = 1'b0;
    enn = 1'b0; eni = 1'b0; enj = 1'b0;
    initx = 1'b0; inity = 1'b0; inita = 1'b0; initb = 1'b0;
    initn = 1'b0; initi = 1'b0; initj = 1'b0;
    plot = 1'b0; done = 1'b0;

    // State-specific assignments
    case (current)
        INIT: begin
            inity = 1'b1; eny = 1'b1;   // Reset and enable y register
            initj = 1'b1; enj = 1'b1;   // Reset and enable vertical index (j)
        end

        JLOOP: begin
            initx = 1'b1; enx = 1'b1;   // Reset and enable x register
            initi = 1'b1; eni = 1'b1;   // Reset and enable horizontal index (i)
        end

        ILOOP: begin
            inita = 1'b1; ena = 1'b1;   // Reset and enable `a` register
            initb = 1'b1; enb = 1'b1;   // Reset and enable `b` register
            initn = 1'b1; enn = 1'b1;   // Reset and enable iteration counter (n)
        end

        ITERLOOP: begin
            ena = 1'b1; enb = 1'b1;     // Enable updates for `a` and `b` registers
            enn = ~dist_gt_max_dist;    // Increment iteration count if within escape radius
        end

        PLOT: begin
            enx = 1'b1; eni = 1'b1;     // Enable updates for x and horizontal index (i)
            plot = 1'b1;                // Enable VGA plotting
        end

        ENDLOOP: begin
            eny = 1'b1; enj = 1'b1;     // Enable updates for y and vertical index (j)
        end

        DONE: begin
            done = 1'b1;                // Indicate computation completion
        end
    endcase
end

endmodule
