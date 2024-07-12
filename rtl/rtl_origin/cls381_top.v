module  cls381_top
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	
	output	wire			scl			,
	output	reg				r_valid		,
	output	reg				g_valid		,
	output	reg				b_valid		,
	
	inout	wire			sda
);

wire			i2c_start	;
wire	[3:0]	cfg_num		;
wire	[15:0]	cfg_data	;
wire			i2c_clk		;
wire			cfg_start	;
wire	[23:0]	data_r		;
wire	[23:0]	data_g		;
wire	[23:0]	data_b		;

always@(posedge i2c_clk or negedge sys_rst_n)
	if(sys_rst_n == 1'b0)
		begin
			r_valid  <=  1'b0  ;
			g_valid  <=  1'b0  ;
			b_valid  <=  1'b0  ;
		end
	else  if(data_r > data_g + data_b)
		begin
			r_valid  <=  1'b1  ;
			g_valid  <=  1'b0  ;
			b_valid  <=  1'b0  ;
		end
	else  if(data_g > data_r + data_b)
		begin
			r_valid  <=  1'b0  ;
			g_valid  <=  1'b1  ;
			b_valid  <=  1'b0  ;
		end
	else  if(data_b > data_r + data_g)
		begin
			r_valid  <=  1'b0  ;
			g_valid  <=  1'b0  ;
			b_valid  <=  1'b1  ;
		end
	else
		begin
			r_valid  <=  1'b0  ;
			g_valid  <=  1'b0  ;
			b_valid  <=  1'b0  ;		
		end

i2c_ctrl  i2c_ctrl_inst
(
	.sys_clk	(sys_clk	),
	.sys_rst_n	(sys_rst_n	),
	.i2c_start	(i2c_start	),
	.cfg_num	(cfg_num	),
	.cfg_data	(cfg_data	),
	.scl		(scl		),
	.i2c_clk	(i2c_clk	),
	.cfg_start	(cfg_start	),
	.data_r		(data_r		),
	.data_g		(data_g		),
	.data_b		(data_b		),
	.sda        (sda        )
);

cls381_cfg_ctrl  cls381_cfg_ctrl_inst
(
	.i2c_clk	(i2c_clk	),
	.sys_rst_n	(sys_rst_n	),
	.cfg_start	(cfg_start	),
	.cfg_data	(cfg_data	),
	.cfg_num	(cfg_num	),
	.i2c_start	(i2c_start	)
);

endmodule
