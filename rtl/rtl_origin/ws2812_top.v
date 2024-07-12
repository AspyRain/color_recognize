module  ws2812_top
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	wire			r_valid		,
	input	wire			g_valid		,
	input	wire			b_valid		,
	
	output	wire			led_data
);

wire			cfg_start	;
wire			ws2812_start;
wire	[5:0]	cfg_num		;
wire	[23:0]	cfg_data	;

ws2812_cfg_ctrl  ws2812_cfg_ctrl_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.cfg_start		(cfg_start		),
	.r_valid		(r_valid		),
	.g_valid		(g_valid		),
	.b_valid		(b_valid		),
	.ws2812_start	(ws2812_start	),
	.cfg_num		(cfg_num		),
	.cfg_data       (cfg_data       )
);

ws2812_ctrl  ws2812_ctrl_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.ws2812_start	(ws2812_start	),
	.cfg_data		(cfg_data		),
	.cfg_num		(cfg_num		),
	.cfg_start		(cfg_start		),
	.led_data	    (led_data	    )
);

endmodule
