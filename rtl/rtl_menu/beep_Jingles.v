module beep_jingles#(parameter CLK_PRE = 50_000_000, TIME_300MS = 5_000_000)(
    input           clk             ,
    input           rst_n           ,
    input  [4:0]    key             ,
    input  [1:0]    select_flag     ,
    output reg      pwm
);
    //频率控制音色 ，占空比控制音量 ，占空比越大，低电平越少，音量越小

    parameter   
        DO_     =   CLK_PRE / 262,
        RE_     =   CLK_PRE / 294,
        MI_     =   CLK_PRE / 330,
        FA_     =   CLK_PRE / 349,
        SO_     =   CLK_PRE / 392,
        LA_     =   CLK_PRE / 440,
        SI_     =   CLK_PRE / 494,             
        DO      =   CLK_PRE / 523,
        RE      =   CLK_PRE / 587,
        MI      =   CLK_PRE / 659,
        FA      =   CLK_PRE / 698,
        SO      =   CLK_PRE / 784,
        LA      =   CLK_PRE / 880,
        SI      =   CLK_PRE / 988;

    reg         [16:0]      cnt1    ;   //计数频率
    wire                    add_cnt1;
    wire                    end_cnt1;
    reg         [16:0]      X       ;   //cnt1最大值

    reg         [23:0]      cnt2    ;   //计数每个音符发声300ms
    wire                    add_cnt2;
    wire                    end_cnt2;

    reg         [7:0]       cnt3    ;   //计数乐谱48
    wire                    add_cnt3;
    wire                    end_cnt3;

    reg                     ctrl    ;   //后25%消音
    reg                     en      ;
    reg                    ok_flag ;//按下是否为ok键

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            en <= 0;
        end 
        else if(key != 5'b0000 )begin 
            if (key[4]==1'b1)begin
                ok_flag <= 1'b1;
            end
            else begin
                ok_flag <= 1'b0;
            end
            en <= 1'b1;
        end
        else if (key == 5'b0000 && end_cnt3 == 1'b1)begin
            en <= 1'b0;
        end
        else begin 
            en <= en;
        end 
    end

    

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt1 <= 17'b0;
        end
        else if(end_cnt2)begin
            cnt1 <= 17'b0;
        end
        else if(add_cnt1)begin
            if(end_cnt1)begin
                cnt1 <= 17'b0;
            end
            else begin
                cnt1 <= cnt1 + 1'b1;
            end
        end
        else begin
            cnt1 <= cnt1;
        end 
    end

    assign add_cnt1 = en;
    assign end_cnt1 = add_cnt1 && cnt1 == X - 1;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt2 <= 24'b0;
        end
        else if(add_cnt2)begin
            if(end_cnt2)begin
                cnt2 <= 24'b0;
            end
            else begin
                cnt2 <= cnt2 + 1'b1;
            end
        end
        else begin
            cnt2 <= cnt2;
        end
    end 

    assign add_cnt2 = en;
    assign end_cnt2 = add_cnt2 && cnt2 == TIME_300MS -1;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt3 <= 6'b0;
        end
        else if(add_cnt3)begin
            if(end_cnt3)begin
                cnt3 <= 24'b0;
            end
            else begin
                cnt3 <= cnt3 + 1'b1;
            end
        end
        else begin
            cnt3 <= cnt3;
        end
    end 

    assign add_cnt3 = end_cnt2;
    assign end_cnt3 = add_cnt3 && cnt3 == 4 - 1;


    always @(*)begin
        if (ok_flag)begin
            case (select_flag)
                2'b10:
                case (cnt3)
                    0:          X = SO;
                    1:          X = 1;  
                    2:          X = 1;
                    3:          X = 1;
                default:X=1;
            endcase
                2'b00:
                                case (cnt3)
                    0:          X = LA;
                    1:          X = SI;  
                    2:          X = 1;
                    3:          X = 1;
                default:X=1;
            endcase
                2'b01:
                                case (cnt3)
                    0:          X = SI;
                    1:          X = LA;  
                    2:          X = 1;
                    3:          X = 1;
                default:X=1;
            endcase
                default: 
                case (cnt3)
                    0:          X = SO;
                    1:          X = 1;  
                    2:          X = 1;
                    3:          X = 1;
                default:X=1;
            endcase
            endcase
            
        end
        else begin
                case (cnt3)
                    0:          X = FA;
                    1:          X = 1;  
                    2:          X = 1;
                    3:          X = 1;
                default:X=1;
            endcase
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            ctrl <= 1'b0;
        end
        else if(cnt2 >= ((TIME_300MS >> 1) + (TIME_300MS >>2)))begin
            ctrl <= 1'b1;
        end
        else if(X == 1)begin
            ctrl <= 1'b1;
        end
        else begin
            ctrl <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            pwm <= 1'b1;
        end
        else if(ctrl)begin
            pwm <= 1'b1;
        end
        else if(en && (cnt1 < (X >> 5)))begin
            pwm <= 1'b0;
        end
        else begin
            pwm <= 1'b1;
        end
    end


endmodule