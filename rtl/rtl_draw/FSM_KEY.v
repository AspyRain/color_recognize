module FSM_KEY#(parameter TIME_20MS = 1_000_000, width = 5)(
    input                           clk     ,
    input                           rst_n   ,
    input        [width - 1:0]      key_in  ,       //没有消抖的按键
    output reg   [width - 1:0]      key_out         //消抖完成的按键
);

    reg     [19:0]              cnt     ;
    wire                        add_cnt ;
    wire                        end_cnt ;

    reg     [width - 1:0]       key_r0  ;   //同步信号 同步到时钟上升沿
    reg     [width - 1:0]       key_r1  ;   //打拍    打拍延迟一个时钟周期
    wire                        nedge   ;   //下降沿
    wire                        podge   ;   //上升沿

    //状态定义
    parameter   IDLE    =   4'b0001,
                DOWN    =   4'b0010,
                HOLD    =   4'b0100,
                UP      =   4'b1000;
    
    //状态转移条件
    wire                idle2down   ;
    wire                down2idle   ;   //如果是抖动
    wire                down2hold   ;   //如果是按键按下
    wire                hold2up     ;
    wire                up2idle     ;

    //状态寄存器
    reg     [3:0]       state_c     ;
    reg     [3:0]       state_n     ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 20'b0;
        end
        else if(add_cnt)begin
            if(end_cnt)begin
                cnt <= 20'b0;
            end
            else begin
                cnt <= cnt + 1'b1;
            end
        end
        else begin
            cnt <= 20'b0;
        end
    end

    assign add_cnt = state_c == DOWN || state_c == UP;
    assign end_cnt = add_cnt && cnt == TIME_20MS - 1;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            key_r0 <= {width{1'b1}};       //{3{1'b1}} = 3'b111
            key_r1 <= {width{1'b1}};
        end
        else begin
            key_r0 <= key_in;
            key_r1 <= key_r0;
        end
    end

    assign nedge = |(~key_r0 & key_r1) ;
    assign podge = |(key_r0 & ~key_r1) ;

    //状态机第一段
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            state_c <= IDLE;
        end
        else begin
            state_c <= state_n;
        end
    end

    //状态机第二段 采用组合逻辑
    always @(*)begin
        case(state_c)
            IDLE    :   if(idle2down)
                            state_n = DOWN;
                        else 
                            state_n = state_c;
            DOWN    :   if(down2idle)
                            state_n = IDLE;
                        else if(down2hold)
                            state_n = HOLD;
                        else 
                            state_n = state_c;
            HOLD    :   if(hold2up)
                            state_n = UP;
                        else 
                            state_n = state_c;
            UP      :   if(up2idle)
                            state_n = IDLE;
                        else 
                            state_n = state_c;
            default :   state_n = state_c;
        endcase
    end

    assign idle2down = state_c == IDLE && nedge;
    assign down2idle = state_c == DOWN && end_cnt && (&key_r0)  ;
    assign down2hold = state_c == DOWN && end_cnt && (~(&key_r0)) ;
    assign hold2up   = state_c == HOLD && podge ;
    assign up2idle   = state_c == UP   && end_cnt ;

    // 添加一个新的信号用于控制key_out的短暂高电平输出
reg        [1:0]      key_out_pulse;

always @(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        key_out <= {width{1'b0}};
        key_out_pulse <= 2'b00;
    end
    else begin
        // 当状态转移到HOLD并且之前没有发出过脉冲时，设置key_out_pulse为1
        if(state_n == HOLD && state_c != HOLD) begin
            key_out_pulse <= 2'b01; // 设置为1表示下一个周期key_out应为高电平
        end
        // 自动复位，在一个周期后将key_out_pulse复位为0
        else if(key_out_pulse == 2'b01) begin
            key_out_pulse <= 2'b00;
        end

        // 根据key_out_pulse的值更新key_out
        if(key_out_pulse == 2'b01) begin
            key_out <= ~key_r1; // 按键按下时，key_out为高电平一个周期
        end
        else begin
            key_out <= {width{1'b0}}; // 其他情况key_out为低电平
        end
    end
end


endmodule