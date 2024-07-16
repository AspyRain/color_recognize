module  esp8266_ctrl
#(
	parameter	CLK_FRE		=	'd50_000_000									,	//时钟频率
				BAUD_RATE	=	'd115200										,	//串口通信波特率
				INSTR_0		=	"+++"											,	//退出透传模式指令
				INSTR_1		=	"AT+SAVETRANSLINK=0"							,	//设置上电不进入透传
				INSTR_2		=	"AT+CWMODE=1"									,	//设置wifi模式
				INSTR_3		=	"AT+RST"										,	//重启生效
				INSTR_4		=	"AT+CWJAP=\"FPGA\",\"00000001\""				,	//连接wifi，wifi名称“FPGA”，密码“88888888”
				INSTR_5		=	"AT+CIFSR"										,	//查询模块IP
				INSTR_6		=	"AT+CIPSTART=\"TCP\",\"192.168.236.212\",8888"	,	//连接TCP服务器，IP地址192.168.135.107，端口号8888
				INSTR_7		=	"AT+CIPMODE=1"									,	//开始透传模式
				INSTR_8		=	"AT+CIPSEND"									,	//开始透传
				INSTR_9     = 	"GET http://192.168.233.191:8080/weather/getTemp"     ,//指令
				ACK_OK		=	"OK"											,	//响应的OK数据	
				ACK_ADD		=	"++"											,	//退出透传模式标志
				ACK_END		=	16'h0d0a											//响应_回车+换行
)
(
	input	wire			sys_clk		,	//系统时钟，频率为50MHZ
	input	wire			sys_rst_n	,	//系统复位，低电平有效
	input	wire	[7:0]	pi_data		,	//输入的响应数据
	input	wire			pi_flag		,	//与输入的指令数据同步的标志信号
	
	output	reg		[7:0]	po_data		,	//输出的指令数据
	output	reg				po_flag		,	//与输出的指令数据同步的标志信号
	output			[2:0]	state,
	output	reg				cfg_done	
);
//aa25dbe4d279055d99a3d41fa91b7326
parameter	CNT_WAIT_MAX	=	CLK_FRE/BAUD_RATE * 10	;
parameter	CNT_DELAY_MAX	=	32'd50_000_000	   		;

localparam  IDLE        = 2'd0,
            SEND_INSTR  = 2'd1,
            ACK         = 2'd2,
            SEND_INSTR_9  = 2'd3;

reg		[407:0]	instr_data		;	//指令数据
reg		[5:0]	instr_num		;	//指定十六进制数据个数		
reg		[3:0]	cnt_instr		;	//指令个数计数器
reg		[5:0]	cnt_bit			;	//发送的比特数据计数器
reg		[15:0]	data_ack		;	//响应数据
reg				skip_en			;	//跳转信号
reg		[1:0]	n_state			;	//次态
reg		[1:0]	c_state			;	//现态
reg		[31:0]	cnt_delay_1s		;	//等待时间，指令发送必须存在间隔
reg		[14:0]	cnt_wait		;	//等待计数器
reg				flag_bit		;	//计数中点采数据
reg				ack_en			;	//响应有效信号
reg				ack_end			;	//响应结束信号
reg				ack_end_d		;	//响应结束信号打拍
wire			ack_raise		;	//响应结束信号上升沿
wire	[7:0]	data_reg[50:0]	;	//定义数组，存储数据

assign ack_raise = ack_end & (~ack_end_d)  ;


always@(*)
	case(c_state)
		IDLE		:	po_data = 8'd0  ;
		SEND_INSTR	:	po_data = data_reg[instr_num - 1'b1 - cnt_bit]  ;
		ACK			:	po_data = 8'd0  ;
		default		:	po_data = 8'd0  ;
	endcase
	
always@(*)
	case(c_state)
		IDLE		:	po_flag = 1'b0  ;
		SEND_INSTR	:	if(cnt_wait == 15'd0)
							po_flag = 1'b1  ;
						else
							po_flag = 1'b0  ;
		ACK			:	po_flag = 1'b0  ;
		default		:	po_flag = 1'b0  ;
	endcase
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		c_state  <=  IDLE  ;
	else
		c_state  <=  n_state  ;
		
always@(*)
	case(c_state)
        IDLE       : begin
            if(skip_en == 1'b1)
                n_state = SEND_INSTR;
            else 
                n_state = c_state; 
        end
		SEND_INSTR	:	if(skip_en == 1'b1)
							n_state = ACK  ;
						else
							n_state = SEND_INSTR  ;
		ACK			:	if(skip_en == 1'b1 || end_cnt_5s == 1'b1)
							n_state = IDLE  ;
						else
							n_state = ACK  ;
		default		:	n_state = IDLE  ;
	endcase
	

reg         [32-1:0]      cnt_1s    ; //计数器
wire                    add_cnt_1s; //开始计数
wire                    end_cnt_1s; //计数器最大值
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		 cnt_1s <= 32'b0;
	end
	else if (add_cnt_1s)begin
		if (end_cnt_1s)begin
			cnt_1s<=32'b0;
		end
		else begin
			cnt_1s <= cnt_1s +1'd1;
		end
	end
	else begin
		cnt_1s <= cnt_1s;
	end
end
assign add_cnt_1s = 1'b1;
assign end_cnt_1s = add_cnt_1s && (cnt_1s == CNT_DELAY_MAX - 1'b1);

reg         [3-1:0]      cnt_5s    ; //计数器
wire                    add_cnt_5s; //开始计数
wire                    end_cnt_5s; //计数器最大值
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		 cnt_5s <= 3'b0;
	end
	else if (add_cnt_5s)begin
		if (end_cnt_5s)begin
			cnt_5s<=3'b0;
		end
		else begin
			cnt_5s <= cnt_5s +1'd1;
		end
	end
	else begin
		cnt_5s <= cnt_5s;
	end
end
assign add_cnt_5s = end_cnt_1s && (c_state == ACK && cfg_done == 1'b1);
assign end_cnt_5s = add_cnt_5s && (cnt_5s == 3'd5 - 3'd1);

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			skip_en		<=  1'b0	;
			cnt_instr	<=  4'd0	;	
			cnt_bit		<=  6'd0	;
			data_ack	<=  16'd0   ;
			ack_en		<=  1'b0	;
			ack_end		<=  1'b1	;
			ack_end_d	<=  1'b0	;
			cnt_delay_1s	<=  32'd0	;	
			flag_bit	<=  1'b0	;	
			cnt_wait	<=  15'd0	;	
			cfg_done	<=  1'b0	;	
		end
	else	
		case(c_state)
			IDLE		:begin
							ack_en		<=  1'b0	;	
							cnt_wait	<=  15'd0	;	
							if((cnt_delay_1s == CNT_DELAY_MAX - 1'b1))
								cnt_delay_1s  <=  32'd0  ;
							else
								cnt_delay_1s  <=  cnt_delay_1s + 1'b1  ;
							if(cnt_delay_1s == CNT_DELAY_MAX - 2'd2)
								skip_en  <=  1'b1  ;
							else
								skip_en  <=  1'b0  ;
						end
			SEND_INSTR	:begin
							if(cnt_wait == CNT_WAIT_MAX - 1'b1)
								cnt_wait  <=  15'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;
							if((cnt_wait == CNT_WAIT_MAX - 1'b1)&&(cnt_bit == instr_num - 1'b1))
								cnt_bit  <=  6'd0  ;
							else  if(cnt_wait == CNT_WAIT_MAX - 1'b1)
								cnt_bit  <=  cnt_bit + 1'b1  ;
							else
								cnt_bit  <=  cnt_bit  ;
							if((cnt_wait == CNT_WAIT_MAX - 2'd2)&&(cnt_bit == instr_num - 1'b1))
								skip_en  <=  1'b1  ;
							else
								skip_en  <=  1'b0  ;
						 end
			ACK			:begin
							if(cnt_wait == CNT_WAIT_MAX - 1'b1)
								cnt_wait  <=  15'd0  ;
							else
								cnt_wait  <=  cnt_wait + 1'b1  ;
							if(cnt_wait == CNT_WAIT_MAX/2 - 1'b1)
								flag_bit  <=  1'b1  ;
							else
								flag_bit  <=  1'b0  ;
							if(flag_bit == 1'b1)
								data_ack  <=  {data_ack[7:0],pi_data}  ;
							else
								data_ack  <=  data_ack  ;
							if(data_ack == ACK_OK)
								ack_en  <=  1'b1  ;
							else
								ack_en  <=  ack_en  ;
							if((data_ack == ACK_END)||((cnt_instr == 4'd0)&&(data_ack == ACK_ADD)))
								ack_end  <=  1'b1  ;
							else
								ack_end  <=  1'b0  ;
							ack_end_d  <=  ack_end  ;

							if(skip_en == 1'b1) begin
								if (cfg_done==1'b1)begin
									cnt_instr <= 4'd9;
								end
								else begin
									cnt_instr  <=  cnt_instr + 1'b1  ;
								end								
							end
							else
								cnt_instr  <=  cnt_instr  ;
							if((ack_raise == 1'b1)&&(cnt_instr == 4'd0))
								skip_en  <=  1'b1  ;
							else  if((ack_raise == 1'b1)&&(ack_en == 1'b1))
								skip_en  <=  1'b1  ;
							else
								skip_en  <=  1'b0  ;
							if((cnt_instr == 4'd8)&&(skip_en == 1'b1))
								cfg_done  <=  1'b1  ;
							else
								cfg_done  <=  cfg_done  ;
						 end
			default		:begin
							skip_en		<=  1'b0	;
							cnt_instr	<=  4'd0	;	
							cnt_bit		<=  6'd0	;
							data_ack	<=  16'd0   ;	
							ack_en		<=  1'b0	;
							ack_end		<=  1'b0	;
							ack_end_d	<=  1'b0	;
							cnt_delay_1s	<=  32'd0	;	
							flag_bit	<=  1'b0	;	
							cnt_wait	<=  15'd0	;	
							cfg_done	<=  1'b0	;
						 end
		endcase

always@(*)
	case(cnt_instr)
		4'd0	:begin
					instr_data	=	INSTR_0	;
					instr_num	=	6'd3	;
				 end
		4'd1	:begin
					instr_data	=	{INSTR_1,8'h0d,8'h0a}  ;
					instr_num	=	6'd20	;
				 end		
		4'd2	:begin
					instr_data	=	{INSTR_2,8'h0d,8'h0a}  ;
					instr_num	=	6'd13	;
				 end	
		4'd3	:begin
					instr_data	=	{INSTR_3,8'h0d,8'h0a}  ;
					instr_num	=	6'd8	;
				 end		
		4'd4	:begin
					instr_data	=	{INSTR_4,8'h0d,8'h0a}  ;
					instr_num	=	6'd35	;
				 end
		4'd5	:begin
					instr_data	=	{INSTR_5,8'h0d,8'h0a}  ;
					instr_num	=	6'd10	;
				 end		 
		4'd6	:begin
					instr_data	=	{INSTR_6,8'h0d,8'h0a}  ;
					instr_num	=	6'd42	;
				 end
		4'd7	:begin
					instr_data	=	{INSTR_7,8'h0d,8'h0a}  ;
					instr_num	=	6'd14	;
				 end		
		4'd8	:begin
					instr_data	=	{INSTR_8,8'h0d,8'h0a}  ;
					instr_num	=	6'd12	;
				 end
        4'd9: begin
                instr_data = {INSTR_9,8'h0d,8'h0a};
                instr_num = 6'd49;
		end
		default	:begin
					instr_data	=	400'd0  ;
					instr_num	=	6'd0	;
				 end
	endcase
	assign	state = c_state;
assign  data_reg[00] = instr_data[007:000]  ;
assign  data_reg[01] = instr_data[015:008]  ;
assign  data_reg[02] = instr_data[023:016]  ;
assign  data_reg[03] = instr_data[031:024]  ;
assign  data_reg[04] = instr_data[039:032]  ;
assign  data_reg[05] = instr_data[047:040]  ;
assign  data_reg[06] = instr_data[055:048]  ;
assign  data_reg[07] = instr_data[063:056]  ;
assign  data_reg[08] = instr_data[071:064]  ;
assign  data_reg[09] = instr_data[079:072]  ;
assign  data_reg[10] = instr_data[087:080]  ;
assign  data_reg[11] = instr_data[095:088]  ;
assign  data_reg[12] = instr_data[103:096]  ;
assign  data_reg[13] = instr_data[111:104]  ;
assign  data_reg[14] = instr_data[119:112]  ;
assign  data_reg[15] = instr_data[127:120]  ;
assign  data_reg[16] = instr_data[135:128]  ;
assign  data_reg[17] = instr_data[143:136]  ;
assign  data_reg[18] = instr_data[151:144]  ;
assign  data_reg[19] = instr_data[159:152]  ;
assign  data_reg[20] = instr_data[167:160]  ;
assign  data_reg[21] = instr_data[175:168]  ;
assign  data_reg[22] = instr_data[183:176]  ;
assign  data_reg[23] = instr_data[191:184]  ;
assign  data_reg[24] = instr_data[199:192]  ;
assign  data_reg[25] = instr_data[207:200]  ;
assign  data_reg[26] = instr_data[215:208]  ;
assign  data_reg[27] = instr_data[223:216]  ;
assign  data_reg[28] = instr_data[231:224]  ;
assign  data_reg[29] = instr_data[239:232]  ;
assign  data_reg[30] = instr_data[247:240]  ;
assign  data_reg[31] = instr_data[255:248]  ;
assign  data_reg[32] = instr_data[263:256]  ;
assign  data_reg[33] = instr_data[271:264]  ;
assign  data_reg[34] = instr_data[279:272]  ;
assign  data_reg[35] = instr_data[287:280]  ;
assign  data_reg[36] = instr_data[295:288]  ;
assign  data_reg[37] = instr_data[303:296]  ;
assign  data_reg[38] = instr_data[311:304]  ;
assign  data_reg[39] = instr_data[319:312]  ;
assign  data_reg[40] = instr_data[327:320]  ;
assign  data_reg[41] = instr_data[335:328]  ;
assign  data_reg[42] = instr_data[343:336]  ;
assign  data_reg[43] = instr_data[351:344]  ;
assign  data_reg[44] = instr_data[359:352]  ;
assign  data_reg[45] = instr_data[367:360]  ;
assign  data_reg[46] = instr_data[375:368]  ;
assign  data_reg[47] = instr_data[383:376]  ;
assign  data_reg[48] = instr_data[391:384]  ;
assign  data_reg[49] = instr_data[399:392]  ;
assign	data_reg[50] = instr_data[407:400]	;
endmodule