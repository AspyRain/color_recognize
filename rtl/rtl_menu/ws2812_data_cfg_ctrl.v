module  ws2812_data_cfg_ctrl
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

	output  	    [7:0] 	set_r ,
	output		    [7:0] 	set_g ,
	output			[7:0] 	set_b
);

localparam	CNT_WAIT_MAX  =  20'd1_000_000  ;	//上电等待20ms，自行设定
reg		[5:0]	now_index;
reg     [1:0]   mode_c;//模式选择
reg     [1:0]   mode_n;//模式选择

reg	[23:0]	data_show[63:0]			;
reg	[23:0]	data_background[63:0]	;
wire    [23:0]  data_find [63:0]    ;
wire	[23:0]	data_S[63:0]			;
wire	[23:0]	data_D[63:0]            ;			//图片数据
reg	[63:0]	is_correct				;

reg		[19:0]	cnt_wait  				;			//上电等待计数器，等待20ms后一直保持最大值
reg				start_en  				;			//上电等待结束开始工作信号
reg				flash_en				;
wire			select_en			;
           
//光标坐标控制
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		now_index <= 6'b0;
	end
	else begin
        if (mode_c != 2'b0) begin
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
        else begin
            now_index <= 6'b0;
        end
	end
end

//模式选择

//模式坐标控制
always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		mode_n <= 2'b0;
	end
	else begin
        if (mode_c == 2'b0)begin
            case (key[4:2])
			3'b001:begin
				mode_n <= 2'b1;
			end
			3'b010:begin
				mode_n <= 2'b10;
			end
			default:
				mode_n <= mode_n;
		endcase
        end
        else begin
            mode_n <= mode_n;
        end
	end
end


always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		mode_c <= 2'b0;
	end
	else begin
		if (key[4]==1'b1 && mode_c == 2'b0)begin
			mode_c <= mode_n;
		end
		else begin
			mode_c <= mode_c;
		end
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

//显示选择器
always @(*) begin : data_gen
            //灯阵显示
            data_show[cfg_num] =
                (mode_c == 2'b0) ? //处于菜单模块
                    (mode_n == 2'b0) ? 24'h0: (mode_n == 2'b1) ? data_S[cfg_num] : (mode_n == 2'b10) ? data_D[cfg_num] : 24'h0
                : // 否则(即为颜色配对模块和识色绘图模块)
                    (cfg_num == now_index && flash_en == 1'b1) ? {data_g,data_r,data_b}: data_background[cfg_num];
            //灯阵数据配置
            data_background[cfg_num] = 
                (mode_c == 2'b0 || sys_rst_n==1'b0) ? //复位或者处于菜单界面
                    {8'h00,8'h00,8'h00} //情况数据缓存
                :(mode_c == 2'b01) ? //处于颜色配对模块
                    (flash_en == 1'b0 || is_correct[cfg_num]) ? // 配对成功
                        data_find[cfg_num] 
                    : //否则
                        {8'h00,8'h00,8'h00} //清空
                :(mode_c == 2'b10) ? //处于识色绘图模块
                    (key[4]==1'b1) ?  
                        data_show[cfg_num]
                        : //否则
                        data_background[cfg_num]
                    : //否则
                        {8'h00,8'h00,8'h00};

            //颜色匹配模块中判断是颜色是否匹配成功
            is_correct[cfg_num] =  (sys_rst_n == 1'b0)?1'b0:( cfg_num == now_index ? ((similar_flag == 2'b01) ? 1'b1:(similar_flag == 2'b10)?is_correct[cfg_num]:1'b0) : is_correct[cfg_num]);
    end
// genvar k;
// generate
//     for (k = 0; k < 64; k = k + 1) begin : data_gen
//             //灯阵显示
//             assign data_show[cfg_num] =
//                 (mode_c == 2'b0) ? //处于菜单模块
//                     (mode_n == 2'b0) ? 24'h0: (mode_n == 2'b1) ? data_S[cfg_num] : (mode_n == 2'b10) ? data_D[cfg_num] : 24'h0
//                 : // 否则(即为颜色配对模块和识色绘图模块)
//                     (cfg_num == now_index && flash_en == 1'b1) ? {data_g,data_r,data_b}: data_background[cfg_num];
//             //灯阵数据配置
//             assign data_background[cfg_num] = 
//                 (mode_c == 2'b0 || sys_rst_n==1'b0) ? //复位或者处于菜单界面
//                     {8'h00,8'h00,8'h00} //情况数据缓存
//                 :(mode_c == 2'b01) ? //处于颜色配对模块
//                     (flash_en == 1'b0 || is_correct[cfg_num]) ? // 配对成功
//                         data_find[cfg_num] 
//                     : //否则
//                         {8'h00,8'h00,8'h00} //清空
//                 :(mode_c == 2'b10) ? //处于识色绘图模块
//                     (key[4]==1'b1) ?  
//                         data_show[cfg_num]
//                         : //否则
//                         data_background[cfg_num]
//                     : //否则
//                         {8'h00,8'h00,8'h00};

//             //颜色匹配模块中判断是颜色是否匹配成功
//             assign is_correct[cfg_num] =  
//             (sys_rst_n == 1'b0 || mode_c == 2'b0) ? 
//                     1'b0
//                 :(mode_c == 2'b01) ? //处于颜色匹配模块?  
//                     (cfg_num == now_index) ? 
//                         (similar_flag == 2'b01) ? 
//                             1'b1
//                             :(similar_flag == 2'b10) ? 
//                                     is_correct[cfg_num]
//                                 :
//                                     1'b0
//                         :   
//                             is_correct[cfg_num]     
//                     : 
//                         is_correct[cfg_num];
//     end
// endgenerate

			assign set_g = (key[4] == 1 && mode_c == 2'b01)   ? data_find[now_index][23:16] 	: {8'h00};
			assign set_r = (key[4] == 1 && mode_c == 2'b01)   ? data_find[now_index][15:8] 	: {8'h00};
			assign set_b = (key[4] == 1 && mode_c == 2'b01)   ? data_find[now_index][7:0] 	: {8'h00};


assign cfg_data  =  {(data_show[cfg_num][23:16] >> 3),(data_show[cfg_num][15:8] >> 3),(data_show[cfg_num][7:0] >> 3)}  ;


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



endmodule