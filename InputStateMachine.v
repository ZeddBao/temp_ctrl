module InputStateMachine(
    input wire KEY1,
    input wire [3:0] keyIn,
    input wire readEn,
    output wire [7:0] valueOut,
    output wire outValid
);
    reg [3:0] num0 = 4'b0000, num1 = 4'b0000;   // 两个寄存器，用于存储按键值
    reg state = 1'b1;
    assign outValid = state;

    DecimalToBinary8 d2b_inst(
        .d0(num0) ,
        .d1(num1),
        .bin(valueOut)
    );
    
    // 当KEY1第一次按下时，进入状态1，再次按下时，进入状态0
    always @(negedge KEY1) begin
        state <= ~state;
    end

    always @(posedge readEn) begin
        if (state) begin
            num1 <= num0;
            num0 <= keyIn;
        end 
    end
endmodule