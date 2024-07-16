module  ws2812_find
(
	input	wire			sys_clk			,
	input	wire			sys_rst_n		,
	input	wire			cfg_start		,	//配置模块开始工作指示的单脉冲信号，由控制模块产生
	input	wire	[7:0]	data_r			,	//红色分量
	input	wire	[7:0]	data_g			,	//绿色分量
	input	wire	[7:0]	data_b			,	//蓝色分量
	input	wire			c_ok			,
	input	wire	[4:0]	key				,	//五个功能按键
	input	wire	[1:0]	similar_flag	,

	output	reg				ws2812_start	,	//控制模块开始工作指示的单脉冲信号，由配置模块产生
	output	reg		[5:0]	cfg_num			,	//配置的8x8点阵个数，最大值64-1
	output			[23:0]	cfg_data		,	//待显示的颜色数据

	output	wire		[2:0]	point		,			//颜色是否找正确的提示信息
	output  	    [7:0] 	set_r ,
	output		    [7:0] 	set_g ,
	output			[7:0] 	set_b
);

localparam	CNT_WAIT_MAX  =  20'd1_000_000  ;	//上电等待20ms，自行设定
reg		[5:0]	now_index;
wire	[23:0]	data_draw[63:0]			;
wire	[23:0]	data_background[63:0]	;
wire    [23:0]  data_find[255:0]            ;			//图片数据
wire	[63:0]	is_correct				;

reg		[19:0]	cnt_wait  				;			//上电等待计数器，等待20ms后一直保持最大值
reg				start_en  				;			//上电等待结束开始工作信号
reg				flash_en				;
wire			select_en				;
//背景赋值



//光标坐标控制
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		now_index <= 6'b0;
	end
	else begin
		case (key[3:0])
			4'b0001:begin
				if (now_index < 6'd8)begin
					now_index <= now_index + (6'd64 - 6'd8);
				end
				else begin
					now_index <= now_index - 6'd8;
				end
			end
			4'b0010:begin
				if (now_index >= 6'd56)begin
					now_index <= now_index - (6'd64 - 6'd8);
				end
				else begin
					now_index <= now_index + 6'd8;
				end
			end
			4'b0100:begin
				if (now_index % 8 == 6'd0)begin
					now_index <= now_index + 6'd7;
				end
				else begin
					now_index <= now_index - 6'd1;
				end
			end
			4'b1000:begin
				if ((now_index+1)%8 == 6'd0)begin
					now_index <= now_index - 6'd7;
				end
				else begin
					now_index <= now_index + 6'd1;
				end
			end 
			default: begin
			end
					
		endcase
	end
end


always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		flash_en <= 1'b0;
	end
	else begin
		if (c_ok)begin
			flash_en <= ~flash_en;
		end
		else begin
			flash_en <= flash_en;
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



//assign num = (key[4] == 1 ) ? ~num : num;
assign cfg_data  =  {(data_draw[cfg_num][23:16] >> 3),(data_draw[cfg_num][15:8] >> 3),(data_draw[cfg_num][7:0] >> 3)}  ;
genvar k;
genvar j;
parameter len = 4'd4;
generate
    for (k = 0; k < 64; k = k + 1) begin : data_gen
			assign is_correct[k] =  (sys_rst_n == 1'b0)?1'b0:( k == now_index ? ((similar_flag == 2'b01) ? 1'b1:(similar_flag == 2'b10)?is_correct[k]:1'b0) : is_correct[k]);
            assign data_draw[k] = (k == now_index && flash_en == 1'b1) ? {data_g,data_r,data_b}: data_background[k];
            //assign num[k] =(key[4] == 1 && k == now_index) ? ~num[k] : num[k];
			assign data_background[k] = (sys_rst_n==1'b1 && (flash_en == 1'b0 || is_correct[k])  ) ? data_find[k] : {8'h00,8'h00,8'h00} ;//修改
    end
endgenerate
			assign set_g = key[4] == 1  ? data_find[now_index][23:16] 	: {8'h00};
			assign set_r = key[4] == 1  ? data_find[now_index][15:8] 	: {8'h00};
			assign set_b = key[4] == 1  ? data_find[now_index][7:0] 	: {8'h00};


//找颜色部分数据
assign  data_find[00]  =  {8'h8c,8'h41,8'h55}  ;//0
assign  data_find[01]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[02]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[03]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[04]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[05]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[06]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[07]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[08]  =  {8'h00,8'hff>>2,8'h00}  ;//1
assign  data_find[09]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[10]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[11]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[12]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[13]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[14]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[15]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[16]  =  {8'h00,8'hff>>2,8'h00}  ;//2
assign  data_find[17]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[18]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[19]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[20]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[21]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[22]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[23]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[24]  =  {8'h00,8'hff>>2,8'h00}  ;//3
assign  data_find[25]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[26]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[27]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[28]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[29]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[30]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[31]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[32]  =  {8'h00,8'hff>>2,8'h00}  ;//4
assign  data_find[33]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[34]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[35]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[36]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[37]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[38]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[39]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[40]  =  {8'h00,8'hff>>2,8'h00}  ;//5
assign  data_find[41]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[42]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[43]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[44]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[45]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[46]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[47]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[48]  =  {8'h00,8'hff>>2,8'h00}  ;//6
assign  data_find[49]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[50]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[51]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[52]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[53]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[54]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[55]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[56]  =  {8'h00,8'hff>>2,8'h00}  ;//7
assign  data_find[57]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[58]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[59]  =  {8'h00,8'hff>>2,8'h00}  ;	
assign  data_find[60]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[61]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[62]  =  {8'h00,8'hff>>2,8'h00}  ;
assign  data_find[63]  =  {8'h00,8'hff>>2,8'h00}  ;//8

assign  data_find[64]  =  {8'h00,8'h00,8'h00}  ;//0
assign  data_find[65]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[66]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[67]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[68]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[69]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[70]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[71]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[72]  =  {8'h00,8'h00,8'h00}  ;//1
assign  data_find[73]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[74]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[75]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[76]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[77]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[78]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[79]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[80]  =  {8'h00,8'h00,8'h00}  ;//2
assign  data_find[81]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[82]  =  {8'hff,8'h00,8'h00}  ;
assign  data_find[83]  =  {8'hff,8'h00,8'h00}  ;	
assign  data_find[84]  =  {8'hff,8'h00,8'h00}  ;
assign  data_find[85]  =  {8'hff,8'h00,8'h00}  ;
assign  data_find[86]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[87]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[88]  =  {8'h00,8'h00,8'h00}  ;//3
assign  data_find[89]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[90]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[91]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[92]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[93]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[94]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[95]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[96]  =  {8'h00,8'h00,8'h00}  ;//4
assign  data_find[97]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[98]  =  {8'h00,8'h00,8'h00}  ;
assign  data_find[99]  =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[100]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[101]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[102]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[103]  =  {8'h00,8'h00,8'h00} ;	
assign  data_find[104]  =  {8'h00,8'h00,8'h00} ;//5
assign  data_find[105]  =  {8'hff,8'h00,8'h00} ;
assign  data_find[106]  =  {8'hff,8'h00,8'h00} ;
assign  data_find[107]  =  {8'hff,8'h00,8'h00} ;	
assign  data_find[108]  =  {8'hff,8'h00,8'h00} ;
assign  data_find[109]  =  {8'hff,8'h00,8'h00} ;
assign  data_find[110]  =  {8'hff,8'h00,8'h00} ;
assign  data_find[111]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[112]  =  {8'h00,8'h00,8'h00} ;//6
assign  data_find[113]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[114]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[115]  =  {8'h00,8'h00,8'h00} ;	
assign  data_find[116]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[117]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[118]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[119]  =  {8'h00,8'h00,8'h00} ;	
assign  data_find[120]  =  {8'h00,8'h00,8'h00} ;//7
assign  data_find[121]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[122]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[123]  =  {8'h00,8'h00,8'h00} ;	
assign  data_find[124]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[125]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[126]  =  {8'h00,8'h00,8'h00} ;
assign  data_find[127]  =  {8'h00,8'h00,8'h00} ;

assign  data_find[128] =  {8'h00,8'h00,8'h00}  ;//0
assign  data_find[129] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[130] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[131] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[132] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[133] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[134] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[135] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[136] =  {8'h00,8'h00,8'h00}  ;//1
assign  data_find[137] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[138] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[139] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[140] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[141] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[142] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[143] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[144] =  {8'h00,8'h00,8'h00}  ;//2
assign  data_find[145] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[146] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[147] =  {8'h00,8'h00,8'hff}  ;	
assign  data_find[148] =  {8'h00,8'h00,8'hff}  ;
assign  data_find[149] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[150] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[151] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[152] =  {8'h00,8'h00,8'h00}  ;//3
assign  data_find[153] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[154] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[155] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[156] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[157] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[158] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[159] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[160] =  {8'h00,8'h00,8'h00}  ;//4
assign  data_find[161] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[162] =  {8'h00,8'h00,8'hff}  ;
assign  data_find[163] =  {8'h00,8'h00,8'hff}  ;	
assign  data_find[164]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[165]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[166]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[167]  = {8'h00,8'h00,8'h00}  ;	
assign  data_find[168]  = {8'h00,8'h00,8'h00}  ;//5
assign  data_find[169]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[170]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[171]  = {8'h00,8'h00,8'h00}  ;	
assign  data_find[172]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[173]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[174]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[175]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[176]  = {8'h00,8'h00,8'h00}  ;//6
assign  data_find[177]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[178]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[179]  = {8'h00,8'h00,8'hff}  ;	
assign  data_find[180]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[181]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[182]  = {8'h00,8'h00,8'hff}  ;
assign  data_find[183]  = {8'h00,8'h00,8'h00}  ;	
assign  data_find[184]  = {8'h00,8'h00,8'h00}  ;//7
assign  data_find[185]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[186]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[187]  = {8'h00,8'h00,8'h00}  ;	
assign  data_find[188]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[189]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[190]  = {8'h00,8'h00,8'h00}  ;
assign  data_find[191] =  {8'h00,8'h00,8'h00}  ;

assign  data_find[192]=  {8'h00,8'h00,8'h00}  ;//0
assign  data_find[193]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[194]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[195]=  {8'h00,8'h00,8'h00}  ;	
assign  data_find[196]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[197]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[198]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[199]=  {8'h00,8'h00,8'h00}  ;	
assign  data_find[200]=  {8'hff,8'hff,8'hff}  ;//1
assign  data_find[201]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[202]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[203]=  {8'hff,8'hff,8'hff}  ;	
assign  data_find[204]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[205]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[206]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[207]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[208]=  {8'hff,8'hff,8'hff}  ;//2
assign  data_find[209]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[210]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[211]=  {8'hff,8'hff,8'hff}  ;	
assign  data_find[212]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[213]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[214]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[215]=  {8'hff,8'hff,8'hff}  ;	
assign  data_find[216]=  {8'hff,8'hff,8'hff}  ;//3
assign  data_find[217]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[218]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[219]=  {8'h00,8'h00,8'h00}  ;	
assign  data_find[220]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[221]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[222]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[223]=  {8'hff,8'hff,8'hff}  ;
assign  data_find[224]=  {8'hff,8'hff,8'hff}  ;//4
assign  data_find[225]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[226]=  {8'h00,8'h00,8'h00}  ;
assign  data_find[227]=  {8'h00,8'h00,8'h00}  ;	
assign  data_find[228] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[229] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[230] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[231] =  {8'hff,8'hff,8'hff}  ;	
assign  data_find[232] =  {8'hff,8'hff,8'hff}  ;//5
assign  data_find[233] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[234] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[235] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[236] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[237] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[238] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[239] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[240] =  {8'hff,8'hff,8'hff}  ;//6
assign  data_find[241] =  {8'hff,8'hff,8'hff}  ;
assign  data_find[242] =  {8'hff,8'hff,8'hff}  ;
assign  data_find[243] =  {8'hff,8'hff,8'hff}  ;	
assign  data_find[244] =  {8'hff,8'hff,8'hff}  ;
assign  data_find[245] =  {8'hff,8'hff,8'hff}  ;
assign  data_find[246] =  {8'hff,8'hff,8'hff}  ;
assign  data_find[247] =  {8'hff,8'hff,8'hff}  ;	
assign  data_find[248] =  {8'h00,8'h00,8'h00}  ;//7
assign  data_find[249] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[250] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[251] =  {8'h00,8'h00,8'h00}  ;	
assign  data_find[252] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[253] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[254] =  {8'h00,8'h00,8'h00}  ;
assign  data_find[255] =  {8'h00,8'h00,8'h00}  ;
endmodule
