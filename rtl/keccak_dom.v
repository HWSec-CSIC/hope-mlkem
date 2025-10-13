`timescale 1ns / 1ps

module keccak_DOM(
    input clk,
    input rst,
    input wire [1599:0] input_data,
    input wire [1599:0] input_data_1,
    input wire [1599:0] input_data_2,
    input wire [1599:0] input_data_3,
    input wire [1599:0] input_data_4,
    input wire [1599:0] random_data_1,
    input wire [1599:0] random_data_2,
    input wire [1599:0] random_data_3,
    input wire  [1599:0] rand_chi_1,  //  random share 1
    input wire  [1599:0] rand_chi_2,  //  random share 2
    input wire  [1599:0] rand_chi_3,  //  random share 3
    input wire  [1599:0] rand_chi_4,  //  random share 4
    input wire  [1599:0] rand_chi_5,  //  random share 5
    input wire  [1599:0] rand_chi_6,  //  random share 6
    input load,
    input start,
    input read,
    input flag_masked_prf,
    output [1599:0] keccak_out,
    output [1599:0] keccak_out_s_1,
    output [1599:0] keccak_out_s_2,
    output [1599:0] keccak_out_s_3,
    output [1599:0] keccak_out_s_4,
    output end_op
);
    
    wire    [7:0]       rc_o_w;     //  next round
    reg     [7:0]       rndc_r; 

    wire [1599:0] st_o_w_1;         //  state out
    wire [1599:0] st_o_w_2;         //  state out
    wire [1599:0] st_o_w_3;         //  state out
    wire [1599:0] st_o_w_4;         //  state out
    reg  [1599:0] st_i_w_1;         //  state in - share 1
    reg  [1599:0] st_i_w_2;         //  state in - share 2
    reg  [1599:0] st_i_w_3;         //  state in - share 3
    reg  [1599:0] st_i_w_4;         //  state in - share 4
    
    assign keccak_out = (flag_masked_prf) ? random_data_1 : st_i_w_1 ^ st_i_w_2 ^ st_i_w_3 ^ st_i_w_4;
    // assign keccak_out = st_i_w_1 ^ st_i_w_2 ^ st_i_w_3 ^ st_i_w_4;
    assign keccak_out_s_1 = st_i_w_1;
    assign keccak_out_s_2 = st_i_w_2;
    assign keccak_out_s_3 = st_i_w_3;
    assign keccak_out_s_4 = st_i_w_4;
    
    //  combinatorial keccak round
    keccak_round_DOM keccak (
        .s_o_1(st_o_w_1),                        //  state out - share 1
        .s_o_2(st_o_w_2),                        //  state out - share 2
        .s_o_3(st_o_w_3),                        //  state out - share 3
        .s_o_4(st_o_w_4),                        //  state out - share 4
        .r_o(rc_o_w),                            //  round out
        .s_i_1(st_i_w_1),                        //  state in - share 1
        .s_i_2(st_i_w_2),                        //  state in - share 2
        .s_i_3(st_i_w_3),                        //  state in - share 3
        .s_i_4(st_i_w_4),                        //  state in - share 4
        .r_i(rndc_r),                            //  round in
        .rand_chi_1(rand_chi_1),                //  random share 1
        .rand_chi_2(rand_chi_2),                //  random share 2
        .rand_chi_3(rand_chi_3),                //  random share 3
        .rand_chi_4(rand_chi_4),                //  random share 4
        .rand_chi_5(rand_chi_5),                //  random share 5
        .rand_chi_6(rand_chi_6)                 //  random share 6
    );
    
    always @(posedge clk) begin
        if(!rst) begin
            st_i_w_1 <= 0;
            st_i_w_2 <= 0;
            st_i_w_3 <= 0;
            st_i_w_4 <= 0;
        end  
        else begin
            if(load & !flag_masked_prf) begin
                st_i_w_1 <= random_data_1 ^ random_data_2 ^ random_data_3 ^ input_data;
                st_i_w_2 <= random_data_1;
                st_i_w_3 <= random_data_2;
                st_i_w_4 <= random_data_3;
            end  
            else if(load & flag_masked_prf) begin
                st_i_w_1 <= input_data_1;
                st_i_w_2 <= input_data_2;
                st_i_w_3 <= input_data_3;
                st_i_w_4 <= input_data_4;
            end                             
            else if(start & !end_op) begin 
                st_i_w_1 <= st_o_w_1;
                st_i_w_2 <= st_o_w_2;
                st_i_w_3 <= st_o_w_3;
                st_i_w_4 <= st_o_w_4;
            end
            else begin 
                st_i_w_1 <= st_i_w_1;
                st_i_w_2 <= st_i_w_2;
                st_i_w_3 <= st_i_w_3;
                st_i_w_4 <= st_i_w_4;
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


module keccak_round_DOM(
    output wire [1599:0] s_o_1,         //  state out
    output wire [1599:0] s_o_2,         //  state out
    output wire [1599:0] s_o_3,         //  state out
    output wire [1599:0] s_o_4,         //  state out
    output wire [7:0]    r_o,           //  rc out
    input wire  [1599:0] s_i_1,         //  state in - share 1
    input wire  [1599:0] s_i_2,         //  state in - share 2
    input wire  [1599:0] s_i_3,         //  state in - share 3
    input wire  [1599:0] s_i_4,         //  state in - share 4
    input wire  [7:0]    r_i,            //  rc in,
    input wire  [1599:0] rand_chi_1,  //  random share 1
    input wire  [1599:0] rand_chi_2,  //  random share 2
    input wire  [1599:0] rand_chi_3,  //  random share 3
    input wire  [1599:0] rand_chi_4,  //  random share 4
    input wire  [1599:0] rand_chi_5,  //  random share 5
    input wire  [1599:0] rand_chi_6   //  random share 6
);

    wire [1599:0] rp_w_1;  
    wire [1599:0] rp_w_2;
    wire [1599:0] rp_w_3; 
    wire [1599:0] rp_w_4;   

    // ThetaRho shares 1
    ThetaRhoPi trp_1 ( .s_i(s_i_1), .s_o(rp_w_1));
    // ThetaRho shares 2
    ThetaRhoPi trp_2 ( .s_i(s_i_2), .s_o(rp_w_2));
    // ThetaRho shares 1
    ThetaRhoPi trp_3 ( .s_i(s_i_3), .s_o(rp_w_3));
    // ThetaRho shares 1
    ThetaRhoPi trp_4 ( .s_i(s_i_4), .s_o(rp_w_4));
    
    wire [1599:0] chi_w_1;
    wire [1599:0] chi_w_2;
    wire [1599:0] chi_w_3;
    wire [1599:0] chi_w_4;

    // Chi
    ChiDOM chi (
        .st_i_1(rp_w_1), 
        .st_i_2(rp_w_2), 
        .st_i_3(rp_w_3), 
        .st_i_4(rp_w_4),
        .rand_chi_1(rand_chi_1), 
        .rand_chi_2(rand_chi_2),
        .rand_chi_3(rand_chi_3),
        .rand_chi_4(rand_chi_4),
        .rand_chi_5(rand_chi_5),
        .rand_chi_6(rand_chi_6),
        .st_o_1(chi_w_1), 
        .st_o_2(chi_w_2), 
        .st_o_3(chi_w_3), 
        .st_o_4(chi_w_4)
    );

    //  Iota (3.2.5)
    /*
    iota iota_1 (.chi_w(chi_w_1),  .s_o(s_o_1),  .r_i(r_i));
    iota iota_2 (.chi_w(chi_w_2),  .s_o(s_o_2),  .r_i(r_i));
    iota iota_3 (.chi_w(chi_w_3),  .s_o(s_o_3),  .r_i(r_i));
    iota iota_4 (.chi_w(chi_w_4),  .s_o(s_o_4),  .r_i(r_i));
    */
    iota iota   (.chi_w(chi_w_1),  .s_o(s_o_1),  .r_i(r_i));
    assign s_o_2 = chi_w_2;
    assign s_o_3 = chi_w_3;
    assign s_o_4 = chi_w_4;
    
    //  This matrix implements 7 steps of the LFSR described in Algorithm 5;
    //  converted from Galois to Fibonacci representation and combined.
    assign  r_o =   ({8{r_i[0]}} & 8'h1A) ^ ({8{r_i[1]}} & 8'h34) ^
                    ({8{r_i[2]}} & 8'h68) ^ ({8{r_i[3]}} & 8'hD0) ^
                    ({8{r_i[4]}} & 8'hBA) ^ ({8{r_i[5]}} & 8'h6E) ^
                    ({8{r_i[6]}} & 8'hC6) ^ ({8{r_i[7]}} & 8'h8D);

endmodule


module ThetaRhoPi (
    input wire [1599:0] s_i,  //  state in
    output wire [1599:0] s_o  //  state out
);

    //  Theta (3.2.1), Algorithm 1

     //  Step 1
    wire [319:0]    c_w =   (   s_i[ 319:   0] ^
                                s_i[ 639: 320] ^
                                s_i[ 959: 640] ^
                                s_i[1279: 960] ^
                                s_i[1599:1280]  );

    //  Step 2
    wire [319:0]    d_w =   {   c_w[255:  0], c_w[319:256] } ^
                            {   c_w[ 62:  0], c_w[ 63],
                                c_w[318:256], c_w[319],
                                c_w[254:192], c_w[255],
                                c_w[190:128], c_w[191],
                                c_w[126: 64], c_w[127] };

    //  Step 3
    wire [1599:0]   th_w =  s_i ^ { d_w, d_w, d_w, d_w, d_w };

    //  Rho (3.2.2), Pi (3.2.3), Combined Algorithms 2 and 3

    wire [1599:0]   rp_w =  {   th_w[1405:1344], th_w[1407:1406],
                                th_w[ 982: 960], th_w[1023: 983],
                                th_w[ 920: 896], th_w[ 959: 921],
                                th_w[ 520: 512], th_w[ 575: 521],
                                th_w[ 129: 128], th_w[ 191: 130],
                                th_w[1479:1472], th_w[1535:1480],
                                th_w[1136:1088], th_w[1151:1137],
                                th_w[ 757: 704], th_w[ 767: 758],
                                th_w[ 347: 320], th_w[ 383: 348],
                                th_w[ 292: 256], th_w[ 319: 293],
                                th_w[1325:1280], th_w[1343:1326],
                                th_w[1271:1216], th_w[1279:1272],
                                th_w[ 870: 832], th_w[ 895: 871],
                                th_w[ 505: 448], th_w[ 511: 506],
                                th_w[ 126:  64], th_w[ 127: 127],
                                th_w[1410:1408], th_w[1471:1411],
                                th_w[1042:1024], th_w[1087:1043],
                                th_w[ 700: 640], th_w[ 703: 701],
                                th_w[ 619: 576], th_w[ 639: 620],
                                th_w[ 227: 192], th_w[ 255: 228],
                                th_w[1585:1536], th_w[1599:1586],
                                th_w[1194:1152], th_w[1215:1195],
                                th_w[ 788: 768], th_w[ 831: 789],
                                th_w[ 403: 384], th_w[ 447: 404],
                                th_w[  63:   0] };

    assign s_o = rp_w;

endmodule


module ChiDOM (
    input [1599:0] st_i_1,  //  state in - share 1
    input [1599:0] st_i_2,  //  state in - share 2
    input [1599:0] st_i_3,  //  state in - share 3
    input [1599:0] st_i_4,  //  state in - share 4

    input [1599:0] rand_chi_1,  //  random share 1
    input [1599:0] rand_chi_2,  //  random share 2
    input [1599:0] rand_chi_3,  //  random share 3
    input [1599:0] rand_chi_4,  //  random share 4  
    input [1599:0] rand_chi_5,  //  random share 5
    input [1599:0] rand_chi_6,  //  random share 6

    output [1599:0] st_o_1,  //  state out - share 1
    output [1599:0] st_o_2,  //  state out - share 2
    output [1599:0] st_o_3,  //  state out - share 3
    output [1599:0] st_o_4   //  state out - share
);

    wire [63:0] sti_1 [0:24];  //  Theta shares 1
    wire [63:0] sti_2 [0:24];  //  Theta shares 2
    wire [63:0] sti_3 [0:24];  //  Theta shares 3
    wire [63:0] sti_4 [0:24];  //  Theta shares 4

    wire [63:0] z_1 [0:24]; 
    wire [63:0] z_2 [0:24];
    wire [63:0] z_3 [0:24];
    wire [63:0] z_4 [0:24];
    wire [63:0] z_5 [0:24];
    wire [63:0] z_6 [0:24];

    genvar i;
    generate 
        for (i = 0; i < 25; i = i + 1) begin : gen_st
            assign sti_1[i] = st_i_1[64*i +: 64];
            assign sti_2[i] = st_i_2[64*i +: 64];
            assign sti_3[i] = st_i_3[64*i +: 64];
            assign sti_4[i] = st_i_4[64*i +: 64];

            assign z_1[i] = rand_chi_1[64*i +: 64];
            assign z_2[i] = rand_chi_2[64*i +: 64];
            assign z_3[i] = rand_chi_3[64*i +: 64];
            assign z_4[i] = rand_chi_4[64*i +: 64];
            assign z_5[i] = rand_chi_5[64*i +: 64];
            assign z_6[i] = rand_chi_6[64*i +: 64];
        end
    endgenerate

    generate
        for (i = 0; i < 25; i = i + 5) begin : gen_st_chi

            wire [5*64-1:0] bc_1;  //  Theta shares 1
            wire [5*64-1:0] bc_2;  //  Theta shares 2
            wire [5*64-1:0] bc_3;  //  Theta
            wire [5*64-1:0] bc_4;  //  Theta shares 4

            //  Assigning the 5 shares to the bc_1, bc_2, bc_3, and bc_4
            assign bc_1 = {sti_1[i+4], sti_1[i+3], sti_1[i+2], sti_1[i+1], sti_1[i]};
            assign bc_2 = {sti_2[i+4], sti_2[i+3], sti_2[i+2], sti_2[i+1], sti_2[i]};
            assign bc_3 = {sti_3[i+4], sti_3[i+3], sti_3[i+2], sti_3[i+1], sti_3[i]};
            assign bc_4 = {sti_4[i+4], sti_4[i+3], sti_4[i+2], sti_4[i+1], sti_4[i]};

            isw_and_dom #(.LANE(1)) isw_1 (
                .sti_1(sti_1[i]), .sti_2(sti_2[i]), .sti_3(sti_3[i]), .sti_4(sti_4[i]),
                .bc_1(bc_1), .bc_2(bc_2), .bc_3(bc_3), .bc_4(bc_4),
                .z_1(z_1[i]), .z_2(z_2[i]), .z_3(z_3[i]), .z_4(z_4[i]), .z_5(z_5[i]), .z_6(z_6[i]),
                .sto_1(st_o_1[64*i +: 64]), .sto_2(st_o_2[64*i +: 64]),
                .sto_3(st_o_3[64*i +: 64]), .sto_4(st_o_4[64*i +: 64])
            );
            isw_and_dom #(.LANE(2)) isw_2 (
                .sti_1(sti_1[i+1]), .sti_2(sti_2[i+1]), .sti_3(sti_3[i+1]), .sti_4(sti_4[i+1]),
                .bc_1(bc_1), .bc_2(bc_2), .bc_3(bc_3), .bc_4(bc_4),
                .z_1(z_1[i+1]), .z_2(z_2[i+1]), .z_3(z_3[i+1]), .z_4(z_4[i+1]), .z_5(z_5[i+1]), .z_6(z_6[i+1]),
                .sto_1(st_o_1[64*(i+1) +: 64]), .sto_2(st_o_2[64*(i+1) +: 64]),
                .sto_3(st_o_3[64*(i+1) +: 64]), .sto_4(st_o_4[64*(i+1) +: 64])
            );
            isw_and_dom #(.LANE(3)) isw_3 (
                .sti_1(sti_1[i+2]), .sti_2(sti_2[i+2]), .sti_3(sti_3[i+2]), .sti_4(sti_4[i+2]),
                .bc_1(bc_1), .bc_2(bc_2), .bc_3(bc_3), .bc_4(bc_4),
                .z_1(z_1[i+2]), .z_2(z_2[i+2]), .z_3(z_3[i+2]), .z_4(z_4[i+2]), .z_5(z_5[i+2]), .z_6(z_6[i+2]),
                .sto_1(st_o_1[64*(i+2) +: 64]), .sto_2(st_o_2[64*(i+2) +: 64]),
                .sto_3(st_o_3[64*(i+2) +: 64]), .sto_4(st_o_4[64*(i+2) +: 64])
            );
            isw_and_dom #(.LANE(4)) isw_4 (
                .sti_1(sti_1[i+3]), .sti_2(sti_2[i+3]), .sti_3(sti_3[i+3]), .sti_4(sti_4[i+3]),
                .bc_1(bc_1), .bc_2(bc_2), .bc_3(bc_3), .bc_4(bc_4),
                .z_1(z_1[i+3]), .z_2(z_2[i+3]), .z_3(z_3[i+3]), .z_4(z_4[i+3]), .z_5(z_5[i+3]), .z_6(z_6[i+3]),
                .sto_1(st_o_1[64*(i+3) +: 64]), .sto_2(st_o_2[64*(i+3) +: 64]),
                .sto_3(st_o_3[64*(i+3) +: 64]), .sto_4(st_o_4[64*(i+3) +: 64])
            );
            isw_and_dom #(.LANE(5)) isw_5 (
                .sti_1(sti_1[i+4]), .sti_2(sti_2[i+4]), .sti_3(sti_3[i+4]), .sti_4(sti_4[i+4]),
                .bc_1(bc_1), .bc_2(bc_2), .bc_3(bc_3), .bc_4(bc_4),
                .z_1(z_1[i+4]), .z_2(z_2[i+4]), .z_3(z_3[i+4]), .z_4(z_4[i+4]), .z_5(z_5[i+4]), .z_6(z_6[i+4]),
                .sto_1(st_o_1[64*(i+4) +: 64]), .sto_2(st_o_2[64*(i+4) +: 64]),
                .sto_3(st_o_3[64*(i+4) +: 64]), .sto_4(st_o_4[64*(i+4) +: 64])
            );
        end

    endgenerate

    /*
    st_1[0] = st_1[0] ^ bc_1[(0+2)%5] ^ (((bc_1[(0+1)%5])&(bc_1[(0+2)%5])) ^ ((((bc_1[(0+1)%5])&(bc_2[(0+2)%5])) ^ z_1) ^ (((bc_1[(0+1)%5])&(bc_3[(0+2)%5])) ^ z_2) ^ (((bc_1[(0+1)%5])&(bc_4[(0+2)%5])) ^ z_4)));
    st_2[0] = st_2[0] ^ bc_2[(0+2)%5] ^ (((bc_2[(0+1)%5])&(bc_2[(0+2)%5])) ^ ((((bc_2[(0+1)%5])&(bc_3[(0+2)%5])) ^ z_3) ^ (((bc_2[(0+1)%5])&(bc_4[(0+2)%5])) ^ z_5) ^ (((bc_2[(0+1)%5])&(bc_1[(0+2)%5])) ^ z_1)));
    st_3[0] = st_3[0] ^ bc_3[(0+2)%5] ^ (((bc_3[(0+1)%5])&(bc_3[(0+2)%5])) ^ ((((bc_3[(0+1)%5])&(bc_4[(0+2)%5])) ^ z_6)) ^ ((((bc_3[(0+1)%5])&(bc_1[(0+2)%5])) ^ z_2) ^ (((bc_3[(0+1)%5])&(bc_2[(0+2)%5])) ^ z_3)));
    st_4[0] = st_4[0] ^ bc_4[(0+2)%5] ^ (((bc_4[(0+1)%5])&(bc_4[(0+2)%5])) ^ ((((bc_4[(0+1)%5])&(bc_1[(0+2)%5])) ^ z_4) ^ (((bc_4[(0+1)%5])&(bc_2[(0+2)%5])) ^ z_5) ^ (((bc_4[(0+1)%5])&(bc_3[(0+2)%5])) ^ z_6)));

    st_1[1] = st_1[1] ^ bc_1[(1+2)%5] ^ (((bc_1[(1+1)%5])&(bc_1[(1+2)%5])) ^ ((((bc_1[(1+1)%5])&(bc_2[(1+2)%5])) ^ z_1) ^ (((bc_1[(1+1)%5])&(bc_3[(1+2)%5])) ^ z_2) ^ (((bc_1[(1+1)%5])&(bc_4[(1+2)%5])) ^ z_4)));
    st_2[1] = st_2[1] ^ bc_2[(1+2)%5] ^ (((bc_2[(1+1)%5])&(bc_2[(1+2)%5])) ^ ((((bc_2[(1+1)%5])&(bc_3[(1+2)%5])) ^ z_3) ^ (((bc_2[(1+1)%5])&(bc_4[(1+2)%5])) ^ z_5) ^ (((bc_2[(1+1)%5])&(bc_1[(1+2)%5])) ^ z_1)));
    st_3[1] = st_3[1] ^ bc_3[(1+2)%5] ^ (((bc_3[(1+1)%5])&(bc_3[(1+2)%5])) ^ ((((bc_3[(1+1)%5])&(bc_4[(1+2)%5])) ^ z_6)) ^ ((((bc_3[(1+1)%5])&(bc_1[(1+2)%5])) ^ z_2) ^ (((bc_3[(1+1)%5])&(bc_2[(1+2)%5])) ^ z_3)));
    st_4[1] = st_4[1] ^ bc_4[(1+2)%5] ^ (((bc_4[(1+1)%5])&(bc_4[(1+2)%5])) ^ ((((bc_4[(1+1)%5])&(bc_1[(1+2)%5])) ^ z_4) ^ (((bc_4[(1+1)%5])&(bc_2[(1+2)%5])) ^ z_5) ^ (((bc_4[(1+1)%5])&(bc_3[(1+2)%5])) ^ z_6)));

    */



endmodule


module isw_and_dom #(
    parameter LANE = 1
)
(
    input [63:0] sti_1,
    input [63:0] sti_2,  
    input [63:0] sti_3,
    input [63:0] sti_4,
    input [5*64-1:0] bc_1,
    input [5*64-1:0] bc_2,
    input [5*64-1:0] bc_3,
    input [5*64-1:0] bc_4,
    input [63:0] z_1,
    input [63:0] z_2,
    input [63:0] z_3,
    input [63:0] z_4,
    input [63:0] z_5,
    input [63:0] z_6,
    output [63:0] sto_1,
    output [63:0] sto_2,
    output [63:0] sto_3,
    output [63:0] sto_4
);

generate

    if(LANE == 1) begin
        assign sto_1 = sti_1 ^ bc_1[64*2 +: 64] ^ (((bc_1[64*1 +: 64])&(bc_1[64*2 +: 64])) ^ ((((bc_1[64*1 +: 64])&(bc_2[64*2 +: 64])) ^ z_1) ^ (((bc_1[64*1 +: 64])&(bc_3[64*2 +: 64])) ^ z_2) ^ (((bc_1[64*1 +: 64])&(bc_4[64*2 +: 64])) ^ z_4)));
        assign sto_2 = sti_2 ^ bc_2[64*2 +: 64] ^ (((bc_2[64*1 +: 64])&(bc_2[64*2 +: 64])) ^ ((((bc_2[64*1 +: 64])&(bc_3[64*2 +: 64])) ^ z_3) ^ (((bc_2[64*1 +: 64])&(bc_4[64*2 +: 64])) ^ z_5) ^ (((bc_2[64*1 +: 64])&(bc_1[64*2 +: 64])) ^ z_1)));
        assign sto_3 = sti_3 ^ bc_3[64*2 +: 64] ^ (((bc_3[64*1 +: 64])&(bc_3[64*2 +: 64])) ^ ((((bc_3[64*1 +: 64])&(bc_4[64*2 +: 64])) ^ z_6)) ^ ((((bc_3[64*1 +: 64])&(bc_1[64*2 +: 64])) ^ z_2) ^ (((bc_3[64*1 +: 64])&(bc_2[64*2 +: 64])) ^ z_3)));
        assign sto_4 = sti_4 ^ bc_4[64*2 +: 64] ^ (((bc_4[64*1 +: 64])&(bc_4[64*2 +: 64])) ^ ((((bc_4[64*1 +: 64])&(bc_1[64*2 +: 64])) ^ z_4) ^ (((bc_4[64*1 +: 64])&(bc_2[64*2 +: 64])) ^ z_5) ^ (((bc_4[64*1 +: 64])&(bc_3[64*2 +: 64])) ^ z_6)));
    end
    else if(LANE == 2) begin
        assign sto_1 = sti_1 ^ bc_1[64*3 +: 64] ^ (((bc_1[64*2 +: 64])&(bc_1[64*3 +: 64])) ^ ((((bc_1[64*2 +: 64])&(bc_2[64*3 +: 64])) ^ z_1) ^ (((bc_1[64*2 +: 64])&(bc_3[64*3 +: 64])) ^ z_2) ^ (((bc_1[64*2 +: 64])&(bc_4[64*3 +: 64])) ^ z_4)));
        assign sto_2 = sti_2 ^ bc_2[64*3 +: 64] ^ (((bc_2[64*2 +: 64])&(bc_2[64*3 +: 64])) ^ ((((bc_2[64*2 +: 64])&(bc_3[64*3 +: 64])) ^ z_3) ^ (((bc_2[64*2 +: 64])&(bc_4[64*3 +: 64])) ^ z_5) ^ (((bc_2[64*2 +: 64])&(bc_1[64*3 +: 64])) ^ z_1)));
        assign sto_3 = sti_3 ^ bc_3[64*3 +: 64] ^ (((bc_3[64*2 +: 64])&(bc_3[64*3 +: 64])) ^ ((((bc_3[64*2 +: 64])&(bc_4[64*3 +: 64])) ^ z_6)) ^ ((((bc_3[64*2 +: 64])&(bc_1[64*3 +: 64])) ^ z_2) ^ (((bc_3[64*2 +: 64])&(bc_2[64*3 +: 64])) ^ z_3)));
        assign sto_4 = sti_4 ^ bc_4[64*3 +: 64] ^ (((bc_4[64*2 +: 64])&(bc_4[64*3 +: 64])) ^ ((((bc_4[64*2 +: 64])&(bc_1[64*3 +: 64])) ^ z_4) ^ (((bc_4[64*2 +: 64])&(bc_2[64*3 +: 64])) ^ z_5) ^ (((bc_4[64*2 +: 64])&(bc_3[64*3 +: 64])) ^ z_6)));
    end
    else if(LANE == 3) begin
        assign sto_1 = sti_1 ^ bc_1[64*4 +: 64] ^ (((bc_1[64*3 +: 64])&(bc_1[64*4 +: 64])) ^ ((((bc_1[64*3 +: 64])&(bc_2[64*4 +: 64])) ^ z_1) ^ (((bc_1[64*3 +: 64])&(bc_3[64*4 +: 64])) ^ z_2) ^ (((bc_1[64*3 +: 64])&(bc_4[64*4 +: 64])) ^ z_4)));
        assign sto_2 = sti_2 ^ bc_2[64*4 +: 64] ^ (((bc_2[64*3 +: 64])&(bc_2[64*4 +: 64])) ^ ((((bc_2[64*3 +: 64])&(bc_3[64*4 +: 64])) ^ z_3) ^ (((bc_2[64*3 +: 64])&(bc_4[64*4 +: 64])) ^ z_5) ^ (((bc_2[64*3 +: 64])&(bc_1[64*4 +: 64])) ^ z_1)));
        assign sto_3 = sti_3 ^ bc_3[64*4 +: 64] ^ (((bc_3[64*3 +: 64])&(bc_3[64*4 +: 64])) ^ ((((bc_3[64*3 +: 64])&(bc_4[64*4 +: 64])) ^ z_6)) ^ ((((bc_3[64*3 +: 64])&(bc_1[64*4 +: 64])) ^ z_2) ^ (((bc_3[64*3 +: 64])&(bc_2[64*4 +: 64])) ^ z_3)));
        assign sto_4 = sti_4 ^ bc_4[64*4 +: 64] ^ (((bc_4[64*3 +: 64])&(bc_4[64*4 +: 64])) ^ ((((bc_4[64*3 +: 64])&(bc_1[64*4 +: 64])) ^ z_4) ^ (((bc_4[64*3 +: 64])&(bc_2[64*4 +: 64])) ^ z_5) ^ (((bc_4[64*3 +: 64])&(bc_3[64*4 +: 64])) ^ z_6)));
    end
    else if(LANE == 4) begin
        assign sto_1 = sti_1 ^ bc_1[64*0 +: 64] ^ (((bc_1[64*4 +: 64])&(bc_1[64*0 +: 64])) ^ ((((bc_1[64*4 +: 64])&(bc_2[64*0 +: 64])) ^ z_1) ^ (((bc_1[64*4 +: 64])&(bc_3[64*0 +: 64])) ^ z_2) ^ (((bc_1[64*4 +: 64])&(bc_4[64*0 +: 64])) ^ z_4)));
        assign sto_2 = sti_2 ^ bc_2[64*0 +: 64] ^ (((bc_2[64*4 +: 64])&(bc_2[64*0 +: 64])) ^ ((((bc_2[64*4 +: 64])&(bc_3[64*0 +: 64])) ^ z_3) ^ (((bc_2[64*4 +: 64])&(bc_4[64*0 +: 64])) ^ z_5) ^ (((bc_2[64*4 +: 64])&(bc_1[64*0 +: 64])) ^ z_1)));
        assign sto_3 = sti_3 ^ bc_3[64*0 +: 64] ^ (((bc_3[64*4 +: 64])&(bc_3[64*0 +: 64])) ^ ((((bc_3[64*4 +: 64])&(bc_4[64*0 +: 64])) ^ z_6)) ^ ((((bc_3[64*4 +: 64])&(bc_1[64*0 +: 64])) ^ z_2) ^ (((bc_3[64*4 +: 64])&(bc_2[64*0 +: 64])) ^ z_3)));
        assign sto_4 = sti_4 ^ bc_4[64*0 +: 64] ^ (((bc_4[64*4 +: 64])&(bc_4[64*0 +: 64])) ^ ((((bc_4[64*4 +: 64])&(bc_1[64*0 +: 64])) ^ z_4) ^ (((bc_4[64*4 +: 64])&(bc_2[64*0 +: 64])) ^ z_5) ^ (((bc_4[64*4 +: 64])&(bc_3[64*0 +: 64])) ^ z_6)));
    end
    else begin
        assign sto_1 = sti_1 ^ bc_1[64*1 +: 64] ^ (((bc_1[64*0 +: 64])&(bc_1[64*1 +: 64])) ^ ((((bc_1[64*0 +: 64])&(bc_2[64*1 +: 64])) ^ z_1) ^ (((bc_1[64*0 +: 64])&(bc_3[64*1 +: 64])) ^ z_2) ^ (((bc_1[64*0 +: 64])&(bc_4[64*1 +: 64])) ^ z_4)));
        assign sto_2 = sti_2 ^ bc_2[64*1 +: 64] ^ (((bc_2[64*0 +: 64])&(bc_2[64*1 +: 64])) ^ ((((bc_2[64*0 +: 64])&(bc_3[64*1 +: 64])) ^ z_3) ^ (((bc_2[64*0 +: 64])&(bc_4[64*1 +: 64])) ^ z_5) ^ (((bc_2[64*0 +: 64])&(bc_1[64*1 +: 64])) ^ z_1)));
        assign sto_3 = sti_3 ^ bc_3[64*1 +: 64] ^ (((bc_3[64*0 +: 64])&(bc_3[64*1 +: 64])) ^ ((((bc_3[64*0 +: 64])&(bc_4[64*1 +: 64])) ^ z_6)) ^ ((((bc_3[64*0 +: 64])&(bc_1[64*1 +: 64])) ^ z_2) ^ (((bc_3[64*0 +: 64])&(bc_2[64*1 +: 64])) ^ z_3)));
        assign sto_4 = sti_4 ^ bc_4[64*1 +: 64] ^ (((bc_4[64*0 +: 64])&(bc_4[64*1 +: 64])) ^ ((((bc_4[64*0 +: 64])&(bc_1[64*1 +: 64])) ^ z_4) ^ (((bc_4[64*0 +: 64])&(bc_2[64*1 +: 64])) ^ z_5) ^ (((bc_4[64*0 +: 64])&(bc_3[64*1 +: 64])) ^ z_6)));
    end
endgenerate

endmodule


module iota (
    input wire [1599:0] chi_w,   //  state in
    input wire [7:0] r_i,        //  round index in
    output wire [1599:0] s_o     //  state out
);

    //  Expands low 7 bits into 64 words for lane (0,) as per Algorithm 6.
    assign  s_o =   {   chi_w[1599:64],
                            r_i[6] ^ chi_w[63], chi_w[62:32],
                            r_i[5] ^ chi_w[31], chi_w[30:16],
                            r_i[4] ^ chi_w[15], chi_w[14: 8],
                            r_i[3] ^ chi_w[ 7], chi_w[ 6: 4],
                            r_i[2] ^ chi_w[ 3], chi_w[ 2],
                            r_i[1] ^ chi_w[ 1],
                            r_i[0] ^ chi_w[ 0]  };

endmodule