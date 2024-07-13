module  ws2812_top
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	[4:0]			key_in		,
	input	wire	[7:0]	data_r		,
	input	wire	[7:0]	data_g		,
	input	wire	[7:0]	data_b		,
	output	wire			led_data
);

wire			cfg_start	;
wire			ws2812_start;
wire	[5:0]	cfg_num		;
wire	[23:0]	cfg_data	;

wire			ws2812_start_draw;
wire	[5:0]	cfg_num_draw		;
wire	[23:0]	cfg_data_draw	;

wire			ws2812_start_select;
wire	[5:0]	cfg_num_select		;
wire	[23:0]	cfg_data_select	;

wire	[4:0]		key_out		;
wire	[1:0]	mode		;

reg	[4:0]	key_draw;
reg	[4:0]	key_menu;
wire            c_ok        ;

ws2812_select  ws2812_cfg_ctrl_select_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.cfg_start		(cfg_start		),
	.ws2812_start	(ws2812_start_select	),
 	.key            (key_menu        ),
 	.data_r			(data_r			),
	.data_g			(data_g			),
	.data_b			(data_b			),
	.mode			(mode			),
	.cfg_num		(cfg_num_select		),
	.cfg_data       (cfg_data_select       )
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

counter         counter_inst(
    .clk        (sys_clk    ),
    .rst_n      (sys_rst_n  ),
    .c_ok       (c_ok       )
);

ws2812_draw  ws2812_cfg_ctrl_draw_inst
(
	.sys_clk		(sys_clk		),
	.sys_rst_n		(sys_rst_n		),
	.cfg_start		(cfg_start		),
	.ws2812_start	(ws2812_start_draw	),
 	.data_r			(data_r			),
	.data_g			(data_g			),
	.data_b			(data_b			),
 	.key            (key_draw        ),
 	.c_ok           (c_ok           ),
	.cfg_num		(cfg_num_draw		),
	.cfg_data       (cfg_data_draw       )
);

FSM_KEY         FSM_KEY_inst(
    .clk        (sys_clk    ),
    .rst_n      (sys_rst_n  ),
    .key_in     (key_in     ),
    .key_out    (key_out    )
);

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		key_draw <= 5'b0;
		key_menu <= 5'b0;
	end
	else begin
		case (mode)
			2'b00:begin
				key_menu <= key_out; 
				key_draw <= 5'b0;
			end
			2'b10:begin
				key_draw <= key_out; 
				key_menu <= 5'b0;
			end

			default: begin
				key_draw <= 5'b0;
				key_menu <= 5'b0;
			end
		endcase
	end
end

assign cfg_num = (mode == 2'b00)?cfg_num_select:(mode == 2'b10)?cfg_num_draw:6'b0;
assign cfg_data = (mode == 2'b00)?cfg_data_select:(mode == 2'b10)?cfg_data_draw:24'b0;
assign ws2812_start = (mode == 2'b00)?ws2812_start_select:(mode == 2'b10)?ws2812_start_draw:1'b0;



endmodule
