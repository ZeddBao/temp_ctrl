module DS18B20Driver(
    input wire clk1M,				// 时钟，频率1M，周期1us
    input wire rst,        			// 低电平有效的复位信号	
    
    inout wire dq,		    		// 单总线（双向信号）
    output wire [15:0] tempOut,		// 转换后得到的温度值
    output reg sign,        		// 符号位
	output reg outPulse = 1'b1		// 负脉冲信号
);
 
	localparam INIT1 = 3'b000,
		WR_CMD = 3'b001,
		WAIT = 3'b010,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
		INIT2 = 3'b011,
		RD_CMD = 3'b100,
		RD_DATA = 3'b101,
			
		//时间参数定义
		T_INIT = 1000,				// 初始化最大时间，单位us
		T_WAIT = 780000,			// 转换等待延时，单位us
		
		//命令定义	
		WR_CMD_DATA = 16'h44cc, 	// 跳过 ROM 及温度转换命令，低位在前
		RD_CMD_DATA = 16'hbecc; 	// 跳过 ROM 及读取温度命令，低位在前
						
    reg	[2:0] currState;			// 现态
    reg	[2:0] nextState;			// 次态
    reg	dqOut;						// 双向总线输出
    reg	dqOutEn;					// 双向总线输出使能，1则输出，0则高阻态
    reg	flagAck;					// 从机响应标志信号
    reg [19:0] usCount;				// us计数器,最大可表示1048.576ms
    reg [3:0] bitCount;				// 接收数据计数器
    reg [15:0] dataTemp;			// 读取的温度数据寄存
    reg [15:0] data;				// 未处理的原始温度数据
    reg [20:0] temp;
								
	wire dqIn;						//双向总线输入

	assign	dqIn = dq;							// 高阻态的话，则把总线上的数据赋给dqIn
	assign	dq =  dqOutEn ? dqOut : 1'bz;		// 使能1则输出，0则高阻态

	always @(negedge clk1M or negedge rst) begin
		if (!rst)		
			currState <= INIT1;	
		else
			currState <= nextState;
	end

	always @(*) begin	
		case (currState)
			INIT1: begin
				if (usCount == T_INIT && flagAck)				// 满足初始化时间且接收到了从机的响应信号	
					nextState = WR_CMD;							// 跳转到写状态
				else	
					nextState = INIT1;							// 不满足则保持原有状态
			end	
			WR_CMD:	begin	
				if (bitCount == 4'd15 && usCount == 20'd62)		// 写完了16个数据，写跳过ROM和写温度转换命令	
					nextState = WAIT;							// 跳转到等待状态，等待温度转换完成 
				else	
					nextState = WR_CMD;							// 不满足则保持原有状态
			end	
			WAIT: begin	
				if (usCount == T_WAIT)							// 等待时间结束
					nextState = INIT2;	
				else	
					nextState = WAIT;	
			end	
			INIT2: begin	
				if (usCount == T_INIT && flagAck)				// 再进行初始化，时序同INIT1
					nextState = RD_CMD;
				else
					nextState = INIT2;
			end
			RD_CMD: begin
				if (bitCount == 4'd15 && usCount == 20'd62)		// 写完了16个数据，写跳过ROM和写读取温度转换命令	
					nextState = RD_DATA;						// 跳转到读取温度数据状态
				else	
					nextState = RD_CMD;	
			end	
			RD_DATA: begin	
				if (bitCount == 4'd15 && usCount == 20'd62)		// 读取完了16个数据
					nextState = INIT1;							// 跳转到初始化状态，开始新一轮温度采集
				else	
					nextState = RD_DATA;	
			end			
			default: nextState = INIT1;							// 默认初始化状态
		endcase
	end	

	always @(negedge clk1M or negedge rst) begin
		if (!rst) begin											// 默认输出
			dqOutEn <= 1'b0;
			dqOut <= 1'b0;
			flagAck <= 1'b0;
			usCount <= 20'd0;
			bitCount <= 4'd0;
			outPulse <= 1'b1;
		end
		else begin
			if (!outPulse)
				outPulse <= 1'b1;
			case (currState)
				INIT1: begin
					if (usCount == T_INIT) begin				// 时间计数到最大值（初始化时间）
						usCount <= 20'd0;						// 计数器清零
						flagAck <= 1'b0;						// 从机响应标志信号拉低
					end
					else begin									// 没有计数到最大值
						usCount <= usCount + 1'd1;				// 计数器计数
						if (usCount <= 20'd499) begin			// 小于500us时
							dqOutEn <= 1'b1;					// 控制总线
							dqOut <= 1'b0;						// 输出0，即拉低总线
						end
						else begin								// 在500us处
							dqOutEn <= 1'b0;					// 释放总线，等待从机响应						
							if (usCount == 20'd570 && !dqIn)	// 在570us处采集总线电平，如果为0则说明从机响应了
								flagAck <= 1'b1;				// 拉高从机响应标志信号
						end	
					end
				end
				WR_CMD: begin
					if (usCount == 20'd62) begin				// 一个写时隙周期63us，满足计时条件则
						usCount <= 20'd0;						// 清空计数器
						dqOutEn <= 1'b0;						// 释放总线
						if (bitCount == 4'd15)					// 如果数据已经写了15个
							bitCount <= 4'd0;					// 则清空
						else									// 没写15个
							bitCount <= bitCount + 1'd1;		// 则数据计数器+1，代表写入了一个数据
					end	
					else begin									// 一个写时隙周期63us未完成
						usCount <= usCount + 1'd1;				// 计数器一直计数
						if (usCount <= 20'd1) begin				// 0~1us（每两个写数据之间需要间隔2us）
							dqOutEn <= 1'b1;					// 拉低总线
							dqOut <= 1'b0;
						end
						else begin					
							if (WR_CMD_DATA[bitCount] == 1'b0) begin			// 需要写入的数据为0
								dqOutEn <= 1'b1;								// 拉低总线
								dqOut <= 1'b0;							
							end
							else if (WR_CMD_DATA[bitCount] == 1'b1) begin
								dqOutEn <= 1'b0;								// 需要写入的数据为1
								dqOut <= 1'b0;									// 释放总线						
							end
						end	
					end		
				end		
				WAIT: begin										// 等待温度转换完成
					dqOutEn <= 1'b1;							// 拉低总线兼容寄生电源模式
					dqOut <= 1'b1;									
					if (usCount == T_WAIT)						// 计数完成
						usCount <= 20'd0;
					else
						usCount <= usCount + 1'd1;
				end	
				INIT2: begin									// 二次初始化，时序同INIT1
					if (usCount == T_INIT) begin						
						usCount <= 20'd0;
						flagAck <= 1'b0;
					end
					else begin
						usCount <= usCount + 1'd1;
						if (usCount <= 20'd499) begin
							dqOutEn <= 1'b1;						
							dqOut <= 1'b0;
						end
						else begin
							dqOutEn <= 1'b0;												
							if (usCount == 20'd570 && !dqIn)
								flagAck <= 1'b1;
						end	
					end
				end	
				RD_CMD: begin									// 写16个数据，时序同WR_CMD
					if (usCount == 20'd62) begin
						usCount <= 20'd0;
						dqOutEn <= 1'b0;
						if (bitCount == 4'd15)
							bitCount <= 4'd0;
						else
							bitCount <= bitCount + 1'd1;
					end
					else begin
						usCount <= usCount + 1'd1;
						if (usCount <= 20'd1) begin
							dqOutEn <= 1'b1;							
							dqOut <= 1'b0;
						end
						else begin					
							if (RD_CMD_DATA[bitCount] == 1'b0) begin
								dqOutEn <= 1'b1;						
								dqOut <= 1'b0;														
							end
							else if (RD_CMD_DATA[bitCount] == 1'b1) begin
								dqOutEn <= 1'b0;						
								dqOut <= 1'b0;												
							end
						end	
					end
				end	
				RD_DATA: begin									// 读16位温度数据
					if (usCount == 20'd62) begin				// 一个读时隙周期63us，满足计时条件则
						usCount <= 20'd0;						// 清空计数器
						dqOutEn <= 1'b0;						// 释放总线
						if (bitCount == 4'd15) begin			// 如果数据已经读取了15个
							bitCount <= 4'd0;					// 则清空
							data <= dataTemp;					// 临时的数据赋值给data
							outPulse <= 1'b0;					// 输出脉冲信号
						end
						else begin								// 如果数据没有读取15个
							bitCount <= bitCount + 1'd1;		// 则数据计数器+1，意味着读取了一个数据
							data <= data;
						end
					end
					else begin									// 一个读时隙周期还没结束
						usCount <= usCount + 1'd1;				// 计数器累加
						if (usCount <= 20'd1) begin				// 0~1us（每两个读数据之间需要间隔2us）
							dqOutEn <= 1'b1;					// 拉低总线
							dqOut <= 1'b0;
						end
						else begin										// 2us后
							dqOutEn <= 1'b0;							// 释放总掉线					
							if (usCount == 20'd10)						// 在10us处读取总线电平
								dataTemp <= {dq, dataTemp[15:1]};		// 右移读取总线电平
						end	
					end
				end
				default: ;		
			endcase
		end
	end
	
	assign tempOut = temp[15:0];								// 输出温度值

	always @(negedge clk1M or negedge rst) begin
		if (!rst) begin											// 初始状态
			temp <= 21'd0;	
			sign <= 1'b0;	
		end	
		else begin	
			if (!data[15]) begin										// 最高位为0则温度为正
				sign <= 1'b0;											// 标志位为正
				temp <= data[10:0] * 10'd625 / 7'd100;					// 12位温度数据处理
			end
			else begin													// 最高位为1则温度为负
				sign <= 1'b1;											// 标志位为负
				temp <= (~data[10:0] + 1'b1) * 10'd625 / 7'd100;		// 12位温度数据处理			
			end
		end
	end
endmodule


// module DS18B20Driver(
//   input         clk,                  // 50MHz时钟
//   input         rst,                  // 复位
//   inout         dq,             // One-Wire总线
//   output [15:0] tempOut          // 输出温度值 
// );


// //++++++++++++++++++++++++++++++++++++++
// // 延时模块 开始
// //++++++++++++++++++++++++++++++++++++++
// reg [19:0] cnt_1us;                      // 1us延时计数子
// reg cnt_1us_clear;                       // 请1us延时计数子

// always @ (posedge clk)
//   if (cnt_1us_clear)
//     cnt_1us <= 0;
//   else
//     cnt_1us <= cnt_1us + 1'b1;
// //--------------------------------------
// // 延时模块 结束
// //--------------------------------------


// //++++++++++++++++++++++++++++++++++++++
// // DS18B20状态机 开始
// //++++++++++++++++++++++++++++++++++++++
// //++++++++++++++++++++++++++++++++++++++
// // 格雷码
// parameter S00     = 5'h00;
// parameter S0      = 5'h01;
// parameter S1      = 5'h03;
// parameter S2      = 5'h02;
// parameter S3      = 5'h06;
// parameter S4      = 5'h07;
// parameter S5      = 5'h05;
// parameter S6      = 5'h04;
// parameter S7      = 5'h0C;
// parameter WRITE0  = 5'h0D;
// parameter WRITE1  = 5'h0F;
// parameter WRITE00 = 5'h0E;
// parameter WRITE01 = 5'h0A;
// parameter READ0   = 5'h0B;
// parameter READ1   = 5'h09;
// parameter READ2   = 5'h08;
// parameter READ3   = 5'h18;

// reg [4:0] state;                       // 状态寄存器
// //-------------------------------------

// reg dq_buf;                      // One-Wire总线 缓存寄存器

// reg [15:0] temperature_buf;            // 采集到的温度值缓存器（未处理）
// reg [5:0] step;                        // 子状态寄存器 0~50
// reg [3:0] bit_valid;                   // 有效位  
  
// always @(posedge clk, posedge rst)
// begin
//   if (rst)
//   begin
//     dq_buf <= 1'bZ;
//     step         <= 0;
//     state        <= S00;
//   end
//   else
//   begin
//     case (state)
//       S00 : begin              
//               temperature_buf <= 16'h001F;
//               state           <= S0;
//             end
//       S0 :  begin                       // 初始化
//               cnt_1us_clear <= 1;
//               dq_buf  <= 0;              
//               state         <= S1;
//             end
//       S1 :  begin
//               cnt_1us_clear <= 0;
//               if (cnt_1us == 500)         // 延时500us
//               begin
//                 cnt_1us_clear <= 1;
//                 dq_buf  <= 1'bZ;  // 释放总线
//                 state         <= S2;
//               end 
//             end
//       S2 :  begin
//               cnt_1us_clear <= 0;
//               if (cnt_1us == 100)         // 等待100us
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= S3;
//               end 
//             end
//       S3 :  if (~dq)              // 若18b20拉低总线,初始化成功
//               state <= S4;
//             else if (dq)          // 否则,初始化不成功,返回S0
//               state <= S0;
//       S4 :  begin
//               cnt_1us_clear <= 0;
//               if (cnt_1us == 400)         // 再延时400us
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= S5;
//               end 
//             end        
//       S5 :  begin                       // 写数据
//               if      (step == 0)       // 0xCC
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 1)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 2)
//               begin                
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01; 
//               end
//               else if (step == 3)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;                
//               end
//               else if (step == 4)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 5)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 6)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
//               else if (step == 7)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
              
//               else if (step == 8)       // 0x44
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 9)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 10)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
//               else if (step == 11)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 12)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 13)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 14)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
                 
//               end
//               else if (step == 15)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
              
//               // 第一次写完,750ms后,跳回S0
//               else if (step == 16)
//               begin
//                 dq_buf <= 1'bZ;
//                 step         <= step + 1'b1;
//                 state        <= S6;                
//               end
              
//               // 再次置数0xCC和0xBE
//               else if (step == 17)      // 0xCC
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 18)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 19)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;                
//               end
//               else if (step == 20)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE01;
//                 dq_buf <= 0;
//               end
//               else if (step == 21)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 22)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 23)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
//               else if (step == 24)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;               
//               end
              
//               else if (step == 25)      // 0xBE
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 26)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;                
//               end
//               else if (step == 27)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;                
//               end
//               else if (step == 28)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;                
//               end
//               else if (step == 29)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
//               else if (step == 30)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
//               else if (step == 31)
//               begin
//                 step  <= step + 1'b1;
//                 state <= WRITE0;
//               end
//               else if (step == 32)
//               begin
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= WRITE01;
//               end
              
//               // 第二次写完,跳到S7,直接开始读数据
//               else if (step == 33)
//               begin
//                 step  <= step + 1'b1;
//                 state <= S7;
//               end 
//             end
//       S6 :  begin
//               cnt_1us_clear <= 0;
//               if (cnt_1us == 750000 | dq)     // 延时750ms!!!!
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= S0;    // 跳回S0,再次初始化
//               end 
//             end
            
//       S7 :  begin                       // 读数据
//               if      (step == 34)
//               begin
//                 bit_valid    <= 0;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;
//               end
//               else if (step == 35)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;
//               end
//               else if (step == 36)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;
//               end
//               else if (step == 37)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;               
//               end
//               else if (step == 38)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 39)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;               
//               end
//               else if (step == 40)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 41)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;
//               end
//               else if (step == 42)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 43)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;
//               end
//               else if (step == 44)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 45)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 46)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 47)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 48)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 49)
//               begin
//                 bit_valid    <= bit_valid + 1'b1;
//                 dq_buf <= 0;
//                 step         <= step + 1'b1;
//                 state        <= READ0;                
//               end
//               else if (step == 50)
//               begin
//                 step  <= 0;
//                 state <= S0;
//               end 
//             end            
            
            
//       //++++++++++++++++++++++++++++++++
//       // 写状态机
//       //++++++++++++++++++++++++++++++++
//       WRITE0 :
//             begin
//               cnt_1us_clear <= 0;
//               dq_buf  <= 0;       // 输出0             
//               if (cnt_1us == 80)        // 延时80us
//               begin
//                 cnt_1us_clear <= 1;
//                 dq_buf  <= 1'bZ;  // 释放总线，自动拉高                
//                 state         <= WRITE00;
//               end 
//             end
//       WRITE00 :                         // 空状态
//               state <= S5;
//       WRITE01 :                         // 空状态
//               state <= WRITE1;
//       WRITE1 :
//             begin
//               cnt_1us_clear <= 0;
//               dq_buf  <= 1'bZ;    // 输出1   释放总线，自动拉高
//               if (cnt_1us == 80)        // 延时80us
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= S5;
//               end 
//             end
//       //--------------------------------
//       // 写状态机
//       //--------------------------------
      
      
//       //++++++++++++++++++++++++++++++++
//       // 读状态机
//       //++++++++++++++++++++++++++++++++
//       READ0 : state <= READ1;           // 空延时状态
//       READ1 :
//             begin
//               cnt_1us_clear <= 0;
//               dq_buf  <= 1'bZ;    // 释放总线
//               if (cnt_1us == 10)        // 再延时10us
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= READ2;
//               end 
//             end
//       READ2 :                           // 读取数据
//             begin
//               temperature_buf[bit_valid] <= dq;
//               state                      <= READ3;
//             end
//       READ3 :
//             begin
//               cnt_1us_clear <= 0;
//               if (cnt_1us == 55)        // 再延时55us
//               begin
//                 cnt_1us_clear <= 1;
//                 state         <= S7;
//               end 
//             end
//       //--------------------------------
//       // 读状态机
//       //--------------------------------
      
      
//       default : state <= S00;
//     endcase 
//   end 
// end 

// assign dq = dq_buf;         // 注意双向口的使用
// //--------------------------------------
// // DS18B20状态机 结束
// //--------------------------------------


// //++++++++++++++++++++++++++++++++++++++
// // 对采集到的温度进行处理 开始 转BCD码
// //++++++++++++++++++++++++++++++++++++++
// reg [15:4] reg_temperature;
// assign tempOut[3 : 0] = (temperature_buf[3:0] * 10) >> 4;
// assign tempOut[15: 4] =  reg_temperature[15:4] ;  

//   wire[2:0] c_in;
//   wire[2:0] c_out;
//   reg [3:0] dec_sreg0;
//   reg [3:0] dec_sreg1;
//   reg [3:0] dec_sreg2;
//   wire[3:0] next_sreg0,next_sreg1,next_sreg2;
  
//   reg [3:0] bit_cnt;
//   reg [7:0] bin_sreg;
  
// wire load=~|bit_cnt;//读入二进制数据，准备转换
// wire convert_ready= (bit_cnt==4'h9);//转换成功
// wire convert_end= (bit_cnt==4'ha);//完毕，重新开始
// /********************************************************/
// always @ (posedge clk)
// begin
//   if(convert_end) bit_cnt<=4'h0;
//   else bit_cnt<=bit_cnt+4'h1; 
// end
// /*******************************************************/ 
// always @ (posedge clk)
// begin
//   if(load) bin_sreg<=temperature_buf[11:4];
//   else bin_sreg <={bin_sreg[6:0],1'b0};
// end

// assign c_in[0] =bin_sreg[7];
// assign c_in[1] =(dec_sreg0>=5);
// assign c_in[2] =(dec_sreg1>=5);

// assign c_out[0]=c_in[1];
// assign c_out[1]=c_in[2];
// assign c_out[2]=(dec_sreg2>=5);

// //确定移位输出
// assign next_sreg0=c_out[0]? ({dec_sreg0[2:0],c_in[0]}+4'h6):({dec_sreg0[2:0],c_in[0]});
// assign next_sreg1=c_out[1]? ({dec_sreg1[2:0],c_in[1]}+4'h6):({dec_sreg1[2:0],c_in[1]});
// assign next_sreg2=c_out[2]? ({dec_sreg2[2:0],c_in[2]}+4'h6):({dec_sreg2[2:0],c_in[2]});


// //装入数据
// /********************************************************************/
// always @ (posedge clk)
// begin
//   if(load) 
//     begin 
//       dec_sreg0<=4'h0;
//       dec_sreg1<=4'h0;
//       dec_sreg2<=4'h0;
//     end     
//   else  
//     begin
//       dec_sreg0<=next_sreg0;
//       dec_sreg1<=next_sreg1;
//       dec_sreg2<=next_sreg2;
//     end
// end

// //输出
// /*******************************************************************/

// always @ (posedge clk)
// begin
//   if(convert_ready) 
//     begin 
//       reg_temperature[7:4]<=dec_sreg0;
//       reg_temperature[11:8]<=dec_sreg1;
//       reg_temperature[15:12]<=dec_sreg2;
//     end     
// end
// //--------------------------------------
// // 对采集到的温度进行处理 结束
// //--------------------------------------  

// endmodule