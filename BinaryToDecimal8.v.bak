module BinaryToDecimal8(
    input wire [7:0] bin,
    output wire [3:0] d0, // Least significant digit
    output wire [3:0] d1  // Most significant digit
);
    // Convert the binary input to decimal digits
    assign d0 = bin % 10;
    assign d1 = (bin / 10) % 10;
endmodule