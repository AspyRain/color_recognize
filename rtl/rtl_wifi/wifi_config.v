module  wifi_config
(
	input	wire			sys_clk		,	//系统时钟，频率为50MHZ
	input	wire			sys_rst_n	,	//系统复位，低电平有效
	input	wire			tx_device	,	//esp8266数据发送引脚
	
	output	wire			rx_device	,	//esp8266数据接收引脚
	output	wire			test_rx		,	//FPGA接收到的数据测试，连接TTL_1—TX端口
	output	wire			test_tx			//FPGA发送的数据测试，连接TTL_2-TX端口
);

parameter	CLK_FRE		=	'd50_000_000									,	//时钟频率
			BAUD_RATE	=	'd115200										,	//串口通信波特率
			INSTR_0		=	"+++"											,	//退出透传模式指令
			INSTR_1		=	"AT+SAVETRANSLINK=0"							,	//设置上电不进入透传
			INSTR_2		=	"AT+CWMODE=1"									,	//设置wifi模式
			INSTR_3		=	"AT+RST"										,	//重启生效
			INSTR_4		=	"AT+CWJAP=\"AspyRain\",\"Lxr20030106\""				,	//连接wifi，wifi名称“FPGA”，密码“00000001”
			INSTR_5		=	"AT+CIFSR"										,	//查询模块IP
			INSTR_6		=	"AT+CIPSTART=\"TCP\",\"192.168.233.191\",8080"	,	//连接TCP服务器，IP地址192.168.135.107，端口号8888
			INSTR_7		=	"AT+CIPMODE=1"									,	//开始透传模式
			INSTR_8		=	"AT+CIPSEND"									,	//开始透传
			INSTR_9     = "GET http://192.168.233.191:8080/weather/getTemp"	,
			ACK_OK		=	"OK"											,	//响应的OK数据	
			ACK_ADD		=	"++"											,	//退出透传模式标志
			ACK_END		=	16'h0d0a										;	//响应_回车+换行

wire	[7:0]	ack_data	;	//esp8266响应的数据
wire			ack_flag	;	//与响应数据同步的标志信号
wire	[7:0]	cmd_data	;	//FPGA生成的指令数据
wire			cmd_flag	;	//与指令数据同步的标志信号
wire			cfg_done	;	//配置完成信号



esp8266_ctrl
#(
	.BAUD_RATE	(BAUD_RATE	),
	.INSTR_0	(INSTR_0	),
	.INSTR_1	(INSTR_1	),
	.INSTR_2	(INSTR_2	),
	.INSTR_3	(INSTR_3	),
	.INSTR_4	(INSTR_4	),
	.INSTR_5	(INSTR_5	),
	.INSTR_6	(INSTR_6	),
	.INSTR_7	(INSTR_7	),
	.INSTR_8	(INSTR_8	),
	.ACK_OK		(ACK_OK		),
	.ACK_ADD	(ACK_ADD	),
	.ACK_END	(ACK_END	)
)
esp8266_ctrl
(
	.sys_clk		(sys_clk	),	
	.sys_rst_n		(sys_rst_n	),	
	.pi_data		(ack_data	),	
	.pi_flag		(ack_flag	),	
	.po_data		(cmd_data	),	
	.po_flag		(cmd_flag	),	
	.cfg_done	    (cfg_done	)
);

uart_tx
#(
	.CLK_FRE	(CLK_FRE	),
	.BAUD_RATE	(BAUD_RATE	)
)
uart_tx_inst
(
	.sys_clk	(sys_clk	),	
	.sys_rst_n	(sys_rst_n	),	
	.pi_data	(cmd_data	),	
	.pi_flag	(cmd_flag	),	
	.tx			(rx_device	)
);

uart_rx
#(
	.CLK_FRE	(CLK_FRE	),
	.BAUD_RATE	(BAUD_RATE	)
)
uart_rx_inst
(
	.sys_clk	(sys_clk	),	
	.sys_rst_n	(sys_rst_n	),	
	.rx			(tx_device	),	
	.po_data	(ack_data	),	
	.po_flag	(ack_flag	)	
);


endmodule