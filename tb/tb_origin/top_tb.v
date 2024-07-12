`timescale 1ns/1ps
module top_tb;
    reg                 clk                 ;
    reg                 rst_n               ;
//模块例化
driver u_top(
/* input            */.clk      (clk          ),
/* input            */.rst_n    (rst_n        )
);
//产生时钟
localparam CLK_PERIOD = 20;
initial clk = 1'b0;
always #(CLK_PERIOD/2) clk=~clk;
//复位3个周期
initial begin
    rst_n = 1'b0;
    #(CLK_PERIOD * 3);
    rst_n = 1'b1;

end
//激励
initial begin
   
end
endmodule