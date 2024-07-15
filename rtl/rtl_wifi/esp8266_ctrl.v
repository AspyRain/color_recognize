/* 反斜杠\的作用是转义下一个字符，使得原本具有特殊含义的字符（如引号 "）成为普通字符。
在这里，反斜杠用于转义双引号，使其成为字符串中的普通字符，而不是表示字符串的开始或结束。
这样做可以确保 "FPGA" 和 "12345678" 作为完整的字符串参数被包含在整个指令字符串中，确保命令的正确格式 */
module esp8266_ctrl
#(                                                       //模块参数化
    parameter   CLK_RFE     = 'd50_000_000                                          ,//
                BAUD_RATE   = 'd115200                                              ,//
                INSTR_0     = "+++"                                                 ,//退出透传模式指令
                INSTR_1     = "AT+SAVETRANSLINK=0"                                  ,//设置上电不进入透传(取消开机透传)
                INSTR_2     = "AT+RST"                                              ,//重启模块
                INSTR_3     = "AT+CWMODE=1"                                         ,//设置模块模式为Station模式，AT
                INSTR_4     = "AT+CWJAP=\"FPGA\",\"12345678\""                      ,//连接wifi，wifi名，wifi密码
                INSTR_5     = "AT+CIFSR"                                            ,//查询模块ip
                INSTR_6     = "AT+CIPSTART=\"TCP\",\"172.16.203.207\",8888"         ,//连接TCP服务器，IP地址，端口号
                INSTR_7     = "AT+CIPMODE=1"                                        ,//打开透传模式
                INSTR_8     = "AT+CIPSEND"                                          ,//开始透传
                ACK_OK      = "OK"                                                  ,//响应的OK数据
                ACK_ADD     = "++"                                                  ,//退出透传模式标志
                ACK_END     = 16'h0d0a                                              ,//回车+换行 
                TIME_1S     = 28'd50_000_000                                                                                      
)
(       
    input                   clk             ,
    input                   rst_n           ,
    input    [7:0]          pi_data         ,//接收由wifi模块相应的数据
    input                   pi_vld          ,//有效信号
    output   [7:0]          po_data         ,//发送给wifi模块指令数据
    output                  po_vld          ,//  
    output     reg          done             //所有指令数据发送完成信号     
);

//参数定义
// parameter   TIME_1S = 28'd50_000_000; //采用参数化时，除了端口上定义的参数（即模块的接口参数，也称为端口参数或参数端口）
                                         //其他使用 parameter 关键字定义的常量都是局部参数定义
parameter   TIME_BYTE_MAX = CLK_RFE / BAUD_RATE * 10; //一帧数据10bit，一个字节所需要的时间

localparam  IDLE        = 2'd0,
            SEND_INSTR  = 2'd1,
            ACK         = 2'd2;

//内部信号
reg   [1:0]     state_c,state_n;
wire            idle2send   ;
wire            send2ack    ;
wire            ack2idle    ;

reg	[27:0]	        cnt_1s;
wire				add_cnt_1s;
wire				end_cnt_1s;

reg	[15:0]	        cnt_wait;//一帧数据传输所需要的时间
wire				add_cnt_wait;
wire				end_cnt_wait;

reg	[7:0]	        cnt_byte;
wire				add_cnt_byte;
wire				end_cnt_byte;

reg     [7:0]       instr_num   ;//指令字符个数寄存器
reg     [399:0]     instr_data  ;//指令数据寄存
wire    [7:0]       instr_data_reg [49:0]   ;
reg                 ack_en      ;//响应数据有效信号
reg                 ack_end     ;//响应数据结束信号（接收完回车换行结束）
reg                 ack_end_r   ;
wire                ack_podge   ;

reg  [3:0]          cnt_instr;//计数发送第几条指令
wire                add_cnt_instr;
wire                end_cnt_instr;

reg     [15:0]      data_ack;//接收应答数据

//内部逻辑
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        state_c <= IDLE;
    end
    else begin
        state_c <= state_n;
    end
end

always @(*)begin
    case (state_c)
        IDLE       : begin
            if(idle2send)
                state_n = SEND_INSTR;
            else 
                state_n = state_c; 
        end
        SEND_INSTR : begin
            if(send2ack)
                state_n = ACK;
            else 
                state_n = state_c; 
        end
        ACK        : begin
            if(ack2idle)
                state_n = IDLE;
            else 
                state_n = state_c; 
        end
        default: ;
    endcase
end

assign idle2send = (state_c == IDLE       ) && (end_cnt_1s);   
assign send2ack  = (state_c == SEND_INSTR ) && (end_cnt_byte);
assign ack2idle  = (state_c == ACK        ) && (ack_podge);

//
always @(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      cnt_1s <= 0;
   end
   else if(add_cnt_1s)begin
       if(end_cnt_1s)begin
           cnt_1s <= 0;
       end
       else begin
           cnt_1s <= cnt_1s + 1;
       end
   end
end
               
assign add_cnt_1s = (state_c == IDLE && done == 0);
assign end_cnt_1s = add_cnt_1s && (cnt_1s == TIME_1S - 1); 

//一帧数据传输的时间
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_wait <= 0;
    end
    else if(state_c == IDLE)begin
        cnt_wait <= 1'b0;
    end
    else if(add_cnt_wait)begin
        if(end_cnt_wait)begin
            cnt_wait <= 0;
        end
        else begin
            cnt_wait <= cnt_wait + 1;
        end
    end
end
              
assign add_cnt_wait = (state_c == SEND_INSTR) || (state_c == ACK);
assign end_cnt_wait = add_cnt_wait && (cnt_wait == TIME_BYTE_MAX - 1); 

//一条指令有多少帧数据
always @(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      cnt_byte <= 0;
   end
   else if(add_cnt_byte)begin
       if(end_cnt_byte)begin
           cnt_byte <= 0;
       end
       else begin
           cnt_byte <= cnt_byte + 1;
       end
   end
end
               
assign add_cnt_byte = state_c == SEND_INSTR && end_cnt_wait;
assign end_cnt_byte = add_cnt_byte && (cnt_byte == instr_num - 1);//一条指令发送完成
//计数发送第几条指令
always @(posedge clk or negedge rst_n)begin
   if(!rst_n)begin
      cnt_instr <= 0;
   end
   else if(add_cnt_instr)begin
       if(end_cnt_instr)begin
           cnt_instr <= 0;
       end
       else begin
           cnt_instr <= cnt_instr + 1;
       end
   end
end
               
assign add_cnt_instr = ack2idle;
assign end_cnt_instr = add_cnt_instr && (cnt_instr == 9 - 1); 

//
always @(*)begin
    case (cnt_instr)
        8'd0: begin 
                instr_data = {INSTR_0};
                instr_num = 3;
            end
        8'd1: begin 
                instr_data = {INSTR_1,8'h0d,8'h0a};
                instr_num = 20;
            end
        8'd2: begin 
                instr_data = {INSTR_2,8'h0d,8'h0a};
                instr_num = 8;
            end
        8'd3: begin 
                instr_data = {INSTR_3,8'h0d,8'h0a};
                instr_num = 13;
            end
        8'd4: begin 
                instr_data = {INSTR_4,8'h0d,8'h0a};
                instr_num = 28;
            end
        8'd5: begin 
                instr_data = {INSTR_5,8'h0d,8'h0a};
                instr_num = 10;
            end
        8'd6: begin 
                instr_data = {INSTR_6,8'h0d,8'h0a};
                instr_num = 41;
            end
        8'd7: begin 
                instr_data = {INSTR_7,8'h0d,8'h0a};
                instr_num = 14;
            end
        8'd8: begin 
                instr_data = {INSTR_8,8'h0d,8'h0a};
                instr_num = 12;
            end 
        default: ;
    endcase
end

//
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        data_ack <= 16'd0;
    end
    else if((state_c == ACK) && (TIME_BYTE_MAX >> 1))begin
        data_ack <= {data_ack[7:0],pi_data};
    end
end

//
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ack_en <= 1'b0;
    end
    else if(data_ack == ACK_OK)begin
        ack_en <= 1'b1;
    end
    else if(cnt_1s == 1)begin
        ack_en <= 1'b0;
    end
end

always @(*)begin
    if(!rst_n)begin
        ack_end <= 1'b0;
    end
    else if((cnt_instr == 0 && state_c == ACK) 
         || (cnt_instr > 0  && cnt_instr < 8 && ack_en && data_ack == ACK_END)
         || (cnt_instr == 8 && ack_en && data_ack == 16'h0a3e))
        begin
        ack_end <= 1'b1;
    end
    else begin
        ack_end <= 1'b0;
    end
end

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        ack_end_r <= 1'b0;
    end
    else begin
        ack_end_r <= ack_end;
    end
end

assign ack_podge = ack_end & ~ack_end_r;//检测到应答信号有效的上升沿信号

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        done <= 1'b0;
    end
    else if(cnt_instr == 8 && ack_podge)begin
        done <= 1'b1;
    end
end

// always @(*)begin
//     case (state_c)
//         IDLE       : po_data = 8'h0;
//         SEND_INSTR : po_data = instr_data_reg[instr_num - cnt_byte - 1'b1];
//         ACK        : po_data = 8'h0;
//         default: ;
//     endcase
// end
assign po_data = (state_c == SEND_INSTR) ? instr_data_reg[instr_num - cnt_byte - 1'b1] : 8'h0;
assign po_vld  = (state_c == SEND_INSTR && cnt_wait == 16'd1) ? 1'd1 : 1'b0;

assign instr_data_reg[00] = instr_data[007 -: 8];
assign instr_data_reg[01] = instr_data[015 -: 8];
assign instr_data_reg[02] = instr_data[023 -: 8];
assign instr_data_reg[03] = instr_data[031 -: 8];
assign instr_data_reg[04] = instr_data[039 -: 8];
assign instr_data_reg[05] = instr_data[047 -: 8];
assign instr_data_reg[06] = instr_data[055 -: 8];
assign instr_data_reg[07] = instr_data[063 -: 8];
assign instr_data_reg[08] = instr_data[071 -: 8];
assign instr_data_reg[09] = instr_data[079 -: 8];
assign instr_data_reg[10] = instr_data[087 -: 8];
assign instr_data_reg[11] = instr_data[095 -: 8];
assign instr_data_reg[12] = instr_data[103 -: 8];
assign instr_data_reg[13] = instr_data[111 -: 8];
assign instr_data_reg[14] = instr_data[119 -: 8];
assign instr_data_reg[15] = instr_data[127 -: 8];
assign instr_data_reg[16] = instr_data[135 -: 8];
assign instr_data_reg[17] = instr_data[143 -: 8];
assign instr_data_reg[18] = instr_data[151 -: 8];
assign instr_data_reg[19] = instr_data[159 -: 8];
assign instr_data_reg[20] = instr_data[167 -: 8];
assign instr_data_reg[21] = instr_data[175 -: 8];
assign instr_data_reg[22] = instr_data[183 -: 8];
assign instr_data_reg[23] = instr_data[191 -: 8];
assign instr_data_reg[24] = instr_data[199 -: 8];
assign instr_data_reg[25] = instr_data[207 -: 8];
assign instr_data_reg[26] = instr_data[215 -: 8];
assign instr_data_reg[27] = instr_data[223 -: 8];
assign instr_data_reg[28] = instr_data[231 -: 8];
assign instr_data_reg[29] = instr_data[239 -: 8];
assign instr_data_reg[30] = instr_data[247 -: 8];
assign instr_data_reg[31] = instr_data[255 -: 8];
assign instr_data_reg[32] = instr_data[263 -: 8];
assign instr_data_reg[33] = instr_data[271 -: 8];
assign instr_data_reg[34] = instr_data[279 -: 8];
assign instr_data_reg[35] = instr_data[287 -: 8];
assign instr_data_reg[36] = instr_data[295 -: 8];
assign instr_data_reg[37] = instr_data[303 -: 8];
assign instr_data_reg[38] = instr_data[311 -: 8];
assign instr_data_reg[39] = instr_data[319 -: 8];
assign instr_data_reg[40] = instr_data[327 -: 8];
assign instr_data_reg[41] = instr_data[335 -: 8];
assign instr_data_reg[42] = instr_data[343 -: 8];
assign instr_data_reg[43] = instr_data[351 -: 8];
assign instr_data_reg[44] = instr_data[359 -: 8];
assign instr_data_reg[45] = instr_data[367 -: 8];
assign instr_data_reg[46] = instr_data[375 -: 8];
assign instr_data_reg[47] = instr_data[383 -: 8];
assign instr_data_reg[48] = instr_data[391 -: 8];
assign instr_data_reg[49] = instr_data[399 -: 8];




endmodule