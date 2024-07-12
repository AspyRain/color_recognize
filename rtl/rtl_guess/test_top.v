module test_top (
    input           clk     ,
    input           rst_n   ,
    input   [2:0]   switch  ,
    output          scl     ,

    inout           sda     
);
    wire    [7:0]   data_r  ;
    wire    [7:0]   data_g  ;
    wire    [7:0]   data_b  ;

    wire    [8:0]   hsv1_h;
    wire    [8:0]   hsv1_s;
    wire    [8:0]   hsv1_v;

    wire    [8:0]   hsv2_h;
    wire    [8:0]   hsv2_s;
    wire    [8:0]   hsv2_v;

    wire            similar_flag;

    cls381_top_multi        cls381_top_inst(
        .sys_clk            (clk        ),
        .sys_rst_n          (rst_n      ),
        
        .scl                (scl        ),
        .sda                (sda        ),

        .data_r_out         (data_r     ),
        .data_g_out         (data_g     ),
        .data_b_out         (data_b     )
    );

    rgb_hsv                 rgb_hsv_get_inst(
        .clk                (clk        ),
        .rst                (rst_n      ),


        .rgb_r              (data_r     ),
        .rgb_g              (data_g     ),
        .rgb_b              (data_b     ),

        .hsv_h              (hsv1_h     ),
        .hsv_s              (hsv1_s     ),
        .hsv_v              (hsv1_v     )
    );

    rgb_hsv                 rgb_hsv_set_inst(
        .clk                (clk        ),
        .rst                (rst_n      ),


        .rgb_r              (8'h1F     ),
        .rgb_g              (8'h5E     ),
        .rgb_b              (8'h6E     ),

        .hsv_h              (hsv2_h     ),
        .hsv_s              (hsv2_s     ),
        .hsv_v              (hsv2_v     )
    );   

    HSVComparator       HSVComparator_inst(
        .clk                (clk   ),
        .hsv1_h             (hsv1_h),
        .hsv1_s             (hsv1_s),
        .hsv1_v             (hsv1_v),

        .hsv2_h             (hsv2_h),
        .hsv2_s             (hsv2_s),
        .hsv2_v             (hsv2_v),

        .threshold_level    (switch),
        .similar_flag       (similar_flag)
    );
endmodule