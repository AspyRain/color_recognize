module  ws2812_top
(
	input	wire			sys_clk		,
	input	wire			sys_rst_n	,
	input	[4:0]			key_in		,
	input   [2:0]   		switch  	,
	input	wire	[7:0]	data_r		,
	input	wire	[7:0]	data_g		,
	input	wire	[7:0]	data_b		,
	output	wire			led_data	,
	output					pwm			
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

wire			ws2812_start_find;
wire	[5:0]	cfg_num_find		;
wire	[23:0]	cfg_data_find	;
wire	[7:0]	set_r		;
wire	[7:0]	set_g		;
wire	[7:0]	set_b		;

wire	[4:0]	key_out		;
wire	[1:0]	mode		;

reg		[4:0]	key_draw;
reg		[4:0]	key_menu;
reg		[4:0]	key_find;
wire            c_ok        ;
wire			pwm_bgm		;
wire			pwm_jingle	;

    wire    [8:0]   hsv_get_h;
    wire    [8:0]   hsv_get_s;
    wire    [8:0]   hsv_get_v;

    wire    [8:0]   hsv_set_h;
    wire    [8:0]   hsv_set_s;
    wire    [8:0]   hsv_set_v;

    wire    [1:0]       similar_flag;

ws2812_select  ws2812_cfg_ctrl_select_inst
(
	.sys_clk		(sys_clk		)			,
	.sys_rst_n		(sys_rst_n		)			,
	.cfg_start		(cfg_start		)			,
	.ws2812_start	(ws2812_start_select	)	,
 	.key            (key_menu        )			,
 	.data_r			(data_r			)			,
	.data_g			(data_g			)			,
	.data_b			(data_b			)			,
	.mode			(mode			)			,
	.cfg_num		(cfg_num_select		)		,
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

ws2812_find  ws2812_cfg_ctrl_find_inst
(
	.sys_clk		(sys_clk			),
	.sys_rst_n		(sys_rst_n			),
	.cfg_start		(cfg_start			),
	.ws2812_start	(ws2812_start_find	),
 	.data_r			(data_r				),
	.data_g			(data_g				),
	.data_b			(data_b				),
	.set_r			(set_r				),
	.set_g			(set_g				),
	.set_b			(set_b				),
 	.key            (key_find       	),
	.similar_flag	(similar_flag		),
 	.c_ok           (c_ok           	),
	.cfg_num		(cfg_num_find		),
	.cfg_data       (cfg_data_find      )
);

// ws2812_draw  ws2812_cfg_ctrl_draw_inst
// (
// 	.sys_clk		(sys_clk		),
// 	.sys_rst_n		(sys_rst_n		),
// 	.cfg_start		(cfg_start		),
// 	.ws2812_start	(ws2812_start_draw	),
//  	.data_r			(data_r			),
// 	.data_g			(data_g			),
// 	.data_b			(data_b			),
//  	.key            (key_draw        ),
//  	.c_ok           (c_ok           ),
// 	.cfg_num		(cfg_num_draw		),
// 	.cfg_data       (cfg_data_draw       )
// );

FSM_KEY         FSM_KEY_inst(
    .clk        (sys_clk    ),
    .rst_n      (sys_rst_n  ),
    .key_in     (key_in     ),
    .key_out    (key_out    )
);

beep_bgm		beep_bgm_inst(
	.clk		(sys_clk	),
	.rst_n		(sys_rst_n	),
	.flag		(sys_rst_n	),
	.mode_n		(mode		),

	.pwm		(pwm_bgm		)
);

beep_jingles	beep_jingles_inst(
	.clk			(sys_clk		),
	.rst_n			(sys_rst_n		),
	.select_flag	(similar_flag	),
	.key			(key_out		),
	.pwm			(pwm_jingle		)
);

    rgb_hsv                 rgb_hsv_get_inst(
        .clk                (sys_clk        ),
        .rst                (sys_rst_n      ),


        .rgb_r              (data_r     ),
        .rgb_g              (data_g     ),
        .rgb_b              (data_b     ),

        .hsv_h              (hsv_get_h     ),
        .hsv_s              (hsv_get_s     ),
        .hsv_v              (hsv_get_v     )
    );

    rgb_hsv                 rgb_hsv_set_inst(
        .clk                (sys_clk        ),
        .rst                (sys_rst_n      ),


        .rgb_r              (set_r     ),
        .rgb_g              (set_g     ),
        .rgb_b              (set_b     ),

        .hsv_h              (hsv_set_h     ),
        .hsv_s              (hsv_set_s     ),
        .hsv_v              (hsv_set_v     )
    );   

    HSVComparator       HSVComparator_inst(
        .clk                (sys_clk   ),
        .hsv_get_h             (hsv_get_h),
        .hsv_get_s             (hsv_get_s),
        .hsv_get_v             (hsv_get_v),

        .hsv_set_h             (hsv_set_h),
        .hsv_set_s             (hsv_set_s),
        .hsv_set_v             (hsv_set_v),

        .threshold_level    (switch),
        .similar_flag       (similar_flag)
    );

//assign pwm = pwm_jingle;

always @(posedge sys_clk or negedge sys_rst_n) begin
	if (!sys_rst_n)begin
		key_draw <= 5'b0;
		key_menu <= 5'b0;
		key_find <= 5'b0;
	end
	else begin
		case (mode)
			2'b00:begin
				key_menu <= key_out; 
				key_draw <= 5'b0;
				key_find <= 5'b0;
			end
			2'b10:begin
				key_draw <= key_out; 
				key_menu <= 5'b0;
				key_find <= 5'b0;
			end
			2'b01:begin
				key_find <= key_out; 
				key_menu <= 5'b0;
				key_draw <= 5'b0;
			end
			default: begin
				key_draw <= 5'b0;
				key_menu <= 5'b0;
				key_find <= 5'b0;
			end
		endcase
	end
end

assign cfg_num = (mode == 2'b00)?cfg_num_select:(mode == 2'b10)?cfg_num_draw:(mode == 2'b01)?cfg_num_find:6'b0;
assign cfg_data = (mode == 2'b00)?cfg_data_select:(mode == 2'b10)?cfg_data_draw:(mode == 2'b01)?cfg_data_find:24'b0;
assign ws2812_start = (mode == 2'b00)?ws2812_start_select:(mode == 2'b10)?ws2812_start_draw:(mode == 2'b01)?ws2812_start_find:1'b0;



endmodule
