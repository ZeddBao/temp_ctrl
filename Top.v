module Top(
    input wire clk,     // 24 MHz clock
    input wire KEY1,
    input wire KEY2,    

    input wire KEY9,
    input wire KEY10,
    input wire KEY11,
    input wire KEY12,
    output wire KEY13,
    output wire KEY14,
    output wire KEY15,
    output wire KEY16,

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
    output wire DLA_3,

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
    output wire HEX17,

    output wire LEDR1,
    output wire LEDR2,
    output wire LEDR3,

    inout wire GPIO0,
    output wire GPIO1,
    output wire GPIO2
);

    assign LEDR1 = outValid;

    wire clk240, clk2_4, clk1, clk1M;
    FrequencyDivider fd_inst(
        .clk(clk),
        .clk1M(clk1M),
        .clk240(clk240),
        .clk2_4(clk2_4),
        .clk1_2(),
        .clk1(clk1)
    );

    wire stableKEY1;
    Debounce debounce_inst(
        .clk(clk240),
        .keyIn(KEY1),
        .keyOut(stableKEY1)
    );

    wire [3:0] keySignal;
    wire keyValid;
    KeyboardDriver keyboard_inst(
        .clk(clk240),
        .KEY9(KEY9),
        .KEY10(KEY10),
        .KEY11(KEY11),
        .KEY12(KEY12),
        .KEY13(KEY13),
        .KEY14(KEY14),
        .KEY15(KEY15),
        .KEY16(KEY16),
        .keyOut(keySignal),
        .keyValid(keyValid)
    );

    wire [15:0] tempOut;
    Display4Driver display4_inst(
        .clk(clk240),
        .en(1'b0),
        .inputNum(tempOut),
        .DL_a(DL_a),
        .DL_b(DL_b),
        .DL_c(DL_c),
        .DL_d(DL_d),
        .DL_e(DL_e),
        .DL_f(DL_f),
        .DL_g(DL_g),
        .DL_DP(DL_DP),
        .DLA_0(DLA_0),
        .DLA_1(DLA_1),
        .DLA_2(DLA_2),
        .DLA_3(DLA_3)
    );

    wire outValid;
    wire [7:0] setTemp;
    Display2Driver display2_inst(
        .inputNum(setTemp),
        .en(outValid ? clk1 : 1'b0),
        .HEX00(HEX00),
        .HEX01(HEX01),
        .HEX02(HEX02),
        .HEX03(HEX03),
        .HEX04(HEX04),
        .HEX05(HEX05),
        .HEX06(HEX06),
        .HEX07(HEX07),
        .HEX10(HEX10),
        .HEX11(HEX11),
        .HEX12(HEX12),
        .HEX13(HEX13),
        .HEX14(HEX14),
        .HEX15(HEX15),
        .HEX16(HEX16),
        .HEX17(HEX17)
    );

    InputStateMachine inputStateMachine_inst(
        .KEY1(stableKEY1),
        .keyIn(keySignal),
        .readEn(keyValid),
        .valueOut(setTemp),
        .outValid(outValid)
    );
    
    wire outPulse;
    DS18B20Driver ds18b20_inst(
        .clk1M(clk1M),
        .rst(KEY2),
        .dq(GPIO0),
        .tempOut(tempOut),
        .sign(),
        .outPulse(outPulse)
    );

    wire [7:0] pidOut;
    wire pidSign;
    PWMDriver pwm_fan(
        .clk(clk1M),
        .inputNum(pidSign ? 8'h00 : pidOut),
        .en(outValid),
        .pwm(GPIO1)
    );
    assign LEDR2 = ~GPIO1;

    
    PWMDriver pwm_heater(
        .clk(clk1M),
        .inputNum(pidSign ? pidOut : 8'h00),
        .en(outValid),
        .pwm(GPIO2)
    );
    assign LEDR3 = ~GPIO2;

    wire [15:0] setTempx100;
    assign setTempx100 = setTemp * 100;
    PID PID_inst(
        .clk(outPulse),
        .rst(outValid),
        .inputNum(tempOut),
        .setNum(setTempx100),
        .outputNum(pidOut),
        .sign(pidSign)
    );
endmodule