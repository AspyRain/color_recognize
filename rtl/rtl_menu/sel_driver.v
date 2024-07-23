module sel_driver(
    input               clk         ,
    input               rst_n       ,
    input       [7:0]   din         ,//传递的温度值
    input       [1:0]   mode        ,//菜单选项
    input       [1:0]   similar_flag,//加分标志
    output reg  [5:0]   sel         ,//片选
    output reg  [7:0]   dig         //段选
);

    parameter   ZER = 7'b100_0000,
                ONE = 7'b111_1001,
                TWO = 7'b010_0100,
                THR = 7'b011_0000,
                FOU = 7'b001_1001,
                FIV = 7'b001_0010,
                SIX = 7'b000_0010,
                SEV = 7'b111_1000,
                EIG = 7'b000_0000,
                NIN = 7'b001_0000,
                A   = 7'b000_1111,
                B   = 7'b011_1111;

    parameter   TIME_20US = 1000;   

    reg     [9:0]       cnt     ;
    wire                add_cnt ;
    wire                end_cnt ;

    reg                 dot     ;   //小数点
    reg     [3:0]       data    ;   //寄存时分秒

    wire       [23:0]      dis_data    ;
    reg        [3:0]       data_1      ;//个位
    reg        [3:0]       data_10     ;//十位
    reg        [23:0]      data_b      ;  
    
    // assign  data_b       = din                  ;
    // assign  data_1       = data_b%10            ;
    // assign  data_10       = (data_b/10)%10      ;
    // 
    assign dis_data = (mode == 2'd1)? {16'h0000,data_10,data_1}:{8'h00,data_10,data_1,8'h00};

    reg     [19:0]      cnt1    ;
    wire                add_cnt1;

    reg                 flag    ;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flag <= 1'b0;
        end
        else if (similar_flag == 2'd1) begin
            flag <= 1'b1;
        end
        else begin
            flag <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt1 <= 0;
        end 
        else if(add_cnt1)begin 
            if (flag == 1'b1) begin
                cnt1 <= cnt1 + 1;
            end 
            else begin 
                cnt1 <= cnt1;
            end 
        end
        else begin
            cnt1<=0;
        end
    end 
    assign add_cnt1 = mode == 2'd1;

    always @(*) begin
        if (mode!=2'd1) begin
            data_b = din;            
            data_1 = data_b%10;
            data_10= (data_b/10)%10;
        end
        else if (mode == 2'd1) begin
            data_b = cnt1;
            data_1 = data_b%10;
            data_10= (data_b/10)%10;
        end
    end

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt <= 0;
        end 
        else if(add_cnt)begin 
            if(end_cnt)begin 
                cnt <= 0;
            end
            else begin 
                cnt <= cnt + 1;
            end 
        end
        else begin 
            cnt <= cnt;
        end 
    end 
    assign add_cnt = 1'b1;
    assign end_cnt = add_cnt && cnt == TIME_20US - 1 ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            sel <= 6'b011_111;
        end 
        else if(end_cnt)begin 
            sel <= {sel[0],sel[5:1]};
        end 
        else begin 
            sel <= sel;
        end 
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dot <= 1'b1;
            data <= 4'hf;
        end
        else begin
            case(sel)
                6'b011_111 : begin data <= dis_data[3:0]    ; dot <= 1'b1; end
                6'b101_111 : begin data <= dis_data[7:4]    ; dot <= 1'b1; end
                6'b110_111 : begin data <= dis_data[11:8]   ; 
                            if(mode != 2'd1) 
                            dot <= 1'b0; 
                            else
                            dot <= 1'b1;
                            end
                6'b111_011 : begin data <= dis_data[15:12]  ; dot <= 1'b1; end
                6'b111_101 : begin data <= dis_data[19:16]  ; dot <= 1'b1; end
                6'b111_110 : begin data <= dis_data[23:20]  ; dot <= 1'b1; end
                default    : begin data <= 4'hf             ; dot <= 1'b1; end
            endcase
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dig <= 8'hFF;
        end
        else begin
            case(data)
                4'd0   :   dig <= {dot,ZER} ;
                4'd1   :   dig <= {dot,ONE} ;
                4'd2   :   dig <= {dot,TWO} ;
                4'd3   :   dig <= {dot,THR} ;
                4'd4   :   dig <= {dot,FOU} ;
                4'd5   :   dig <= {dot,FIV} ;
                4'd6   :   dig <= {dot,SIX} ;
                4'd7   :   dig <= {dot,SEV} ;
                4'd8   :   dig <= {dot,EIG} ;
                4'd9   :   dig <= {dot,NIN} ;
                4'hA   :   dig <= {dot,A  } ;
                4'hB   :   dig <= {dot,B  } ;
                default : dig <= 8'hFF;
            endcase
        end
    end

endmodule
