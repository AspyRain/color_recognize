module  uart_rx
#(
	parameter	CLK_FRE		=	'd50_000_000	,	//串口通信时钟频率
				BAUD_RATE	=	'd115200			//串口通信波特率
)
(
	input	wire			sys_clk		,	//系统时钟，频率为50MHZ
	input	wire			sys_rst_n	,	//系统复位，低电平有效
	input	wire			rx			,	//串口数据接收信号线
	
	output	reg 	[7:0]	po_data		,	//串口将单比特数据编码完成后的8比特数据
	output	reg 			po_flag			//与编码完成后数据同步输出的标志信号
);

localparam	CNT_BAUD_MID	=	CLK_FRE / (BAUD_RATE*2)	,	//波特率计数中值
			CNT_BAUD_MAX	=	CLK_FRE	/ BAUD_RATE		;	//波特率计数最大值

reg				rx_d0		;	//FPGA接收串口数据打一拍
reg				rx_d1		;	//FPGA接收串口数据打两拍
reg				rx_d2		;	//FPGA接收串口数据打三拍
reg				work_valid	;	//FPGA进行串口数据并串转换有效的工作区间
reg		[14:0]	cnt_baud	;	//波特率计数器
reg		[3:0]	cnt_bit		;	//接收到的起始位和数据个数计数器
reg				flag_bit	;	//采集串行数据的点（计数中点采集最稳定）
reg		[7:0]	po_data_reg	;	//采集数据寄存器
wire			start_en	;	//串口接收模块开始工作标志信号
wire			stop_en		;	//串口接收模块结束工作标志信号

assign  start_en	=	((rx_d1 == 1'b0)&&(rx_d2 == 1'b1)) ? 1'b1 : 1'b0  ;
assign	stop_en		=	((cnt_baud == CNT_BAUD_MID - 1'b1)&&(cnt_bit == 4'd8)) ? 1'b1 : 1'b0  ;

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			rx_d0  <=  1'b0  ;
			rx_d1  <=  1'b0  ;
			rx_d2  <=  1'b0  ;
		end
	else
		begin
			rx_d0  <=  rx     ;
			rx_d1  <=  rx_d0  ;
			rx_d2  <=  rx_d1  ;
		end
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		work_valid  <=  1'b0  ;
	else  if(start_en == 1'b1)
		work_valid  <=  1'b1  ;
	else  if(stop_en == 1'b1)
		work_valid  <=  1'b0  ;
	else
		work_valid  <=  work_valid  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_baud  <=  15'd0  ;
	else  if((cnt_baud == CNT_BAUD_MAX - 1'b1)&&(work_valid == 1'b1))
		cnt_baud  <=  15'd0  ;
	else  if(work_valid == 1'b1)
		cnt_baud  <=  cnt_baud + 1'b1  ;
	else
		cnt_baud  <=  15'd0  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_bit  <=  4'd0  ;
	else  if((cnt_baud == CNT_BAUD_MAX - 1'b1)&&(work_valid == 1'b1)&&(cnt_bit == 4'd8))
		cnt_bit  <=  4'd0  ;	
	else  if((cnt_baud == CNT_BAUD_MAX - 1'b1)&&(work_valid == 1'b1))
		cnt_bit  <=  cnt_bit + 1'b1  ;
	else  if(work_valid == 1'b0)
		cnt_bit  <=  4'd0  ;
	else
		cnt_bit  <=  cnt_bit  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		flag_bit  <=  1'b0  ;
	else  if((cnt_baud == CNT_BAUD_MID - 2'd3)&&(cnt_bit != 4'd0))
		flag_bit  <=  1'b1  ;
	else
		flag_bit  <=  1'b0  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		po_data_reg  <=  8'd0  ;
	else  if((flag_bit == 1'b1)&&(work_valid == 1'b1))
		po_data_reg  <=  {rx_d2,po_data_reg[7:1]}  ;
	else  if(work_valid == 1'b0)
		po_data_reg  <=  8'd0  ;
	else
		po_data_reg  <=  po_data_reg  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		po_data  <=  8'd0  ;
	else  if((cnt_bit == 4'd8)&&(stop_en == 1'b1))
		po_data  <=  po_data_reg  ;
	else
		po_data  <=  po_data  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		po_flag  <=  1'b0  ;
	else  if((cnt_bit == 4'd8)&&(stop_en == 1'b1))
		po_flag  <=  1'b1  ;
	else
		po_flag  <=  1'b0  ;

endmodule