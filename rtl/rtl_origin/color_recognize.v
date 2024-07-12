module  color_recognize
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	
	output	wire			scl			,
	output	wire			led_data	,
	
	inout	wire			sda	
);

wire	r_valid  ;
wire	g_valid  ;
wire	b_valid  ;

ws2812_top  ws2812_top_inst
(
	.sys_clk	(sys_clk	),
	.sys_rst_n	(sys_rst_n	),
	.r_valid	(r_valid	),
	.g_valid	(g_valid	),
	.b_valid	(b_valid	),
	.led_data   (led_data    )
);

cls381_top  cls381_top_inst
(
	.sys_clk	(sys_clk	)	,
	.sys_rst_n	(sys_rst_n	)	,
	.scl		(scl		)	,
	.r_valid	(r_valid	)	,
	.g_valid	(g_valid	)	,
	.b_valid	(b_valid	)	,
	.sda		(sda		)
);

endmodule
