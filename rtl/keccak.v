`timescale 1ns / 1ps

module keccak(
    input clk,
    input rst,
    input [1599:0] input_data,
    input load,
    input start,
    input read,
    output [1599:0] keccak_out,
    output end_op
    );
    
    wire    [1599:0]    st_o_w;     //  keccak permutation output
    wire    [7:0]       rc_o_w;     //  next round
    reg     [1599:0]    st_i_w;
    reg     [7:0]       rndc_r; 
    
    assign keccak_out = st_i_w;
    
    //  combinatorial keccak round
    keccak_round keccak (
        .s_o(st_o_w ),                          //  state out
        .r_o(rc_o_w ),                          //  round out
        .s_i(st_i_w ),                          //  state in
        .r_i(rndc_r )                           //  round in
    );
    
    always @(posedge clk) begin
        if(!rst)                                    st_i_w <= 0;
        else begin
            if(load)                                st_i_w <= input_data;
            else if(start & !end_op)                st_i_w <= st_o_w;
            else                                    st_i_w <= st_i_w;
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

//  keccak_round.v
//  Markku-Juhani O. Saarinen <mjos@iki.fi>.  See LICENSE.

//  === Purely combinatorial ("stackable") logic for Keccak-f1600 (of "SHA3").

module keccak_round(
    output wire [1599:0] s_o,           //  state out
    output wire [7:0]    r_o,           //  rc out
    input wire  [1599:0] s_i,           //  state in
    input wire  [7:0]    r_i            //  rc in
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

    //  Chi (3.2.4), Algorithm 4

    wire [1599:0]   chi_w = rp_w ^ {
                            {   rp_w[1407:1280], rp_w[1599:1408] } &~
                            {   rp_w[1343:1280], rp_w[1599:1344] },
                            {   rp_w[1087: 960], rp_w[1279:1088] } &~
                            {   rp_w[1023: 960], rp_w[1279:1024] },
                            {   rp_w[ 767: 640], rp_w[ 959: 768] } &~
                            {   rp_w[ 703: 640], rp_w[ 959: 704] },
                            {   rp_w[ 447: 320], rp_w[ 639: 448] } &~
                            {   rp_w[ 383: 320], rp_w[ 639: 384] },
                            {   rp_w[ 127:   0], rp_w[ 319: 128] } &~
                            {   rp_w[  63:   0], rp_w[ 319:  64] }  };

    //  Iota (3.2.5)

    //  This matrix implements 7 steps of the LFSR described in Algorithm 5;
    //  converted from Galois to Fibonacci representation and combined.
    assign  r_o =   ({8{r_i[0]}} & 8'h1A) ^ ({8{r_i[1]}} & 8'h34) ^
                    ({8{r_i[2]}} & 8'h68) ^ ({8{r_i[3]}} & 8'hD0) ^
                    ({8{r_i[4]}} & 8'hBA) ^ ({8{r_i[5]}} & 8'h6E) ^
                    ({8{r_i[6]}} & 8'hC6) ^ ({8{r_i[7]}} & 8'h8D);

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


module gen_input_keccak (
    input                   clk,
    input                   rst,
    input                   load,
    input                   read,
    input       [1087:0]    ek_pke_in, // 384
    input       [3:0]       mode_gen,
    input       [7:0]       i,
    input       [7:0]       j,
    input       [255:0]     i_seed_0, // d / rho
    input       [255:0]     i_seed_1, // m
    output  reg [255:0]     o_seed_0,
    output  reg [255:0]     o_seed_1,
    input       [255:0]     i_hek,
    input       [255:0]     i_ss,
    output      [255:0]     o_hek,
    output      [255:0]     o_ss,
    input       [1599:0]    do_keccak,
    output  reg [1599:0]    di_keccak
);
    
    // mode_gen = 4'h0 - NONE
    // mode_gen = 4'h1 - G(d/k) i_seed_0 = d, o_seed_0 <- rho, o_seed_1 <- sigma
    // mode_gen = 4'h2 - SHAKE128(rho,i,j) rho = o_seed_0
    // mode_gen = 4'h3 - SHAKE256(sigma,N) sigma = o_seed_1, N = i
    // mode_gen = 4'h4 - XXX
    // mode_gen = 4'h5 - XXX
    // mode_gen = 4'h6 - H(ek) = LOAD 
    // mode_gen = 4'h7 - H(ek) = LOAD SEED for k = 2
    // mode_gen = 4'h8 - H(ek) = LOAD SEED for k = 3
    // mode_gen = 4'h9 - H(ek) = LOAD SEED for k = 4
    // mode_gen = 4'hA - G(m/H(ek)) i_seed_0 = m, i_seed_1 = H(ek), 
     
    always @(posedge clk) begin
        if (!rst) begin
            o_seed_0 <= 0;
            o_seed_1 <= 0;
        end 
        else if (load) begin
            o_seed_0 <= i_seed_0;
            o_seed_1 <= o_seed_1;
        end 
        else if (read) begin
            case (mode_gen)
                4'h1: begin
                    o_seed_0 <= do_keccak[255:0];
                    // o_seed_0 <= {32{8'h5A}}; // For capturing traces at constant time
                    o_seed_1 <= do_keccak[511:256];
                end
                4'hA: begin
                    o_seed_0 <= o_seed_0; 
                    o_seed_1 <= do_keccak[511:256];
                end
                default: begin
                    o_seed_0 <= o_seed_0; // rho
                    o_seed_1 <= o_seed_1; // r
                end
            endcase
        end
    end
    
    reg [255:0]     hek;
    reg [255:0]     ss;
    
    assign o_hek = hek;
    assign o_ss = ss;
    
    always @(posedge clk) begin
        if(!rst)            hek <= 0;
        else if (load)      hek <= i_hek;
        else if (read) begin
            if(mode_gen == 4'h7 | mode_gen == 4'h8 | mode_gen == 4'h9)
                            hek <= do_keccak[255:000]; // H(ek)
            else
                            hek <= hek; // H(ek) = LOAD
        end
        else                hek <= hek;
    end
    
    always @(posedge clk) begin
        if(!rst)                            ss <= 0;
        else if (read & mode_gen == 4'hA)   ss <= do_keccak[255:000]; // G(m/H(ek))
        else                                ss <= ss;
    end
    
    always @(posedge clk) begin
        if(!rst) begin
            di_keccak <= 0;
        end 
        else begin
            case (mode_gen)
                4'h1: di_keccak <= {{128{8'h00}},8'h80,{37{8'h00}},8'h06, i ,i_seed_0}; // G(d/k), BS = 576
                4'h2: di_keccak <= {{32{8'h00}},8'h80,{132{8'h00}},8'h1F, j , i, o_seed_0}; // SHAKE128(rho,i,j) BS = 1344
                4'h3: di_keccak <= {{64{8'h00}},8'h80,{101{8'h00}},8'h1F, i, o_seed_1}; // SHAKE256(sigma,N) BS = 1088
                // 4'h4: di_keccak <= {{152{8'h00}}, ek_pke_in}; // ek[383:000] BS = 1088
                // 4'h5: di_keccak <= {{104{8'h00}}, ek_pke_in, di_keccak}; // ek[767:000] BS = 1088
                4'h6: di_keccak <= {{64{8'h00}}, ek_pke_in} ^ do_keccak; // ek[1087:000] BS = 1088
                4'h7: di_keccak <= {{64{8'h00}}, 8'h80,{14{8'h00}}, 8'h06, o_seed_0, ek_pke_in[703:000]} ^ do_keccak; // k = 2
                4'h8: di_keccak <= {{64{8'h00}}, 8'h80,{38{8'h00}}, 8'h06, o_seed_0, ek_pke_in[511:000]} ^ do_keccak; // k = 3
                4'h9: di_keccak <= {{64{8'h00}}, 8'h80,{62{8'h00}}, 8'h06, o_seed_0, ek_pke_in[319:000]} ^ do_keccak; // k = 4
                4'hA: di_keccak <= {{128{8'h00}}, 8'h80,{6{8'h00}}, 8'h06, hek, i_ss}; // G(m,hek)
                default: di_keccak <= di_keccak;
            endcase
        end
    end

endmodule


module gen_input_keccak_MASKED_KECCAK (
    input                   clk,
    input                   rst,
    input                   load,
    input                   read,
    input       [1087:0]    ek_pke_in, // 384
    input       [3:0]       mode_gen,
    input       [7:0]       i,
    input       [7:0]       j,
    input       [255:0]     i_seed_0, // d / rho
    input       [255:0]     i_seed_1, // m
    output  reg [255:0]     o_seed_0,
    output      [255:0]     o_seed_1,
    input       [255:0]     i_hek,
    input       [255:0]     i_ss,
    output      [255:0]     o_hek,
    output      [255:0]     o_ss,
    input       [1599:0]    do_keccak,
    input       [1599:0]    do_keccak_s1, // share 1
    input       [1599:0]    do_keccak_s2, // share 2
    input       [1599:0]    do_keccak_s3, // share 3
    input       [1599:0]    do_keccak_s4, // share 4
    output  reg [1599:0]    di_keccak,
    output  reg [1599:0]    di_keccak_s1, // share 1
    output  reg [1599:0]    di_keccak_s2, // share 2
    output  reg [1599:0]    di_keccak_s3, // share 3
    output  reg [1599:0]    di_keccak_s4, // share 4
    input       [1599:0]    random_data_1,
    input       [1599:0]    random_data_2,
    input       [1599:0]    random_data_3,
    output  reg             flag_masked_prf ,
    input                   flag_update_keccak
);
    
    // mode_gen = 4'h0 - NONE
    // mode_gen = 4'h1 - G(d/k) i_seed_0 = d, o_seed_0 <- rho, o_seed_1 <- sigma
    // mode_gen = 4'h2 - SHAKE128(rho,i,j) rho = o_seed_0
    // mode_gen = 4'h3 - SHAKE256(sigma,N) sigma = o_seed_1, N = i
    // mode_gen = 4'h4 - XXX
    // mode_gen = 4'h5 - XXX
    // mode_gen = 4'h6 - H(ek) = LOAD 
    // mode_gen = 4'h7 - H(ek) = LOAD SEED for k = 2
    // mode_gen = 4'h8 - H(ek) = LOAD SEED for k = 3
    // mode_gen = 4'h9 - H(ek) = LOAD SEED for k = 4
    // mode_gen = 4'hA - G(m/H(ek)) i_seed_0 = m, i_seed_1 = H(ek), 

    reg [255:0]    o_seed_1_s1;
    reg [255:0]    o_seed_1_s2;
    reg [255:0]    o_seed_1_s3;
    reg [255:0]    o_seed_1_s4;

    wire [1599:0] masked_prf_1;
    wire [1599:0] masked_prf_2;

    reg [255:0]    delay_1;
    reg [255:0]    delay_2;
     
    always @(posedge clk) begin
        if (!rst) begin
            o_seed_0 <= 0;
            o_seed_1_s1 <= 0;
            o_seed_1_s2 <= 0;
            o_seed_1_s3 <= 0;
            o_seed_1_s4 <= 0;
        end 
        else if (load) begin
            o_seed_0 <= i_seed_0;
            o_seed_1_s1 <= o_seed_1_s1;
            o_seed_1_s2 <= o_seed_1_s2;
            o_seed_1_s3 <= o_seed_1_s3;
            o_seed_1_s4 <= o_seed_1_s4;
        end 
        else if (read) begin
            case (mode_gen)
                4'h1: begin
                    o_seed_0 <= do_keccak_s1[255:0] ^ do_keccak_s2[255:0] ^ do_keccak_s3[255:0] ^ do_keccak_s4[255:0];
                    // o_seed_0 <= {32{8'h5A}}; // For capturing traces at constant time
                    // o_seed_1 <= do_keccak[511:256];
                    o_seed_1_s1 <= do_keccak_s1[511:256];
                    o_seed_1_s2 <= do_keccak_s2[511:256];
                    o_seed_1_s3 <= do_keccak_s3[511:256];
                    o_seed_1_s4 <= do_keccak_s4[511:256];
                end
                4'hA: begin
                    o_seed_0 <= o_seed_0; 
                    // o_seed_1 <= do_keccak[511:256];
                    o_seed_1_s1 <= do_keccak_s1[511:256];
                    o_seed_1_s2 <= do_keccak_s2[511:256];
                    o_seed_1_s3 <= do_keccak_s3[511:256];
                    o_seed_1_s4 <= do_keccak_s4[511:256];
                end
                default: begin
                    o_seed_0 <= o_seed_0; // rho
                    // o_seed_1 <= o_seed_1; // r
                    o_seed_1_s1 <= o_seed_1_s1;
                    o_seed_1_s2 <= o_seed_1_s2;
                    o_seed_1_s3 <= o_seed_1_s3;
                    o_seed_1_s4 <= o_seed_1_s4;
                end
            endcase
        end
    end

    assign o_seed_1     = o_seed_1_s1 ^ o_seed_1_s2 ^ o_seed_1_s3 ^ o_seed_1_s4;
    assign masked_prf_1   = {{64{8'h00}},8'h80,{101{8'h00}},8'h1F, i, o_seed_1}; // SHAKE256(sigma,N) BS = 1088 TO BE MASKED
    assign masked_prf_2   = {{128{8'h00}},8'h80,{37{8'h00}},8'h06, i ,i_seed_0}; // G(d/k), BS = 576
    
    always @(posedge clk) begin
        if(!rst) begin
            di_keccak_s1 <= 0;
            di_keccak_s2 <= 0;
            di_keccak_s3 <= 0;
            di_keccak_s4 <= 0;
            flag_masked_prf <= 0;
        end
        else if(flag_update_keccak) begin
            case (mode_gen)
                4'h1: begin
                    di_keccak_s1 <= masked_prf_2 ^ random_data_1 ^ random_data_2 ^ random_data_3;
                    di_keccak_s2 <= random_data_1;
                    di_keccak_s3 <= random_data_2;
                    di_keccak_s4 <= random_data_3;
                    flag_masked_prf <= 1;
                end
                4'h3: begin
                    di_keccak_s1 <= masked_prf_1 ^ random_data_1 ^ random_data_2 ^ random_data_3;
                    di_keccak_s2 <= random_data_1;
                    di_keccak_s3 <= random_data_2;
                    di_keccak_s4 <= random_data_3;
                    flag_masked_prf <= 1;
                end
                default: begin
                    di_keccak_s1 <= di_keccak_s1;
                    di_keccak_s2 <= di_keccak_s2;
                    di_keccak_s3 <= di_keccak_s3;
                    di_keccak_s4 <= di_keccak_s4;
                    flag_masked_prf <= 0;
                end
            endcase
        end
        else begin
            di_keccak_s1 <= di_keccak_s1;
            di_keccak_s2 <= di_keccak_s2;
            di_keccak_s3 <= di_keccak_s3;
            di_keccak_s4 <= di_keccak_s4;
            flag_masked_prf <= flag_masked_prf;
        end
    end
    
    reg [255:0]     hek;
    reg [255:0]     ss;
    
    assign o_hek = hek;
    assign o_ss = ss;
    
    always @(posedge clk) begin
        if(!rst)            hek <= 0;
        else if (load)      hek <= i_hek;
        else if (read) begin
            if(mode_gen == 4'h7 | mode_gen == 4'h8 | mode_gen == 4'h9)
                            hek <= do_keccak[255:000]; // H(ek)
            else
                            hek <= hek; // H(ek) = LOAD
        end
        else                hek <= hek;
    end
    
    always @(posedge clk) begin
        if(!rst)                            ss <= 0;
        else if (read & mode_gen == 4'hA)   ss <= do_keccak[255:000]; // G(m/H(ek))
        else                                ss <= ss;
    end
    

    always @(posedge clk) begin
        if(!rst) begin
            di_keccak <= 0;
        end 
        else begin
            case (mode_gen)
                // 4'h1: di_keccak <= {{128{8'h00}},8'h80,{37{8'h00}},8'h06, i ,i_seed_0}; // G(d/k), BS = 576
                4'h2: di_keccak <= {{32{8'h00}},8'h80,{132{8'h00}},8'h1F, j , i, o_seed_0}; // SHAKE128(rho,i,j) BS = 1344
                // 4'h3: di_keccak <= {{64{8'h00}},8'h80,{101{8'h00}},8'h1F, i, o_seed_1}; // SHAKE256(sigma,N) BS = 1088 MASKED
                // 4'h4: di_keccak <= {{152{8'h00}}, ek_pke_in}; // ek[383:000] BS = 1088
                // 4'h5: di_keccak <= {{104{8'h00}}, ek_pke_in, di_keccak}; // ek[767:000] BS = 1088
                4'h6: di_keccak <= {{64{8'h00}}, ek_pke_in} ^ do_keccak; // ek[1087:000] BS = 1088
                4'h7: di_keccak <= {{64{8'h00}}, 8'h80,{14{8'h00}}, 8'h06, o_seed_0, ek_pke_in[703:000]} ^ do_keccak; // k = 2
                4'h8: di_keccak <= {{64{8'h00}}, 8'h80,{38{8'h00}}, 8'h06, o_seed_0, ek_pke_in[511:000]} ^ do_keccak; // k = 3
                4'h9: di_keccak <= {{64{8'h00}}, 8'h80,{62{8'h00}}, 8'h06, o_seed_0, ek_pke_in[319:000]} ^ do_keccak; // k = 4
                4'hA: di_keccak <= {{128{8'h00}}, 8'h80,{6{8'h00}}, 8'h06, hek, i_ss}; // G(m,hek)
                default: di_keccak <= di_keccak;
            endcase
        end
    end

endmodule

