// 输入 x = 0-255，输出相应占空比 x/255 的 PWM 波

module PWMDriver(
    input clk,
    input [7:0] inputNum,
    input en,
    output reg pwm
);

    reg [7:0] count;

    always @(negedge clk) begin
        if (~en) begin
            if (count <= inputNum)
                pwm <= 1;
            else
                pwm <= 0;

            if (count == 255)
                count <= 0;
            else
                count <= count + 1;
        end else begin
            pwm <= 0;
        end
    end

endmodule