module  color_recognize
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	wire	[4:0]	key_in		,
	output	wire			scl			,
	output	wire			led_data	,
	
	inout	wire			sda	
);

wire	r_valid  ;
wire	g_valid  ;
wire	b_valid  ;
wire	[7:0]	data_r;
wire	[7:0]	data_g;
wire	[7:0]	data_b;

draw_top  ws2812_top_inst
(
	.sys_clk	(sys_clk	),
	.sys_rst_n	(sys_rst_n	),
	.key_in		(key_in		),
	.data_r		(data_r	)	,
	.data_g		(data_g	)	,
	.data_b		(data_b	)	,
	.led_data   (led_data    )
);

cls381_top_multi  cls381_top_inst
(
	.sys_clk	(sys_clk	)	,
	.sys_rst_n	(sys_rst_n	)	,
	.scl		(scl		)	,
	.data_r_out		(data_r	)	,
	.data_g_out		(data_g	)	,
	.data_b_out		(data_b	)	,
	.sda			(sda		)
);
endmodule
