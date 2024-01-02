module DecimalToBinary8(
    input wire [3:0] d0,    // Least significant digit
    input wire [3:0] d1,    // Most significant digit
    output wire [7:0] bin
);
    wire [7:0] d1Ext;
    assign d1Ext = {4'b0000, d1};
    // Convert the decimal input to binary
    assign bin = d0 + d1Ext * 10;
endmodule