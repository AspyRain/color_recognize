module  draw_top
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
    input   wire   [4:0]    key_in      ,
    input	wire	[7:0]	data_r		,
	input	wire	[7:0]	data_g		,
	input	wire	[7:0]	data_b		,
	output	wire			led_data
);

wire			cfg_start	;
wire    [4:0]   key_out     ;
wire			ws2812_start;
wire	[5:0]	cfg_num		;
wire	[23:0]	cfg_data	;
wire            c_ok        ;
wire   [23:0]   color_out   ;

FSM_KEY         FSM_KEY_inst(
    .clk        (sys_clk    ),
    .rst_n      (sys_rst_n  ),
    .key_in     (key_in     ),
    .key_out    (key_out    )
);

counter         counter_inst(
    .clk        (sys_clk    ),
    .rst_n      (sys_rst_n  ),
    .c_ok       (c_ok       )
);

ws2812_draw  ws2812_cfg_ctrl_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.cfg_start		(cfg_start		),
	.ws2812_start	(ws2812_start	),
 	.data_r			(data_r			),
	.data_g			(data_g			),
	.data_b			(data_b			),
 	.key            (key_out        ),
 	.c_ok           (c_ok           ),
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
