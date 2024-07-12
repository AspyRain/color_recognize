module driver (
    input           clk         ,
    input           rst_n       ,
    output          scl         ,
    inout           sda         
);
    
//参数定义
parameter   WAIT        = 4'd0,
            IDLE        = 4'd1,
            START       = 4'd2,
            SLAVE_ADDR  = 4'd3,
            ACK_1       = 4'd4,
            REG_ADDR    = 4'd5,
            ACK_2       = 4'd6,
            DATA        = 4'd7,
            ACK_3       = 4'd8,
            STOP        = 4'd9;  
parameter   TIME_20MS = 20'd1_000_000,
            TIME_SCL = 200;//同步时钟周期计数器最大值，250KHz

//内部信号
reg    [3:0]    state_c,state_n;//现态，次态
wire            wait2idle   ;//状态跳转条件
wire            idle2start  ; 
wire            start2slave ;
wire            slave2ack1  ;
wire            ack1_2_reg  ;
wire            reg2ack2    ;
wire            ack2_2_data ;
wire            data2ack3   ;
wire            ack3_2_stop ;
wire            stop2idle   ;

reg     [19:0]  cnt_20ms;//上电等待20ms
wire            add_cnt_20ms;
wire            end_cnt_20ms;

reg     [7:0]   cnt_scl;//描述同步时钟计数器
wire            add_cnt_scl;
wire            end_cnt_scl;
reg             scl_r   ;

reg     [3:0]   cnt_bit;
wire            add_cnt_bit;
wire            end_cnt_bit;

//三态门
wire            sda_in      ;//从机输入
reg             sda_out     ;//主机输出
reg             sda_out_en  ;//主机输出使能

assign sda_in = sda;
assign sda = sda_out_en ? sda_out : 1'bz;
//
parameter SLAVE_ID = 7'h53;
reg   [7:0]  slave_addr;//slave_addr = {SLVAE_ADDR,1'b0};
reg   [7:0]  reg_addr  ;
reg   [7:0]  data      ;

//内部逻辑
always@(posedge clk or negedge rst_n)begin          
    if(!rst_n)begin                                     
        slave_addr <= 8'd0;
        reg_addr   <= 8'd0;
        data       <= 8'd0;                                             
    end                                             
    else begin                                      
        slave_addr <= {SLAVE_ID,1'b0};
        reg_addr   <= 8'h00;
        data       <= 8'h06;                                            
    end                                             
end                                                 

//状态机第一段
always@(posedge clk or negedge rst_n)begin          
    if(!rst_n)begin                                     
        state_c <= WAIT;                                             
    end                                             
    else begin                                      
        state_c <= state_n;                                           
    end                                             
end                                                 
//状态机第二段
always @(*)begin
    case (state_c)
        WAIT    : begin
            if(wait2idle)
                state_n = IDLE;
            else 
                state_n = state_c; 
        end  
        IDLE       : begin
            if(idle2start)
                state_n = START;
            else 
                state_n = state_c; 
        end
        START      : begin
            if(start2slave)
                state_n = SLAVE_ADDR;
            else 
                state_n = state_c; 
        end
        SLAVE_ADDR : begin
            if(slave2ack1)
                state_n = ACK_1;
            else 
                state_n = state_c; 
        end
        ACK_1      : begin
            if(ack1_2_reg)
                state_n = REG_ADDR;
            else 
                state_n = state_c; 
        end
        REG_ADDR   : begin
            if(reg2ack2)
                state_n = ACK_2;
            else 
                state_n = state_c; 
        end
        ACK_2      : begin
            if(ack2_2_data)
                state_n = DATA;
            else 
                state_n = state_c; 
        end
        DATA       : begin
            if(data2ack3)
                state_n = ACK_3;
            else 
                state_n = state_c; 
        end
        ACK_3      : begin
            if(ack3_2_stop)
                state_n = STOP;
            else 
                state_n = state_c; 
        end
        STOP       : begin
            if(stop2idle)
                state_n = IDLE;
            else 
                state_n = state_c; 
        end
        default: ;
    endcase
end
//描述状态跳转条件
assign wait2idle   = (state_c == WAIT       ) && (end_cnt_20ms);
assign idle2start  = (state_c == IDLE       ) ;
assign start2slave = (state_c == START      ) && (end_cnt_scl);
assign slave2ack1  = (state_c == SLAVE_ADDR ) && (end_cnt_bit);
assign ack1_2_reg  = (state_c == ACK_1      ) && (end_cnt_scl) ;//&& (~sda_in);
assign reg2ack2    = (state_c == REG_ADDR   ) && (end_cnt_bit);
assign ack2_2_data = (state_c == ACK_2      ) && (end_cnt_scl) ;//&& (~sda_in);
assign data2ack3   = (state_c == DATA       ) && (end_cnt_bit);
assign ack3_2_stop = (state_c == ACK_3      ) && (end_cnt_scl) ;//&& (~sda_in);
assign stop2idle   = (state_c == STOP       ) && (end_cnt_scl);
//20ms计数器
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_20ms <= 0;
    end
    else if(add_cnt_20ms)begin
        if(end_cnt_20ms)begin
            cnt_20ms <= 0;
        end
        else begin
            cnt_20ms <= cnt_20ms + 1;
        end
    end
end

assign add_cnt_20ms = (state_c == WAIT);
assign end_cnt_20ms = add_cnt_20ms && (cnt_20ms == TIME_20MS - 1);
//同步时钟scl
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_scl <= 0;
    end
    else if(add_cnt_scl)begin
        if(end_cnt_scl)begin
            cnt_scl <= 0;
        end
        else begin
            cnt_scl <= cnt_scl + 1;
        end
    end
end

assign add_cnt_scl = (state_c == START) || (state_c == SLAVE_ADDR) || (state_c == ACK_1) || (state_c == REG_ADDR)
                    || (state_c == ACK_2) || (state_c == DATA) || (state_c == ACK_3) || (state_c == STOP);
assign end_cnt_scl = add_cnt_scl && (cnt_scl == 200 - 1);
                                               
always@(posedge clk or negedge rst_n)begin          
    if(!rst_n)begin                                     
        scl_r <= 1'b1;                                             
    end                                             
    else if(cnt_scl == 1'b1)begin                                      
        scl_r <= 1'b0;                                             
    end              
    else if(cnt_scl >= 100)begin
        scl_r <= 1'b1;
    end                               
end                                                 
// assign scl = (cnt_scl >= 0 && cnt_scl <100) ? 1'b0 : 1'b1;
assign scl = scl_r;
//
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        cnt_bit <= 0;
    end
    else if(add_cnt_bit)begin
        if(end_cnt_bit)begin
            cnt_bit <= 0;
        end
        else begin
            cnt_bit <= cnt_bit + 1;
        end
    end
end

assign add_cnt_bit = end_cnt_scl && ((state_c == SLAVE_ADDR) || (state_c == REG_ADDR) || (state_c == DATA));
assign end_cnt_bit = add_cnt_bit && (cnt_bit == 8 - 1);
//输出sda_out,sda_out_en描述
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        sda_out <= 1'b1;
        sda_out_en <= 1'b0;
    end
    else begin
        case (state_c)
            START     : begin
                sda_out_en <= 1'b1;
                if(cnt_scl < 150)begin
                    sda_out <= 1'b1;
                end
                else begin
                    sda_out <= 1'b0;
                end
            end
            SLAVE_ADDR   : begin
                sda_out_en <= 1'b1;
                if(cnt_scl == (TIME_SCL >> 2))begin
                    sda_out <= slave_addr[7 - cnt_bit];
                end
            end
            REG_ADDR   :begin
                sda_out_en <= 1'b1;
                if(cnt_scl == (TIME_SCL >> 2))begin
                    sda_out <= reg_addr[7 - cnt_bit];
                end
            end    
            DATA      : begin
                sda_out_en <= 1'b1;
                if(cnt_scl == (TIME_SCL >> 2))begin
                    sda_out <= data[7 - cnt_bit];
                end
            end
            ACK_1,ACK_2,ACK_3 : begin
                sda_out_en <= 1'b0;
            end     
            STOP  : begin
                sda_out_en <= 1'b1;
                if(cnt_scl < 150)begin
                    sda_out <= 1'b0;
                end
                else begin
                    sda_out <= 1'b1;
                end
            end    
            default: begin 
                    sda_out <= 1'b1;
                    sda_out_en <= 1'b0;
                end
        endcase
    end
end

endmodule