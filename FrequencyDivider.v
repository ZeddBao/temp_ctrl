module FrequencyDivider(
    input wire clk,                      // Input clock signal
	output reg clk1M = 1,
    output reg clk12k = 1,
    output reg clk240 = 1,
    output reg clk2_4 = 1,
    output reg clk1_2 = 1,
    output reg clk1 = 1
);

    reg [3:0] count12 = 0;     // 24 MHz -> 1 MHz
    reg [9:0] count1k = 0;   // 24 MHz -> 12 kHz
    reg [4:0] count25 = 0;   // 12 kHz -> 240 Hz
    reg [5:0] count50 = 0;   // 240 Hz -> 2.4 Hz
    reg [6:0] count120 = 0;  // 240 Hz -> 1 Hz

    always @(negedge clk) begin
        // For 12 kHz clock
        if (count1k == 999) begin
            count1k <= 0;                  // Reset the counter
            clk12k <= ~clk12k;           // Toggle the output clock
        end
        else begin
            count1k <= count1k + 1;     // Increment the counter
        end

        // For 1 MHz clock
        if (count12 == 11) begin
            count12 <= 0;                   // Reset the counter
            clk1M <= ~clk1M;                // Toggle the output clock
        end
        else begin
            count12 <= count12 + 1;         // Increment the counter
        end
    end

    always @(negedge clk12k) begin
        // For 240 Hz clock
        if (count25 == 24) begin
            count25 <= 0;                  // Reset the counter
            clk240 <= ~clk240;           // Toggle the output clock
        end
        else begin
            count25 <= count25 + 1;       // Increment the counter
        end
    end

    always @(negedge clk240) begin
        // For 2.4 Hz clock
        if (count50 == 49) begin
            count50 <= 0;                  // Reset the counter
            clk2_4 <= ~clk2_4;           // Toggle the output clock
        end
        else begin
            count50 <= count50 + 1;       // Increment the counter
        end

        // For 1 Hz clock
        if (count120 == 119) begin
            count120 <= 0;                  // Reset the counter
            clk1 <= ~clk1;           // Toggle the output clock
        end
        else begin
            count120 <= count120 + 1;       // Increment the counter
        end
    end

    always @(negedge clk2_4) begin
        // For 1.2 Hz clock
        clk1_2 <= ~clk1_2;              // Toggle the output clock
    end
endmodule