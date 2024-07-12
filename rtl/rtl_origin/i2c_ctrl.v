module  i2c_ctrl
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	wire			i2c_start	,
	input	wire	[3:0]	cfg_num		,
	input	wire	[15:0]	cfg_data	,
	
	output	wire			scl			,
	output	reg				i2c_clk		,
	output	reg				cfg_start	,
	output	reg		[23:0]	data_r		,
	output	reg		[23:0]	data_g		,
	output	reg		[23:0]	data_b		,
	
	inout	wire			sda
);

localparam	IDLE		=	4'd0	,
			START		=	4'd1	,
			SLAVE_ADDR	=	4'd2	,
			ACK_1		=	4'd3	,
			REG_ADDR	=	4'd4	,
			ACK_2		=	4'd5	,
			DATA		=	4'd6	,
			ACK_3		=	4'd7	,
			STOP		=	4'd8	,
			NACK		=	4'd9	,
			WAIT		=	4'd10	;
localparam	CNT_CLK_MAX		=	5'd25		;	//系统时钟计数器最大值
localparam	SLAVE_ID		=	7'h53		;	//从设备的I2C ID号

reg		[4:0]	cnt_clk		;	//系统时钟计数器，计数25次产生1MHZ i2c驱动时钟
reg				skip_en_0	;	//配置寄存器状态跳转信号
reg				skip_en_1	;	//读取绿色分量状态跳转信号
reg				skip_en_2	;	//读取红色分量状态跳转信号
reg				skip_en_3	;	//读取蓝色分量状态跳转信号
reg		[3:0]	n_state		;	//次态
reg		[3:0]	c_state		;	//现态
reg		[1:0]	cnt_i2c_clk	;	//i2c_clk时钟计数器，每计数4次就是一个SCL周期
reg		[2:0]	cnt_bit		;	//计数发送的比特数
reg				i2c_scl		;	//这就是scl信号，加i2c_是为了与i2c_sda同步
reg				i2c_sda		;	//由主机产生，在主机控制SDA通信总线时赋值给SDA
reg				ack_en		;	//响应使能信号，为1时代表接收的ACK响应有效
reg				i2c_end		;	//结束信号，在STOP最后一个时钟周期拉高，表示一次通信结束
reg		[2:0]	step		;	//操作步骤信号，与跳转信号相关联
								//在向寄存器里面写入数据或者读出数据时，状态跳转情况是不一样的
reg				flag_g		;	//读取绿色数据指示不同的状态跳转
reg		[1:0]	cnt_g		;	//绿色寄存器个数计数
(*noprune*)reg		[23:0]	rec_data_g	;	//读取到的绿色分量
reg				flag_r		;	//读取红色数据指示不同的状态跳转
reg		[1:0]	cnt_r		;	//红色寄存器个数计数
(*noprune*)reg		[23:0]	rec_data_r	;	//读取到的红色分量
reg				flag_b		;	//读取蓝色数据指示不同的状态跳转
reg		[1:0]	cnt_b		;	//蓝色寄存器个数计数
(*noprune*)reg		[23:0]	rec_data_b	;	//读取到的蓝色分量
reg		[7:0]	slave_addr	;
reg		[7:0]	reg_addr	;
reg		[7:0]	wr_data		;
wire			sda_in		;	//sda赋值给sda_in，主机在接收从机数据时采集sda_in的数据，间接采集了SDA数据
wire			sda_en		;	//主机控制SDA使能信号，为1代表主机控制SDA，为0代表控制权为从机

assign  scl  =  i2c_scl  ;
//三态门
assign  sda_in  =  sda  ;
assign  sda_en  =  ((c_state == ACK_1)||(c_state == ACK_2)||(c_state == ACK_3)||((step != 3'd0)&&(c_state == DATA))) ? 1'b0 : 1'b1  ;
assign  sda     =  (sda_en == 1'b1) ? i2c_sda : 1'bz  ;

always@(*)
	case(step)
		3'd0	:begin	
					slave_addr  =  {SLAVE_ID,1'b0}  ;
					reg_addr	=  cfg_data[15:8]  ;	//主控寄存器地址
					wr_data		=  cfg_data[7:0]  ;
				 end
		3'd1	:begin
					slave_addr  =  {SLAVE_ID,flag_g}  ;
					reg_addr	=  cfg_data[15:8]  ;
					wr_data		=  8'h0  ;	//未写入数据
				 end
		3'd2	:begin
					slave_addr  =  {SLAVE_ID,flag_r}  ;
					reg_addr	=  cfg_data[15:8]  ;
					wr_data		=  8'h0  ;	//未写入数据
				 end
		3'd3	:begin
					slave_addr  =  {SLAVE_ID,flag_b}  ;
					reg_addr	=  cfg_data[15:8]  ;
					wr_data		=  8'h0  ;	//未写入数据
				 end				 
		default	:begin	
					slave_addr  =  slave_addr  ;
					reg_addr	=  reg_addr  ;
					wr_data		=  wr_data  ;
				 end
	endcase		

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_clk  <=  5'd0  ;
	else  if(cnt_clk == CNT_CLK_MAX - 1'b1)
		cnt_clk  <=  5'd0  ;
	else
		cnt_clk  <=  cnt_clk + 1'b1  ;

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		i2c_clk  <=  1'b0  ;
	else  if(cnt_clk == CNT_CLK_MAX - 1'b1)
		i2c_clk  <=  ~i2c_clk  ;
	else
		i2c_clk  <=  i2c_clk  ;
		
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cfg_start  <=  1'b0  ;
	else
		cfg_start  <=  i2c_end  ;
		
//状态机第一段
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		c_state  <=  IDLE  ;
	else
		c_state  <=  n_state  ;
		
//状态机第二段
always@(*)
	case(c_state)
		IDLE		:	if((skip_en_0 == 1'b1)||(skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  START  ;
						else
							n_state  =  IDLE  ;
		START		:	if((skip_en_0 == 1'b1)||(skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  SLAVE_ADDR  ;
						else
							n_state  =  START  ;
		SLAVE_ADDR	:	if((skip_en_0 == 1'b1)||(skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  ACK_1  ;
						else
							n_state  =  SLAVE_ADDR  ;
		ACK_1		:	if((skip_en_0 == 1'b1)||((skip_en_1 == 1'b1)&&(flag_g == 1'b0))||((skip_en_2 == 1'b1)&&(flag_r == 1'b0))||((skip_en_3 == 1'b1)&&(flag_b == 1'b0)))
							n_state  =  REG_ADDR  ;
						else  if((skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  DATA  ;
						else
							n_state  =  ACK_1  ;
		REG_ADDR	:	if((skip_en_0 == 1'b1)||(skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  ACK_2  ;
						else
							n_state  =  REG_ADDR  ;
		ACK_2		:	if(skip_en_0 == 1'b1)
							n_state  =  DATA  ;
						else  if((skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  WAIT  ;
						else
							n_state  =  ACK_2  ;
		WAIT		:	if((skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  START  ;
						else
							n_state  =  WAIT  ;
		DATA		:	if(skip_en_0 == 1'b1)
							n_state  =  ACK_3  ;
						else  if((skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  NACK  ;
						else
							n_state  =  DATA  ;
		ACK_3		:	if(skip_en_0 == 1'b1)
							n_state  =  STOP  ;
						else
							n_state  =  ACK_3  ;
		NACK		:	if((skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  STOP  ;
						else
							n_state  =  NACK  ;
		STOP		:	if((skip_en_0 == 1'b1)||(skip_en_1 == 1'b1)||(skip_en_2 == 1'b1)||(skip_en_3 == 1'b1))
							n_state  =  IDLE  ;
						else
							n_state  =  STOP  ;
		default		:	n_state  =  IDLE  ;
	endcase
	
//状态机第三段
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			skip_en_0	<=  1'b0   	;
			skip_en_1	<=  1'b0	;
			skip_en_2 	<=  1'b0	;
			skip_en_3	<=  1'b0	;
			cnt_i2c_clk	<=  2'd0	;
			cnt_bit		<=  3'd0	;
			flag_g		<=  1'b0	;
			cnt_g		<=  2'd0	;
			flag_r		<=  1'b0	;
			cnt_r		<=  2'd0	;	
			flag_b		<=  1'b0	;
			cnt_b		<=  2'd0	;			
			i2c_end		<=  1'b0    ;
			step		<=  3'd0	;
		end
	else
		case(c_state)
			IDLE		:begin
							if((i2c_start == 1'b1)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((i2c_start == 1'b1)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;
							if((i2c_start == 1'b1)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((i2c_start == 1'b1)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;								
						 end
			START		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;								
						 end
			SLAVE_ADDR	:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if(cnt_i2c_clk == 2'd3)
								cnt_bit  <=  cnt_bit + 1'b1  ;
							else
								cnt_bit  <=  cnt_bit  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end
			ACK_1		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end
			REG_ADDR	:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if(cnt_i2c_clk == 2'd3)
								cnt_bit  <=  cnt_bit + 1'b1  ;
							else
								cnt_bit  <=  cnt_bit  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end
			ACK_2		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end	
			WAIT		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;	
							flag_g  <=  1'b1  ;
							flag_r  <=  1'b1  ;
							flag_b  <=  1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end
			DATA		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if(cnt_i2c_clk == 2'd3)
								cnt_bit  <=  cnt_bit + 1'b1  ;
							else
								cnt_bit  <=  cnt_bit  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(cnt_bit == 3'd7)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;									
						 end
			NACK		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;		
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;								
						 end	
			ACK_3		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(ack_en == 1'b1)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
						 end	
			STOP		:begin
							cnt_i2c_clk  <=  cnt_i2c_clk + 1'b1  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd0))
								skip_en_0  <=  1'b1  ;
							else
								skip_en_0  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd1))
								skip_en_1  <=  1'b1  ;
							else
								skip_en_1  <=  1'b0  ;	
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd2))
								skip_en_2  <=  1'b1  ;
							else
								skip_en_2  <=  1'b0  ;
							if((cnt_i2c_clk == 2'd2)&&(step == 3'd3))
								skip_en_3  <=  1'b1  ;
							else
								skip_en_3  <=  1'b0  ;								
							if(cnt_i2c_clk == 2'd2)	
								i2c_end  <=  1'b1  ;
							else
								i2c_end  <=  1'b0  ;
							if((cnt_b == 2'd2)&&(cnt_i2c_clk == 2'd3))
								step  <=  3'd1  ;
							else  if((cfg_num == 3'd3)&&(cnt_i2c_clk == 2'd3))
								step  <=  step + 1'b1  ;
							else  if((cnt_r == 2'd2)&&(cnt_i2c_clk == 2'd3))
								step  <=  step + 1'b1  ;
							else  if((cnt_g == 2'd2)&&(cnt_i2c_clk == 2'd3))
								step  <=  step + 1'b1  ;							
							else
								step  <=  step  ;
							if((i2c_end == 1'b1)&&(cnt_g == 2'd2))
								cnt_g  <=  2'd0  ;
							else  if((i2c_end == 1'b1)&&(cfg_num >= 4'd4)&&(cfg_num <= 4'd6))
								cnt_g  <=  cnt_g + 1'b1  ;
							else
								cnt_g  <=  cnt_g  ;
							if((i2c_end == 1'b1)&&(cnt_r == 2'd2))
								cnt_r  <=  2'd0  ;
							else  if((i2c_end == 1'b1)&&(cfg_num >= 4'd7)&&(cfg_num <= 4'd9))
								cnt_r  <=  cnt_r + 1'b1  ;
							else
								cnt_r  <=  cnt_r  ;	
							if((i2c_end == 1'b1)&&(cnt_b == 2'd2))
								cnt_b  <=  2'd0  ;
							else  if((i2c_end == 1'b1)&&(cfg_num >= 4'd10)&&(cfg_num <= 4'd12))
								cnt_b  <=  cnt_b + 1'b1  ;
							else
								cnt_b  <=  cnt_b  ;									
							if(i2c_end == 1'b1)
								begin
									flag_g  <=  1'b0  ;
									flag_r  <=  1'b0  ;
									flag_b  <=  1'b0  ;
								end
							else
								begin
									flag_g  <=  flag_g  ;
									flag_r  <=  flag_r  ;
									flag_b  <=  flag_b  ;
								end
						 end
			default		:begin
							skip_en_0	<=  1'b0   	;
							skip_en_1   <=  1'b0    ;
							cnt_i2c_clk	<=  2'd0	;
							cnt_bit		<=  3'd0	;
							flag_g		<=  1'b0	;
							cnt_g		<=  2'd0	;
							i2c_end		<=  1'b0    ;
							step		<=  3'd0	;
						 end
		endcase
		
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		rec_data_g  <=  24'd0  ;
	else
		case(c_state)
			DATA	:	if((step == 3'd1)&&(cnt_i2c_clk == 2'd1))
							rec_data_g  <=  {rec_data_g[22:0],sda_in}  ;
						else
							rec_data_g  <=  rec_data_g  ;
			default	:	rec_data_g  <=  rec_data_g  ;	//必须写这一句
		endcase
		
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		rec_data_r  <=  24'd0  ;
	else
		case(c_state)
			DATA	:	if((step == 3'd2)&&(cnt_i2c_clk == 2'd1))
							rec_data_r  <=  {rec_data_r[22:0],sda_in}  ;
						else
							rec_data_r  <=  rec_data_r  ;
			default	:	rec_data_r  <=  rec_data_r  ;	//必须写这一句
		endcase	

always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		rec_data_b  <=  24'd0  ;
	else
		case(c_state)
			DATA	:	if((step == 3'd3)&&(cnt_i2c_clk == 2'd1))
							rec_data_b  <=  {rec_data_b[22:0],sda_in}  ;
						else
							rec_data_b  <=  rec_data_b  ;
			default	:	rec_data_b  <=  rec_data_b  ;	//必须写这一句
		endcase	

always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			data_r	<=  24'd0  ;
			data_g	<=  24'd0  ;
			data_b	<=  24'd0  ;
		end
	else  if((step == 3'd3)&&(c_state == STOP)&&(cnt_b == 2'd2))
		begin
			data_r  <=  rec_data_r  ;
			data_g	<=  rec_data_g  ;
			data_b  <=  rec_data_b  ;
		end
	else
		begin
			data_r  <=  data_r  ;
			data_g	<=  data_g  ;
			data_b  <=  data_b  ;
		end
		
always@(*)
	case(c_state)
		ACK_1,ACK_2,ACK_3
					:	ack_en  =  ~sda_in  ;
		NACK		:	ack_en  =  i2c_sda  ;
		default		:	ack_en  =  1'b0  ;
	endcase
	
always@(*)
	case(c_state)
		IDLE		:	i2c_scl  =  1'b1  ;
		START		:	if(cnt_i2c_clk == 2'd3)
							i2c_scl  =  1'b0  ;
						else
							i2c_scl  =  1'b1  ;
		SLAVE_ADDR,REG_ADDR,DATA,ACK_1,ACK_2,ACK_3,NACK
					:	if((cnt_i2c_clk == 2'd0)||(cnt_i2c_clk == 2'd3))
							i2c_scl  =  1'b0  ;
						else
							i2c_scl  =  1'b1  ;
		WAIT		:	i2c_scl  =  1'b0  ;
		STOP		:	if(cnt_i2c_clk == 2'd0)
							i2c_scl  =  1'b0  ;
						else
							i2c_scl  =  1'b1  ;	
		default		:	i2c_scl  =  1'b1  ;
	endcase
	
always@(*)
	case(c_state)
		IDLE		:	i2c_sda  =  1'b1  ;
		START		:	if((cnt_i2c_clk == 2'd0)||(cnt_i2c_clk == 2'd1))
							i2c_sda  =  1'b1  ;
						else
							i2c_sda  =  1'b0  ;
		SLAVE_ADDR	:	i2c_sda  =  slave_addr[7 - cnt_bit]  ;
		REG_ADDR	:	i2c_sda  =  reg_addr[7 - cnt_bit]  ;
		DATA		:	i2c_sda  =  wr_data[7 - cnt_bit]  ;
		ACK_1,ACK_2,ACK_3,NACK,WAIT	
					:	i2c_sda  =  1'b1  ;
		STOP		:	if((cnt_i2c_clk == 2'd0)||(cnt_i2c_clk == 2'd1))
							i2c_sda  =  1'b0  ;
						else
							i2c_sda  =  1'b1  ;
		default		:	i2c_sda  =  1'b1  ;
	endcase

endmodule
