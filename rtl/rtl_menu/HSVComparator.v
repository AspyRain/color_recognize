module HSVComparator (
    input   clk,
    input wire [8:0] hsv_get_h, hsv_get_s, hsv_get_v,
    input wire [8:0] hsv_set_h, hsv_set_s, hsv_set_v,
    input wire [2:0] threshold_level,
    output reg [1:0] similar_flag //相似标签:0不相似；1相似；2未比较
);
parameter THRESHOLD1_H = 60, THRESHOLD1_S = 32, THRESHOLD1_V = 32;  // 第一档阈值
parameter THRESHOLD2_H = 15, THRESHOLD2_S = 8,  THRESHOLD2_V = 8; // 第二档阈值
parameter THRESHOLD3_H = 10, THRESHOLD3_S = 5,  THRESHOLD3_V = 5; // 第三档阈值
parameter THRESHOLD4_H = 5,  THRESHOLD4_S = 3,  THRESHOLD4_V = 3;  // 第四档阈值


reg [8:0] h_diff, s_diff, v_diff;

// 自定义绝对值函数
function [8:0] abs_diff;
    input [8:0] a, b;
    if (a > b) begin
        abs_diff = a - b;
    end else begin
        abs_diff = b - a;
    end
endfunction

always @(posedge clk) begin
    similar_flag <= 2'b0; // 初始化相似标志为0

    // 计算色调、饱和度、明度的差值
    h_diff = abs_diff(hsv_get_h, hsv_set_h);
    s_diff = abs_diff(hsv_get_s, hsv_set_s);
    v_diff = abs_diff(hsv_get_v, hsv_set_v);

    // 考虑色调的周期性
    if (h_diff > 180) begin
        h_diff = 360 - h_diff;
        
    end
    if ({hsv_set_h,hsv_set_s,hsv_set_v} == 24'b0)begin
        similar_flag <= 2'b10;
    end
    else begin
       // 根据输入的档位决定阈值，并判断颜色是否相似
    case(threshold_level)
        3'b000: begin // 较低难度，较宽松的阈值
            if (h_diff <= THRESHOLD1_H && s_diff <= THRESHOLD1_S && v_diff <= THRESHOLD1_V) begin
                similar_flag <= 2'b01; // 颜色相似
            end
        end
        3'b001: begin // 中等难度，中等阈值
            if (h_diff <= THRESHOLD2_H && s_diff <= THRESHOLD2_S && v_diff <= THRESHOLD2_V) begin
                similar_flag <= 2'b01; // 颜色相似
            end
        end
        3'b010: begin // 最高难度，最严格阈值
            if (h_diff <= THRESHOLD3_H && s_diff <= THRESHOLD3_S && v_diff <= THRESHOLD3_V) begin
                similar_flag <= 2'b01; // 颜色相似
            end
        end
        3'b111: begin // 最高难度，最严格阈值
            if (h_diff <= THRESHOLD4_H && s_diff <= THRESHOLD4_S && v_diff <= THRESHOLD4_V) begin
                similar_flag <= 2'b01; // 颜色相似
            end
        end
        default: ; // 默认情况，不做处理
    endcase 
    end
end

endmodule