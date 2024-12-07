`define HIGH_RES

module fractal_generator_top(
    input CLOCK_50,          // System clock input
    input [3:0] KEY,         // Keys for reset and control
    input [9:0] SW,          // Switches for input and configuration

    output [9:0] LEDR,       // LEDs for debugging
    output [9:0] VGA_R,      // VGA Red color signal
    output [9:0] VGA_G,      // VGA Green color signal
    output [9:0] VGA_B,      // VGA Blue color signal
    output VGA_HS,           // VGA horizontal sync
    output VGA_VS,           // VGA vertical sync
    output VGA_BLANK,        // VGA blanking signal
    output VGA_SYNC,         // VGA synchronization
    output VGA_CLK           // VGA clock
);

    // Internal signals
    wire reset;              // Reset signal from KEY
    wire start;              // Start signal (always enabled)
    wire plot;               // Plot signal for VGA
    wire done;               // Completion signal
    wire [2:0] color;        // Color data for VGA
    wire green_plot;         // Plot signal for green screen
    wire [2:0] green_color;  // Green screen color data

    // Resolution-dependent signals
    `ifdef HIGH_RES
    wire [8:0] x;            // Horizontal pixel coordinate
    wire [7:0] y;            // Vertical pixel coordinate
    `else
    wire [7:0] x;            // Horizontal pixel coordinate
    wire [6:0] y;            // Vertical pixel coordinate
    `endif

    // Assign reset and start signals
    assign reset = KEY[3];   // Active-low reset
    assign start = 1'b1;     // Start always enabled

    // VGA Adapter instance
    vga_adapter #(
        .RESOLUTION(`ifdef HIGH_RES "320x240" `else "160x120" `endif)
    ) VA (
        .resetn(reset),       // Reset signal (active low)
        .clock(CLOCK_50),     // Input clock
        .colour(green_color), // Green screen color data
        .x(x),                // Horizontal coordinate
        .y(y),                // Vertical coordinate
        .plot(green_plot),    // Green screen plot signal
        .VGA_R(VGA_R),        // VGA Red output
        .VGA_G(VGA_G),        // VGA Green output
        .VGA_B(VGA_B),        // VGA Blue output
        .VGA_HS(VGA_HS),      // VGA horizontal sync
        .VGA_VS(VGA_VS),      // VGA vertical sync
        .VGA_BLANK(VGA_BLANK),// VGA blanking
        .VGA_SYNC(VGA_SYNC),  // VGA synchronization
        .VGA_CLK(VGA_CLK)     // VGA clock
    );

// Green Screen module instance
green_screen_generator green_screen (
    .clk(CLOCK_50),       // System clock
    .rstn(reset),         // Reset signal
    .start(start),        // Start signal
    .done(done),          // Done signal (unused but provided for consistency)

    .vga_x(x),            // VGA horizontal coordinate
    .vga_y(y),            // VGA vertical coordinate
    .vga_colour(color),   // VGA color output
    .vga_plot(plot)       // VGA plot enable signal
);


    // Debugging LED assignments
    assign LEDR[7:0] = y;    // Display vertical coordinate on LEDs
    assign LEDR[8] = green_plot; // Indicate green screen plot signal
    assign LEDR[9] = done;   // Indicate completion signal

endmodule
