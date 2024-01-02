module Debounce (
    input wire clk,
    input wire keyIn,
    output reg keyOut
);

    reg [1:0] count = 2'b00;

    always @(negedge clk) begin
        if (keyIn != keyOut) begin
            count <= count + 1;
            if (count == 2'b11) begin
                keyOut <= keyIn;
                count <= 2'b00;
            end
        end
        else begin
            count <= 2'b00;
        end
    end
endmodule