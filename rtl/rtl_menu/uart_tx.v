module  uart_tx
#(
	parameter	CLK_FRE		=	'd50_000_000	,	//串口通信时钟频率
				BAUD_RATE	=	'd115200			//串口通信波特率
)
(
	input	wire			sys_clk		,	//系统时钟，频率为50MHZ
	input	wire			sys_rst_n	,	//系统复位，低电平有效
	input	wire	[7:0]	pi_data		,	//8bit并行串口数据
	input	wire			pi_flag		,	//与并行数据同步的标志信号
	
	output	reg 			tx				//串口数据发送信号线
);

localparam	CNT_BAUD_MAX	=	CLK_FRE	/ BAUD_RATE		;	//波特率计数最大值

reg				work_en		;	//FPGA对串口数据进行并串转换的有效工作区间
reg		[14:0]	cnt_baud	;	//波特率计数器
reg		[3:0]	cnt_bit		;	//起始位和数据个数计数器
wire			stop_en		;	//串口发送模块结束工作标志信号

assign  stop_en = ((cnt_bit == 4'd8)&&(cnt_baud == CNT_BAUD_MAX - 1'b1))? 1'b1 : 1'b0  ;

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		work_en  <=  1'b0  ;
	else  if(pi_flag == 1'b1)
		work_en  <=  1'b1  ;
	else  if(stop_en == 1'b1)
		work_en  <=  1'b0  ;
	else
		work_en  <=  work_en  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_baud  <=  15'd0  ;
	else  if((work_en == 1'b1)&&(cnt_baud == CNT_BAUD_MAX - 1'b1))
		cnt_baud  <=  15'd0  ;
	else  if(work_en == 1'b1)
		cnt_baud  <=  cnt_baud + 1'b1  ;
	else
		cnt_baud  <=  15'd0  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_bit  <=  4'd0  ;
	else  if((cnt_bit == 4'd8)&&(stop_en == 1'b1)&&(work_en == 1'b1))
		cnt_bit  <=  4'd0  ;
	else  if((work_en == 1'b1)&&(cnt_baud == CNT_BAUD_MAX - 1'b1))
		cnt_bit  <=  cnt_bit + 1'b1  ;
	else  if(work_en == 1'b0)
		cnt_bit  <=  4'd0  ;
	else
		cnt_bit  <=  cnt_bit  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		tx  <=  1'b1  ;
	else  if((cnt_bit == 4'd0)&&(pi_flag == 1'b1))
		tx  <=  1'b0  ;
	else  if(work_en == 1'b1)
		case(cnt_bit)
			4'd0	:	tx  <=  1'b0	    ;
			4'd1	:	tx  <=  pi_data[0]  ;
			4'd2	:	tx  <=  pi_data[1]  ;
			4'd3	:	tx  <=  pi_data[2]  ;
			4'd4	:	tx  <=  pi_data[3]  ;
			4'd5	:	tx  <=  pi_data[4]  ;
			4'd6	:	tx  <=  pi_data[5]  ;
			4'd7	:	tx  <=  pi_data[6]  ;
			4'd8	:	tx  <=  pi_data[7]  ;
		    default	:	tx  <=  1'b1  ;
		endcase
	else
		tx  <=  1'b1  ;	

endmodule