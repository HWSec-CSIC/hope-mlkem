`timescale 1ns / 1ps

module DMU_N_BU_4 (
    
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
    
    
    // -- BU - 1 -- // 
    always @(posedge clk) begin
        if(cbd_1) begin 
            // RAM 
            enable_1_01     <= en_write;
            enable_2_01     <= en_write; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, data_in_1_cbd};
            data_in_2_01    <=  {12'h000, data_in_2_cbd};
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
        else if(adsub_11 | adsub_12 | adsub_13 | adsub_14) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_11,adsub_12,adsub_13,adsub_14})
                // 4'b1000: di_1         <=     {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]};  
                4'b1000: di_1         <=     0;  
                4'b0100: di_1         <=  (sel_ram_1) ? 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_01[23:00], data_out_1_01[23:00]} ; 
                4'b0010: di_1         <=  (sel_ram_1) ? 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_01[23:00], data_out_1_01[23:00]} ; 
                4'b0001: di_1         <=  (sel_ram_1) ? 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_01[23:00], data_out_1_01[23:00]} ; 
                // default: di_1         <=  {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]};
                default: di_1         <=  0;
            endcase                     
        
        end
        
        else if(adsub_21 | adsub_31 | adsub_41) begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;
            
            // case per each one
            case({adsub_21,adsub_31,adsub_41})
                3'b100: begin
                            addr_1_01    <=  (sel_ram_2) ? ad_2[23:16] + (off_r2 << 7) : ad_2[07:00] + (off_r2 << 7);
                            addr_2_01    <=  (sel_ram_2) ? ad_2[31:24] + (off_r2 << 7) : ad_2[15:08] + (off_r2 << 7); 
                            addr_1_11    <=  (sel_ram_2) ? ad_2[07:00] + (off_r2 << 7) : ad_2[23:16] + (off_r2 << 7);
                            addr_2_11    <=  (sel_ram_2) ? ad_2[15:08] + (off_r2 << 7) : ad_2[31:24] + (off_r2 << 7);
                        end 
                3'b010: begin
                            addr_1_01    <=  (sel_ram_3) ? ad_3[23:16] + (off_r3 << 7) : ad_3[07:00] + (off_r3 << 7);
                            addr_2_01    <=  (sel_ram_3) ? ad_3[31:24] + (off_r3 << 7) : ad_3[15:08] + (off_r3 << 7); 
                            addr_1_11    <=  (sel_ram_3) ? ad_3[07:00] + (off_r3 << 7) : ad_3[23:16] + (off_r3 << 7);
                            addr_2_11    <=  (sel_ram_3) ? ad_3[15:08] + (off_r3 << 7) : ad_3[31:24] + (off_r3 << 7);
                        end 
                3'b001: begin
                            addr_1_01    <=  (sel_ram_4) ? ad_4[23:16] + (off_r4 << 7) : ad_4[07:00] + (off_r4 << 7);
                            addr_2_01    <=  (sel_ram_4) ? ad_4[31:24] + (off_r4 << 7) : ad_4[15:08] + (off_r4 << 7); 
                            addr_1_11    <=  (sel_ram_4) ? ad_4[07:00] + (off_r4 << 7) : ad_4[23:16] + (off_r4 << 7);
                            addr_2_11    <=  (sel_ram_4) ? ad_4[15:08] + (off_r4 << 7) : ad_4[31:24] + (off_r4 << 7);
                        end 
               default: begin
                            addr_1_01    <=  (sel_ram_2) ? ad_2[23:16] + (off_r2 << 7) : ad_2[07:00] + (off_r2 << 7);
                            addr_2_01    <=  (sel_ram_2) ? ad_2[31:24] + (off_r2 << 7) : ad_2[15:08] + (off_r2 << 7); 
                            addr_1_11    <=  (sel_ram_2) ? ad_2[07:00] + (off_r2 << 7) : ad_2[23:16] + (off_r2 << 7);
                            addr_2_11    <=  (sel_ram_2) ? ad_2[15:08] + (off_r2 << 7) : ad_2[31:24] + (off_r2 << 7);
                        end 
            endcase
            
            di_1         <= 0;
        
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
        
        else if(decod_1) begin
            enable_1_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_2_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_1_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            enable_2_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            
            data_in_1_01    <=  {12'h000, input_decoder[23:00]};
            data_in_2_01    <=  {12'h000, input_decoder[47:24]};
            data_in_1_11    <=  {12'h000, input_decoder[23:00]};
            data_in_2_11    <=  {12'h000, input_decoder[47:24]};
            
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
     
    // -- BU - 2 -- // 
    always @(posedge clk) begin
        if(cbd_2) begin 
            // RAM 
            enable_1_02     <= en_write;
            enable_2_02     <= en_write; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
                            
            data_in_1_02    <=  {12'h000, data_in_1_cbd};
            data_in_2_02    <=  {12'h000, data_in_2_cbd};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  addr_1_cbd + (off_ram02 << 7);
            addr_2_02       <=  addr_2_cbd + (off_ram02 << 7);
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
        else if(adsub_21 | adsub_22 | adsub_23 | adsub_24) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_21,adsub_22,adsub_23,adsub_24})
            
                4'b1000: di_2         <=   (sel_ram_2) ? 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_02[23:00], data_out_1_02[23:00]} ;  
                // 4'b0100: di_2         <=     {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]};  
                4'b0100: di_2         <=  0;  
                4'b0010: di_2         <=  (sel_ram_2) ? 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_02[23:00], data_out_1_02[23:00]} ; 
                4'b0001: di_2         <=  (sel_ram_2) ? 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_02[23:00], data_out_1_02[23:00]} ; 
                // default: di_2         <=     {data_out_2_12[23:00], data_out_1_12[23:00], data_out_2_02[23:00], data_out_1_02[23:00]};
                default: di_2         <=   0;
            
            endcase                     
        
        end
        
        else if(adsub_12 | adsub_32 | adsub_42) begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            // case per each one
            case({adsub_12,adsub_32,adsub_42})
                3'b100: begin
                            addr_1_02    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_02    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_12    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_12    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
                3'b010: begin
                            addr_1_02    <=  (sel_ram_3) ? ad_3[23:16] + (off_r3 << 7) : ad_3[07:00] + (off_r3 << 7);
                            addr_2_02    <=  (sel_ram_3) ? ad_3[31:24] + (off_r3 << 7) : ad_3[15:08] + (off_r3 << 7); 
                            addr_1_12    <=  (sel_ram_3) ? ad_3[07:00] + (off_r3 << 7) : ad_3[23:16] + (off_r3 << 7);
                            addr_2_12    <=  (sel_ram_3) ? ad_3[15:08] + (off_r3 << 7) : ad_3[31:24] + (off_r3 << 7);
                        end 
                3'b001: begin
                            addr_1_02   <=  (sel_ram_4) ? ad_4[23:16] + (off_r4 << 7) : ad_4[07:00] + (off_r4 << 7);
                            addr_2_02   <=  (sel_ram_4) ? ad_4[31:24] + (off_r4 << 7) : ad_4[15:08] + (off_r4 << 7); 
                            addr_1_12   <=  (sel_ram_4) ? ad_4[07:00] + (off_r4 << 7) : ad_4[23:16] + (off_r4 << 7);
                            addr_2_12   <=  (sel_ram_4) ? ad_4[15:08] + (off_r4 << 7) : ad_4[31:24] + (off_r4 << 7);
                        end 
               default: begin
                            addr_1_02    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_02    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_12    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_12    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
            endcase
            
            di_2         <= 0;
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
        
        else if(decod_2) begin
            enable_1_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_2_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_1_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            enable_2_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            
            data_in_1_02    <=  {12'h000, input_decoder[23:00]};
            data_in_2_02    <=  {12'h000, input_decoder[47:24]};
            data_in_1_12    <=  {12'h000, input_decoder[23:00]};
            data_in_2_12    <=  {12'h000, input_decoder[47:24]};
            
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
        if(cbd_3) begin 
            // RAM 
            enable_1_03     <= en_write;
            enable_2_03     <= en_write; 
            enable_1_13     <= 0;
            enable_2_13     <= 0;
            
            data_in_1_03    <=  {12'h000, data_in_1_cbd};
            data_in_2_03    <=  {12'h000, data_in_2_cbd};
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
        else if(adsub_31 | adsub_32 | adsub_33 | adsub_34) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_31,adsub_32,adsub_33,adsub_34})
            
                4'b1000: di_3         <=   (sel_ram_3) ? 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_13[23:00], data_out_1_13[23:00]} : 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_03[23:00], data_out_1_03[23:00]} ;  
                4'b0100: di_3         <=   (sel_ram_3) ? 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_13[23:00], data_out_1_13[23:00]} : 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_03[23:00], data_out_1_03[23:00]} ;   
                // 4'b0010: di_3         <=     {data_out_2_13[23:00], data_out_1_13[23:00], data_out_2_03[23:00], data_out_1_03[23:00]};
                4'b0010: di_3         <=  0;
                
                4'b0001: di_3         <=  (sel_ram_3) ? 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_13[23:00], data_out_1_13[23:00]} : 
                                            {data_out_2_04[23:00], data_out_1_04[23:00], data_out_2_03[23:00], data_out_1_03[23:00]} ; 
                // default: di_3         <=     {data_out_2_13[23:00], data_out_1_13[23:00], data_out_2_03[23:00], data_out_1_03[23:00]};
                default: di_3         <=  0;
            
            endcase                     
        
        end
        
        else if(adsub_13 | adsub_23 | adsub_43) begin
            enable_1_03     <= 0;
            enable_2_03     <= 0; 
            enable_1_13     <= 0;
            enable_2_13     <= 0;
            
            data_in_1_03    <=  0;
            data_in_2_03    <=  0;
            data_in_1_13    <=  0;
            data_in_2_13    <=  0;
            
            // case per each one
            case({adsub_13,adsub_23,adsub_43})
                3'b100: begin
                            addr_1_03    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_03    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_13    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_13    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
                3'b010: begin
                            addr_1_03    <=  (sel_ram_2) ? ad_2[23:16] + (off_r2 << 7) : ad_2[07:00] + (off_r2 << 7);
                            addr_2_03    <=  (sel_ram_2) ? ad_2[31:24] + (off_r2 << 7) : ad_2[15:08] + (off_r2 << 7); 
                            addr_1_13    <=  (sel_ram_2) ? ad_2[07:00] + (off_r2 << 7) : ad_2[23:16] + (off_r2 << 7);
                            addr_2_13    <=  (sel_ram_2) ? ad_2[15:08] + (off_r2 << 7) : ad_2[31:24] + (off_r2 << 7);
                        end 
                3'b001: begin
                            addr_1_03    <=  (sel_ram_4) ? ad_4[23:16] + (off_r4 << 7) : ad_4[07:00] + (off_r4 << 7);
                            addr_2_03    <=  (sel_ram_4) ? ad_4[31:24] + (off_r4 << 7) : ad_4[15:08] + (off_r4 << 7); 
                            addr_1_13    <=  (sel_ram_4) ? ad_4[07:00] + (off_r4 << 7) : ad_4[23:16] + (off_r4 << 7);
                            addr_2_13    <=  (sel_ram_4) ? ad_4[15:08] + (off_r4 << 7) : ad_4[31:24] + (off_r4 << 7);
                        end 
               default: begin
                            addr_1_03    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_03    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_13    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_13    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
            endcase
            
            di_3         <= 0;
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
        
        else if(decod_3) begin
            enable_1_03     <= (sel_d_3) ? 1'b0 : 1'b1;
            enable_2_03     <= (sel_d_3) ? 1'b0 : 1'b1;
            enable_1_13     <= (sel_d_3) ? 1'b1 : 1'b0;
            enable_2_13     <= (sel_d_3) ? 1'b1 : 1'b0;
            
            data_in_1_03    <=  {12'h000, input_decoder[23:00]};
            data_in_2_03    <=  {12'h000, input_decoder[47:24]};
            data_in_1_13    <=  {12'h000, input_decoder[23:00]};
            data_in_2_13    <=  {12'h000, input_decoder[47:24]};
            
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
    always @(posedge clk) begin
        if(cbd_4) begin 
            // RAM 
            enable_1_04     <= en_write;
            enable_2_04     <= en_write; 
            enable_1_14     <= 0;
            enable_2_14     <= 0;
            
            data_in_1_04    <=  {12'h000, data_in_1_cbd};
            data_in_2_04    <=  {12'h000, data_in_2_cbd};
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;
            
            addr_1_04       <=  addr_1_cbd + (off_ram04 << 7);
            addr_2_04       <=  addr_2_cbd + (off_ram04 << 7);
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
        else if(adsub_41 | adsub_42 | adsub_43 | adsub_44) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_41,adsub_42,adsub_43,adsub_44})
            
                4'b1000: di_4         <=   (sel_ram_4) ? 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_14[23:00], data_out_1_14[23:00]} : 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_04[23:00], data_out_1_04[23:00]} ;  
                4'b0100: di_4         <=   (sel_ram_4) ? 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_14[23:00], data_out_1_14[23:00]} : 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_04[23:00], data_out_1_04[23:00]} ;   
                4'b0010: di_4         <=   (sel_ram_4) ? 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_14[23:00], data_out_1_14[23:00]} : 
                                            {data_out_2_03[23:00], data_out_1_03[23:00], data_out_2_04[23:00], data_out_1_04[23:00]} ;  
                // 4'b0001: di_4         <=     {data_out_2_14[23:00], data_out_1_14[23:00], data_out_2_04[23:00], data_out_1_04[23:00]}; 
                4'b0001: di_4         <=     0; 
                // default: di_4         <=     {data_out_2_14[23:00], data_out_1_14[23:00], data_out_2_04[23:00], data_out_1_04[23:00]};
                default: di_4         <=     0;
            endcase                     
        
        end
        
        else if(adsub_14 | adsub_24 | adsub_34) begin
            enable_1_04     <= 0;
            enable_2_04     <= 0; 
            enable_1_14     <= 0;
            enable_2_14     <= 0;
            
            data_in_1_04    <=  0;
            data_in_2_04    <=  0;
            data_in_1_14    <=  0;
            data_in_2_14    <=  0;
            
            // case per each one
            case({adsub_14,adsub_24,adsub_34})
                3'b100: begin
                            addr_1_04    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_04    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_14    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_14    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
                3'b010: begin
                            addr_1_04    <=  (sel_ram_2) ? ad_2[23:16] + (off_r2 << 7) : ad_2[07:00] + (off_r2 << 7);
                            addr_2_04    <=  (sel_ram_2) ? ad_2[31:24] + (off_r2 << 7) : ad_2[15:08] + (off_r2 << 7); 
                            addr_1_14    <=  (sel_ram_2) ? ad_2[07:00] + (off_r2 << 7) : ad_2[23:16] + (off_r2 << 7);
                            addr_2_14    <=  (sel_ram_2) ? ad_2[15:08] + (off_r2 << 7) : ad_2[31:24] + (off_r2 << 7);
                        end 
                3'b001: begin
                            addr_1_04   <=  (sel_ram_3) ? ad_3[23:16] + (off_r3 << 7) : ad_3[07:00] + (off_r3 << 7);
                            addr_2_04   <=  (sel_ram_3) ? ad_3[31:24] + (off_r3 << 7) : ad_3[15:08] + (off_r3 << 7); 
                            addr_1_14   <=  (sel_ram_3) ? ad_3[07:00] + (off_r3 << 7) : ad_3[23:16] + (off_r3 << 7);
                            addr_2_14   <=  (sel_ram_3) ? ad_3[15:08] + (off_r3 << 7) : ad_3[31:24] + (off_r3 << 7);
                        end 
               default: begin
                            addr_1_04    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
                            addr_2_04    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
                            addr_1_14    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
                            addr_2_14    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
                        end 
            endcase
            
            di_4         <= 0;
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
        
        else if(decod_4) begin
            enable_1_04     <= (sel_d_4) ? 1'b0 : 1'b1;
            enable_2_04     <= (sel_d_4) ? 1'b0 : 1'b1;
            enable_1_14     <= (sel_d_4) ? 1'b1 : 1'b0;
            enable_2_14     <= (sel_d_4) ? 1'b1 : 1'b0;
            
            data_in_1_04    <=  {12'h000, input_decoder[23:00]};
            data_in_2_04    <=  {12'h000, input_decoder[47:24]};
            data_in_1_14    <=  {12'h000, input_decoder[23:00]};
            data_in_2_14    <=  {12'h000, input_decoder[47:24]};
            
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
            
            addr_1_04       <=  0;
            addr_2_04       <=  0; 
            addr_1_14       <=  0;
            addr_2_14       <=  0;
            
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



module DMU_N_BU_2 (
    
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
    
    assign cbd_1    = control_dmu[0];
    assign ntt_1    = control_dmu[1];
    assign pwm_1_r0 = control_dmu[2];
    assign pwm_1_r1 = control_dmu[3];
    assign adsub_11 = control_dmu[4];
    assign adsub_12 = control_dmu[5];
    
    wire cbd_2;
    wire ntt_2;
    wire pwm_2_r0;
    wire pwm_2_r1;
    wire adsub_21;
    wire adsub_22;
    
    assign cbd_2    = control_dmu[8];
    assign ntt_2    = control_dmu[9];
    assign pwm_2_r0 = control_dmu[10];
    assign pwm_2_r1 = control_dmu[11];
    assign adsub_21 = control_dmu[12];
    assign adsub_22 = control_dmu[13];
    
    wire encod; 
    wire decod_1;   
    wire sel_d_1;
    wire decod_2;
    wire sel_d_2;
    
    assign encod    = control_dmu[32]; 
    assign decod_1  = control_dmu[33];
    assign sel_d_1  = control_dmu[34]; 
    assign decod_2  = control_dmu[35];
    assign sel_d_2  = control_dmu[36]; 
    // assign deco_dk  = control_dmu[33]; 
    // assign deco_ct  = control_dmu[34]; 
    
    wire sel_ram_1;
    wire sel_ram_2;
    assign sel_ram_1 = en_ram[0];
    assign sel_ram_2 = en_ram[2];
    
    
    // -- BU - 1 -- // 
    always @(posedge clk) begin
        if(cbd_1) begin 
            // RAM 
            enable_1_01     <= en_write;
            enable_2_01     <= en_write; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, data_in_1_cbd};
            data_in_2_01    <=  {12'h000, data_in_2_cbd};
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
        else if(adsub_11 | adsub_12) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_11,adsub_12})
                // 4'b1000: di_1         <=     {data_out_2_11[23:00], data_out_1_11[23:00], data_out_2_01[23:00], data_out_1_01[23:00]};  
                2'b10: di_1         <=     (sel_ram_1) ? 
                                            {24'h000000, 24'h000000, data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_01[23:00], data_out_1_01[23:00]} ;    
                2'b01: di_1         <=  (sel_ram_1) ? 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_11[23:00], data_out_1_11[23:00]} : 
                                            {data_out_2_02[23:00], data_out_1_02[23:00], data_out_2_01[23:00], data_out_1_01[23:00]} ; 
                default: di_1       <=  0;
            endcase                     
        
        end
        
        else if(adsub_21) begin
            enable_1_01     <= 0;
            enable_2_01     <= 0; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  0;
            data_in_2_01    <=  0;
            data_in_1_11    <=  0;
            data_in_2_11    <=  0;

            addr_1_01    <=  (sel_ram_2) ? ad_2[23:16] + (off_r2 << 7) : ad_2[07:00] + (off_r2 << 7);
            addr_2_01    <=  (sel_ram_2) ? ad_2[31:24] + (off_r2 << 7) : ad_2[15:08] + (off_r2 << 7); 
            addr_1_11    <=  (sel_ram_2) ? ad_2[07:00] + (off_r2 << 7) : ad_2[23:16] + (off_r2 << 7);
            addr_2_11    <=  (sel_ram_2) ? ad_2[15:08] + (off_r2 << 7) : ad_2[31:24] + (off_r2 << 7);
            
            di_1         <= 0;
        
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
        
        else if(decod_1) begin
            enable_1_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_2_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_1_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            enable_2_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            
            data_in_1_01    <=  {12'h000, input_decoder[23:00]};
            data_in_2_01    <=  {12'h000, input_decoder[47:24]};
            data_in_1_11    <=  {12'h000, input_decoder[23:00]};
            data_in_2_11    <=  {12'h000, input_decoder[47:24]};
            
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
     
    // -- BU - 2 -- // 
    always @(posedge clk) begin
        if(cbd_2) begin 
            // RAM 
            enable_1_02     <= en_write;
            enable_2_02     <= en_write; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
                            
            data_in_1_02    <=  {12'h000, data_in_1_cbd};
            data_in_2_02    <=  {12'h000, data_in_2_cbd};
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;
            
            addr_1_02       <=  addr_1_cbd + (off_ram02 << 7);
            addr_2_02       <=  addr_2_cbd + (off_ram02 << 7);
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
        else if(adsub_21 | adsub_22) begin
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
            
            // I suppose the final solution (s and e) is in RAM 1 
            case({adsub_21,adsub_22})
            
                2'b10: di_2         <=   (sel_ram_2) ? 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {data_out_2_01[23:00], data_out_1_01[23:00], data_out_2_02[23:00], data_out_1_02[23:00]} ;  
                2'b01: di_2         <=  (sel_ram_2) ? 
                                            {24'h000000, 24'h000000, data_out_2_12[23:00], data_out_1_12[23:00]} : 
                                            {24'h000000, 24'h000000, data_out_2_02[23:00], data_out_1_02[23:00]} ;   
                default: di_2         <=   0;
            
            endcase                     
        
        end
        
        else if(adsub_12) begin
            enable_1_02     <= 0;
            enable_2_02     <= 0; 
            enable_1_12     <= 0;
            enable_2_12     <= 0;
            
            data_in_1_02    <=  0;
            data_in_2_02    <=  0;
            data_in_1_12    <=  0;
            data_in_2_12    <=  0;

            addr_1_02    <=  (sel_ram_1) ? ad_1[23:16] + (off_r1 << 7) : ad_1[07:00] + (off_r1 << 7);
            addr_2_02    <=  (sel_ram_1) ? ad_1[31:24] + (off_r1 << 7) : ad_1[15:08] + (off_r1 << 7); 
            addr_1_12    <=  (sel_ram_1) ? ad_1[07:00] + (off_r1 << 7) : ad_1[23:16] + (off_r1 << 7);
            addr_2_12    <=  (sel_ram_1) ? ad_1[15:08] + (off_r1 << 7) : ad_1[31:24] + (off_r1 << 7);
            
            di_2         <= 0;
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
        
        else if(decod_2) begin
            enable_1_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_2_02     <= (sel_d_2) ? 1'b0 : 1'b1;
            enable_1_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            enable_2_12     <= (sel_d_2) ? 1'b1 : 1'b0;
            
            data_in_1_02    <=  {12'h000, input_decoder[23:00]};
            data_in_2_02    <=  {12'h000, input_decoder[47:24]};
            data_in_1_12    <=  {12'h000, input_decoder[23:00]};
            data_in_2_12    <=  {12'h000, input_decoder[47:24]};
            
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


module DMU_N_BU_1 (
    
    input           clk,
    
    input   [40:0]  control_dmu,
    input   [3:0]   off_r1,
    input   [3:0]   off_ram01,
    input   [3:0]   off_ram11,
    
    input   [09:00] ad_1_01,
    input   [09:00] ad_2_01,
    input   [09:00] ad_1_11,
    input   [09:00] ad_2_11,
    
    // CBD
    input           en_write,
    input   [23:0]  data_in_1_cbd,
    input   [23:0]  data_in_2_cbd,
    input   [7:0]   addr_1_cbd,  
    input   [7:0]   addr_2_cbd, 
    
    // REJ - UNIFORM
    input       [23:0]  do_1_0_r0,
    output  reg [9:0]   ar_1_0_r0,
    
    input       [23:0]  do_1_0_r1,
    output  reg [9:0]   ar_1_0_r1,
    
    // BU ENGINE
    input       [7:0]       en_ram,
    output reg  [4*24-1:0]  di_1,
    input       [4*24-1:0]  do_1,
    input       [4*8-1:0]   ad_1,
    
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
    input       [35:0]      data_out_2_11
    

    );
    
    wire cbd_1;
    wire ntt_1;
    wire pwm_1_r0;
    wire pwm_1_r1;
    wire adsub_11;
    wire adsub_12;
    
    assign cbd_1    = control_dmu[0];
    assign ntt_1    = control_dmu[1];
    assign pwm_1_r0 = control_dmu[2];
    assign pwm_1_r1 = control_dmu[3];
    assign adsub_11 = control_dmu[4];
    assign adsub_12 = control_dmu[5];
    
    wire encod; 
    wire decod_1;   
    wire sel_d_1;
    
    assign encod    = control_dmu[32]; 
    assign decod_1  = control_dmu[33] | control_dmu[35] | control_dmu[37] | control_dmu[39];
    assign sel_d_1  = control_dmu[34]; 
    // assign deco_dk  = control_dmu[33]; 
    // assign deco_ct  = control_dmu[34]; 
    
    wire sel_ram_1;
    assign sel_ram_1 = en_ram[0];
    
    
    // -- BU - 1 -- // 
    always @(posedge clk) begin
        if(cbd_1) begin 
            // RAM 
            enable_1_01     <= en_write;
            enable_2_01     <= en_write; 
            enable_1_11     <= 0;
            enable_2_11     <= 0;
            
            data_in_1_01    <=  {12'h000, data_in_1_cbd};
            data_in_2_01    <=  {12'h000, data_in_2_cbd};
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

        else if(adsub_12) begin
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
        
        else if(decod_1) begin
            enable_1_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_2_01     <= (sel_d_1) ? 1'b0 : 1'b1;
            enable_1_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            enable_2_11     <= (sel_d_1) ? 1'b1 : 1'b0;
            
            data_in_1_01    <=  {12'h000, input_decoder[23:00]};
            data_in_2_01    <=  {12'h000, input_decoder[47:24]};
            data_in_1_11    <=  {12'h000, input_decoder[23:00]};
            data_in_2_11    <=  {12'h000, input_decoder[47:24]};
            
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
     
    
    // REJ - UNIFORM 
    
    // Seguramente haya que poner distintos off_r0 / off_r1
    always @(posedge clk) begin
        if(pwm_1_r0)    ar_1_0_r0 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r0 <= 0;
        if(pwm_1_r1)    ar_1_0_r1 <= (sel_ram_1) ? ad_1[23:16] + (off_r1  << 7) : ad_1[07:00] + (off_r1 << 7);
        else            ar_1_0_r1 <= 0;
    end
endmodule

