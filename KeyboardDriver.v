// module KeyboardDriver(
//     input wire clk,              // Input clock signal
//     input wire KEY9,             // Column 0
//     input wire KEY10,            // Column 1
//     input wire KEY11,            // Column 2
//     input wire KEY12,            // Column 3
//     output reg KEY13,            // Row 0
//     output reg KEY14,            // Row 1
//     output reg KEY15,            // Row 2
//     output reg KEY16,            // Row 3
//     output reg [3:0] keyOut,     // Output key signal
//     output reg keyValid = 1'b1   // Output validity signal
// );

//     reg [1:0] rowScan = 2'b00;   // Row scanning state
//     wire keyPress = ~KEY9 | ~KEY10 | ~KEY11 | ~KEY12; // Key press detection

//     always @(negedge clk) begin
//         if (keyPress) begin
//             // Update the key output
//             if (~KEY9) keyOut = {rowScan, 2'b00};
//             else if (~KEY10) keyOut = {rowScan, 2'b01};
//             else if (~KEY11) keyOut = {rowScan, 2'b10};
//             else if (~KEY12) keyOut = {rowScan, 2'b11};
//             keyValid = 1'b0; // Set keyValid to 0
//         end else begin
//             keyValid = 1'b1; // Set keyValid to 1
//         end
//         // Scan the next row
//         rowScan = rowScan + 1;
//         case (rowScan)
//             2'b00: {KEY13, KEY14, KEY15, KEY16} = 4'b0111;
//             2'b01: {KEY13, KEY14, KEY15, KEY16} = 4'b1011;
//             2'b10: {KEY13, KEY14, KEY15, KEY16} = 4'b1101;
//             2'b11: {KEY13, KEY14, KEY15, KEY16} = 4'b1110;
//             default: {KEY13, KEY14, KEY15, KEY16} = 4'b1111;
//         endcase
//     end
// endmodule

module KeyboardDriver(
    input wire clk,              // Input clock signal
    input wire KEY9,             // Column 0
    input wire KEY10,            // Column 1
    input wire KEY11,            // Column 2
    input wire KEY12,            // Column 3
    output reg KEY13,            // Row 0
    output reg KEY14,            // Row 1
    output reg KEY15,            // Row 2
    output reg KEY16,            // Row 3
    output reg [3:0] keyOut,     // Output key signal
    output reg keyValid = 1'b1   // Output validity signal
);

    reg [1:0] rowScan = 2'b00;   // Row scanning state
    reg [3:0] keyPressedCount = 4'b0000;       // 多设置一位防止毛刺
    wire keyPress = ~KEY9 | ~KEY10 | ~KEY11 | ~KEY12; // Key press detection

    always @(negedge clk) begin

        if (keyPressedCount == 4'b0000 && !keyPress) begin
            keyValid = 1'b1; // Set keyValid to 1
        end
        else if (keyPressedCount > 4'b0000 && !keyPress) begin
            keyPressedCount = keyPressedCount - 1;
        end
        else if (keyPressedCount == 4'b0000 && keyPress) begin
            // Update the key output
            if (~KEY9) keyOut = {rowScan, 2'b00};
            else if (~KEY10) keyOut = {rowScan, 2'b01};
            else if (~KEY11) keyOut = {rowScan, 2'b10};
            else if (~KEY12) keyOut = {rowScan, 2'b11};
            keyPressedCount = 4'b1111; // Set keyPressedCount to 4
            keyValid = 1'b0; // Set keyValid to 0
        end

        // Scan the next row
        rowScan = rowScan + 1;

        case (rowScan)
            2'b00: {KEY13, KEY14, KEY15, KEY16} = 4'b0111;
            2'b01: {KEY13, KEY14, KEY15, KEY16} = 4'b1011;
            2'b10: {KEY13, KEY14, KEY15, KEY16} = 4'b1101;
            2'b11: {KEY13, KEY14, KEY15, KEY16} = 4'b1110;
            default: {KEY13, KEY14, KEY15, KEY16} = 4'b1111;
        endcase
    end
endmodule