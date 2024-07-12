module  ws2812_cfg_ctrl
(
	input	wire			sys_clk			,
	input	wire			sys_rst_n		,
	input	wire			cfg_start		,	//配置模块开始工作指示的单脉冲信号，由控制模块产生
	input	wire			r_valid			,	//红色分量有效信号，为持续拉高的电平信号
	input	wire			g_valid			,	//绿色分量有效信号，为持续拉高的电平信号
	input	wire			b_valid			,	//蓝色分量有效信号，为持续拉高的电平信号
	
	output	reg				ws2812_start	,	//控制模块开始工作指示的单脉冲信号，由配置模块产生
	output	reg		[5:0]	cfg_num			,	//配置的8x8点阵个数，最大值64-1
	output	reg		[23:0]	cfg_data			//待显示的颜色数据
);

localparam	CNT_WAIT_MAX  =  20'd1_000_000  ;	//上电等待20ms，自行设定

wire	[23:0]	data_none[63:0]	;	//显示白色字母“N”
wire	[23:0]	data_r[63:0]	;	//显示红色字母“R”
wire	[23:0]	data_g[63:0]	;	//显示绿色字母“G”
wire	[23:0]	data_b[63:0]	;	//显示蓝色字母“B”
reg		[19:0]	cnt_wait  ;			//上电等待计数器，等待20ms后一直保持最大值
reg				start_en  ;			//上电等待结束开始工作信号

always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cnt_wait  <=  20'd0  ;
	else  if(cnt_wait >= CNT_WAIT_MAX - 1'b1)
		cnt_wait  <=  CNT_WAIT_MAX  ;
	else
		cnt_wait  <=  cnt_wait + 1'b1  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		start_en  <=  1'b0  ;
	else  if(cnt_wait == CNT_WAIT_MAX - 1'b1)
		start_en  <=  1'b1  ;
	else
		start_en  <=  1'b0  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		ws2812_start  <=  1'b0  ;
	else  if((start_en == 1'b1)||((cfg_start == 1'b1)&&(cfg_num == 6'd63)))
		ws2812_start  <=  1'b1  ;
	else
		ws2812_start  <=  1'b0  ;
		
always@(posedge sys_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		cfg_num  <=  6'd0  ;
	else  if(cfg_start == 1'b1)
		cfg_num  <=  cfg_num + 1'b1  ;
	else
		cfg_num  <=  cfg_num  ;

//选择显示的字母和颜色类型
//r_valid有效显示红色“R”
//g_valid有效显示绿色"G"
//b_valid有效显示蓝色"B"
//三种信号均无效显示白色"N"	
//RGB每一位向右移5位是在不改变显示颜色条件下减小显示亮度，否则发光太刺眼
always@(*)
	case({r_valid,g_valid,b_valid})
		3'b100	:	cfg_data  =  {(data_r[cfg_num][23:16] >> 5),(data_r[cfg_num][15:8] >> 5),(data_r[cfg_num][7:0] >> 5)}  ;
		3'b010	:	cfg_data  =  {(data_g[cfg_num][23:16] >> 5),(data_g[cfg_num][15:8] >> 5),(data_g[cfg_num][7:0] >> 5)}  ;
		3'b001	:	cfg_data  =  {(data_b[cfg_num][23:16] >> 5),(data_b[cfg_num][15:8] >> 5),(data_b[cfg_num][7:0] >> 5)}  ;		
		default	:	cfg_data  =  {(data_none[cfg_num][23:16] >> 5),(data_none[cfg_num][15:8] >> 5),(data_none[cfg_num][7:0] >> 5)}  ;
	endcase
		
//默认显示字母“N”
assign  data_none[00]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[01]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[02]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[03]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[04]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[05]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[06]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[07]  =  {8'hff,8'hff,8'hff}  ;	
assign  data_none[08]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[09]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[10]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[11]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[12]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[13]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[14]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[15]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[16]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[17]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[18]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[19]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[20]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[21]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[22]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[23]  =  {8'hff,8'hff,8'hff}  ;	
assign  data_none[24]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[25]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[26]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[27]  =  {8'hff,8'hff,8'hff}  ;	
assign  data_none[28]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[29]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[30]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[31]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[32]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[33]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[34]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[35]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[36]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[37]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[38]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[39]  =  {8'hff,8'hff,8'hff}  ;	
assign  data_none[40]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[41]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[42]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[43]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[44]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[45]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[46]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[47]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[48]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[49]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[50]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[51]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[52]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[53]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[54]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[55]  =  {8'hff,8'hff,8'hff}  ;	
assign  data_none[56]  =  {8'hff,8'hff,8'hff}  ;
assign  data_none[57]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[58]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[59]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_none[60]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[61]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[62]  =  {8'h00,8'h00,8'h00}  ;
assign  data_none[63]  =  {8'hff,8'hff,8'hff}  ;
//检测到红色显示字母“R”
assign  data_r[00]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[01]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[02]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[03]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[04]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[05]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[06]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[07]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[08]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[09]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[10]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[11]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[12]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[13]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[14]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[15]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[16]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[17]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[18]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[19]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[20]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[21]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[22]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[23]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[24]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[25]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[26]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[27]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[28]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[29]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[30]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[31]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[32]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[33]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[34]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[35]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[36]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[37]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[38]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[39]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[40]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[41]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[42]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[43]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[44]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[45]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[46]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[47]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[48]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[49]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[50]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[51]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[52]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[53]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[54]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[55]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[56]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[57]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[58]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[59]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[60]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[61]  =  {8'h00,8'h00,8'h00}  ;
assign  data_r[62]  =  {8'h00,8'hff,8'h00}  ;
assign  data_r[63]  =  {8'h00,8'h00,8'h00}  ;
//检测到绿色显示字母“G”
assign  data_g[00]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[01]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[02]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[03]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[04]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[05]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[06]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[07]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[08]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[09]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[10]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[11]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[12]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[13]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[14]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[15]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[16]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[17]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[18]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[19]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[20]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[21]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[22]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[23]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[24]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[25]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[26]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[27]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[28]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[29]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[30]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[31]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[32]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[33]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[34]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[35]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[36]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[37]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[38]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[39]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[40]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[41]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[42]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[43]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[44]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[45]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[46]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[47]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[48]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[49]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[50]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[51]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[52]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[53]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[54]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[55]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[56]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[57]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[58]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[59]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[60]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[61]  =  {8'hff,8'h00,8'h00}  ;
assign  data_g[62]  =  {8'h00,8'h00,8'h00}  ;
assign  data_g[63]  =  {8'h00,8'h00,8'h00}  ;
//检测到绿色显示字母“B”
assign  data_b[00]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[01]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[02]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[03]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[04]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[05]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[06]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[07]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[08]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[09]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[10]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[11]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[12]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[13]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[14]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[15]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[16]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[17]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[18]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[19]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[20]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[21]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[22]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[23]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[24]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[25]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[26]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[27]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[28]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[29]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[30]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[31]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[32]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[33]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[34]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[35]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[36]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[37]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[38]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[39]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[40]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[41]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[42]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[43]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[44]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[45]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[46]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[47]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[48]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[49]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[50]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[51]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[52]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[53]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[54]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[55]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[56]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[57]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[58]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[59]  =  {8'h00,8'h00,8'hff}  ;
assign  data_b[60]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[61]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[62]  =  {8'h00,8'h00,8'h00}  ;
assign  data_b[63]  =  {8'h00,8'h00,8'h00}  ;

endmodule
