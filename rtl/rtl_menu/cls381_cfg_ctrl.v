module  cls381_cfg_ctrl
(
	input	wire			i2c_clk		,	//与i2c_ctrl公用的驱动时钟
	input	wire			sys_rst_n	,
	input	wire			cfg_start	,	//cfg_ctrl模块开始信号，i2c_ctrl模块每配置完成一次产生
	
	output	wire	[15:0]	cfg_data	,	//打包的寄存器地址和数据
	output	reg		[3:0]	cfg_num		,	//配置的寄存器个数
	output	reg				i2c_start		//i2c_ctrl模块开始信号
);

localparam	CNT_WAIT_MAX  =  15'd20_000  ;	//上电等待20ms

reg		[14:0]	cnt_wait		;		//等待20ms计数器
reg				i2c_start_reg	;		//i2c_start未打拍的信号，打拍后才与数据和个数保持同步
wire	[15:0]	cfg_data_reg[11:0]	;	//待发送数据的寄存

always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_wait  <=  15'd0  ;
	else  if(cnt_wait >= CNT_WAIT_MAX - 1'b1)
		cnt_wait  <=  CNT_WAIT_MAX  ;
	else
		cnt_wait  <=  cnt_wait + 1'b1  ;

always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		i2c_start_reg  <=  1'b0  ;
	else  if(cnt_wait == CNT_WAIT_MAX - 2'd2)
		i2c_start_reg  <=  1'b1  ;
	else
		i2c_start_reg  <=  1'b0  ;
		
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cfg_num  <=  4'd0  ;
	else  if((cfg_num == 4'd12)&&(cfg_start == 1'b1))
		cfg_num  <=  4'd4  ;
	else  if((cfg_start == 1'b1)||(i2c_start_reg == 1'b1))
		cfg_num  <=  cfg_num + 1'b1  ;
	else
		cfg_num  <=  cfg_num  ;
	
always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)	
		i2c_start  <=  1'b0  ;
	else  if((cfg_start == 1'b1)||(i2c_start_reg == 1'b1))	
		i2c_start  <=  1'b1  ;
	else
		i2c_start  <=  1'b0  ;

assign  cfg_data = (cfg_num == 4'd0) ? 16'd0 : cfg_data_reg[cfg_num - 1]  ;
assign  cfg_data_reg[00]  =  {8'h00,8'b0000_0110}  ;
assign  cfg_data_reg[01]  =  {8'h04,8'b0100_0000}  ;
assign  cfg_data_reg[02]  =  {8'h05,8'b0000_0100}  ;
assign  cfg_data_reg[03]  =  {8'h0F,8'h0}  ;
assign  cfg_data_reg[04]  =  {8'h0E,8'h0}  ;
assign  cfg_data_reg[05]  =  {8'h0D,8'h0}  ;
assign  cfg_data_reg[06]  =  {8'h12,8'h0}  ;
assign  cfg_data_reg[07]  =  {8'h11,8'h0}  ;
assign  cfg_data_reg[08]  =  {8'h10,8'h0}  ;
assign  cfg_data_reg[09]  =  {8'h15,8'h0}  ;
assign  cfg_data_reg[10]  =  {8'h14,8'h0}  ;
assign  cfg_data_reg[11]  =  {8'h13,8'h0}  ;

endmodule
