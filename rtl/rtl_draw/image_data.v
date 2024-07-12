module data_cfg(
    //input  wire [4:0]         cnt_bit       ,
    //input  wire [6:0]         cnt_led       ,
//    input  wire [3: 0]        ges_data      ,
    input wire [1:0]    pic_num,    
    
    output wire	[24*64 - 1:0]	pic_flattened 
);
wire  [1: 0]   ges_pic;
wire [23:0] data [255:0];
wire [3: 0]        ges_data      ;
wire	[23:0] pic [63:0];
assign ges_pic = 2'd0 ;
assign pic = (pic_num==2'b0)?data[(0 + 1) * 64-1 : 0 * 64]:(pic_num==2'b1)?data[(1 + 1) * 64-1 : 1 * 64]:(pic_num==2'b10)?data[(2 + 1) * 64-1 : 2 * 64]:data[(0 + 1) * 64-1 : 0 * 64];
//assign pic = data[ges_pic * 64 + cnt_led][23 - cnt_bit];

genvar k;
generate
    for (k = 0; k < 64; k = k + 1) begin : data_gen
        assign pic = data[k];

    end
endgenerate

//always @(*) begin
//    case(ges_data)
//        4'b0001:     ges_pic = 2'd0;
//        4'b0010:     ges_pic = 2'd1;
//        4'b0100:     ges_pic = 2'd2;
//        4'b1000:     ges_pic = 2'd3;
//        default:     ges_pic = 2'd0;
//    endcase
//end
//U
assign  data[00]  =  {8'h00,8'h00,8'h00}  ;//0
assign  data[01]  =  {8'h00,8'h00,8'h00}  ;
assign  data[02]  =  {8'h00,8'h00,8'h00}  ;
assign  data[03]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[04]  =  {8'h00,8'h00,8'h00}  ;
assign  data[05]  =  {8'h00,8'h00,8'h00}  ;
assign  data[06]  =  {8'h00,8'h00,8'h00}  ;
assign  data[07]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[08]  =  {8'h00,8'h00,8'h00}  ;//1
assign  data[09]  =  {8'h00,8'h00,8'h00}  ;
assign  data[10]  =  {8'h00,8'h00,8'h00}  ;
assign  data[11]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[12]  =  {8'h00,8'h00,8'h00}  ;
assign  data[13]  =  {8'h00,8'h00,8'h00}  ;
assign  data[14]  =  {8'h00,8'h00,8'h00}  ;
assign  data[15]  =  {8'h00,8'h00,8'h00}  ;
assign  data[16]  =  {8'h00,8'h00,8'h00}  ;//2
assign  data[17]  =  {8'h00,8'h00,8'h00}  ;
assign  data[18]  =  {8'h00,8'h00,8'h00}  ;
assign  data[19]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[20]  =  {8'h00,8'h00,8'h00}  ;
assign  data[21]  =  {8'h00,8'h00,8'h00}  ;
assign  data[22]  =  {8'h00,8'h00,8'h00}  ;
assign  data[23]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[24]  =  {8'h00,8'h00,8'h00}  ;//3
assign  data[25]  =  {8'h00,8'hff,8'h00}  ;
assign  data[26]  =  {8'h00,8'hff,8'h00}  ;
assign  data[27]  =  {8'h00,8'hff,8'h00}  ;	
assign  data[28]  =  {8'h00,8'hff,8'h00}  ;
assign  data[29]  =  {8'h00,8'hff,8'h00}  ;
assign  data[30]  =  {8'h00,8'hff,8'h00}  ;
assign  data[31]  =  {8'h00,8'h00,8'h00}  ;
assign  data[32]  =  {8'h00,8'h00,8'h00}  ;//4
assign  data[33]  =  {8'h00,8'h00,8'h00}  ;
assign  data[34]  =  {8'h00,8'h00,8'h00}  ;
assign  data[35]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[36]  =  {8'h00,8'h00,8'h00}  ;
assign  data[37]  =  {8'h00,8'h00,8'h00}  ;
assign  data[38]  =  {8'h00,8'h00,8'h00}  ;
assign  data[39]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[40]  =  {8'h00,8'h00,8'h00}  ;//5
assign  data[41]  =  {8'h00,8'h00,8'h00}  ;
assign  data[42]  =  {8'h00,8'h00,8'h00}  ;
assign  data[43]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[44]  =  {8'h00,8'h00,8'h00}  ;
assign  data[45]  =  {8'h00,8'h00,8'h00}  ;
assign  data[46]  =  {8'h00,8'h00,8'h00}  ;
assign  data[47]  =  {8'h00,8'h00,8'h00}  ;
assign  data[48]  =  {8'h00,8'h00,8'h00}  ;//6
assign  data[49]  =  {8'h00,8'h00,8'h00}  ;
assign  data[50]  =  {8'h00,8'h00,8'h00}  ;
assign  data[51]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[52]  =  {8'h00,8'h00,8'h00}  ;
assign  data[53]  =  {8'h00,8'h00,8'h00}  ;
assign  data[54]  =  {8'h00,8'h00,8'h00}  ;
assign  data[55]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[56]  =  {8'h00,8'h00,8'h00}  ;//7
assign  data[57]  =  {8'h00,8'h00,8'h00}  ;
assign  data[58]  =  {8'h00,8'h00,8'h00}  ;
assign  data[59]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[60]  =  {8'h00,8'h00,8'h00}  ;
assign  data[61]  =  {8'h00,8'h00,8'h00}  ;
assign  data[62]  =  {8'h00,8'h00,8'h00}  ;
assign  data[63]  =  {8'h00,8'h00,8'h00}  ;//8
//D
assign  data[64]  =  {8'h00,8'h00,8'h00}  ;//0
assign  data[65]  =  {8'h00,8'h00,8'h00}  ;
assign  data[66]  =  {8'h00,8'h00,8'h00}  ;
assign  data[67]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[68]  =  {8'h00,8'h00,8'h00}  ;
assign  data[69]  =  {8'h00,8'h00,8'h00}  ;
assign  data[70]  =  {8'h00,8'h00,8'h00}  ;
assign  data[71]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[72]  =  {8'h00,8'h00,8'h00}  ;//1
assign  data[73]  =  {8'h00,8'h00,8'h00}  ;
assign  data[74]  =  {8'h00,8'h00,8'h00}  ;
assign  data[75]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[76]  =  {8'h00,8'h00,8'h00}  ;
assign  data[77]  =  {8'h00,8'h00,8'h00}  ;
assign  data[78]  =  {8'h00,8'h00,8'h00}  ;
assign  data[79]  =  {8'h00,8'h00,8'h00}  ;
assign  data[80]  =  {8'h00,8'h00,8'h00}  ;//2
assign  data[81]  =  {8'h00,8'h00,8'h00}  ;
assign  data[82]  =  {8'hff,8'h00,8'h00}  ;
assign  data[83]  =  {8'hff,8'h00,8'h00}  ;	
assign  data[84]  =  {8'hff,8'h00,8'h00}  ;
assign  data[85]  =  {8'hff,8'h00,8'h00}  ;
assign  data[86]  =  {8'h00,8'h00,8'h00}  ;
assign  data[87]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[88]  =  {8'h00,8'h00,8'h00}  ;//3
assign  data[89]  =  {8'h00,8'h00,8'h00}  ;
assign  data[90]  =  {8'h00,8'h00,8'h00}  ;
assign  data[91]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[92]  =  {8'h00,8'h00,8'h00}  ;
assign  data[93]  =  {8'h00,8'h00,8'h00}  ;
assign  data[94]  =  {8'h00,8'h00,8'h00}  ;
assign  data[95]  =  {8'h00,8'h00,8'h00}  ;
assign  data[96]  =  {8'h00,8'h00,8'h00}  ;//4
assign  data[97]  =  {8'h00,8'h00,8'h00}  ;
assign  data[98]  =  {8'h00,8'h00,8'h00}  ;
assign  data[99]  =  {8'h00,8'h00,8'h00}  ;	
assign  data[100]  =  {8'h00,8'h00,8'h00} ;
assign  data[101]  =  {8'h00,8'h00,8'h00} ;
assign  data[102]  =  {8'h00,8'h00,8'h00} ;
assign  data[103]  =  {8'h00,8'h00,8'h00} ;	
assign  data[104]  =  {8'h00,8'h00,8'h00} ;//5
assign  data[105]  =  {8'hff,8'h00,8'h00} ;
assign  data[106]  =  {8'hff,8'h00,8'h00} ;
assign  data[107]  =  {8'hff,8'h00,8'h00} ;	
assign  data[108]  =  {8'hff,8'h00,8'h00} ;
assign  data[109]  =  {8'hff,8'h00,8'h00} ;
assign  data[110]  =  {8'hff,8'h00,8'h00} ;
assign  data[111]  =  {8'h00,8'h00,8'h00} ;
assign  data[112]  =  {8'h00,8'h00,8'h00} ;//6
assign  data[113]  =  {8'h00,8'h00,8'h00} ;
assign  data[114]  =  {8'h00,8'h00,8'h00} ;
assign  data[115]  =  {8'h00,8'h00,8'h00} ;	
assign  data[116]  =  {8'h00,8'h00,8'h00} ;
assign  data[117]  =  {8'h00,8'h00,8'h00} ;
assign  data[118]  =  {8'h00,8'h00,8'h00} ;
assign  data[119]  =  {8'h00,8'h00,8'h00} ;	
assign  data[120]  =  {8'h00,8'h00,8'h00} ;//7
assign  data[121]  =  {8'h00,8'h00,8'h00} ;
assign  data[122]  =  {8'h00,8'h00,8'h00} ;
assign  data[123]  =  {8'h00,8'h00,8'h00} ;	
assign  data[124]  =  {8'h00,8'h00,8'h00} ;
assign  data[125]  =  {8'h00,8'h00,8'h00} ;
assign  data[126]  =  {8'h00,8'h00,8'h00} ;
assign  data[127]  =  {8'h00,8'h00,8'h00} ;
//L
assign  data[128] =  {8'h00,8'h00,8'h00}  ;//0
assign  data[129] =  {8'h00,8'h00,8'h00}  ;
assign  data[130] =  {8'h00,8'h00,8'h00}  ;
assign  data[131] =  {8'h00,8'h00,8'h00}  ;	
assign  data[132] =  {8'h00,8'h00,8'h00}  ;
assign  data[133] =  {8'h00,8'h00,8'h00}  ;
assign  data[134] =  {8'h00,8'h00,8'h00}  ;
assign  data[135] =  {8'h00,8'h00,8'h00}  ;	
assign  data[136] =  {8'h00,8'h00,8'h00}  ;//1
assign  data[137] =  {8'h00,8'h00,8'h00}  ;
assign  data[138] =  {8'h00,8'h00,8'h00}  ;
assign  data[139] =  {8'h00,8'h00,8'h00}  ;	
assign  data[140] =  {8'h00,8'h00,8'h00}  ;
assign  data[141] =  {8'h00,8'h00,8'h00}  ;
assign  data[142] =  {8'h00,8'h00,8'h00}  ;
assign  data[143] =  {8'h00,8'h00,8'h00}  ;
assign  data[144] =  {8'h00,8'h00,8'h00}  ;//2
assign  data[145] =  {8'h00,8'h00,8'h00}  ;
assign  data[146] =  {8'h00,8'h00,8'h00}  ;
assign  data[147] =  {8'h00,8'h00,8'hff}  ;	
assign  data[148] =  {8'h00,8'h00,8'hff}  ;
assign  data[149] =  {8'h00,8'h00,8'h00}  ;
assign  data[150] =  {8'h00,8'h00,8'h00}  ;
assign  data[151] =  {8'h00,8'h00,8'h00}  ;	
assign  data[152] =  {8'h00,8'h00,8'h00}  ;//3
assign  data[153] =  {8'h00,8'h00,8'h00}  ;
assign  data[154] =  {8'h00,8'h00,8'h00}  ;
assign  data[155] =  {8'h00,8'h00,8'h00}  ;	
assign  data[156] =  {8'h00,8'h00,8'h00}  ;
assign  data[157] =  {8'h00,8'h00,8'h00}  ;
assign  data[158] =  {8'h00,8'h00,8'h00}  ;
assign  data[159] =  {8'h00,8'h00,8'h00}  ;
assign  data[160] =  {8'h00,8'h00,8'h00}  ;//4
assign  data[161] =  {8'h00,8'h00,8'h00}  ;
assign  data[162] =  {8'h00,8'h00,8'hff}  ;
assign  data[163] =  {8'h00,8'h00,8'hff}  ;	
assign  data[164]  = {8'h00,8'h00,8'hff}  ;
assign  data[165]  = {8'h00,8'h00,8'hff}  ;
assign  data[166]  = {8'h00,8'h00,8'h00}  ;
assign  data[167]  = {8'h00,8'h00,8'h00}  ;	
assign  data[168]  = {8'h00,8'h00,8'h00}  ;//5
assign  data[169]  = {8'h00,8'h00,8'h00}  ;
assign  data[170]  = {8'h00,8'h00,8'h00}  ;
assign  data[171]  = {8'h00,8'h00,8'h00}  ;	
assign  data[172]  = {8'h00,8'h00,8'h00}  ;
assign  data[173]  = {8'h00,8'h00,8'h00}  ;
assign  data[174]  = {8'h00,8'h00,8'h00}  ;
assign  data[175]  = {8'h00,8'h00,8'h00}  ;
assign  data[176]  = {8'h00,8'h00,8'h00}  ;//6
assign  data[177]  = {8'h00,8'h00,8'hff}  ;
assign  data[178]  = {8'h00,8'h00,8'hff}  ;
assign  data[179]  = {8'h00,8'h00,8'hff}  ;	
assign  data[180]  = {8'h00,8'h00,8'hff}  ;
assign  data[181]  = {8'h00,8'h00,8'hff}  ;
assign  data[182]  = {8'h00,8'h00,8'hff}  ;
assign  data[183]  = {8'h00,8'h00,8'h00}  ;	
assign  data[184]  = {8'h00,8'h00,8'h00}  ;//7
assign  data[185]  = {8'h00,8'h00,8'h00}  ;
assign  data[186]  = {8'h00,8'h00,8'h00}  ;
assign  data[187]  = {8'h00,8'h00,8'h00}  ;	
assign  data[188]  = {8'h00,8'h00,8'h00}  ;
assign  data[189]  = {8'h00,8'h00,8'h00}  ;
assign  data[190]  = {8'h00,8'h00,8'h00}  ;
assign  data[191] =  {8'h00,8'h00,8'h00}  ;
//R
assign  data[192]=  {8'h00,8'h00,8'h00}  ;//0
assign  data[193]=  {8'h00,8'h00,8'h00}  ;
assign  data[194]=  {8'h00,8'h00,8'h00}  ;
assign  data[195]=  {8'h00,8'h00,8'h00}  ;	
assign  data[196]=  {8'h00,8'h00,8'h00}  ;
assign  data[197]=  {8'h00,8'h00,8'h00}  ;
assign  data[198]=  {8'h00,8'h00,8'h00}  ;
assign  data[199]=  {8'h00,8'h00,8'h00}  ;	
assign  data[200]=  {8'hff,8'hff,8'hff}  ;//1
assign  data[201]=  {8'hff,8'hff,8'hff}  ;
assign  data[202]=  {8'hff,8'hff,8'hff}  ;
assign  data[203]=  {8'hff,8'hff,8'hff}  ;	
assign  data[204]=  {8'hff,8'hff,8'hff}  ;
assign  data[205]=  {8'hff,8'hff,8'hff}  ;
assign  data[206]=  {8'hff,8'hff,8'hff}  ;
assign  data[207]=  {8'hff,8'hff,8'hff}  ;
assign  data[208]=  {8'hff,8'hff,8'hff}  ;//2
assign  data[209]=  {8'h00,8'h00,8'h00}  ;
assign  data[210]=  {8'hff,8'hff,8'hff}  ;
assign  data[211]=  {8'hff,8'hff,8'hff}  ;	
assign  data[212]=  {8'h00,8'h00,8'h00}  ;
assign  data[213]=  {8'hff,8'hff,8'hff}  ;
assign  data[214]=  {8'h00,8'h00,8'h00}  ;
assign  data[215]=  {8'hff,8'hff,8'hff}  ;	
assign  data[216]=  {8'hff,8'hff,8'hff}  ;//3
assign  data[217]=  {8'hff,8'hff,8'hff}  ;
assign  data[218]=  {8'hff,8'hff,8'hff}  ;
assign  data[219]=  {8'h00,8'h00,8'h00}  ;	
assign  data[220]=  {8'h00,8'h00,8'h00}  ;
assign  data[221]=  {8'hff,8'hff,8'hff}  ;
assign  data[222]=  {8'hff,8'hff,8'hff}  ;
assign  data[223]=  {8'hff,8'hff,8'hff}  ;
assign  data[224]=  {8'hff,8'hff,8'hff}  ;//4
assign  data[225]=  {8'h00,8'h00,8'h00}  ;
assign  data[226]=  {8'h00,8'h00,8'h00}  ;
assign  data[227]=  {8'h00,8'h00,8'h00}  ;	
assign  data[228] =  {8'h00,8'h00,8'h00}  ;
assign  data[229] =  {8'h00,8'h00,8'h00}  ;
assign  data[230] =  {8'h00,8'h00,8'h00}  ;
assign  data[231] =  {8'hff,8'hff,8'hff}  ;	
assign  data[232] =  {8'hff,8'hff,8'hff}  ;//5
assign  data[233] =  {8'h00,8'h00,8'h00}  ;
assign  data[234] =  {8'h00,8'h00,8'h00}  ;
assign  data[235] =  {8'h00,8'h00,8'h00}  ;	
assign  data[236] =  {8'h00,8'h00,8'h00}  ;
assign  data[237] =  {8'h00,8'h00,8'h00}  ;
assign  data[238] =  {8'h00,8'h00,8'h00}  ;
assign  data[239] =  {8'h00,8'h00,8'h00}  ;
assign  data[240] =  {8'hff,8'hff,8'hff}  ;//6
assign  data[241] =  {8'hff,8'hff,8'hff}  ;
assign  data[242] =  {8'hff,8'hff,8'hff}  ;
assign  data[243] =  {8'hff,8'hff,8'hff}  ;	
assign  data[244] =  {8'hff,8'hff,8'hff}  ;
assign  data[245] =  {8'hff,8'hff,8'hff}  ;
assign  data[246] =  {8'hff,8'hff,8'hff}  ;
assign  data[247] =  {8'hff,8'hff,8'hff}  ;	
assign  data[248] =  {8'h00,8'h00,8'h00}  ;//7
assign  data[249] =  {8'h00,8'h00,8'h00}  ;
assign  data[250] =  {8'h00,8'h00,8'h00}  ;
assign  data[251] =  {8'h00,8'h00,8'h00}  ;	
assign  data[252] =  {8'h00,8'h00,8'h00}  ;
assign  data[253] =  {8'h00,8'h00,8'h00}  ;
assign  data[254] =  {8'h00,8'h00,8'h00}  ;
assign  data[255] =  {8'h00,8'h00,8'h00}  ;
genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin : flatten_loop
        assign pic_flattened[(i+1)*24-1:i*24] = pic[i];
    end
endgenerate
endmodule