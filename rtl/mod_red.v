`timescale 1ns / 1ps

module fqmult_mod(
    input clk,
    input [11:0] a,
    input [11:0] b,
    output [11:0] t
);
    (* KEEP = "TRUE" *) reg [23:0] c;
    always @(posedge clk) c <= a * b; // DSP
    
    mod_red mod_red (.clk(clk), .c(c[23:0]), .data_out(t)); // mod_red - Dadda tree
    
endmodule

module mod_red #(
    parameter Q = 3329
    )(
    input clk,
    input [23:0] c,
    output [11:0] data_out 
    );
    
    // Dadda tree
    wire [14:0] SUM_DADDA;
    wire [14:0] CARRY_DADDA;
    
    dadda_tree dadda_tree 
    (
    .c(c),
    .SUM(SUM_DADDA),
    .CARRY(CARRY_DADDA)
    );
    
    // S + C + Q
    wire [14:0] S_SCQ;
    wire [14:0] C_SCQ;
    SC_VAL #(.VAL(Q)) SCQ (.SUM(SUM_DADDA), .CARRY(CARRY_DADDA), .S(S_SCQ), .C(C_SCQ));
    
    // S + C - Q
    wire [14:0] S_SCmQ;
    wire [14:0] C_SCmQ;
    SC_VAL #(.VAL(-Q)) SCmQ (.SUM(SUM_DADDA), .CARRY(CARRY_DADDA), .S(S_SCmQ), .C(C_SCmQ));
    
    // S + C - 2Q
    wire [14:0] S_SCm2Q;
    wire [14:0] C_SCm2Q;
    SC_VAL #(.VAL((-2*Q))) SCm2Q (.SUM(SUM_DADDA), .CARRY(CARRY_DADDA), .S(S_SCm2Q), .C(C_SCm2Q));
    
    reg [14:0] S0, C0;
    reg [14:0] S1, C1;
    reg [14:0] S2, C2;
    reg [14:0] S3, C3;
    
    always @(posedge clk) S0 <= S_SCm2Q;
    always @(posedge clk) C0 <= C_SCm2Q;
    always @(posedge clk) S1 <= S_SCmQ;
    always @(posedge clk) C1 <= C_SCmQ;
    always @(posedge clk) S2 <= S_SCQ;
    always @(posedge clk) C2 <= C_SCQ;
    always @(posedge clk) S3 <= SUM_DADDA;
    always @(posedge clk) C3 <= CARRY_DADDA;
    
    wire [14:0] data0;
    wire [14:0] data1;
    wire [14:0] data2;
    wire [14:0] data3;
    
    assign data0 = S0 + C0;
    assign data1 = S1 + C1;
    assign data2 = S2 + C2;
    assign data3 = S3 + C3;
    
    wire cond0;
    wire cond1; 
    wire cond2; // not used
    wire cond3;

    assign cond0 = (data0[14] == 0) ? 1 : 0;
    assign cond1 = (data1[14] == 0) ? 1 : 0;
    assign cond2 = (data2[14] == 0) ? 1 : 0; // not used
    assign cond3 = (data3[14] == 0) ? 1 : 0;
    
    reg [11:0] DR; 
    assign data_out = DR; 

    always @* begin
        if(cond0)       DR = data0[11:0];
        else if (cond1) DR = data1[11:0];
        else if (cond3) DR = data3[11:0]; // Done because of mod Q when number is 0
        else            DR = data2[11:0];
    end     
    
endmodule

module SC_VAL #(
    parameter VAL = 3329
    )(
    input [14:0] SUM,
    input [14:0] CARRY,
    output [14:0] S,
    output [14:0] C
    );
    
    wire [14:0] val = VAL;
    
    assign C[0] = 1'b0;
    
    // 0 - stage
    full_adder FA00 (.a(SUM[0]),  .b(val[0]),    .Cin(CARRY[0]),     .S(S[0]),       .Cout(C[1]));
    full_adder FA01 (.a(SUM[1]),  .b(val[1]),    .Cin(CARRY[1]),     .S(S[1]),       .Cout(C[2]));
    full_adder FA02 (.a(SUM[2]),  .b(val[2]),    .Cin(CARRY[2]),     .S(S[2]),       .Cout(C[3]));
    full_adder FA03 (.a(SUM[3]),  .b(val[3]),    .Cin(CARRY[3]),     .S(S[3]),       .Cout(C[4]));
    full_adder FA04 (.a(SUM[4]),  .b(val[4]),    .Cin(CARRY[4]),     .S(S[4]),       .Cout(C[5]));
    full_adder FA05 (.a(SUM[5]),  .b(val[5]),    .Cin(CARRY[5]),     .S(S[5]),       .Cout(C[6]));
    full_adder FA06 (.a(SUM[6]),  .b(val[6]),    .Cin(CARRY[6]),     .S(S[6]),       .Cout(C[7]));
    full_adder FA07 (.a(SUM[7]),  .b(val[7]),    .Cin(CARRY[7]),     .S(S[7]),       .Cout(C[8]));
    full_adder FA08 (.a(SUM[8]),  .b(val[8]),    .Cin(CARRY[8]),     .S(S[8]),       .Cout(C[9]));
    full_adder FA09 (.a(SUM[9]),  .b(val[9]),    .Cin(CARRY[9]),     .S(S[9]),       .Cout(C[10]));
    full_adder FA010 (.a(SUM[10]),  .b(val[10]),    .Cin(CARRY[10]),     .S(S[10]),       .Cout(C[11]));
    full_adder FA011 (.a(SUM[11]),  .b(val[11]),    .Cin(CARRY[11]),     .S(S[11]),       .Cout(C[12]));
    full_adder FA012 (.a(SUM[12]),  .b(val[12]),    .Cin(CARRY[12]),     .S(S[12]),       .Cout(C[13]));
    full_adder FA013 (.a(SUM[13]),  .b(val[13]),    .Cin(CARRY[13]),     .S(S[13]),       .Cout(C[14]));
    full_adder FA014 (.a(SUM[14]),  .b(val[14]),    .Cin(CARRY[14]),     .S(S[14]),       .Cout());
    
endmodule

module dadda_tree 
    (
    input [23:0] c,
    output [14:0] SUM,
    output [14:0] CARRY 
    );
    
    wire [8:0] val0  = {1'b0  , 1'b0  , ~c[20], ~c[19], ~c[18], ~c[17], ~c[14], ~c[12], c[0]};
    wire [8:0] val1  = {1'b0  , 1'b1  , ~c[21], ~c[20], ~c[18], ~c[17], ~c[15], ~c[13], c[1]};
    wire [8:0] val2  = {1'b0  , ~c[22], ~c[21], ~c[19], ~c[18], ~c[17], ~c[16], ~c[14], c[2]};
    wire [8:0] val3  = {1'b0  , 1'b0  , ~c[23], ~c[22], ~c[20], ~c[19], ~c[18], ~c[15], c[3]};
    wire [8:0] val4  = {1'b0  , 1'b0  , 1'b1  , ~c[23], ~c[21], ~c[20], ~c[19], ~c[16], c[4]};
    wire [8:0] val5  = {1'b0  , 1'b0  , 1'b0  , 1'b0  , ~c[22], ~c[21], ~c[20], ~c[17], c[5]};
    wire [8:0] val6  = {1'b0  , 1'b0  , 1'b0  , 1'b1  , ~c[23], ~c[22], ~c[21], ~c[18], c[6]};
    wire [8:0] val7  = {1'b0  , 1'b0  , 1'b0  , 1'b0  , 1'b0  , ~c[23], ~c[22], ~c[19], c[7]};
    wire [8:0] val8  = {~c[23], ~c[21], ~c[18], ~c[14],  c[21],  c[19],  c[17],  c[12], c[8]};
    wire [8:0] val9  = {1'b0  , 1'b0  , 1'b0  ,  c[19],  c[18],  c[15],  c[13],  c[12], c[9]};
    wire [8:0] val10 = {1'b0  , 1'b1  , ~c[18], ~c[16], ~c[15],  c[19],  c[17],  c[13], c[10]};
    wire [8:0] val11 = {1'b0  , 1'b0  , 1'b0  , 1'b0  , 1'b0  ,  1'b0 ,  1'b0 ,  1'b1 , c[11]};
    wire [8:0] val12 = {1'b0  , 1'b0  , 1'b0  , 1'b0  , 1'b0  ,  1'b0 ,  1'b0 ,  1'b0 , 1'b0 };
    wire [8:0] val13 = {1'b0  , 1'b0  , 1'b0  , 1'b0  , 1'b0  ,  1'b0 ,  1'b0 ,  1'b0 , 1'b1 };
    wire [8:0] val14 = {1'b0  , 1'b0  , 1'b0  , 1'b0  , 1'b0  ,  1'b0 ,  1'b0 ,  1'b0 , 1'b1 };
    
    assign CARRY[0]     = 1'b0;
    assign CARRY[14]    = 1'b0;
    assign SUM[13]      = val13[0];
    assign SUM[14]      = val14[0];

    wire S000, C000;
    wire S100, C100;
    wire S200, C200;
    wire S010, C010;
    wire S011, C011;
    wire S110, C110;
    wire S111, C111;
    wire S210, C210;
    wire S020, C020;
    wire S021, C021;
    wire S120, C120;
    wire S121, C121;
    wire S220, C220;
    wire S030, C030;
    wire S031, C031;
    wire S130, C130;
    wire S131, C131;
    wire S230, C230;
    wire S040, C040;
    wire S041, C041;
    wire S140, C140;
    wire S141, C141;
    wire S240, C240;
    wire S050, C050;
    wire S150, C150;
    wire S151, C151;
    wire S250, C250;
    wire S060, C060;
    wire S160, C160;
    wire S161, C161;
    wire S260, C260;
    wire S170, C170;
    wire S171, C171;
    wire S270, C270;
    wire S080, C080;
    wire S081, C081;
    wire S180, C180;
    wire S181, C181;
    wire S280, C280;
    wire S090, C090;
    wire S190, C190;
    wire S191, C191;
    wire S290, C290;
    wire S0100, C0100;
    wire S0101, C0101;
    wire S1100, C1100;
    wire S1101, C1101;
    wire S2100, C2100;
    wire S1110, C1110;
    wire S2110, C2110; 

    // SUM 0
    half_adder HA000 (.a(val0[0]),  .b(val0[1]),                    .S(S000),        .Cout(C000));
    
    full_adder FA100 (.a(val0[2]),  .b(val0[3]),    .Cin(S000),     .S(S100),        .Cout(C100));
    
    half_adder HA200 (.a(S100),     .b(val0[4]),                    .S(S200),        .Cout(C200));
    
    full_adder FA300 (.a(val0[5]),  .b(val0[6]),    .Cin(S200),     .S(SUM[0]),      .Cout(CARRY[1]));
    
    // SUM1
    full_adder FA010 (.a(val1[0]),  .b(val1[1]),    .Cin(val1[2]),  .S(S010),        .Cout(C010));    
    half_adder HA011 (.a(val1[3]),  .b(val1[4]),                    .S(S011),        .Cout(C011));
    
    full_adder FA110 (.a(C000),     .b(S010),       .Cin(S011),     .S(S110),        .Cout(C110));    
    half_adder HA111 (.a(val1[5]),  .b(val1[6]),                    .S(S111),        .Cout(C111));
    
    full_adder FA210 (.a(C100),     .b(S110),       .Cin(S111),     .S(S210),        .Cout(C210));  
    
    full_adder FA310 (.a(C200),     .b(S210),       .Cin(val1[7]),  .S(SUM[1]),      .Cout(CARRY[2]));
    
    // SUM2
    full_adder FA020 (.a(val2[0]),  .b(val2[1]),    .Cin(val2[2]),  .S(S020),        .Cout(C020));
    full_adder FA021 (.a(val2[3]),  .b(val2[4]),    .Cin(val2[5]),  .S(S021),        .Cout(C021));
    
    full_adder FA120 (.a(C010),     .b(C011),       .Cin(S020),     .S(S120),        .Cout(C120));
    full_adder FA121 (.a(val2[6]),  .b(val2[7]),    .Cin(S021),     .S(S121),        .Cout(C121));
    
    full_adder FA220 (.a(C110),     .b(C111),       .Cin(S120),     .S(S220),        .Cout(C220));
    
    full_adder FA320 (.a(C210),     .b(S220),       .Cin(S121),     .S(SUM[2]),      .Cout(CARRY[3]));
    
    // SUM 3
    full_adder FA030 (.a(val3[0]),  .b(val3[1]),    .Cin(val3[2]),  .S(S030),        .Cout(C030));
    half_adder HA031 (.a(val3[3]),  .b(val3[4]),                    .S(S031),        .Cout(C031));
    
    full_adder FA130 (.a(C020),     .b(C021),       .Cin(S030),     .S(S130),        .Cout(C130));
    full_adder FA131 (.a(val3[5]),  .b(val3[6]),    .Cin(S031),     .S(S131),        .Cout(C131));
    
    full_adder FA230 (.a(C120),     .b(C121),       .Cin(S130),     .S(S230),        .Cout(C230));
    
    full_adder FA330 (.a(C220),     .b(S230),       .Cin(S131),     .S(SUM[3]),      .Cout(CARRY[4]));
    
    // SUM 4
    full_adder FA040 (.a(val4[0]),  .b(val4[1]),    .Cin(val4[2]),  .S(S040),        .Cout(C040));
    half_adder HA041 (.a(val4[3]),  .b(val4[4]),                    .S(S041),        .Cout(C041));
    
    full_adder FA140 (.a(C030),     .b(C031),       .Cin(S040),     .S(S140),        .Cout(C140));
    full_adder FA141 (.a(val4[5]),  .b(val4[6]),    .Cin(S041),     .S(S141),        .Cout(C141));
    
    full_adder FA240 (.a(C130),     .b(C131),       .Cin(S140),     .S(S240),        .Cout(C240));
    
    full_adder FA340 (.a(C230),     .b(S240),       .Cin(S141),     .S(SUM[4]),      .Cout(CARRY[5]));
    
    // SUM 5
    half_adder HA050 (.a(val5[0]),  .b(val5[1]),                    .S(S050),        .Cout(C050));
    
    full_adder FA150 (.a(C040),     .b(C041),       .Cin(S050),     .S(S150),        .Cout(C150));
    full_adder FA151 (.a(val5[2]),  .b(val5[3]),    .Cin(val5[4]),  .S(S151),        .Cout(C151));
    
    full_adder FA250 (.a(C140),     .b(C141),       .Cin(S150),     .S(S250),        .Cout(C250));
    
    full_adder FA350 (.a(C240),     .b(S250),       .Cin(S151),     .S(SUM[5]),      .Cout(CARRY[6]));
    
    // SUM 6
    half_adder HA060 (.a(val6[0]),  .b(val6[1]),                    .S(S060),        .Cout(C060));
    
    full_adder FA160 (.a(C050),     .b(val6[2]),    .Cin(S060),     .S(S160),        .Cout(C160));
    full_adder FA161 (.a(val6[3]),  .b(val6[4]),    .Cin(val6[5]),  .S(S161),        .Cout(C161));
    
    full_adder FA260 (.a(C150),     .b(C151),       .Cin(S160),     .S(S260),        .Cout(C260));
    
    full_adder FA360 (.a(C250),     .b(S260),       .Cin(S161),     .S(SUM[6]),      .Cout(CARRY[7]));
    
    // SUM 7
    // -- no 0 stage
    
    full_adder FA170 (.a(val7[0]),  .b(val7[1]),    .Cin(C060),     .S(S170),        .Cout(C170));
    half_adder HA171 (.a(val7[2]),  .b(val7[3]),                    .S(S171),        .Cout(C171));
    
    full_adder FA270 (.a(C160),     .b(C161),       .Cin(S170),     .S(S270),        .Cout(C270));
    
    full_adder FA370 (.a(C260),     .b(S270),       .Cin(S171),     .S(SUM[7]),      .Cout(CARRY[8]));
    
    // SUM 8
    full_adder FA080 (.a(val8[0]),  .b(val8[1]),    .Cin(val8[2]),  .S(S080),        .Cout(C080));
    half_adder HA081 (.a(val8[3]),  .b(val8[4]),                    .S(S081),        .Cout(C081));
                  
    full_adder FA180 (.a(S080),     .b(S081),       .Cin(val8[5]),  .S(S180),        .Cout(C180));
    full_adder FA181 (.a(val8[6]),  .b(val8[7]),    .Cin(val8[8]),  .S(S181),        .Cout(C181));
                  
    full_adder FA280 (.a(C170),     .b(C171),       .Cin(S180),     .S(S280),        .Cout(C280));
                  
    full_adder FA380 (.a(C270),     .b(S280),       .Cin(S181),     .S(SUM[8]),      .Cout(CARRY[9]));
    
    // SUM 9
    full_adder FA090 (.a(val9[0]),  .b(val9[1]),    .Cin(val9[2]),  .S(S090),        .Cout(C090));
                  
    full_adder FA190 (.a(S090),     .b(C080),       .Cin(C081),     .S(S190),        .Cout(C190));
    full_adder FA191 (.a(val9[3]),  .b(val9[4]),    .Cin(val9[5]),  .S(S191),        .Cout(C191));
                  
    full_adder FA290 (.a(C180),     .b(C181),       .Cin(S190),     .S(S290),        .Cout(C290));
                  
    full_adder FA390 (.a(C280),     .b(S290),       .Cin(S191),     .S(SUM[9]),      .Cout(CARRY[10]));
    
    // SUM 10
    full_adder FA0100 (.a(val10[0]),  .b(val10[1]),  .Cin(val10[2]), .S(S0100),      .Cout(C0100));
    half_adder HA0101 (.a(val10[3]),  .b(val10[4]),                  .S(S0101),      .Cout(C0101));
                  
    full_adder FA1100 (.a(S0100),     .b(S0101),     .Cin(C090),     .S(S1100),      .Cout(C1100));
    full_adder FA1101 (.a(val10[5]),  .b(val10[6]),  .Cin(val10[7]), .S(S1101),      .Cout(C1101));
                  
    full_adder FA2100 (.a(C190),      .b(C191),      .Cin(S1100),    .S(S2100),      .Cout(C2100));
                  
    full_adder FA3100 (.a(C290),      .b(S2100),     .Cin(S1101),    .S(SUM[10]),    .Cout(CARRY[11]));
    
    // SUM 11
    // -- no 0 stage
    
    full_adder FA1110 (.a(val11[0]),  .b(C0100),    .Cin(C0101),     .S(S1110),      .Cout(C1110));
    
    full_adder FA2110 (.a(C1100),     .b(C1101),    .Cin(S1110),     .S(S2110),      .Cout(C2110));
    
    full_adder FA3110 (.a(val11[1]),  .b(C2100),    .Cin(S2110),     .S(SUM[11]),    .Cout(CARRY[12]));
    
    // SUM 12
    // -- no 0 stage
    // -- no 1 stage
    // -- no 2 stage
    half_adder HA0121 (.a(C1110),     .b(C2110),                    .S(SUM[12]),     .Cout(CARRY[13]));
    
    
endmodule

module full_adder (
    input a,
    input b,
    input Cin,
    output S,
    output Cout
);
    
    assign {Cout,S} = a + b + Cin;

endmodule

module half_adder (
    input a,
    input b,
    output S,
    output Cout
);
    
    assign {Cout,S} = a + b;
    
    // assign S        = a ^ b;
    // assign Cout     = a & b;

endmodule


module mod_add #(
    parameter Q = 3329
    )(
    input [11:0] a,
    input [11:0] b,
    output[11:0] c
    );

    wire        [12:0] R;
    wire        [15:0] Rq;

    assign R    = a + b;

    adder_N_bits #(.N(15)) adder (.a({2'b00,R}), .b(-Q), .c(Rq));

assign c = (Rq[13] == 0) ? Rq[11:0] : R[11:0];

endmodule

module mod_sub #(
    parameter Q = 3329
    )(
    input [11:0] a,
    input [11:0] b,
    output[11:0] c
    );

    wire        [12:0] R;
    wire        [15:0] Rq;

    assign R    = a - b;
    // assign Rq   = R + Q;
    
    adder_N_bits #(.N(15)) adder_0 (.a({2'b00,R}), .b(Q),     .c(Rq));
    
    assign c = (R[12] == 0) ? R[11:0] : Rq[11:0];

endmodule

module adder_N_bits #(
    parameter N = 12
    )(
    input [N-1:0] a,
    input [N-1:0] b,
    output [N:0] c
    );
    
    wire [15:0] in_a;
    wire [15:0] in_b;
    assign in_a = {{(15-N){1'b0}}, a};
    assign in_b = {{(15-N){1'b0}}, b};
    
    wire [15:0] S;
    wire C;
    kogge_stone_16bit kogge_stone_16bit (
        .A(in_a),
        .B(in_b),
        .Sum(S),
        .Cout(C)
    );
    
    assign c[N-1:0] = S[N-1:0];
    assign c[N] = S[N]; 
    
endmodule

module kogge_stone_16bit (
    input  [15:0] A, B,
    output [15:0] Sum,
    output        Cout
);

    wire [15:0] G, P;     // Generate and Propagate
    wire [15:0] C;        // Carry signals

    // Initial generate and propagate
    assign G = A & B;
    assign P = A ^ B;

    // Prefix stages
    wire [15:0] G1, P1, G2, P2, G3, P3, G4;

    // Stage 1 (distance = 1)
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: stage1
            if (i == 0) begin
                assign G1[i] = G[i];
                assign P1[i] = P[i];
            end else begin
                assign G1[i] = G[i] | (P[i] & G[i-1]);
                assign P1[i] = P[i] & P[i-1];
            end
        end
    endgenerate

    // Stage 2 (distance = 2)
    generate
        for (i = 0; i < 16; i = i + 1) begin: stage2
            if (i < 2) begin
                assign G2[i] = G1[i];
                assign P2[i] = P1[i];
            end else begin
                assign G2[i] = G1[i] | (P1[i] & G1[i-2]);
                assign P2[i] = P1[i] & P1[i-2];
            end
        end
    endgenerate

    // Stage 3 (distance = 4)
    generate
        for (i = 0; i < 16; i = i + 1) begin: stage3
            if (i < 4) begin
                assign G3[i] = G2[i];
                assign P3[i] = P2[i];
            end else begin
                assign G3[i] = G2[i] | (P2[i] & G2[i-4]);
                assign P3[i] = P2[i] & P2[i-4];
            end
        end
    endgenerate

    // Stage 4 (distance = 8)
    generate
        for (i = 0; i < 16; i = i + 1) begin: stage4
            if (i < 8) begin
                assign G4[i] = G3[i];
            end else begin
                assign G4[i] = G3[i] | (P3[i] & G3[i-8]);
            end
        end
    endgenerate

    // Compute carries (shifted by 1 bit)
    assign C[0] = 1'b0;  // Cin = 0
    generate
        for (i = 1; i < 16; i = i + 1) begin : carry_compute
            assign C[i] = G4[i-1];
        end
    endgenerate

    assign Cout = G4[15];

    // Compute final sum
    assign Sum = P ^ C;

endmodule


