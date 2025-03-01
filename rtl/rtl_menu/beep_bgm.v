module beep_bgm#(parameter CLK_PRE = 50_000_000, TIME_300MS = 10_000_000)(
    input               clk     ,
    input               rst_n   ,
    input               flag     ,
    input   [1:0]       mode_n   ,
    output reg          pwm
);
    //频率控制音色 ，占空比控制音量 ，占空比越大，低电平越少，音量越小
//音符-频率对照
    parameter


        ___DO = CLK_PRE / 65,
        ___RE = CLK_PRE / 73,
        ___MI = CLK_PRE / 82,
        ___FA = CLK_PRE / 87,
        ___SO = CLK_PRE / 98,
        ___LA = CLK_PRE / 110,
        ___SI = CLK_PRE / 123,

        __DO = CLK_PRE / 131,
        __RE = CLK_PRE / 147,
        __MI = CLK_PRE / 165,
        __FA = CLK_PRE / 175,
        __SO = CLK_PRE / 196,
        __LA = CLK_PRE / 220,
        __SI = CLK_PRE / 247, 

        _DO = CLK_PRE / 262,
        _RE = CLK_PRE / 294,
        _MI = CLK_PRE / 330,
        _FA = CLK_PRE / 349,
        _SO = CLK_PRE / 392,
        _LA = CLK_PRE / 440,
        _SI = CLK_PRE / 494, 

        DO = CLK_PRE / 523,
        RE = CLK_PRE / 587,
        MI = CLK_PRE / 659,
        FA = CLK_PRE / 698,
        FA1= CLK_PRE / 740,
        SO = CLK_PRE / 784,
        SO1= CLK_PRE / 831,
        LA = CLK_PRE / 880,
        LA1= CLK_PRE / 932,
        SI = CLK_PRE / 988,

        DO_ = CLK_PRE / 1046,
        RE_ = CLK_PRE / 1175,
        MI_ = CLK_PRE / 1318,
        FA_ = CLK_PRE / 1397,
        SO_ = CLK_PRE / 1568,
        LA_ = CLK_PRE / 1760,
        SI_ = CLK_PRE / 1976;


    reg         [7:0]       MUSIC_LEN;
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

    reg                    mode_change;
    reg        [1:0]       mode_c;
    reg                     ctrl    ;   //后25%消音
    reg                     en      ;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            MUSIC_LEN <= 8'd0;
        end
        else begin
            case (mode_c)
                2'b00:begin
                    MUSIC_LEN <=8'd142;
                end
                2'b10:begin
                    MUSIC_LEN <= 0;
                end
                default:begin
                    MUSIC_LEN <= MUSIC_LEN;
                end 
            endcase
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            mode_c <= 2'b00;
        end
        else begin
            mode_c <= mode_n;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            mode_change <= 1'b0;
        end
        else begin
            if (mode_c != mode_n)begin
                mode_change <= 1'b1;
            end
            else begin
                mode_change <= 1'b0;
            end
        end
    end

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            en <= 0;
        end 
        else if(flag == 1'b1)begin 
            en <= 1'b1;
        end
        else begin 
            en <= 1'b0;
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
    assign end_cnt3 = add_cnt3 && ((cnt3 == MUSIC_LEN - 1)||(mode_change == 1'b1));


    always @(*)begin
        case (mode_c)
            2'b00:begin
                case (cnt3)
                    0:          X = _SO;
                    1:          X = _LA;

                    2:          X = 1;
                    3:          X = DO;

                    4:          X = MI;        
                    5:          X = 1;  

                    6:          X = SO;         
                    7:          X = 1;

                    8:          X = SI;     
                    9:          X = 1;

                    10:         X = LA1;    
                    11:         X = LA;

                    12:         X = 1;      
                    13:         X = 1;

                    14:         X = _SO;     
                    15:         X = 1;

                    16:         X = SO;       
                    17:         X = 1;

                    18:         X = SO1;     
                    19:         X = LA;

                    20:         X = 1;      
                    21:         X = 1;

                    22:         X = 1;       
                    23:         X = 1;

                    24:         X = SO;              
                    25:         X = 1;  

                    26:         X = SO1;              
                    27:         X = LA;         

                    28:         X = 1;      
                    29:         X = LA;

                    30:         X = SO;      
                    31:         X = LA;


                    32:         X = SI;
                    33:         X = 1;

                    34:         X = SI;
                    35:         X = 1;

                    36:         X = LA;        
                    37:         X = 1; 

                    38:         X = FA;        
                    39:         X = 1; 

                    40:         X = 1;
                    41:         X = 1;

                    42:         X = 1;
                    43:         X = 1;

                    44:       X = 1; 
                    45:       X = 1;  

                    46:       X = 1;  
                    47:       X = 1; 

                    48:       X = FA;
                    49:       X = 1;

                    50:       X = FA1;
                    51:       X = SO;

                    52:       X = 1;
                    53:       X = 1;

                    54:       X = 1;
                    55:       X = 1;

                    56:       X = FA;
                    57:       X = 1;

                    58:       X = FA1;
                    59:       X = SO;

                    60:       X = 1;
                    61:       X = SO;

                    62:       X = FA;
                    63:       X = SO;

                    64:       X = LA;
                    65:       X = 1;

                    66:       X = LA;
                    67:       X = 1;

                    68:       X = SO;
                    69:       X = 1;

                    70:       X = MI;
                    71:       X = 1;

                    72:       X = 1;
                    73:       X = 1;

                    74:       X = 1;
                    75:       X = 1;

                    76:       X = 1;
                    77:       X = 1;

                    78:       X = 1;
                    79:       X = 1;

                    80:       X = SO;
                    81:       X = 1;

                    82:       X = SO1;
                    83:       X = LA;

                    84:       X = 1;
                    85:       X = 1;

                    86:       X = 1;
                    87:       X = 1;

                    88:       X = SO;
                    89:       X = SO;

                    90:       X = SO1;
                    91:       X = LA;

                    92:       X = 1 ;
                    93:      X = SO;

                    94:      X = LA;
                    95:       X = SI;

                    96:       X = 1;
                    97:       X = SI;

                    98:       X = 1;
                    99:       X = LA;

                    100:       X = 1;
                    101:       X = FA;

                    102:       X = 1;
                    103:       X = 1;

                    104:       X = 1;
                    105:       X = 1;

                    106:       X = 1;
                    107:       X = 1;

                    108:       X = 1;
                    109:       X = 1;

                    110:       X = 1;
                    111:       X = FA;

                    112:       X = 1;
                    113:       X = FA1;

                    114:       X = SO;
                    115:       X = 1;

                    116:       X = 1;
                    117:       X = 1;

                    118:       X = 1;
                    119:       X = FA;

                    120:       X = 1;
                    121:       X = FA1;

                    122:       X = SO;
                    123:       X = 1;

                    124:       X = SO;
                    125:       X = FA;

                    126:       X = SO;
                    127:       X = LA;

                    128:       X = 1;
                    129:       X =LA;

                    130:       X = 1;
                    131:       X = SO;

                    132:       X = 1;
                    133:       X = MI;

                    134:       X = 1;
                    135:       X = 1;

                    136:       X = 1;
                    137:       X = 1;

                    138:       X = 1;
                    139:       X = 1;

                    140:       X = 1;
                    141:       X = 1;
                    142:       X = 1;


default:X=1;
        endcase
            end 
            default: X = 1;
        endcase
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