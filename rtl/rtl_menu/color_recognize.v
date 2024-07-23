module  color_recognize
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	wire	[4:0]	key_in		,
	input			[2:0]	switch		,
	input					tx_device	,


	output	wire			scl			,
	output	wire			led_data	,
	output					pwm			,
	output					rx_device	,
	output 		  [5:0]   	sel         ,//片选
	output 		  [7:0]   	dig         ,//段选
	
	inout	wire			sda	
);

wire	[7:0]	data_r;
wire	[7:0]	data_g;
wire	[7:0]	data_b;
wire	[7:0]	temp_data;
wire	[1:0]	similar_flag;
wire	[1:0]	mode;
ws2812_top  ws2812_top_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.key_in			(key_in			),
	.data_r			(data_r			),
	.data_g			(data_g			),
	.data_b			(data_b			),
	.switch			(switch			),
	.pwm			(pwm			),
	.similar_flag 	(similar_flag	),
	.mode		  	(mode			),
	.led_data   	(led_data    	)
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

wifi_config	wifi_config_temp(
	.sys_clk		(sys_clk	),
	.sys_rst_n		(sys_rst_n	),
	.tx_device		(tx_device	),

	.temp_data		(temp_data	),
	.rx_device		(rx_device	)
);
sel_driver sel_driver_inst(
	.clk   			(sys_clk		),
	.rst_n 			(sys_rst_n		),
	.mode			(mode			),
	.similar_flag	(similar_flag	),
	.din   			(temp_data		),
	.sel   			(sel			),
	.dig   			(dig			)

);
endmodule
