module BinaryToDecimal16(
    input wire [15:0] bin,
    output wire [3:0] d0, // Least significant digit
    output wire [3:0] d1,
    output wire [3:0] d2,
    output wire [3:0] d3  // Most significant digit
);
    // Convert the binary input to decimal digits
    assign d0 = bin % 10;
    assign d1 = (bin / 10) % 10;
    assign d2 = (bin / 100) % 10;
    assign d3 = (bin / 1000) % 10;
endmodule