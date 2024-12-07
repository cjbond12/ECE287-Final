module statemachine (
    // Inputs
    input clk,
    input rst,
    input start,

    input n_equals_iterations,
    input n_lt_iterations,
    input donei,
    input donej,
    input dist_gt_max_dist,

    // Outputs
    output reg enx,
    output reg eny,
    output reg ena,
    output reg enb,
    output reg enn,
    output reg eni,
    output reg enj,

    output reg initx,
    output reg inity,
    output reg inita,
    output reg initb,
    output reg initn,
    output reg initi,
    output reg initj,

    output reg plot,
    output reg done
);

    // State encoding
    parameter IDLE = 3'b000,
              INIT = 3'b001,
              JLOOP = 3'b010,
              ILOOP = 3'b011,
              ITERLOOP = 3'b100,
              PLOT = 3'b101,
              ENDLOOP = 3'b110,
              DONE = 3'b111;

    reg [2:0] current, next;

    // Next state logic
    always @(*) begin
        case (current)
            IDLE: next = start ? INIT : IDLE;
            INIT: next = JLOOP;
            JLOOP: next = ILOOP;
            ILOOP: next = ITERLOOP;
            ITERLOOP: next = (dist_gt_max_dist || ~n_lt_iterations) ? PLOT : ITERLOOP;
            PLOT: next = donei ? ENDLOOP : ILOOP;
            ENDLOOP: next = donej ? DONE : JLOOP;
            DONE: next = DONE;
            default: next = IDLE;
        endcase
    end

    // State transition
    always @(posedge clk or negedge rst) begin
        if (!rst)
            current <= IDLE;
        else
            current <= next;
    end

    // Output logic
    always @(*) begin
        // Default values for outputs
        enx = 1'b0;
        eny = 1'b0;
        ena = 1'b0;
        enb = 1'b0;
        enn = 1'b0;
        eni = 1'b0;
        enj = 1'b0;
        initx = 1'b0;
        inity = 1'b0;
        inita = 1'b0;
        initb = 1'b0;
        initn = 1'b0;
        initi = 1'b0;
        initj = 1'b0;
        plot = 1'b0;
        done = 1'b0;

        // Output assignments based on state
        case (current)
            INIT: begin
                inity = 1'b1;
                eny = 1'b1;
                initj = 1'b1;
                enj = 1'b1;
            end
            JLOOP: begin
                initx = 1'b1;
                enx = 1'b1;
                initi = 1'b1;
                eni = 1'b1;
            end
            ILOOP: begin
                inita = 1'b1;
                ena = 1'b1;
                initb = 1'b1;
                enb = 1'b1;
                initn = 1'b1;
                enn = 1'b1;
            end
            ITERLOOP: begin
                ena = 1'b1;
                enb = 1'b1;
                enn = ~dist_gt_max_dist;
            end
            PLOT: begin
                enx = 1'b1;
                eni = 1'b1;
                plot = 1'b1;
            end
            ENDLOOP: begin
                eny = 1'b1;
                enj = 1'b1;
            end
            DONE: begin
                done = 1'b1;
            end
            default: begin
                done = 1'b0;
            end
        endcase
    end

endmodule
