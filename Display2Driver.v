module Display2Driver(
    input wire [7:0] inputNum,
    input wire en,
    output wire HEX00,
    output wire HEX01,
    output wire HEX02,
    output wire HEX03,
    output wire HEX04,
    output wire HEX05,
    output wire HEX06,
    output wire HEX07,
    output wire HEX10,
    output wire HEX11,
    output wire HEX12,
    output wire HEX13,
    output wire HEX14,
    output wire HEX15,
    output wire HEX16,
    output wire HEX17
);

    wire [7:0] seg1, seg2, buffer1, buffer2;    // Seven segment display
    // Map the decoder outputs to the seven segment display outputs
    assign {HEX00, HEX01, HEX02, HEX03, HEX04, HEX05, HEX06, HEX07} = seg1;
    assign {HEX10, HEX11, HEX12, HEX13, HEX14, HEX15, HEX16, HEX17} = seg2;

    // 8-bit binary to decimal converter
    wire [3:0] digit_0, digit_1;
    BinaryToDecimal8 b2d_inst (
        .bin(inputNum),
        .d0(digit_0),
        .d1(digit_1)
    );

    SevenSegmentDecoder ssd_inst1 (
        .bcd(digit_0),
        .seg(buffer2)
    );

    SevenSegmentDecoder ssd_inst2 (
        .bcd(digit_1),
        .seg(buffer1)
    );

    assign seg1 = (en) ? 8'b11111111 : buffer1;
    assign seg2 = (en) ? 8'b11111111 : buffer2;
endmodule