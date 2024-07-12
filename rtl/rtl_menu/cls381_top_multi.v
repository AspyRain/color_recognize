module  cls381_top_multi
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	
	output	wire			scl			,
	output			[7:0]	data_r_out	,
	output			[7:0]	data_g_out	,
	output			[7:0]	data_b_out	,
	
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
assign data_r_out = data_r [15:8] ;
assign data_g_out = data_g [15:8] ;
assign data_b_out = data_b [15:8] ;
endmodule
