module multiplier (
    input signed [31:0] a,   // Input operand a
    input signed [31:0] b,   // Input operand b
    output signed [31:0] out // Output result
);
    wire signed [63:0] product; // Intermediate 64-bit product

    assign product = a * b;       // Perform signed multiplication
    assign out = product[53:22];  // Extract 32-bit fixed-point result
endmodule
