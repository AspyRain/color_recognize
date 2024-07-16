module  ws2812_draw
(
	input	wire			sys_clk			,
	input	wire			sys_rst_n		,
	input	wire			cfg_start		,	//配置模块开始工作指示的单脉冲信号，由控制模块产生
	input	wire	[7:0]	data_r			,	//红色分量
	input	wire	[7:0]	data_g			,	//绿色分量
	input	wire	[7:0]	data_b			,	//蓝色分量
	input	wire			c_ok			,
	input	wire	[4:0]	key				,	//五个功能按键
	output	reg				ws2812_start	,	//控制模块开始工作指示的单脉冲信号，由配置模块产生
	output	reg		[5:0]	cfg_num			,	//配置的8x8点阵个数，最大值64-1
	output			[23:0]	cfg_data			//待显示的颜色数据
);

localparam	CNT_WAIT_MAX  =  20'd1_000_000  ;	//上电等待20ms，自行设定
reg		[5:0]	now_index;
wire	[23:0]	data_draw[63:0]			;
wire	[23:0]	data_background[63:0]	;
reg		[19:0]	cnt_wait  				;			//上电等待计数器，等待20ms后一直保持最大值
reg				start_en  				;			//上电等待结束开始工作信号
reg				flash_en				;
reg				select_en				;
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




assign cfg_data  =  {(data_draw[cfg_num][23:16] >> 3),(data_draw[cfg_num][15:8] >> 3),(data_draw[cfg_num][7:0] >> 3)}  ;
genvar k;
genvar j;
parameter len = 4'd4;
generate
    for (k = 0; k < 64; k = k + 1) begin : data_gen
            assign data_draw[k] =(k == now_index && flash_en == 1'b1) ? {data_g,data_r,data_b}: data_background[k];
			assign data_background[k] = (sys_rst_n==1'b0)?{8'h00,8'h00,8'h00}:((key[4]==1'b1)?data_draw[k]:data_background[k]);
    end
endgenerate


endmodule
