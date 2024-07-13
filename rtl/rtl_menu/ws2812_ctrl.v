module  ws2812_ctrl
(
	input	wire			sys_clk			,
	input	wire			sys_rst_n		,
	input	wire			ws2812_start	,	//控制模块开始工作指示的单脉冲信号，由配置模块产生
	input	wire	[23:0]	cfg_data		,	//待配置的RGB888颜色数据
	input	wire	[5:0]	cfg_num			,	//配置的RGB灯个数
	
	output	reg				cfg_start		,	//配置模块开始工作指示的单脉冲信号，由控制模块产生
	output	reg				led_data	
);

localparam	
			IDLE			=	3'd0	,	//空闲状态，跳转条件是配置模块产生的ws2812_start
			ARBIT			=	3'd1	,	//仲裁状态，判断每一位RGB888是0还是1，是0跳转到SEND_SERO，是1跳转到SEND_ONE
			SEND_ZERO	=	3'd2	,	//发送数据0状态，发送24x64个数据完毕跳转到RST_N状态，发送完成0码重新跳转到仲裁状态
			SEND_ONE		=	3'd3	,	//发送数据1状态，发送24x64个数据完毕跳转到RST_N状态，发送完成1码重新跳转到仲裁状态
			RST_N			=	3'd4	;	//复位状态，发送完成24x64个数据后，复位状态会持续一段时间低电平
localparam	
			CNT_WAIT_0	=	14'd55		,	//发送数据0等待时间，1100ns，总时间为CNT_WAIT_0 + ARBIT_time = 1180ns
			CNT_WAIT_H0	=	14'd15		,	//发送数据0高电平时间，300ns，低电平时间为CNT_WAIT_0 - CNT_WAIT_H0 + ARBIT_time = 880ns
			CNT_WAIT_1	=	14'd64		,	//发送数据1等待时间，1280ns，总时间为CNT_WAIT_1 + ARBIT_time = 1360ns
			CNT_WAIT_H1	=	14'd32		,	//发送数据1高电平时间，640ns，低电平时间为CNT_WAIT_1 - CNT_WAIT_H1 + ARBIT_time = 720ns
			CNT_WAIT_RST=	14'd15000	;	//发送24x64个数据完成，复位状态等待时间，总时间为300us
			
reg				skip_en_0	;	//	①仲裁状态跳转到发送数据0状态跳转信号；②发送数据0状态跳转到仲裁状态跳转信号
reg				skip_en_1	;	//	①仲裁状态跳转到发送数据1状态跳转信号；②发送数据1状态跳转到仲裁状态跳转信号
reg				skip_en_rst	;	//	①发送数据0/1状态跳转到复位状态跳转信号；②复位状态跳转到空闲状态跳转信号
reg		[2:0]	n_state		;	//次态
reg		[2:0]	c_state		;	//现态
reg		[13:0]	cnt_wait	;	//全局等待计数器
reg				data		;	//数据0或者1，解码cfg_data每一位得到
reg		[4:0]	cnt_num		;	//对配置的RGB888比特个数计数，最多配置24-1个

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		c_state  <=  IDLE  ;
	else
		c_state  <=  n_state ;
		
always@(*)
	case(c_state)
		IDLE		:	if(ws2812_start == 1'b1)
							n_state  =  ARBIT  ;
						else
							n_state  =  IDLE  ;
		ARBIT		:	if(skip_en_0 == 1'b1)
							n_state  =  SEND_ZERO  ;
						else  if(skip_en_1 == 1'b1)
							n_state  =  SEND_ONE  ;
						else
							n_state  =  ARBIT  ;
		SEND_ZERO	:	if(skip_en_0 == 1'b1)
							n_state  =  ARBIT  ;
						else  if(skip_en_rst == 1'b1)
							n_state  =  RST_N  ;
						else
							n_state  =  SEND_ZERO  ;
		SEND_ONE	:	if(skip_en_1 == 1'b1)
							n_state  =  ARBIT  ;
						else  if(skip_en_rst == 1'b1)
							n_state  =  RST_N  ;
						else
							n_state  =  SEND_ONE  ;
		RST_N		:	if(skip_en_rst == 1'b1)
							n_state  =  IDLE  ;
						else
							n_state  =  RST_N  ;
		default		:	n_state  =  IDLE  ;
	endcase
	
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			skip_en_0	<=  1'b0  ;
			skip_en_1	<=  1'b0  ;
			skip_en_rst	<=  1'b0  ;
			cnt_wait	<=  14'd0 ;
			data		<=  1'b0  ;
			cnt_num		<=  5'd0  ;
			cfg_start   <=  1'b0  ;
			led_data	<=  1'b0  ;
		end
	else
		case(c_state)
			ARBIT		:begin
							if(cnt_wait == 14'd3)
								cnt_wait  <=  14'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;
							data  <=  cfg_data[23 - cnt_num]  ;
							cfg_start  <=  1'b0  ;
							if((data == 1'b0)&&(cnt_wait == 14'd2))
								skip_en_0  <=  1'b1  ;
							else  
								skip_en_0  <=  1'b0  ;							
							if((data == 1'b1)&&(cnt_wait == 14'd2))
								skip_en_1  <=  1'b1  ;
							else  
								skip_en_1  <=  1'b0  ;							
						 end
			SEND_ZERO	:begin
							if(cnt_wait == CNT_WAIT_0 - 1'b1)
								cnt_wait  <=  14'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;
							if((cnt_wait == CNT_WAIT_0 - 1'b1)&&(cnt_num == 5'd23)&&(cfg_num != 6'd63))
								cfg_start  <=  1'b1  ;
							else
								cfg_start  <=  1'b0  ;
							if((cnt_num == 5'd23)&&(cnt_wait == CNT_WAIT_0 - 1'b1))
								cnt_num  <=  6'd0  ;
							else  if(cnt_wait == CNT_WAIT_0 - 1'b1)
								cnt_num  <=  cnt_num + 1'b1  ;
							else
								cnt_num  <=  cnt_num  ;
							if((cnt_wait == CNT_WAIT_0 - 2'd2)&&(cnt_num == 5'd23)&&(cfg_num == 6'd63))
								skip_en_rst  <=  1'b1  ;
							else  if(cnt_wait == CNT_WAIT_0 - 2'd2)
								skip_en_0  <=  1'b1  ;
							else
								begin
									skip_en_rst  <=  1'b0  ;
									skip_en_0	 <=  1'b0  ;
								end
							if(cnt_wait <= CNT_WAIT_H0 - 1'b1)
								led_data  <=  1'b1  ;
							else
								led_data  <=  1'b0  ;
						 end
			SEND_ONE	:begin
							if(cnt_wait == CNT_WAIT_1 - 1'b1)
								cnt_wait  <=  14'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;	
							if((cnt_wait == CNT_WAIT_1 - 1'b1)&&(cnt_num == 5'd23)&&(cfg_num != 6'd63))
								cfg_start  <=  1'b1  ;
							else
								cfg_start  <=  1'b0  ;	
							if((cnt_num == 5'd23)&&(cnt_wait == CNT_WAIT_1 - 1'b1))
								cnt_num  <=  6'd0  ;
							else  if(cnt_wait == CNT_WAIT_1 - 1'b1)
								cnt_num  <=  cnt_num + 1'b1  ;
							else
								cnt_num  <=  cnt_num  ;								
							if((cnt_wait == CNT_WAIT_1 - 2'd2)&&(cnt_num == 5'd23)&&(cfg_num == 6'd63))
								skip_en_rst  <=  1'b1  ;
							else  if(cnt_wait == CNT_WAIT_1 - 2'd2)
								skip_en_1  <=  1'b1  ;
							else
								begin
									skip_en_rst  <=  1'b0  ;
									skip_en_1	 <=  1'b0  ;
								end			
							if(cnt_wait <= CNT_WAIT_H1 - 1'b1)
								led_data  <=  1'b1  ;
							else
								led_data  <=  1'b0  ;			
						 end
			RST_N		:begin
							if(cnt_wait == CNT_WAIT_RST - 1'b1)
								cnt_wait  <=  14'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;
							if(cnt_wait == CNT_WAIT_RST - 1'b1)
								cfg_start  <=  1'b1  ;
							else
								cfg_start  <=  1'b0  ;	
							if(cnt_wait == CNT_WAIT_RST - 2'd2)
								skip_en_rst  <=  1'b1  ;
							else
								skip_en_rst  <=  1'b0  ;
							led_data  <=  1'b0  ;
						 end
			default		:begin
							skip_en_0	<=  1'b0  ;
							skip_en_1	<=  1'b0  ;
							skip_en_rst	<=  1'b0  ;
							cnt_wait	<=  14'd0 ;
							data		<=  1'b0  ;
							cnt_num		<=  5'd0  ;
							led_data	<=  1'b0  ;
							cfg_start   <=  1'b0  ;
						 end
		endcase

endmodule
