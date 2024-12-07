module register #(parameter BITS = 32) (
    input [BITS-1:0] d,  // Data input
    input en,            // Enable signal
    input clk,           // Clock signal
    output reg [BITS-1:0] q // Output register
);

    always @(posedge clk) begin
        if (en)
            q <= d; // Update q with d when enable is high
    end
endmodule
