`timescale 1ns / 1ps

//  keccak_ti3.v
module keccak_TI3(
    input clk,
    input rst,
    input wire [1599:0] input_data,
    input wire [1599:0] input_data_1,
    input wire [1599:0] input_data_2,
    input wire [1599:0] input_data_3,
    input wire [1599:0] random_data_1,
    input wire [1599:0] random_data_2,
    input load,
    input start,
    input read,
    input flag_masked_prf,
    output [1599:0] keccak_out,
    output [1599:0] keccak_out_s_1,
    output [1599:0] keccak_out_s_2,
    output [1599:0] keccak_out_s_3,
    output end_op
);
    
    wire    [7:0]       rc_o_w;     //  next round
    reg     [7:0]       rndc_r; 

    wire [1599:0] st_o_w_1;         //  state out
    wire [1599:0] st_o_w_2;         //  state out
    wire [1599:0] st_o_w_3;         //  state out
    reg  [1599:0] st_i_w_1;         //  state in - share 1
    reg  [1599:0] st_i_w_2;         //  state in - share 2
    reg  [1599:0] st_i_w_3;         //  state in - share 3
    
    assign keccak_out = (flag_masked_prf) ? random_data_1 ^ random_data_2 : st_i_w_1 ^ st_i_w_2 ^ st_i_w_3;
    assign keccak_out_s_1 = st_i_w_1;
    assign keccak_out_s_2 = st_i_w_2;
    assign keccak_out_s_3 = st_i_w_3;
    
    //  combinatorial keccak round
    kecti3_round keccak (
        .a_o(st_o_w_1),                        //  state out - share 1
        .b_o(st_o_w_2),                        //  state out - share 2
        .c_o(st_o_w_3),                        //  state out - share 3
        .r_o(rc_o_w),                            //  round out
        .a_i(st_i_w_1),                        //  state in - share 1
        .b_i(st_i_w_2),                        //  state in - share 2
        .c_i(st_i_w_3),                        //  state in - share 3
        .r_i(rndc_r)                            //  round in
    );
    always @(posedge clk) begin
        if(!rst) begin
            st_i_w_1 <= 0;
            st_i_w_2 <= 0;
            st_i_w_3 <= 0;
        end  
        else begin
            if(load & !flag_masked_prf) begin
                st_i_w_1 <= random_data_1;
                st_i_w_2 <= random_data_2;
                st_i_w_3 <= random_data_1 ^ random_data_2 ^ input_data;
            end  
            else if(load & flag_masked_prf) begin
                st_i_w_1 <= input_data_1;
                st_i_w_2 <= input_data_2;
                st_i_w_3 <= input_data_3;
            end                             
            else if(start & !end_op) begin 
                st_i_w_1 <= st_o_w_1;
                st_i_w_2 <= st_o_w_2;
                st_i_w_3 <= st_o_w_3;
            end
            else begin 
                st_i_w_1 <= st_i_w_1;
                st_i_w_2 <= st_i_w_2;
                st_i_w_3 <= st_i_w_3;
            end
        end
    end    
    
    
    always @(posedge clk) begin
        if(!rst) rndc_r <= 0;
        else begin
            if(load | read)                         rndc_r <= 8'h01;
            else if(start & !end_op)                rndc_r <= rc_o_w;
            else                                    rndc_r <= rndc_r;
        end
    end
    
    reg [4:0] round_counter;
    always @(posedge clk) begin
        if(!rst)                                    round_counter <= 0;
        else begin
            if(load | read)                         round_counter <= 0;
            else if(start & !end_op)                round_counter <= round_counter + 1;
            else                                    round_counter <= round_counter;
        end
    end
   
    reg end_op_reg; assign end_op = end_op_reg;
    always @(posedge clk) begin
        if(!rst)                                    end_op_reg <= 0;
        else begin
            if(load | read)                         end_op_reg <= 0;
            else if(round_counter == 23)            end_op_reg <= 1;
            else                                    end_op_reg <= end_op_reg;
        end
    end
    
    
endmodule

//  kecti3_sloth.v
//  Markku-Juhani O. Saarinen <mjos@iki.fi>.  See LICENSE.

//  === Masked Keccak (3-Share Threshold Implementation)
//  This is even more experimental than the rest -- work in progress.

//  Theta (3.2.1), Algorithm 1

module kecti3_lin(
    output wire [1599:0] l_o,
    input wire  [1599:0] x_i
);
    //  Step 1
    wire    [319:0] c_w =   x_i[ 319:   0] ^
                            x_i[ 639: 320] ^
                            x_i[ 959: 640] ^
                            x_i[1279: 960] ^
                            x_i[1599:1280];

    //  Step 2
    wire    [319:0] d_w =   {   c_w[255:  0], c_w[319:256]  } ^
                            {   c_w[ 62:  0], c_w[ 63],
                                c_w[318:256], c_w[319],
                                c_w[254:192], c_w[255],
                                c_w[190:128], c_w[191],
                                c_w[126: 64], c_w[127] };

    //  Step 3
    wire    [1599:0] t_w =  x_i ^ { d_w, d_w, d_w, d_w, d_w };

    //  Rho (3.2.2), Pi (3.2.3), Combined Algorithms 2 and 3

    assign  l_o     =   {   t_w[1405:1344], t_w[1407:1406],
                            t_w[ 982: 960], t_w[1023: 983],
                            t_w[ 920: 896], t_w[ 959: 921],
                            t_w[ 520: 512], t_w[ 575: 521],
                            t_w[ 129: 128], t_w[ 191: 130],
                            t_w[1479:1472], t_w[1535:1480],
                            t_w[1136:1088], t_w[1151:1137],
                            t_w[ 757: 704], t_w[ 767: 758],
                            t_w[ 347: 320], t_w[ 383: 348],
                            t_w[ 292: 256], t_w[ 319: 293],
                            t_w[1325:1280], t_w[1343:1326],
                            t_w[1271:1216], t_w[1279:1272],
                            t_w[ 870: 832], t_w[ 895: 871],
                            t_w[ 505: 448], t_w[ 511: 506],
                            t_w[ 126:  64], t_w[ 127: 127],
                            t_w[1410:1408], t_w[1471:1411],
                            t_w[1042:1024], t_w[1087:1043],
                            t_w[ 700: 640], t_w[ 703: 701],
                            t_w[ 619: 576], t_w[ 639: 620],
                            t_w[ 227: 192], t_w[ 255: 228],
                            t_w[1585:1536], t_w[1599:1586],
                            t_w[1194:1152], t_w[1215:1195],
                            t_w[ 788: 768], t_w[ 831: 789],
                            t_w[ 403: 384], t_w[ 447: 404],
                            t_w[  63:   0] };
endmodule

//  Pairwise Threshold Chi

module kecti3_tchi(
    output wire [319:0] f_o,
    input wire  [319:0] x_i,
    input wire  [319:0] y_i
);

    wire [319:0] x1_w = { x_i[ 63:  0], x_i[319: 64] };
    wire [319:0] x2_w = { x_i[127:  0], x_i[319:128] };
    wire [319:0] y1_w = { y_i[ 63:  0], y_i[319: 64] };
    wire [319:0] y2_w = { y_i[127:  0], y_i[319:128] };

    assign f_o = x_i ^ ( ~x1_w & x2_w ) ^ ( x1_w & y2_w ) ^ ( y1_w & x2_w );

endmodule

//  threshold round

module kecti3_round (
    output wire [1599:0] a_o,           //  shares out
    output wire [1599:0] b_o,
    output wire [1599:0] c_o,
    input wire  [1599:0] a_i,           //  shares in
    input wire  [1599:0] b_i,
    input wire  [1599:0] c_i,
    output wire [7:0]    r_o,           //  rc out
    input wire  [7:0]    r_i            //  rc in
);

    //  Linear layers for shares A, B, C
    wire    [1599:0]    la_w, lb_w, lc_w;
    kecti3_lin  lin_a   (   .l_o(la_w), .x_i(a_i) );
    kecti3_lin  lin_b   (   .l_o(lb_w), .x_i(b_i) );
    kecti3_lin  lin_c   (   .l_o(lc_w), .x_i(c_i) );

    //  Nonlinear ops on shares A, B, C
    wire    [1599:0]    a_w;            //  share without rc
    genvar i;

    generate
        for (i = 0; i < 1600; i = i + 320) begin
            kecti3_tchi tchi_a  (   .f_o(  a_w[319 + i: i]  ),
                                    .x_i( la_w[319 + i: i]  ),
                                    .y_i( lb_w[319 + i: i]  )   );
            kecti3_tchi tchi_b  (   .f_o(  b_o[319 + i: i]  ),
                                    .x_i( lb_w[319 + i: i]  ),
                                    .y_i( lc_w[319 + i: i]  )   );
            kecti3_tchi tchi_c  (   .f_o(  c_o[319 + i: i]  ),
                                    .x_i( lc_w[319 + i: i]  ),
                                    .y_i( la_w[319 + i: i]  )   );
        end
    endgenerate

    //  Iota: spread round constant bits into least signigicant word
    assign  a_o =   {   a_w[1599:64],
                        r_i[6] ^ a_w[63], a_w[62:32],
                        r_i[5] ^ a_w[31], a_w[30:16],
                        r_i[4] ^ a_w[15], a_w[14: 8],
                        r_i[3] ^ a_w[ 7], a_w[ 6: 4],
                        r_i[2] ^ a_w[ 3], a_w[ 2],
                        r_i[1] ^ a_w[ 1],
                        r_i[0] ^ a_w[ 0]    };

    //  This matrix implements 7 steps of the LFSR described in Algorithm 5;
    //  converted from Galois to Fibonacci representation and combined.
    assign  r_o =   ({8{r_i[0]}} & 8'h1A) ^ ({8{r_i[1]}} & 8'h34) ^
                    ({8{r_i[2]}} & 8'h68) ^ ({8{r_i[3]}} & 8'hD0) ^
                    ({8{r_i[4]}} & 8'hBA) ^ ({8{r_i[5]}} & 8'h6E) ^
                    ({8{r_i[6]}} & 8'hC6) ^ ({8{r_i[7]}} & 8'h8D);
endmodule

