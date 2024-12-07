module green_screen_generator(
    input clk,                     // System clock
    input rstn,                    // Active-low reset
    input start,                   // Start signal
    output reg done,               // Done signal

    `ifdef HIGH_RES
    output reg [8:0] vga_x,        // VGA horizontal coordinate
    output reg [7:0] vga_y,        // VGA vertical coordinate
    `else
    output reg [7:0] vga_x,        // VGA horizontal coordinate
    output reg [6:0] vga_y,        // VGA vertical coordinate
    `endif

    output reg [2:0] vga_colour,   // VGA color output
    output reg vga_plot            // VGA plot enable signal
);

    // Parameters for resolution
    `ifdef HIGH_RES
    parameter WIDTH = 320;         // Horizontal resolution
    parameter HEIGHT = 240;        // Vertical resolution
    `else
    parameter WIDTH = 160;         // Horizontal resolution
    parameter HEIGHT = 120;        // Vertical resolution
    `endif

    // Internal counters for X and Y positions
    reg [8:0] x_counter;
    reg [7:0] y_counter;

    // State encoding
    parameter IDLE = 2'b00,
              DRAW = 2'b01,
              DONE_STATE = 2'b10;

    reg [1:0] state, next_state;

    // State transition logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: next_state = start ? DRAW : IDLE;
            DRAW: next_state = (x_counter == WIDTH - 1 && y_counter == HEIGHT - 1) ? DONE_STATE : DRAW;
            DONE_STATE: next_state = IDLE; // Return to IDLE after completion
            default: next_state = IDLE;
        endcase
    end

    // Output and counter logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            vga_x <= 0;
            vga_y <= 0;
            x_counter <= 0;
            y_counter <= 0;
            vga_colour <= 3'b010; // Green
            vga_plot <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    vga_x <= 0;
                    vga_y <= 0;
                    x_counter <= 0;
                    y_counter <= 0;
                    vga_colour <= 3'b010; // Green
                    vga_plot <= 0;
                    done <= 0;
                end
                DRAW: begin
                    vga_plot <= 1;
                    vga_colour <= 3'b010; // Green
                    vga_x <= x_counter;
                    vga_y <= y_counter;

                    // Increment counters
                    if (x_counter < WIDTH - 1) begin
                        x_counter <= x_counter + 1;
                    end else begin
                        x_counter <= 0;
                        if (y_counter < HEIGHT - 1) begin
                            y_counter <= y_counter + 1;
                        end else begin
                            y_counter <= 0;
                        end
                    end
                end
                DONE_STATE: begin
                    vga_plot <= 0;
                    done <= 1;
                end
            endcase
        end
    end

endmodule
