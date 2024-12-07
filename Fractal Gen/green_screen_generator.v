module green_screen_generator(
    input clk,                 // System clock
    input rstn,                // Reset signal (active low)
    input start,               // Start signal
    output reg done,           // Done signal

    output reg [8:0] vga_x,    // VGA horizontal coordinate
    output reg [7:0] vga_y,    // VGA vertical coordinate
    output reg [2:0] vga_colour, // VGA color output
    output reg vga_plot        // VGA plot enable signal
);

    // Parameters for screen resolution
    parameter WIDTH = 320;     // Width of the screen
    parameter HEIGHT = 240;    // Height of the screen

    // Internal variables
    reg [8:0] x_counter;       // Counter for x-coordinate
    reg [7:0] y_counter;       // Counter for y-coordinate

    // Main logic for drawing the screen
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset all signals
            x_counter <= 9'd0;
            y_counter <= 8'd0;
            vga_x <= 9'd0;
            vga_y <= 8'd0;
            vga_colour <= 3'b000; // Default to black
            vga_plot <= 1'b0;
            done <= 1'b0;
        end else if (start) begin
            // Set the plot and color signals
            vga_plot <= 1'b1;
            vga_colour <= 3'b010; // Green color

            // Update coordinates
            if (x_counter < WIDTH - 1) begin
                x_counter <= x_counter + 1;
            end else begin
                x_counter <= 0;
                if (y_counter < HEIGHT - 1) begin
                    y_counter <= y_counter + 1;
                end else begin
                    y_counter <= 0;
                    done <= 1'b1; // Indicate screen is fully drawn
                end
            end

            // Assign current coordinates to VGA
            vga_x <= x_counter;
            vga_y <= y_counter;
        end
    end

endmodule
