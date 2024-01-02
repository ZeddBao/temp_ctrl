module Display4Driver(
    input wire clk,
    input wire [15:0] inputNum,
    input wire en,
    output wire DL_a, 
    output wire DL_b, 
    output wire DL_c, 
    output wire DL_d, 
    output wire DL_e, 
    output wire DL_f, 
    output wire DL_g, 
    output wire DL_DP,
    output wire DLA_0,
    output wire DLA_1,
    output wire DLA_2,
    output wire DLA_3
);

    wire [7:0] seg; // Seven segment display
    // Map the decoder outputs to the seven segment display outputs
    assign {DL_a, DL_b, DL_c, DL_d, DL_e, DL_f, DL_g, DL_DP} = seg;

    // 16-bit binary to decimal converter
    wire [3:0] digit0, digit1, digit2, digit3;
    BinaryToDecimal16 b2d_inst (
        .bin(inputNum),
        .d0(digit0),
        .d1(digit1),
        .d2(digit2),
        .d3(digit3)
    );

    // 4-bit binary counter
    reg [1:0] counter;
    always @(negedge clk) begin
        counter <= counter + 1;
    end

    // Multiplexer to select the current digit
    wire [3:0] currDigit;
    assign currDigit = (counter == 2'b00) ? digit0 :
                           (counter == 2'b01) ? digit1 :
                           (counter == 2'b10) ? digit2 :
                           digit3;

    // Digit select signals
    assign DLA_3 = !(counter == 2'b00) | en;
    assign DLA_2 = !(counter == 2'b01) | en;
    assign DLA_1 = !(counter == 2'b10) | en;
    assign DLA_0 = !(counter == 2'b11) | en;

    // 4-to-7 segment decoder
    SevenSegmentDecoder ssd_inst (
        .bcd(currDigit),
        .seg(seg)
    );

endmodule