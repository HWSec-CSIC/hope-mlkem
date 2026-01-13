`timescale 1ns / 1ps

module DMU_MASKED_N_BU_4 #(
    parameter N_SHARES = 6
)(
    
    input           clk,
    
    input   [40:0]  control_dmu,
    input   [3:0]   off_r1,
    input   [3:0]   off_r2,
    input   [3:0]   off_r3,
    input   [3:0]   off_r4,
    input   [3:0]   off_ram01,
    input   [3:0]   off_ram11,
    input   [3:0]   off_ram02,
    input   [3:0]   off_ram12,
    input   [3:0]   off_ram03,
    input   [3:0]   off_ram13,
    input   [3:0]   off_ram04,
    input   [3:0]   off_ram14,
    
    input   [09:00] ad_1_01,
    input   [09:00] ad_2_01,
    input   [09:00] ad_1_11,
    input   [09:00] ad_2_11,
    input   [09:00] ad_1_02,
    input   [09:00] ad_2_02,
    input   [09:00] ad_1_12,
    input   [09:00] ad_2_12,
    input   [09:00] ad_1_03,
    input   [09:00] ad_2_03,
    input   [09:00] ad_1_13,
    input   [09:00] ad_2_13,
    input   [09:00] ad_1_04,
    input   [09:00] ad_2_04,
    input   [09:00] ad_1_14,
    input   [09:00] ad_2_14,

    // SHARES
    output                      en_read,
    input   [N_SHARES*24-1:0]   random_shares,
    
    // CBD
    input           en_write,
    input   [23:0]  data_in_1_cbd,
    input   [23:0]  data_in_2_cbd,
    input   [7:0]   addr_1_cbd,  
    input   [7:0]   addr_2_cbd, 
    
    // REJ - UNIFORM
    input       [23:0]  do_1_0_r0,
    input       [23:0]  do_2_0_r0,
    input       [23:0]  do_1_1_r0,
    input       [23:0]  do_2_1_r0,
    output  reg [9:0]   ar_1_0_r0,
    output  reg [9:0]   ar_2_0_r0,
    output  reg [9:0]   ar_1_1_r0,
    output  reg [9:0]   ar_2_1_r0,
    
    input       [23:0]  do_1_0_r1,
    input       [23:0]  do_2_0_r1,
    input       [23:0]  do_1_1_r1,
    input       [23:0]  do_2_1_r1,
    output  reg [9:0]   ar_1_0_r1,
    output  reg [9:0]   ar_2_0_r1,
    output  reg [9:0]   ar_1_1_r1,
    output  reg [9:0]   ar_2_1_r1,
    
    // BU ENGINE
    input       [7:0]       en_ram,
    output reg  [4*24-1:0]  di_1,
    input       [4*24-1:0]  do_1,
    input       [4*8-1:0]   ad_1,
    output reg  [4*24-1:0]  di_2,
    input       [4*24-1:0]  do_2,
    input       [4*8-1:0]   ad_2,
    output reg  [4*24-1:0]  di_3,
    input       [4*24-1:0]  do_3,
    input       [4*8-1:0]   ad_3,                           
    output reg  [4*24-1:0]  di_4,
    input       [4*24-1:0]  do_4,
    input       [4*8-1:0]   ad_4,
    
    // DECODER
    input       [2*24-1:0] input_decoder,
    
    // RAM BANK
    output  reg             enable_1_01,
    output  reg             enable_2_01,
    output  reg [9:0]       addr_1_01,
    output  reg [9:0]       addr_2_01,
    output  reg [35:0]      data_in_1_01,
    output  reg [35:0]      data_in_2_01,
    input       [35:0]      data_out_1_01,
    input       [35:0]      data_out_2_01,
    
    output  reg             enable_1_11,
    output  reg             enable_2_11,
    output  reg [9:0]       addr_1_11,
    output  reg [9:0]       addr_2_11,
    output  reg [35:0]      data_in_1_11,
    output  reg [35:0]      data_in_2_11,
    input       [35:0]      data_out_1_11,
    input       [35:0]      data_out_2_11,
    
   output   reg             enable_1_02,
   output   reg             enable_2_02,
   output   reg [9:0]       addr_1_02,
   output   reg [9:0]       addr_2_02,
   output   reg [35:0]      data_in_1_02,
   output   reg [35:0]      data_in_2_02,
    input       [35:0]      data_out_1_02,
    input       [35:0]      data_out_2_02,
    
    output  reg             enable_1_12,
    output  reg             enable_2_12,
    output  reg [9:0]       addr_1_12,
    output  reg [9:0]       addr_2_12,
    output  reg [35:0]      data_in_1_12,
    output  reg [35:0]      data_in_2_12,
    input       [35:0]      data_out_1_12,
    input       [35:0]      data_out_2_12,
    
    output  reg             enable_1_03,
    output  reg             enable_2_03,
    output  reg [9:0]       addr_1_03,
    output  reg [9:0]       addr_2_03,
    output  reg [35:0]      data_in_1_03,
    output  reg [35:0]      data_in_2_03,
    input       [35:0]      data_out_1_03,
    input       [35:0]      data_out_2_03,
    
    output  reg             enable_1_13,
    output  reg             enable_2_13,
    output  reg [9:0]       addr_1_13,
    output  reg [9:0]       addr_2_13,
    output  reg [35:0]      data_in_1_13,
    output  reg [35:0]      data_in_2_13,
    input       [35:0]      data_out_1_13,
    input       [35:0]      data_out_2_13,
    
    output  reg             enable_1_04,
    output  reg             enable_2_04,
    output  reg [9:0]       addr_1_04,
    output  reg [9:0]       addr_2_04,
    output  reg [35:0]      data_in_1_04,
    output  reg [35:0]      data_in_2_04,
    input       [35:0]      data_out_1_04,
    input       [35:0]      data_out_2_04,
    
    output  reg             enable_1_14,
    output  reg             enable_2_14,
    output  reg [9:0]       addr_1_14,
    output  reg [9:0]       addr_2_14,
    output  reg [35:0]      data_in_1_14,
    output  reg [35:0]      data_in_2_14,
    input       [35:0]      data_out_1_14,
    input       [35:0]      data_out_2_14

    );
    
    wire cbd_1;
    wire ntt_1;
    wire pwm_1_r0;
    wire pwm_1_r1;
    wire adsub_11;
    wire adsub_12;
    wire adsub_13;
    wire adsub_14;
    
    assign cbd_1    = control_dmu[0];
    assign ntt_1    = control_dmu[1];
    assign pwm_1_r0 = control_dmu[2];
    assign pwm_1_r1 = control_dmu[3];
    assign adsub_11 = control_dmu[4];
    assign adsub_12 = control_dmu[5];
    assign adsub_13 = control_dmu[6];
    assign adsub_14 = control_dmu[7];  
    
    wire cbd_2;
    wire ntt_2;
    wire pwm_2_r0;
    wire pwm_2_r1;
    wire adsub_21;
    wire adsub_22;
    wire adsub_23;
    wire adsub_24;
    
    assign cbd_2    = control_dmu[8];
    assign ntt_2    = control_dmu[9];
    assign pwm_2_r0 = control_dmu[10];
    assign pwm_2_r1 = control_dmu[11];
    assign adsub_21 = control_dmu[12];
    assign adsub_22 = control_dmu[13];
    assign adsub_23 = control_dmu[14];
    assign adsub_24 = control_dmu[15]; 
    
    wire cbd_3;
    wire ntt_3;
    wire pwm_3_r0;
    wire pwm_3_r1;
    wire adsub_31;
    wire adsub_32;
    wire adsub_33;
    wire adsub_34;
    
    assign cbd_3    = control_dmu[16];
    assign ntt_3    = control_dmu[17];
    assign pwm_3_r0 = control_dmu[18];
    assign pwm_3_r1 = control_dmu[19];
    assign adsub_31 = control_dmu[20];
    assign adsub_32 = control_dmu[21];
    assign adsub_33 = control_dmu[22];
    assign adsub_34 = control_dmu[23]; 
    
    wire cbd_4;
    wire ntt_4;
    wire pwm_4_r0;
    wire pwm_4_r1;
    wire adsub_41;
    wire adsub_42;
    wire adsub_43;
    wire adsub_44;
    
    assign cbd_4    = control_dmu[24];
    assign ntt_4    = control_dmu[25];
    assign pwm_4_r0 = control_dmu[26];
    assign pwm_4_r1 = control_dmu[27];
    assign adsub_41 = control_dmu[28];
    assign adsub_42 = control_dmu[29];
    assign adsub_43 = control_dmu[30];
    assign adsub_44 = control_dmu[31]; 

    wire encod; 
    wire decod_1;   
    wire sel_d_1;
    wire decod_2;
    wire sel_d_2;
    wire decod_3;
    wire sel_d_3;
    wire decod_4;
    wire sel_d_4;
    
    assign encod    = control_dmu[32]; 
    assign decod_1  = control_dmu[33];
    assign sel_d_1  = control_dmu[34]; 
    assign decod_2  = control_dmu[35];
    assign sel_d_2  = control_dmu[36]; 
    assign decod_3  = control_dmu[37];
    assign sel_d_3  = control_dmu[38]; 
    assign decod_4  = control_dmu[39];
    assign sel_d_4  = control_dmu[40];
    // assign deco_dk  = control_dmu[33]; 
    // assign deco_ct  = control_dmu[34]; 
    
    wire sel_ram_1;
    wire sel_ram_2;
    wire sel_ram_3;
    wire sel_ram_4;
    assign sel_ram_1 = en_ram[0];
    assign sel_ram_2 = en_ram[2];
    assign sel_ram_3 = en_ram[4];
    assign sel_ram_4 = en_ram[6];
    
    wire cbd;
    assign cbd = cbd_1 | cbd_2 | cbd_3 | cbd_4;

    wire decod;
    assign decod = decod_1 | decod_2 | decod_3 | decod_4;
    
    wire decod_masked;
    assign decod_masked = decod_1;
    
    // Shares
    assign en_read = cbd | (decod & decod_masked);
    /*
    always @(posedge clk) begin
        if(en_write)    en_read <= 1'b1;
        else            en_read <= 1'b0;
    end
    */
    
    
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_01_p;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_11_p;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_02_p;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_12_p;

    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_01;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_11;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_02;
    (* DONT_TOUCH = "TRUE" *) wire [11:0] sum_random_12;

    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_01_p (.a(random_shares[11:00]), .b(random_shares[59:48]), .c(sum_random_01_p));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_11_p (.a(random_shares[23:12]), .b(random_shares[71:60]), .c(sum_random_11_p));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_02_p (.a(random_shares[35:24]), .b(random_shares[83:72]), .c(sum_random_02_p));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_12_p (.a(random_shares[47:36]), .b(random_shares[95:84]), .c(sum_random_12_p));

    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_01 (.a(random_shares[107:96]),  .b(sum_random_01_p), .c(sum_random_01));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_11 (.a(random_shares[119:108]), .b(sum_random_11_p), .c(sum_random_11));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_02 (.a(random_shares[131:120]), .b(sum_random_02_p), .c(sum_random_02));
    (* DONT_TOUCH = "TRUE" *) mod_add mod_add_12 (.a(random_shares[143:132]), .b(sum_random_12_p), .c(sum_random_12));
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_cbd;

    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_01_cbd (.a(data_in_1_cbd[11:00]), .b(sum_random_01), .c(in_01_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_11_cbd (.a(data_in_1_cbd[23:12]), .b(sum_random_11), .c(in_11_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_02_cbd (.a(data_in_2_cbd[11:00]), .b(sum_random_02), .c(in_02_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_12_cbd (.a(data_in_2_cbd[23:12]), .b(sum_random_12), .c(in_12_cbd));
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_decod_masked;
    
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_01_decod (.a(input_decoder[11:00]), .b(sum_random_01), .c(in_01_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_11_decod (.a(input_decoder[23:12]), .b(sum_random_11), .c(in_11_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_02_decod (.a(input_decoder[35:24]), .b(sum_random_02), .c(in_02_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_12_decod (.a(input_decoder[47:36]), .b(sum_random_12), .c(in_12_decod_masked));
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_decod_1;
    
    assign in_01_decod_1 = (decod_masked) ? in_01_decod_masked : input_decoder[11:00];
    assign in_11_decod_1 = (decod_masked) ? in_11_decod_masked : input_decoder[23:12];
    assign in_02_decod_1 = (decod_masked) ? in_02_decod_masked : input_decoder[35:24];
    assign in_12_decod_1 = (decod_masked) ? in_12_decod_masked : input_decoder[47:36];
    
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_1_decod_2;
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_2_decod_2;

    assign in_1_decod_2 = (decod_masked) ? random_shares[23:00]   : input_decoder[23:00];
    assign in_2_decod_2 = (decod_masked) ? random_shares[47:24]   : input_decoder[47:24];
    
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_1_decod_3;
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_2_decod_3;

    assign in_1_decod_3 = (decod_masked) ? random_shares[71:48]   : input_decoder[23:00];
    assign in_2_decod_3 = (decod_masked) ? random_shares[95:72]   : input_decoder[47:24];
    
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_1_decod_4;
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_2_decod_4;

    assign in_1_decod_4 = (decod_masked) ? random_shares[119:96]    : input_decoder[23:00];
    assign in_2_decod_4 = (decod_masked) ? random_shares[143:120]   : input_decoder[47:24];

    // -- BU - 1 -- // 
    always @(posedge clk) begin
        if(cbd) begin 
            // RAM 
            enable_1_01     <= en_write;
            enable_2_01     <= en_write; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            /*
            data_in_1_01    <=  {12'h000, data_in_1_cbd};
            data_in_2_01    <=  {12'h000, data_in_2_cbd};
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            */
            /*
            data_in_1_01    <=  random_shares[31:00];
            data_in_2_01    <=  random_shares[63:32];
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            */
            
            data_in_1_01    <=  {12'h000, in_11_cbd, in_01_cbd};
            data_in_2_01    <=  {12'h000, in_12_cbd, in_02_cbd};
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01       <=  addr_1_cbd + (off_ram01 << 7);
            addr_2_01       <=  addr_2_cbd + (off_ram11 << 7);
            addr_1_11       <=  0;
            addr_2_11       <=  0;
            
            di_1            <=  {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]}; 
        end 
        
        else if(ntt_1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= en_ram[0]; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= en_ram[1];
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7); 
            
            di_1            <=  {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]}; 
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_1_r0 & !pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_1            <=  (sel_ram_1) ? {do_1_0_r0, data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                            {24'h000_000, 24'h000_000, do_1_0_r0, data_out_1_01[23:00]} ; 
        end
        
        else if(!pwm_1_r0 & pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_1            <=  (sel_ram_1) ? {do_1_0_r1, data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_1_0_r1, data_out_1_01[23:00]} ; 
        end
        else if (pwm_1_r0 & pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_1            <=  (sel_ram_1) ? {data_out_2_11[23:00], data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_01[23:00], data_out_1_01[23:00]} ; 
        end
        
        // Operate over BU_1 
        else if(adsub_11) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);

            di_1            <=  (sel_ram_1) ? 
                                            {24'h000000, 24'h000000, data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_01[23:00], data_out_1_01[23:00]} ;                    
        
        end

        else if(adsub_12 | adsub_13 | adsub_14) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);

            di_1            <=  (sel_ram_1) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_11[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_01[23:00]} ;                    
        
        end
        
        else if(encod) begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01       <=  ad_1_01;
            addr_2_01       <=  ad_2_01; 
            addr_1_11       <=  ad_1_11;
            addr_2_11       <=  ad_2_11;
            
            di_1            <=  0; 
        end
        
        else if(decod) begin
            enable_1_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_2_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_1_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            enable_2_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            
            /*
            data_in_1_01    <=  {12'h000, input_decoder[23:00]};
            data_in_2_01    <=  {12'h000, input_decoder[47:24]};
            data_in_1_11    <=  {12'h000, input_decoder[23:00]};
            data_in_2_11    <=  {12'h000, input_decoder[47:24]};
            */
            
            data_in_1_01    <=  {12'h000, in_11_decod_1, in_01_decod_1};
            data_in_2_01    <=  {12'h000, in_12_decod_1, in_02_decod_1};
            data_in_1_11    <=  {12'h000, in_11_decod_1, in_01_decod_1};
            data_in_2_11    <=  {12'h000, in_12_decod_1, in_02_decod_1};

            addr_1_01       <=  ad_1_01;
            addr_2_01       <=  ad_2_01; 
            addr_1_11       <=  ad_1_11;
            addr_2_11       <=  ad_2_11;
            
            di_1            <=  0; 
        end
        
        else begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01    <=  0;
            addr_2_01    <=  0; 
            addr_1_11    <=  0;
            addr_2_11    <=  0;
            
            di_1         <=  0; 
        
        end   
    end
     
    reg cbd_clk;                always @(posedge clk) cbd_clk <= cbd;
    reg en_write_clk;           always @(posedge clk) en_write_clk <= en_write;
    
    reg [9:0] addr_1;           always @(posedge clk) addr_1 <= addr_1_cbd + (off_ram02 << 7);
    reg [9:0] addr_2;           always @(posedge clk) addr_2 <= addr_2_cbd + (off_ram02 << 7);
    reg [23:0] random_shares_1; always @(posedge clk) random_shares_1 <= random_shares[23:00];
    reg [23:0] random_shares_2; always @(posedge clk) random_shares_2 <= random_shares[47:24];
     
    // -- BU - 2 -- // 
    always @(posedge clk) begin
        if(cbd_clk) begin 
            // RAM 
            enable_1_02     <= en_write_clk;
            enable_2_02     <= en_write_clk; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;

            /*          
            data_in_1_02    <=  {12'h000, data_in_1_cbd};
            data_in_2_02    <=  {12'h000, data_in_2_cbd};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            */
            
            /*
            data_in_1_02    <=  random_shares[95:64];
            data_in_2_02    <=  random_shares[127:96];
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            */
            
            data_in_1_02    <=  {12'h000, random_shares_1};
            data_in_2_02    <=  {12'h000, random_shares_2};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
                      
            addr_1_02       <=  addr_1;
            addr_2_02       <=  addr_2;
            addr_1_12       <=  0;
            addr_2_12       <=  0;
            
            di_2            <=  {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]}; 
        end 
        
        else if(ntt_2) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= en_ram[2]; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= en_ram[3];
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7); 
            
            di_2            <=  {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]};
            
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_2_r0 & !pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_2            <=  (sel_ram_2) ? {do_2_0_r0, data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_0_r0, data_out_1_02[23:00]} ; 
        end
        
        else if(!pwm_2_r0 & pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_2            <=  (sel_ram_2) ? {do_2_0_r1, data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_0_r1, data_out_1_02[23:00]} ; 
        end
        
         else if (pwm_2_r0 & pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[07:00] + (off_r2 << 7);
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[23:16] + (off_r2 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_2            <=  (sel_ram_2) ? {data_out_2_12[23:00], data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_02[23:00], data_out_1_02[23:00]} ; 
        end
        
        // Operate over BU_2 
        else if(adsub_22) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[07:00] + (off_r2 << 7);
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[23:16] + (off_r2 << 7);

            di_2            <=  (sel_ram_2) ? 
                                            {24'h000000, 24'h000000, data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_02[23:00], data_out_1_02[23:00]} ;                    
        
        end

        else if(adsub_21 | adsub_23 | adsub_24) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);

            di_2            <=  (sel_ram_2) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_12[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_02[23:00]} ;                         
        
        end   
           
        else if(encod) begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  ad_1_02;
            addr_2_02       <=  ad_2_02; 
            addr_1_12       <=  ad_1_12;
            addr_2_12       <=  ad_2_12;
            
            di_2            <=  0; 
        end
        
        else if(decod) begin
            enable_1_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_2_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_1_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            enable_2_12     <= (sel_d_2) ? 1'b1 : 1'b0;


            /*
            data_in_1_02    <=  {12'h000, input_decoder[23:00]};
            data_in_2_02    <=  {12'h000, input_decoder[47:24]};
            data_in_1_12    <=  {12'h000, input_decoder[23:00]};
            data_in_2_12    <=  {12'h000, input_decoder[47:24]};
            */

            data_in_1_02    <=  {12'h000, in_1_decod_2};
            data_in_2_02    <=  {12'h000, in_2_decod_2};
            data_in_1_12    <=  {12'h000, in_1_decod_2};
            data_in_2_12    <=  {12'h000, in_2_decod_2};

            addr_1_02       <=  ad_1_02;
            addr_2_02       <=  ad_2_02; 
            addr_1_12       <=  ad_1_12;
            addr_2_12       <=  ad_2_12;
            
            di_2            <=  0; 
        end
        
        else begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  0;
            addr_2_02       <=  0; 
            addr_1_12       <=  0;
            addr_2_12       <=  0;
            
            di_2            <=  0; 
        end   
    end
    
    // -- BU - 3 -- // 
    always @(posedge clk) begin
        if(cbd) begin 
            // RAM 
            enable_1_03     <= en_write;
            enable_2_03     <= en_write; 
            enable_1_13     <= 0;
            enable_2_13     <= 0;
            
            /*
            data_in_1_03    <=  {12'h000, data_in_1_cbd};
            data_in_2_03    <=  {12'h000, data_in_2_cbd};
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
            */
            
            /*
            data_in_1_03    <=  random_shares[159:128];
            data_in_2_03    <=  random_shares[191:160];
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
            */
            
            data_in_1_03    <=  {12'h000, random_shares[71:48]};
            data_in_2_03    <=  {12'h000, random_shares[95:72]};
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
  
            addr_1_03       <=  addr_1_cbd + (off_ram03 << 7);
            addr_2_03       <=  addr_2_cbd + (off_ram03 << 7);
            addr_1_13       <=  0;
            addr_2_13       <=  0;
            
            di_3            <=  {data_out_2_13[23:00], data_out_1_13[23:00], data_out_2_03[23:00], data_out_1_03[23:00]}; 
        end 
        
        else if(ntt_3) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= en_ram[4]; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= en_ram[5];
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[15:08] + (off_ram03 << 7); 
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[31:24] + (off_ram13 << 7); 
            
            di_3            <=  {data_out_2_13[23:00], data_out_1_13[23:00], data_out_2_03[23:00], data_out_1_03[23:00]}; 
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_3_r0 & !pwm_3_r1) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= 0; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[15:08] + (off_ram03 << 7); 
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[31:24] + (off_ram13 << 7); 
            
            // I suppose the final solution (s and e) is in RAM 1
            di_3            <=  (sel_ram_3) ? {do_1_1_r0, data_out_1_13[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_1_1_r0, data_out_1_03[23:00]} ; 
        end
        
        else if(!pwm_3_r0 & pwm_3_r1) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= 0; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[15:08] + (off_ram03 << 7); 
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[31:24] + (off_ram13 << 7); 
            
            // I suppose the final solution (s and e) is in RAM 1
            di_3            <=  (sel_ram_3) ? {do_1_1_r1, data_out_1_13[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_1_1_r1, data_out_1_03[23:00]} ; 
        end
        
        else if (pwm_3_r0 & pwm_3_r1) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= 0; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[07:00] + (off_r3 << 7);
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[23:16] + (off_r3 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_3            <=  (sel_ram_3) ? {data_out_2_13[23:00], data_out_1_13[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_03[23:00], data_out_1_03[23:00]} ; 
        end
        
        // Operate over BU_3 
        else if(adsub_33) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= 0; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[07:00] + (off_r3 << 7);
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[23:16] + (off_r3 << 7);

            di_3            <=  (sel_ram_3) ? 
                                            {24'h000000, 24'h000000, data_out_2_13[23:00], data_out_1_13[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_03[23:00], data_out_1_03[23:00]} ;                    
        
        end

        else if(adsub_31 | adsub_32 | adsub_34) begin
            enable_1_03     <= en_ram[4];
            enable_2_03     <= 0; 
            enable_1_13     <= en_ram[5];
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, do_3[23:00]};
            data_in_2_03    <=  {12'h000, do_3[47:24]};
            data_in_1_13    <=  {12'h000, do_3[71:48]};
            data_in_2_13    <=  {12'h000, do_3[95:72]};
            
            addr_1_03       <=  ad_3[07:00] + (off_ram03 << 7);
            addr_2_03       <=  ad_3[15:08] + (off_ram03 << 7); 
            addr_1_13       <=  ad_3[23:16] + (off_ram13 << 7);
            addr_2_13       <=  ad_3[31:24] + (off_ram13 << 7);

            di_3            <=  (sel_ram_3) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_13[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_03[23:00]} ;                     
        
        end   

        else if(encod) begin
            enable_1_03     <= 0;
            enable_2_03     <= 0; 
            enable_1_13     <= 0;
            enable_2_13     <= 0;
            
            data_in_1_03    <=  0;
            data_in_2_03    <=  0;
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
            
            addr_1_03       <=  ad_1_03;
            addr_2_03       <=  ad_2_03; 
            addr_1_13       <=  ad_1_13;
            addr_2_13       <=  ad_2_13;
            
            di_3            <=  0; 
        end
        
        else if(decod) begin
            enable_1_03     <= (sel_d_3) ? 1'b0 : 1'b1;
            enable_2_03     <= (sel_d_3) ? 1'b0 : 1'b1;
            enable_1_13     <= (sel_d_3) ? 1'b1 : 1'b0;
            enable_2_13     <= (sel_d_3) ? 1'b1 : 1'b0;
            
            /*
            data_in_1_03    <=  {12'h000, input_decoder[23:00]};
            data_in_2_03    <=  {12'h000, input_decoder[47:24]};
            data_in_1_13    <=  {12'h000, input_decoder[23:00]};
            data_in_2_13    <=  {12'h000, input_decoder[47:24]};
            */

            data_in_1_03    <=  {12'h000, in_1_decod_3};
            data_in_2_03    <=  {12'h000, in_2_decod_3};
            data_in_1_13    <=  {12'h000, in_1_decod_3};
            data_in_2_13    <=  {12'h000, in_2_decod_3};

            addr_1_03       <=  ad_1_03;
            addr_2_03       <=  ad_2_03; 
            addr_1_13       <=  ad_1_13;
            addr_2_13       <=  ad_2_13;
            
            di_3            <=  0; 
        end
        
        else begin
            enable_1_03     <= 0;
            enable_2_03     <= 0; 
            enable_1_13     <= 0;
            enable_2_13     <= 0;
            
            data_in_1_03    <=  0;
            data_in_2_03    <=  0;
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
            
            addr_1_03       <=  0;
            addr_2_03       <=  0; 
            addr_1_13       <=  0;
            addr_2_13       <=  0;
            
            di_3            <=  0; 
        end   
    end

    // -- BU - 4 -- // 
    
    reg [9:0] addr_3;           always @(posedge clk) addr_3 <= addr_1_cbd + (off_ram04 << 7);
    reg [9:0] addr_4;           always @(posedge clk) addr_4 <= addr_2_cbd + (off_ram04 << 7);
    reg [23:0] random_shares_3; always @(posedge clk) random_shares_3 <= random_shares[119:96];
    reg [23:0] random_shares_4; always @(posedge clk) random_shares_4 <= random_shares[143:120];
    
    always @(posedge clk) begin
        if(cbd_clk) begin 
            // RAM 
            enable_1_04     <= en_write_clk;
            enable_2_04     <= en_write_clk; 
            enable_1_14     <= 0;
            enable_2_14     <= 0;
            
            /*
            data_in_1_04    <=  {12'h000, data_in_1_cbd};
            data_in_2_04    <=  {12'h000, data_in_2_cbd};
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;
            */

            data_in_1_04    <=  {12'h000, random_shares_3};
            data_in_2_04    <=  {12'h000, random_shares_4};
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;


            addr_1_04       <=  addr_3;
            addr_2_04       <=  addr_4;
            addr_1_14       <=  0;
            addr_2_14       <=  0;
            
            di_4            <=  {data_out_2_14[23:00], data_out_1_14[23:00], data_out_2_04[23:00], data_out_1_04[23:00]}; 
        end 
        
        else if(ntt_4) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= en_ram[6]; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= en_ram[7];
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[15:08] + (off_ram04 << 7); 
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[31:24] + (off_ram14 << 7); 
            
            di_4            <=  {data_out_2_14[23:00], data_out_1_14[23:00], data_out_2_04[23:00], data_out_1_04[23:00]}; 
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_4_r0 & !pwm_4_r1) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= 0; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[15:08] + (off_ram04 << 7); 
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[31:24] + (off_ram14 << 7); 
            
            // I suppose the final solution (s and e) is in RAM 1
            di_4            <=  (sel_ram_4) ? {do_2_1_r0, data_out_1_14[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_1_r0, data_out_1_04[23:00]} ; 
        end
        
        else if(!pwm_4_r0 & pwm_4_r1) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= 0; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[15:08] + (off_ram04 << 7); 
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[31:24] + (off_ram14 << 7);  
            
            // I suppose the final solution (s and e) is in RAM 1
            di_4            <=  (sel_ram_4) ? {do_2_1_r1, data_out_1_14[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_1_r1, data_out_1_04[23:00]} ; 
        end
        
        else if (pwm_4_r0 & pwm_4_r1) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= 0; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[07:00] + (off_r4 << 7);
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[23:16] + (off_r4 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_4            <=  (sel_ram_4) ? {data_out_2_14[23:00], data_out_1_14[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_04[23:00], data_out_1_04[23:00]} ; 
        end
        
        
        // Operate over BU_4 
        else if(adsub_44) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= 0; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[07:00] + (off_r4 << 7);
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[23:16] + (off_r4 << 7);

            di_4            <=  (sel_ram_4) ? 
                                            {24'h000000, 24'h000000, data_out_2_14[23:00], data_out_1_14[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_04[23:00], data_out_1_04[23:00]} ;                    
        
        end

        else if(adsub_41 | adsub_42 | adsub_43) begin
            enable_1_04     <= en_ram[6];
            enable_2_04     <= 0; 
            enable_1_14     <= en_ram[7];
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, do_4[23:00]};
            data_in_2_04    <=  {12'h000, do_4[47:24]};
            data_in_1_14    <=  {12'h000, do_4[71:48]};
            data_in_2_14    <=  {12'h000, do_4[95:72]};
            
            addr_1_04       <=  ad_4[07:00] + (off_ram04 << 7);
            addr_2_04       <=  ad_4[15:08] + (off_ram04 << 7); 
            addr_1_14       <=  ad_4[23:16] + (off_ram14 << 7);
            addr_2_14       <=  ad_4[31:24] + (off_ram14 << 7);

            di_4            <=  (sel_ram_4) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_14[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_04[23:00]} ;                  
        
        end  
        
        else if(encod) begin
            enable_1_04     <= 0;
            enable_2_04     <= 0; 
            enable_1_14     <= 0;
            enable_2_14     <= 0;
            
            data_in_1_04    <=  0;
            data_in_2_04    <=  0;
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;
            
            addr_1_04       <=  ad_1_04;
            addr_2_04       <=  ad_2_04; 
            addr_1_14       <=  ad_1_14;
            addr_2_14       <=  ad_2_14;
            
            di_4            <=  0; 
        end
        
        else if(decod) begin
            enable_1_04     <= (sel_d_4) ? 1'b0 : 1'b1;
            enable_2_04     <= (sel_d_4) ? 1'b0 : 1'b1;
            enable_1_14     <= (sel_d_4) ? 1'b1 : 1'b0;
            enable_2_14     <= (sel_d_4) ? 1'b1 : 1'b0;
            
            /*
            data_in_1_04    <=  {12'h000, input_decoder[23:00]};
            data_in_2_04    <=  {12'h000, input_decoder[47:24]};
            data_in_1_14    <=  {12'h000, input_decoder[23:00]};
            data_in_2_14    <=  {12'h000, input_decoder[47:24]};
            */

            data_in_1_04    <=  {12'h000, in_1_decod_4};
            data_in_2_04    <=  {12'h000, in_2_decod_4};
            data_in_1_14    <=  {12'h000, in_1_decod_4};
            data_in_2_14    <=  {12'h000, in_2_decod_4};

            addr_1_04       <=  ad_1_04;
            addr_2_04       <=  ad_2_04; 
            addr_1_14       <=  ad_1_14;
            addr_2_14       <=  ad_2_14;
            
            di_4            <=  0; 
        end
        
        else begin
            enable_1_04     <= 0;
            enable_2_04     <= 0; 
            enable_1_14     <= 0;
            enable_2_14     <= 0;
            
            data_in_1_04    <=  0;
            data_in_2_04    <=  0;
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;
            
            addr_1_04       <=  (off_ram04 << 7);
            addr_2_04       <=  (off_ram04 << 7); 
            addr_1_14       <=  (off_ram14 << 7);
            addr_2_14       <=  (off_ram14 << 7);
            
            di_4            <=  0; 
        end   
    end
        
    // REJ - UNIFORM 
    
    // Seguramente haya que poner distintos off_r0 / off_r1
    always @(posedge clk) begin
        if(pwm_1_r0)    ar_1_0_r0 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r0 <= 0;
        if(pwm_2_r0)    ar_2_0_r0 <= (sel_ram_2) ? ad_2[23:16] + (off_r2  << 7) : ad_2[07:00] + (off_r2 << 7);
        else            ar_2_0_r0 <= 0;
        if(pwm_3_r0)    ar_1_1_r0 <= (sel_ram_3) ? ad_3[23:16] + (off_r3  << 7) : ad_3[07:00] + (off_r3 << 7);
        else            ar_1_1_r0 <= 0;
        if(pwm_4_r0)    ar_2_1_r0 <= (sel_ram_4) ? ad_4[23:16] + (off_r4  << 7) : ad_4[07:00] + (off_r4 << 7);
        else            ar_2_1_r0 <= 0;
        
        if(pwm_1_r1)    ar_1_0_r1 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r1 <= 0;
        if(pwm_2_r1)    ar_2_0_r1 <= (sel_ram_2) ? ad_2[23:16] + (off_r2  << 7) : ad_2[07:00] + (off_r2 << 7);
        else            ar_2_0_r1 <= 0;
        if(pwm_3_r1)    ar_1_1_r1 <= (sel_ram_3) ? ad_3[23:16] + (off_r3  << 7) : ad_3[07:00] + (off_r3 << 7);
        else            ar_1_1_r1 <= 0;
        if(pwm_4_r1)    ar_2_1_r1 <= (sel_ram_4) ? ad_4[23:16] + (off_r4  << 7) : ad_4[07:00] + (off_r4 << 7);
        else            ar_2_1_r1 <= 0;
    end
endmodule


module DMU_MASKED_N_BU_2 #(
    parameter N_SHARES = 2
)(
    
    input           clk,
    
    input   [40:0]  control_dmu,
    input   [3:0]   off_r1,
    input   [3:0]   off_r2,
    input   [3:0]   off_ram01,
    input   [3:0]   off_ram11,
    input   [3:0]   off_ram02,
    input   [3:0]   off_ram12,
    
    input   [09:00] ad_1_01,
    input   [09:00] ad_2_01,
    input   [09:00] ad_1_11,
    input   [09:00] ad_2_11,
    input   [09:00] ad_1_02,
    input   [09:00] ad_2_02,
    input   [09:00] ad_1_12,
    input   [09:00] ad_2_12,

    // SHARES
    output                      en_read,
    input   [N_SHARES*24-1:0]   random_shares,
    
    // CBD
    input           en_write,
    input   [23:0]  data_in_1_cbd,
    input   [23:0]  data_in_2_cbd,
    input   [7:0]   addr_1_cbd,  
    input   [7:0]   addr_2_cbd, 
    
    // REJ - UNIFORM
    input       [23:0]  do_1_0_r0,
    input       [23:0]  do_2_0_r0,
    output  reg [9:0]   ar_1_0_r0,
    output  reg [9:0]   ar_2_0_r0,
    
    input       [23:0]  do_1_0_r1,
    input       [23:0]  do_2_0_r1,
    output  reg [9:0]   ar_1_0_r1,
    output  reg [9:0]   ar_2_0_r1,
    
    // BU ENGINE
    input       [7:0]       en_ram,
    output reg  [4*24-1:0]  di_1,
    input       [4*24-1:0]  do_1,
    input       [4*8-1:0]   ad_1,
    output reg  [4*24-1:0]  di_2,
    input       [4*24-1:0]  do_2,
    input       [4*8-1:0]   ad_2,
    
    // DECODER
    input       [2*24-1:0] input_decoder,
    
    // RAM BANK
    output  reg             enable_1_01,
    output  reg             enable_2_01,
    output  reg [9:0]       addr_1_01,
    output  reg [9:0]       addr_2_01,
    output  reg [35:0]      data_in_1_01,
    output  reg [35:0]      data_in_2_01,
    input       [35:0]      data_out_1_01,
    input       [35:0]      data_out_2_01,
    
    output  reg             enable_1_11,
    output  reg             enable_2_11,
    output  reg [9:0]       addr_1_11,
    output  reg [9:0]       addr_2_11,
    output  reg [35:0]      data_in_1_11,
    output  reg [35:0]      data_in_2_11,
    input       [35:0]      data_out_1_11,
    input       [35:0]      data_out_2_11,
    
   output   reg             enable_1_02,
   output   reg             enable_2_02,
   output   reg [9:0]       addr_1_02,
   output   reg [9:0]       addr_2_02,
   output   reg [35:0]      data_in_1_02,
   output   reg [35:0]      data_in_2_02,
    input       [35:0]      data_out_1_02,
    input       [35:0]      data_out_2_02,
    
    output  reg             enable_1_12,
    output  reg             enable_2_12,
    output  reg [9:0]       addr_1_12,
    output  reg [9:0]       addr_2_12,
    output  reg [35:0]      data_in_1_12,
    output  reg [35:0]      data_in_2_12,
    input       [35:0]      data_out_1_12,
    input       [35:0]      data_out_2_12

    );
    
    wire cbd_1;
    wire ntt_1;
    wire pwm_1_r0;
    wire pwm_1_r1;
    wire adsub_11;
    wire adsub_12;
    wire adsub_13;
    wire adsub_14;
    
    assign cbd_1    = control_dmu[0];
    assign ntt_1    = control_dmu[1];
    assign pwm_1_r0 = control_dmu[2];
    assign pwm_1_r1 = control_dmu[3];
    assign adsub_11 = control_dmu[4];
    assign adsub_12 = control_dmu[5];
    assign adsub_13 = control_dmu[6];
    assign adsub_14 = control_dmu[7];  
    
    wire cbd_2;
    wire ntt_2;
    wire pwm_2_r0;
    wire pwm_2_r1;
    wire adsub_21;
    wire adsub_22;
    wire adsub_23;
    wire adsub_24;
    
    assign cbd_2    = control_dmu[8];
    assign ntt_2    = control_dmu[9];
    assign pwm_2_r0 = control_dmu[10];
    assign pwm_2_r1 = control_dmu[11];
    assign adsub_21 = control_dmu[12];
    assign adsub_22 = control_dmu[13];
    assign adsub_23 = control_dmu[14];
    assign adsub_24 = control_dmu[15]; 
    

    wire encod; 
    wire decod_1;   
    wire sel_d_1;
    wire decod_2;
    wire sel_d_2;
    wire decod_3;
    wire sel_d_3;
    wire decod_4;
    wire sel_d_4;
    
    assign encod    = control_dmu[32]; 
    assign decod_1  = control_dmu[33];
    assign sel_d_1  = control_dmu[34]; 
    assign decod_2  = control_dmu[35];
    assign sel_d_2  = control_dmu[36]; 
    assign decod_3  = control_dmu[37];
    assign sel_d_3  = control_dmu[38]; 
    assign decod_4  = control_dmu[39];
    assign sel_d_4  = control_dmu[40];
    // assign deco_dk  = control_dmu[33]; 
    // assign deco_ct  = control_dmu[34]; 
    
    wire sel_ram_1;
    wire sel_ram_2;
    wire sel_ram_3;
    wire sel_ram_4;
    assign sel_ram_1 = en_ram[0];
    assign sel_ram_2 = en_ram[2];
    assign sel_ram_3 = en_ram[4];
    assign sel_ram_4 = en_ram[6];
    
    wire cbd;
    assign cbd = cbd_1 | cbd_2 ;

    wire decod;
    assign decod = decod_1 | decod_2 ;
    
    wire decod_masked;
    assign decod_masked = decod_1;
    
    // Shares
    assign en_read = cbd | (decod & decod_masked);
    /*
    always @(posedge clk) begin
        if(en_write)    en_read <= 1'b1;
        else            en_read <= 1'b0;
    end
    */
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_cbd;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_cbd;

    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_01_cbd (.a(data_in_1_cbd[11:00]), .b(random_shares[11:00]), .c(in_01_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_11_cbd (.a(data_in_1_cbd[23:12]), .b(random_shares[23:12]), .c(in_11_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_02_cbd (.a(data_in_2_cbd[11:00]), .b(random_shares[35:24]), .c(in_02_cbd));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_12_cbd (.a(data_in_2_cbd[23:12]), .b(random_shares[47:36]), .c(in_12_cbd));
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_decod_masked;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_decod_masked;
    
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_01_decod (.a(input_decoder[11:00]), .b(random_shares[11:00]), .c(in_01_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_11_decod (.a(input_decoder[23:12]), .b(random_shares[23:12]), .c(in_11_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_02_decod (.a(input_decoder[35:24]), .b(random_shares[35:24]), .c(in_02_decod_masked));
    (* DONT_TOUCH = "TRUE" *) mod_sub mod_sub_12_decod (.a(input_decoder[47:36]), .b(random_shares[47:36]), .c(in_12_decod_masked));
    
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_01_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_11_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_02_decod_1;
    (* DONT_TOUCH = "TRUE" *) wire [11:00] in_12_decod_1;
    
    assign in_01_decod_1 = (decod_masked) ? in_01_decod_masked : input_decoder[11:00];
    assign in_11_decod_1 = (decod_masked) ? in_11_decod_masked : input_decoder[23:12];
    assign in_02_decod_1 = (decod_masked) ? in_02_decod_masked : input_decoder[35:24];
    assign in_12_decod_1 = (decod_masked) ? in_12_decod_masked : input_decoder[47:36];
    
    

    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_1_decod_2;
    (* DONT_TOUCH = "TRUE" *) wire [23:00] in_2_decod_2;

    assign in_1_decod_2 = (decod_masked) ? random_shares[23:00]   : input_decoder[23:00];
    assign in_2_decod_2 = (decod_masked) ? random_shares[47:24]   : input_decoder[47:24];
    
    // -- BU - 1 -- // 
    always @(posedge clk) begin
        if(cbd) begin 
            // RAM 
            enable_1_01     <= en_write;
            enable_2_01     <= en_write; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            /*
            data_in_1_01    <=  {12'h000, data_in_1_cbd};
            data_in_2_01    <=  {12'h000, data_in_2_cbd};
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            */
            /*
            data_in_1_01    <=  random_shares[31:00];
            data_in_2_01    <=  random_shares[63:32];
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            */
            
            data_in_1_01    <=  {12'h000, in_11_cbd, in_01_cbd};
            data_in_2_01    <=  {12'h000, in_12_cbd, in_02_cbd};
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01       <=  addr_1_cbd + (off_ram01 << 7);
            addr_2_01       <=  addr_2_cbd + (off_ram11 << 7);
            addr_1_11       <=  0;
            addr_2_11       <=  0;
            
            di_1            <=  {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]}; 
        end 
        
        else if(ntt_1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= en_ram[0]; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= en_ram[1];
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7); 
            
            di_1            <=  {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]}; 
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_1_r0 & !pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_1            <=  (sel_ram_1) ? {do_1_0_r0, data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                            {24'h000_000, 24'h000_000, do_1_0_r0, data_out_1_01[23:00]} ; 
        end
        
        else if(!pwm_1_r0 & pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[15:08] + (off_ram01 << 7); 
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[31:24] + (off_ram11 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_1            <=  (sel_ram_1) ? {do_1_0_r1, data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_1_0_r1, data_out_1_01[23:00]} ; 
        end
        else if (pwm_1_r0 & pwm_1_r1) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_1            <=  (sel_ram_1) ? {data_out_2_11[23:00], data_out_1_11[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_01[23:00], data_out_1_01[23:00]} ; 
        end
        
        // Operate over BU_1 
        else if(adsub_11) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);

            di_1            <=  (sel_ram_1) ? 
                                            {24'h000000, 24'h000000, data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_01[23:00], data_out_1_01[23:00]} ;                    
        
        end

        else if(adsub_12 | adsub_13 | adsub_14) begin
            enable_1_01     <= en_ram[0];
            enable_2_01     <= 0; 
            enable_1_11     <= en_ram[1];
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, do_1[23:00]};
            data_in_2_01    <=  {12'h000, do_1[47:24]};
            data_in_1_11    <=  {12'h000, do_1[71:48]};
            data_in_2_11    <=  {12'h000, do_1[95:72]};
            
            addr_1_01       <=  ad_1[07:00] + (off_ram01 << 7);
            addr_2_01       <=  ad_1[07:00] + (off_r1 << 7);
            addr_1_11       <=  ad_1[23:16] + (off_ram11 << 7);
            addr_2_11       <=  ad_1[23:16] + (off_r1 << 7);

            di_1            <=  (sel_ram_1) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_11[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_01[23:00]} ;                    
        
        end
        
        else if(encod) begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01       <=  ad_1_01;
            addr_2_01       <=  ad_2_01; 
            addr_1_11       <=  ad_1_11;
            addr_2_11       <=  ad_2_11;
            
            di_1            <=  0; 
        end
        
        else if(decod) begin
            enable_1_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_2_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_1_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            enable_2_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            
            /*
            data_in_1_01    <=  {12'h000, input_decoder[23:00]};
            data_in_2_01    <=  {12'h000, input_decoder[47:24]};
            data_in_1_11    <=  {12'h000, input_decoder[23:00]};
            data_in_2_11    <=  {12'h000, input_decoder[47:24]};
            */
            
            data_in_1_01    <=  {12'h000, in_11_decod_1, in_01_decod_1};
            data_in_2_01    <=  {12'h000, in_12_decod_1, in_02_decod_1};
            data_in_1_11    <=  {12'h000, in_11_decod_1, in_01_decod_1};
            data_in_2_11    <=  {12'h000, in_12_decod_1, in_02_decod_1};

            addr_1_01       <=  ad_1_01;
            addr_2_01       <=  ad_2_01; 
            addr_1_11       <=  ad_1_11;
            addr_2_11       <=  ad_2_11;
            
            di_1            <=  0; 
        end
        
        else begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            addr_1_01    <=  0;
            addr_2_01    <=  0; 
            addr_1_11    <=  0;
            addr_2_11    <=  0;
            
            di_1         <=  0; 
        
        end   
    end
    
    reg cbd_clk;                always @(posedge clk) cbd_clk <= cbd;
    reg en_write_clk;           always @(posedge clk) en_write_clk <= en_write;
    reg [23:0] random_shares_1; always @(posedge clk) random_shares_1 <= random_shares[23:00];
    reg [23:0] random_shares_2; always @(posedge clk) random_shares_2 <= random_shares[47:24];
    reg [9:0] addr_1;           always @(posedge clk) addr_1 <= addr_1_cbd + (off_ram02 << 7);
    reg [9:0] addr_2;           always @(posedge clk) addr_2 <= addr_2_cbd + (off_ram02 << 7);

    /*
    wire en_write_clk;           assign en_write_clk = en_write;
    wire [23:0] random_shares_1; assign random_shares_1 = random_shares[23:00];
    wire [23:0] random_shares_2; assign random_shares_2 = random_shares[47:24];
    wire [9:0] addr_1;           assign addr_1 = addr_1_cbd + (off_ram02 << 7);
    wire [9:0] addr_2;           assign addr_2 = addr_2_cbd + (off_ram02 << 7);
    */
    // -- BU - 2 -- // 
    always @(posedge clk) begin
        if(cbd_clk) begin 
            // RAM 
            
            enable_1_02     <= en_write_clk;
            enable_2_02     <= en_write_clk; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, random_shares_1};
            data_in_2_02    <=  {12'h000, random_shares_2};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  addr_1;
            addr_2_02       <=  addr_2;
            addr_1_12       <=  0;
            addr_2_12       <=  0;
            
            
            /*
            enable_1_02     <= en_write;
            enable_2_02     <= en_write; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            
            data_in_1_02    <=  {12'h000, random_shares[23:00]};
            data_in_2_02    <=  {12'h000, random_shares[47:24]};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
                  
            addr_1_02       <=  addr_1_cbd + (off_ram02 << 7);
            addr_2_02       <=  addr_2_cbd + (off_ram02 << 7);
            addr_1_12       <=  0;
            addr_2_12       <=  0;
            */
            
            di_2            <=  {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]}; 
        end 
        
        else if(ntt_2) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= en_ram[2]; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= en_ram[3];
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7); 
            
            di_2            <=  {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]};
            
        end
        /*
        assign di_10_1 = di_1[23:00]; data_in_1_r0 (a1, a0)
        assign di_20_1 = di_1[47:24]; data_in_2_r0 (b1, b0)
        assign di_11_1 = di_1[71:48]; data_in_1_r1 (a1, a0)
        assign di_21_1 = di_1[95:72]; data_in_2_r1 (b1 ,b0)
        */
        else if(pwm_2_r0 & !pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_2            <=  (sel_ram_2) ? {do_2_0_r0, data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_0_r0, data_out_1_02[23:00]} ; 
        end
        
        else if(!pwm_2_r0 & pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1
            di_2            <=  (sel_ram_2) ? {do_2_0_r1, data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, do_2_0_r1, data_out_1_02[23:00]} ; 
        end
        
         else if (pwm_2_r0 & pwm_2_r1) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[07:00] + (off_r2 << 7);
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[23:16] + (off_r2 << 7);
            
            // I suppose the final solution (s and e) is in RAM 1                      
            di_2            <=  (sel_ram_2) ? {data_out_2_12[23:00], data_out_1_12[23:00], 24'h000_000, 24'h000_000} : 
                                          {24'h000_000, 24'h000_000, data_out_2_02[23:00], data_out_1_02[23:00]} ; 
        end
        
        // Operate over BU_2 
        else if(adsub_22) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[07:00] + (off_r2 << 7);
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[23:16] + (off_r2 << 7);

            di_2            <=  (sel_ram_2) ? 
                                            {24'h000000, 24'h000000, data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_02[23:00], data_out_1_02[23:00]} ;                    
        
        end

        else if(adsub_21 | adsub_23 | adsub_24) begin
            enable_1_02     <= en_ram[2];
            enable_2_02     <= 0; 
            enable_1_12     <= en_ram[3];
            enable_2_12     <= 0;
            
            data_in_1_02    <=  {12'h000, do_2[23:00]};
            data_in_2_02    <=  {12'h000, do_2[47:24]};
            data_in_1_12    <=  {12'h000, do_2[71:48]};
            data_in_2_12    <=  {12'h000, do_2[95:72]};
            
            addr_1_02       <=  ad_2[07:00] + (off_ram02 << 7);
            addr_2_02       <=  ad_2[15:08] + (off_ram02 << 7); 
            addr_1_12       <=  ad_2[23:16] + (off_ram12 << 7);
            addr_2_12       <=  ad_2[31:24] + (off_ram12 << 7);

            di_2            <=  (sel_ram_2) ? 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_12[23:00]} : 
                                            {24'h000000, 24'h000000, 24'h000000, data_out_1_02[23:00]} ;                         
        
        end   
           
        else if(encod) begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  ad_1_02;
            addr_2_02       <=  ad_2_02; 
            addr_1_12       <=  ad_1_12;
            addr_2_12       <=  ad_2_12;
            
            di_2            <=  0; 
        end
        
        else if(decod) begin
            enable_1_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_2_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_1_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            enable_2_12     <= (sel_d_2) ? 1'b1 : 1'b0;


            /*
            data_in_1_02    <=  {12'h000, input_decoder[23:00]};
            data_in_2_02    <=  {12'h000, input_decoder[47:24]};
            data_in_1_12    <=  {12'h000, input_decoder[23:00]};
            data_in_2_12    <=  {12'h000, input_decoder[47:24]};
            */

            data_in_1_02    <=  {12'h000, in_1_decod_2};
            data_in_2_02    <=  {12'h000, in_2_decod_2};
            data_in_1_12    <=  {12'h000, in_1_decod_2};
            data_in_2_12    <=  {12'h000, in_2_decod_2};

            addr_1_02       <=  ad_1_02;
            addr_2_02       <=  ad_2_02; 
            addr_1_12       <=  ad_1_12;
            addr_2_12       <=  ad_2_12;
            
            di_2            <=  0; 
        end
        
        else begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  0;
            addr_2_02       <=  0; 
            addr_1_12       <=  0;
            addr_2_12       <=  0;
            
            di_2            <=  0; 
        end   
    end
    
    // REJ - UNIFORM 
    
    // Seguramente haya que poner distintos off_r0 / off_r1
    always @(posedge clk) begin
        if(pwm_1_r0)    ar_1_0_r0 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r0 <= 0;
        if(pwm_2_r0)    ar_2_0_r0 <= (sel_ram_2) ? ad_2[23:16] + (off_r2  << 7) : ad_2[07:00] + (off_r2 << 7);
        else            ar_2_0_r0 <= 0;
        
        if(pwm_1_r1)    ar_1_0_r1 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r1 <= 0;
        if(pwm_2_r1)    ar_2_0_r1 <= (sel_ram_2) ? ad_2[23:16] + (off_r2  << 7) : ad_2[07:00] + (off_r2 << 7);
        else            ar_2_0_r1 <= 0;
    end
endmodule
