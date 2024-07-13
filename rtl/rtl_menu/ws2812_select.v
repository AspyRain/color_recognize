module  ws2812_select
(
	input	wire			sys_clk			,
	input	wire			sys_rst_n		,
	input	wire			cfg_start		,	//配置模块开始工作指示的单脉冲信号，由控制模块产生
	input	wire	[4:0]	key				,	//五个功能按键
	input	wire	[7:0]	data_r			,	//红色分量
	input	wire	[7:0]	data_g			,	//绿色分量
	input	wire	[7:0]	data_b			,	//蓝色分量
	output	reg				ws2812_start	,	//控制模块开始工作指示的单脉冲信号，由配置模块产生
	output	reg		[5:0]	cfg_num			,	//配置的8x8点阵个数，最大值64-1
	output	reg		[1:0]	mode			,
	output			[23:0]	cfg_data			//待显示的颜色数据
);

localparam	CNT_WAIT_MAX  =  20'd1_000_000  ;	//上电等待20ms，自行设定
reg	[1:0]		select_index			;
wire	[23:0]	data[63:0]				;
wire	[23:0]	data_S[63:0]			;
wire	[23:0]	data_D[63:0]			;


reg		[19:0]	cnt_wait  				;			//上电等待计数器，等待20ms后一直保持最大值
reg				start_en  				;			//上电等待结束开始工作信号
reg				select_en				;
//光标坐标控制
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		select_index <= 2'b0;
	end
	else begin
		case (key[4:2])
			3'b001:begin
				select_index <= 2'b1;
			end
			3'b010:begin
				select_index <= 2'b10;
			end
			default:
				select_index <= select_index;
		endcase
	end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		mode <= 2'b0;
	end
	else begin
		if (key[4]==1'b1)begin
			mode <= select_index;
		end
		else begin
			mode <= mode;
		end
	end
end




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
		cfg_num  <=  6'd0			;
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



genvar k;
generate
    for (k = 0; k < 64; k = k + 1) begin : data_gen
            assign data[k] =(select_index == 2'b0) ? 24'h0: (select_index == 2'b1) ? data_S[k] : (select_index == 2'b10) ? data_D[k] : 24'h0;
    end
endgenerate


assign cfg_data  =  {(data[cfg_num][23:16] >> 3),(data[cfg_num][15:8] >> 3),(data[cfg_num][7:0] >> 3)}  ;


parameter len = 4'd4;

//选择字母
//字母S
assign  data_S[00]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[01]  =  {data_g,data_r,data_b}  ;
assign  data_S[02]  =  {data_g,data_r,data_b}  ;
assign  data_S[03]  =  {data_g,data_r,data_b}  ;	
assign  data_S[04]  =  {data_g,data_r,data_b}  ;
assign  data_S[05]  =  {data_g,data_r,data_b}  ;
assign  data_S[06]  =  {data_g,data_r,data_b}  ;
assign  data_S[07]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_S[08]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[09]  =  {data_g,data_r,data_b}  ;
assign  data_S[10]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[11]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_S[12]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[13]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[14]  =  {data_g,data_r,data_b}  ;
assign  data_S[15]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_S[16]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[17]  =  {data_g,data_r,data_b}  ;
assign  data_S[18]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[19]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_S[20]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[21]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[22]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[23]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_S[24]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[25]  =  {data_g,data_r,data_b}  ;
assign  data_S[26]  =  {data_g,data_r,data_b}  ;
assign  data_S[27]  =  {data_g,data_r,data_b}  ;	
assign  data_S[28]  =  {data_g,data_r,data_b}  ;
assign  data_S[29]  =  {data_g,data_r,data_b}  ;
assign  data_S[30]  =  {data_g,data_r,data_b}  ;
assign  data_S[31]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_S[32]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[33]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2};
assign  data_S[34]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[35]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_S[36]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[37]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[38]  =  {data_g,data_r,data_b}   ;
assign  data_S[39]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	

assign  data_S[40]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[41]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[42]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[43]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_S[44]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[45]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[46]  =  {data_g,data_r,data_b}  ;
assign  data_S[47]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_S[48]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[49]  =  {data_g,data_r,data_b}  ;
assign  data_S[50]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[51]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_S[52]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[53]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[54]  =  {data_g,data_r,data_b}  ;
assign  data_S[55]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
	
assign  data_S[56]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_S[57]  =  {data_g,data_r,data_b}  ;
assign  data_S[58]  =  {data_g,data_r,data_b}  ;
assign  data_S[59]  =  {data_g,data_r,data_b}  ;	
assign  data_S[60]  =  {data_g,data_r,data_b}  ;
assign  data_S[61]  =  {data_g,data_r,data_b}  ;
assign  data_S[62]  =  {data_g,data_r,data_b}  ;
assign  data_S[63]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;


//字母D
assign  data_D[00]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[01]  =  {data_g,data_r,data_b}  ;
assign  data_D[02]  =  {data_g,data_r,data_b}  ;
assign  data_D[03]  =  {data_g,data_r,data_b}  ;	
assign  data_D[04]  =  {data_g,data_r,data_b}  ;
assign  data_D[05]  =  {data_g,data_r,data_b}  ;
assign  data_D[06]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[07]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_D[08]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[09]  =  {data_g,data_r,data_b}  ;
assign  data_D[10]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[11]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_D[12]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[13]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[14]  =  {data_g,data_r,data_b}  ;
assign  data_D[15]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_D[16]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[17]  =  {data_g,data_r,data_b}  ;
assign  data_D[18]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[19]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_D[20]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[21]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[22]  =  {data_g,data_r,data_b}  ;  
assign  data_D[23]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_D[24]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[25]  =  {data_g,data_r,data_b}  ;
assign  data_D[26]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2};
assign  data_D[27]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2};
assign  data_D[28]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2};
assign  data_D[29]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2};
assign  data_D[30]  =  {data_g,data_r,data_b}  ;
assign  data_D[31]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_D[32]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[33]  =  {data_g,data_r,data_b}  ;
assign  data_D[34]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[35]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_D[36]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[37]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[38]  =  {data_g,data_r,data_b}  ;
assign  data_D[39]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	

assign  data_D[40]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[41]  =  {data_g,data_r,data_b}  ;
assign  data_D[42]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[43]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_D[44]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[45]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[46]  =  {data_g,data_r,data_b}  ;
assign  data_D[47]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;

assign  data_D[48]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[49]  =  {data_g,data_r,data_b}  ;
assign  data_D[50]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[51]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;	
assign  data_D[52]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[53]  =  {data_g,data_r,data_b}  ;
assign  data_D[54]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[55]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
	
assign  data_D[56]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[57]  =  {data_g,data_r,data_b}  ;
assign  data_D[58]  =  {data_g,data_r,data_b}  ;
assign  data_D[59]  =  {data_g,data_r,data_b}  ;	
assign  data_D[60]  =  {data_g,data_r,data_b}  ;
assign  data_D[61]  =  {data_g,data_r,data_b}  ;
assign  data_D[62]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
assign  data_D[63]  =  {8'h5e>>2,8'h1a>>2,8'h63>>2}  ;
endmodule
