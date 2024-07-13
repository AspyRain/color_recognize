
module counter#(parameter   TIME_1S = 25_000_000/*用于跨模块传递参数*/ ) (
    input       clk, //一个系统时钟周期为20ns
    input       rst_n, //低电平有效
    output      c_ok
);
    //parameter   TIME_1S = 50_000_000;//默认十进制 1s/20ns
    //parameter   TIME_300MS = 15_000_000;//默认十进制 300ms/20ns
    reg         [25:0]      cnt     ; //计数器
    reg         [23:0]      cnt1     ; //计数器
    wire                    add_cnt1; //开始计数
    wire                    end_cnt1; //计数器最大值
    always @(posedge clk or negedge rst_n) begin
        if (rst_n == 1'b0)begin
            cnt <= 26'b0;
        end
        else if (cnt == TIME_1S - 1)begin
            cnt <= 26'b0;
        end
        else begin
            cnt <= cnt + 1'b1;
        end
    end
    //过了多少秒
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            cnt1 <= 24'b0; // ==>cnt1 <= 0
        end
        else if(add_cnt1)begin //开启计数器
            if (end_cnt1)begin
                cnt1 <= 0;
            end
            else begin
                cnt1 <= cnt1+1'b1;
            end
        end
        else begin
            cnt1 <= cnt1;
        end
    end
    assign add_cnt1 = cnt ==    TIME_1S - 1;
    assign end_cnt1 = cnt1==59 && add_cnt1;
    assign c_ok = add_cnt1;
    
endmodule

