module register #(parameter BITS = 32) (
    input [BITS-1:0] d,     // Data input
    input en,               // en_able signal
    input clk,              // Clock signal
    output reg [BITS-1:0] q // Output register
);
    always @(posedge clk) 
        if (en) q <= d; // Update q with d when en_able is high
endmodule
