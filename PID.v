// module PID(
//     input wire clk,
//     input wire rst, // 高电平复位
//     input wire [15:0] inputNum,
//     input wire [15:0] setNum,
//     output wire [7:0] outputNum,
//     output wire sign
// );

// wire [16:0] err;
// wire [16:0] errD;
// wire [16:0] result;
// wire [15:0] resultAbs;
// reg [16:0] currErr = 0;
// reg [16:0] lastErr = 0;
// reg [32:0] errI = 0;

// assign err = $signed(inputNum) - $signed(setNum);
// assign errD = $signed(currErr) - $signed(lastErr);

// always @(negedge clk) begin
//     if (rst) begin
//         lastErr = 0;
//         currErr = 0;
//         errI = 0;
//     end
//     else if (currErr != err) begin
//         lastErr = currErr;
//         currErr = err;
//         errI = $signed(errI) + $signed(err);
//     end
// end

// localparam kp = 0;
// localparam ki = 0;
// localparam kd = 0;
// assign result = ($signed(err) <<< 2) + ($signed(errI) >>> 7) + ($signed(errD)); // kp * err + ki * errI + kd * errD，kp = 4, ki = 1/128, kd = 1
// // assign result = ($signed(err) >>> 1) + ($signed(errI) >>> 8) + ($signed(errD));  // kp * err + ki * errI + kd * errD，kp = 1/2, ki = 1/256, kd = 1

// assign sign = result[16];   // 取符号位
// assign resultAbs = result[16] ? ~result[15:0] + 16'b1 : result[15:0];   // 取绝对值
// assign outputNum = (resultAbs > 256) ? 8'b11111111 : resultAbs[7:0]; // 饱和处理

// endmodule

module PID(
    input wire clk,
    input wire rst, // 高电平复位
    input wire [15:0] inputNum,
    input wire [15:0] setNum,
    output wire [7:0] outputNum,
    output wire sign
);

    wire [16:0] err;
    wire [16:0] errD;
    wire [16:0] result;
    wire [15:0] resultAbs;
    reg [16:0] currErr = 0;
    reg [16:0] lastErr = 0;
    reg [32:0] errI = 0;

    assign err = $signed(inputNum) - $signed(setNum);
    assign errD = $signed(currErr) - $signed(lastErr);

    always @(negedge clk) begin
        if (rst) begin
            lastErr = 0;
            currErr = 0;
            errI = 0;
        end
        else begin
            lastErr = currErr;
            currErr = err;
            errI = $signed(errI) + $signed(err);
        end
    end

    localparam kp = 0;
    localparam ki = 0;
    localparam kd = 0;

    // kp = 1/2, ki = 1/256, kd = 1
    // assign result = ($signed(err) >>> 1) + ($signed(errI) >>> 8) + ($signed(errD));

    // kp = 1, ki = 1/256, kd = 1
    // assign result = ($signed(err)) + ($signed(errI) >>> 8) + ($signed(errD));

    // kp = 2, ki = 1/256, kd = 1
    // assign result = ($signed(err)) + ($signed(errI) >>> 8) + ($signed(errD));

    // kp = 4, ki = 1/256, kd = 1
    // assign result = ($signed(err) <<< 2) + ($signed(errI) >>> 8) + ($signed(errD)); 

    // kp = 1, ki = 0, kd = 1
    // assign result = ($signed(err)) + ($signed(errD));

    // kp = 2, ki = 0, kd = 1
    assign result = ($signed(err) <<< 1) + ($signed(errD));

    // kp = 1, ki = 1/512, kd = 1
    // assign result = ($signed(err)) + ($signed(errI) >>> 9) + ($signed(errD));

    // kp = 1, ki = 1/512, kd = 2
    // assign result = ($signed(err)) + ($signed(errI) >>> 9) + ($signed(errD) <<< 1);

    // kp = 1, ki = 1/512, kd = 4
    // assign result = ($signed(err)) + ($signed(errI) >>> 9) + ($signed(errD) <<< 2);


    assign sign = result[16];   // 取符号位
    assign resultAbs = result[16] ? ~result[15:0] + 16'b1 : result[15:0];   // 取绝对值
    assign outputNum = (resultAbs > 256) ? 8'b11111111 : resultAbs[7:0]; // 饱和处理
endmodule