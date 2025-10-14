`timescale 1ns / 1ps

module ARITHMETIC_UNIT_MASKED_N_BU_4 #(
    parameter N_BU = 4,
    parameter N_SHARES = 6,
    parameter KECCAK_DOM = 1
)(
    input               clk,
    input               rst,
    input   [255:0]     i_seed_0, // d / rho
    input   [255:0]     i_seed_1, // r
    output  [255:0]     o_seed_0, // rho
    output  [255:0]     o_seed_1, // sigma
    input   [7:0]       i,
    input   [7:0]       j,
    input  [255:0]      i_hek,
    input  [255:0]      i_ss,
    output [255:0]      o_hek,
    output [255:0]      o_ss,
    input   [1087:0]    ek_in,
    input   [11:0]      ctl_keccak,
    output              end_op_keccak,
    input   [7:0]       ctl_cbd,
    output              end_op_cbd,
    input   [3:0]       ctl_rej,
    input   [3:0]       off_rej,
    input   [15:0]      off_rej_dmu,
    output  [3:0]       end_op_rej,
    input   [19:0]      ctl_bu,
    output  [3:0]       end_op_bu,
    input   [40:0]      control_dmu,
    input   [31:0]      off_ram,
    
    input   [15:0]          mode_encdec,
    input   [16*10-1:00]    add_ram,
    input                   start_encoder,
    output                  d_valid_encoder,
    output  [63:0]          out_encoder,
    
    input   [63:0]          input_decoder,
    input                   start_decoder,
    input                   d_valid_decoder,
    output                  d_ready_decoder,
    output                  upd_add_decoder,

    output                      en_read_shares,
    input   [N_SHARES*24-1:0]   random_shares,

    output keccak_flag,

    input wire [1599:0] rand_k_1,
    input wire [1599:0] rand_k_2,
    input wire [1599:0] rand_k_3,
    input wire  [1599:0] rand_chi_1,  //  random share 1
    input wire  [1599:0] rand_chi_2,  //  random share 2
    input wire  [1599:0] rand_chi_3,  //  random share 3
    input wire  [1599:0] rand_chi_4,  //  random share 4
    input wire  [1599:0] rand_chi_5,  //  random share 5
    input wire  [1599:0] rand_chi_6   //  random share 6
);

   wire  [35:00] out_1_01;
   wire  [35:00] out_2_01;
   wire  [35:00] out_1_11;
   wire  [35:00] out_2_11;
   wire  [35:00] out_1_02;
   wire  [35:00] out_2_02;
   wire  [35:00] out_1_12;
   wire  [35:00] out_2_12;
   wire  [35:00] out_1_03;
   wire  [35:00] out_2_03;
   wire  [35:00] out_1_13;
   wire  [35:00] out_2_13;
   wire  [35:00] out_1_04;
   wire  [35:00] out_2_04;
   wire  [35:00] out_1_14;
   wire  [35:00] out_2_14;
   
   wire  [09:00] ad_1_01;
   wire  [09:00] ad_2_01;
   wire  [09:00] ad_1_11;
   wire  [09:00] ad_2_11;
   wire  [09:00] ad_1_02;
   wire  [09:00] ad_2_02;
   wire  [09:00] ad_1_12;
   wire  [09:00] ad_2_12;
   wire  [09:00] ad_1_03;
   wire  [09:00] ad_2_03;
   wire  [09:00] ad_1_13;
   wire  [09:00] ad_2_13;
   wire  [09:00] ad_1_04;
   wire  [09:00] ad_2_04;
   wire  [09:00] ad_1_14;
   wire  [09:00] ad_2_14;
   
   assign ad_1_01 = add_ram[009:000];
   assign ad_2_01 = add_ram[019:010];
   assign ad_1_11 = add_ram[029:020];
   assign ad_2_11 = add_ram[039:030];
   assign ad_1_02 = add_ram[049:040];
   assign ad_2_02 = add_ram[059:050];
   assign ad_1_12 = add_ram[069:060];
   assign ad_2_12 = add_ram[079:070];
   assign ad_1_03 = add_ram[089:080];
   assign ad_2_03 = add_ram[099:090];
   assign ad_1_13 = add_ram[109:100];
   assign ad_2_13 = add_ram[119:110];
   assign ad_1_04 = add_ram[129:120];
   assign ad_2_04 = add_ram[139:130];
   assign ad_1_14 = add_ram[149:140];
   assign ad_2_14 = add_ram[159:150];

    // --- SHA-512/256 / SHAKE-128/256 --- //
    wire reset_gen;
    wire start_gen;
    wire load_gen;
    wire read_gen;
    wire [3:0] mode_gen;
    wire [1599:0] do_keccak;
    wire [1599:0] di_keccak;
    
    assign reset_gen    = ctl_keccak[4];  
    assign load_gen     = ctl_keccak[5];   
    assign start_gen    = ctl_keccak[6];   
    assign read_gen     = ctl_keccak[7];
    assign mode_gen     = ctl_keccak[11:8]; 
    
    // --- keccak signals --- //
    wire reset_keccak;
    wire load_keccak;
    wire start_keccak;
    wire read_keccak;
    
    wire [1599:0] keccak_out;
    
    assign reset_keccak  = ctl_keccak[0];  
    assign load_keccak   = ctl_keccak[1];   
    assign start_keccak  = ctl_keccak[2];   
    assign read_keccak   = ctl_keccak[3];

    assign do_keccak = keccak_out;

    reg load_keccak_clk;
    always @(posedge clk) load_keccak_clk <= load_keccak;
    assign keccak_flag = load_keccak | start_keccak; 

    // --- CBD signals --- //
    wire        reset_cbd;
    wire [1:0]  eta;
    wire        scnd;
    wire        load_cbd;
    wire        start_cbd;
    wire        en_write_cbd;
    wire [23:0] data_in_1_cbd;
    wire [23:0] data_in_2_cbd;
    wire [7:0]  addr_1_cbd;
    wire [7:0]  addr_2_cbd;
    
    assign reset_cbd    = ctl_cbd[0];
    assign eta          = ctl_cbd[2:1];
    assign scnd         = ctl_cbd[3];
    assign load_cbd     = ctl_cbd[4];
    assign start_cbd    = ctl_cbd[5];

    generate
        if(KECCAK_DOM) begin 
            // --- keccak dom --- //
            wire [1599:0] keccak_out_s_1;
            wire [1599:0] keccak_out_s_2;
            wire [1599:0] keccak_out_s_3;
            wire [1599:0] keccak_out_s_4;

            wire [1599:0] di_keccak_s1;
            wire [1599:0] di_keccak_s2;
            wire [1599:0] di_keccak_s3;
            wire [1599:0] di_keccak_s4;

            
            gen_input_keccak_MASKED_KECCAK 
            gen_input_keccak_MASKED_KECCAK (
            .clk        (   clk                 ),
            .rst        (   rst & !reset_gen    ),
            .load       (   load_gen            ),
            .read       (   read_gen            ),
            .mode_gen   (   mode_gen            ),
            .ek_pke_in  (   ek_in               ),
            .i_seed_0   (   i_seed_0            ),
            .i_seed_1   (   i_seed_1            ),
            .o_seed_0   (   o_seed_0            ),
            .o_seed_1   (   o_seed_1            ),
            .i          (   i                   ),
            .j          (   j                   ),
            .i_hek      (   i_hek               ),
            .o_hek      (   o_hek               ),
            .i_ss       (   i_ss                ),
            .o_ss       (   o_ss                ),
            .do_keccak  (   do_keccak           ),
            .do_keccak_s1  (   keccak_out_s_1       ),
            .do_keccak_s2  (   keccak_out_s_2       ),
            .do_keccak_s3  (   keccak_out_s_3       ),
            .do_keccak_s4  (   keccak_out_s_4       ),
            .di_keccak     (   di_keccak            ),
            .di_keccak_s1  (   di_keccak_s1         ),
            .di_keccak_s2  (   di_keccak_s2         ),
            .di_keccak_s3  (   di_keccak_s3         ),
            .di_keccak_s4  (   di_keccak_s4         ),
            .random_data_1 (   rand_k_1       ),
            .random_data_2 (   rand_k_2       ),
            .random_data_3 (   rand_k_3       ),
            .flag_masked_prf ( flag_masked_prf     ),
            .flag_update_keccak (!load_keccak_clk)
            );
            
            keccak_DOM keccak_DOM (
                .clk        (   clk                 ),        
                .rst        (   rst & !reset_keccak ),
                .load       (   load_keccak         ),        
                .start      (   start_keccak        ),  
                .read       (   read_keccak         ), 
                .input_data (   di_keccak           ),  
                .input_data_1       (   di_keccak_s1        ),
                .input_data_2       (   di_keccak_s2        ),
                .input_data_3       (   di_keccak_s3        ),
                .input_data_4       (   di_keccak_s4        ),
                .flag_masked_prf    (   flag_masked_prf     ),
                .keccak_out (   keccak_out          ), 
                .keccak_out_s_1 (   keccak_out_s_1    ),
                .keccak_out_s_2 (   keccak_out_s_2    ),
                .keccak_out_s_3 (   keccak_out_s_3    ),
                .keccak_out_s_4 (   keccak_out_s_4    ),
                .end_op     (   end_op_keccak       ),
                .random_data_1 (   rand_k_1      ),
                .random_data_2 (   rand_k_2      ),
                .random_data_3 (   rand_k_3      ),
                .rand_chi_1 (   rand_chi_1      ),  //  random share 1
                .rand_chi_2 (   rand_chi_2      ),  //  random share 2
                .rand_chi_3 (   rand_chi_3      ),  //  random share 3
                .rand_chi_4 (   rand_chi_4      ),  //  random share 4
                .rand_chi_5 (   rand_chi_5      ),  //  random share 5
                .rand_chi_6 (   rand_chi_6      )   //  random share 6
            );
           
            // --- cbd --- //
            
            CBD_MASKED_DOM_SDRR CBD_MASKED_DOM_SDRR (
                .clk            (   clk                     ),
                .rst            (   rst & !reset_cbd        ),
                .eta            (   eta                     ),
                .scnd           (   scnd                    ),
                .rand_1         (   rand_k_1                ),
                .rand_2         (   rand_k_2                ),
                .rand_3         (   rand_k_3                ),
                .in_shake_s_1   (   keccak_out_s_1[1087:0]  ),
                .in_shake_s_2   (   keccak_out_s_2[1087:0]  ),
                .in_shake_s_3   (   keccak_out_s_3[1087:0]  ),
                .in_shake_s_4   (   keccak_out_s_4[1087:0]  ),
                .load           (   load_cbd                ),
                .start          (   start_cbd               ),
                .end_op         (   end_op_cbd              ),
                .en_write       (   en_write_cbd            ),
                .data_in_1      (   data_in_1_cbd           ),
                .data_in_2      (   data_in_2_cbd           ),
                .addr_1         (   addr_1_cbd              ),
                .addr_2         (   addr_2_cbd              )
            );

        end 

        else begin
            // --- keccak --- //
            
            keccak keccak (
                .clk        (   clk                 ),        
                .rst        (   rst & !reset_keccak ),
                .load       (   load_keccak         ),        
                .start      (   start_keccak        ),  
                .read       (   read_keccak         ), 
                .input_data (   di_keccak           ),  
                .keccak_out (   keccak_out          ), 
                .end_op     (   end_op_keccak       )
            );
            

            // --- cbd --- //
            
            CBD CBD (
                .clk            (   clk                     ),
                .rst            (   rst & !reset_cbd        ),
                .eta            (   eta                     ),
                .scnd           (   scnd                    ),
                .in_shake       (   keccak_out[1087:0]      ),
                .load           (   load_cbd                ),
                .start          (   start_cbd               ),
                .end_op         (   end_op_cbd              ),
                .en_write       (   en_write_cbd            ),
                .data_in_1      (   data_in_1_cbd           ),
                .data_in_2      (   data_in_2_cbd           ),
                .addr_1         (   addr_1_cbd              ),
                .addr_2         (   addr_2_cbd              )
            );
        end
    endgenerate

    
    // --- Rej Uniform --- //
    
    wire reset_r0;
    wire selw_r0;
    wire load_r0;
    wire start_r0;
    wire end_op_r0;
    wire end_rd_r0;
    wire [3:0] off_r0;
    wire [3:0] off_r1;
    
    wire [23:00] do_1_0_r0;
    wire [23:00] do_2_0_r0;
    wire [23:00] do_1_1_r0;
    wire [23:00] do_2_1_r0;
    wire [09:00] ar_1_0_r0;
    wire [09:00] ar_2_0_r0;
    wire [09:00] ar_1_1_r0;
    wire [09:00] ar_2_1_r0;
    
    wire [23:00] do_1_0_r1;
    wire [23:00] do_2_0_r1;
    wire [23:00] do_1_1_r1;
    wire [23:00] do_2_1_r1;
    wire [09:00] ar_1_0_r1;
    wire [09:00] ar_2_0_r1;
    wire [09:00] ar_1_1_r1;
    wire [09:00] ar_2_1_r1;
    
    assign reset_rej    = ctl_rej[0];
    assign selw_rej     = ctl_rej[1];
    assign load_rej     = ctl_rej[2];
    assign start_rej    = ctl_rej[3];
    
    assign off_r0       = off_rej[3:0];
    assign off_r1       = off_rej[3:0];
    
    REJ_UNIFORM REJ_UNIFORM (
        .clk            (   clk                 ),
        .rst            (   rst & !reset_rej    ),
        .selw           (   selw_rej            ),
        .in_shake       (   keccak_out[1343:0]  ),
        .off_r0         (   off_r0              ),
        .off_r1         (   off_r1              ),
        .load           (   load_rej            ),
        .start          (   start_rej           ),
        .end_op         (   end_op_rej[0]       ),
        .end_read       (   end_op_rej[1]       ),
        .do_1_0         (   do_1_0_r0           ),
        .do_2_0         (   do_2_0_r0           ),
        .do_1_1         (   do_1_1_r0           ),
        .do_2_1         (   do_2_1_r0           ),
        .ar_1_0         (   ar_1_0_r0           ),
        .ar_2_0         (   ar_2_0_r0           ),
        .ar_1_1         (   ar_1_1_r0           ),
        .ar_2_1         (   ar_2_1_r0           ),
        .do_3_0         (   do_1_0_r1           ),
        .do_4_0         (   do_2_0_r1           ),
        .do_3_1         (   do_1_1_r1           ),
        .do_4_1         (   do_2_1_r1           ),
        .ar_3_0         (   ar_1_0_r1           ),
        .ar_4_0         (   ar_2_0_r1           ),
        .ar_3_1         (   ar_1_1_r1           ),
        .ar_4_1         (   ar_2_1_r1           )
    );
    
    
    // ---- BU ENGINE ---- //
    wire    [3:0]   start_bu;
    wire    [15:0]  mode_bu;
    
    assign start_bu    = ctl_bu[03:00];
    assign mode_bu     = ctl_bu[19:04]; 
    
    wire [7:0]       en_ram;   
    wire [4*24-1:0]  di_1;  
    wire [4*24-1:0]  do_1;  
    wire [4*8-1:0]   ad_1;  
    wire [4*24-1:0]  di_2;  
    wire [4*24-1:0]  do_2;  
    wire [4*8-1:0]   ad_2;  
    wire [4*24-1:0]  di_3;  
    wire [4*24-1:0]  do_3;  
    wire [4*8-1:0]   ad_3;  
    wire [4*24-1:0]  di_4;  
    wire [4*24-1:0]  do_4;  
    wire [4*8-1:0]   ad_4;  
    
    BU_ENGINE_N_BU_4 #(
        .MASKED(1)
    ) 
    BU_ENGINE_N_BU_4 (
        .clk        (   clk         ),
        .rst        (   rst         ),
        .start      (   start_bu    ),
        .mode       (   mode_bu     ),
        .end_op     (   end_op_bu   ),
        .en_ram     (   en_ram      ),
        .ad_1       (   ad_1        ),
        .ad_2       (   ad_2        ),
        .ad_3       (   ad_3        ),
        .ad_4       (   ad_4        ),
        .di_1       (   di_1        ),
        .di_2       (   di_2        ),
        .di_3       (   di_3        ),
        .di_4       (   di_4        ),
        .do_1       (   do_1        ),
        .do_2       (   do_2        ),
        .do_3       (   do_3        ),
        .do_4       (   do_4        )
    );

    // --- RAM BANK --- //
    wire            enable_1_01;
    wire            enable_2_01;
    wire [9:0]      addr_1_01;
    wire [9:0]      addr_2_01;
    wire [35:0]     data_in_1_01;
    wire [35:0]     data_in_2_01;
    wire [35:0]     data_out_1_01;
    wire [35:0]     data_out_2_01;
    
    wire            enable_1_11;
    wire            enable_2_11;
    wire [9:0]      addr_1_11;
    wire [9:0]      addr_2_11;
    wire [35:0]     data_in_1_11;
    wire [35:0]     data_in_2_11;
    wire [35:0]     data_out_1_11;
    wire [35:0]     data_out_2_11;
    
    wire            enable_1_02;
    wire            enable_2_02;
    wire [9:0]      addr_1_02;
    wire [9:0]      addr_2_02;
    wire [35:0]     data_in_1_02;
    wire [35:0]     data_in_2_02;
    wire [35:0]     data_out_1_02;
    wire [35:0]     data_out_2_02;
    
    wire            enable_1_12;
    wire            enable_2_12;
    wire [9:0]      addr_1_12;
    wire [9:0]      addr_2_12;
    wire [35:0]     data_in_1_12;
    wire [35:0]     data_in_2_12;
    wire [35:0]     data_out_1_12;
    wire [35:0]     data_out_2_12;
    
    wire            enable_1_03;
    wire            enable_2_03;
    wire [9:0]      addr_1_03;
    wire [9:0]      addr_2_03;
    wire [35:0]     data_in_1_03;
    wire [35:0]     data_in_2_03;
    wire [35:0]     data_out_1_03;
    wire [35:0]     data_out_2_03;
    
    wire            enable_1_13;
    wire            enable_2_13;
    wire [9:0]      addr_1_13;
    wire [9:0]      addr_2_13;
    wire [35:0]     data_in_1_13;
    wire [35:0]     data_in_2_13;
    wire [35:0]     data_out_1_13;
    wire [35:0]     data_out_2_13;
    
    wire            enable_1_04;
    wire            enable_2_04;
    wire [9:0]      addr_1_04;
    wire [9:0]      addr_2_04;
    wire [35:0]     data_in_1_04;
    wire [35:0]     data_in_2_04;
    wire [35:0]     data_out_1_04;
    wire [35:0]     data_out_2_04;
    
    wire            enable_1_14;
    wire            enable_2_14;
    wire [9:0]      addr_1_14;
    wire [9:0]      addr_2_14;
    wire [35:0]     data_in_1_14;
    wire [35:0]     data_in_2_14;
    wire [35:0]     data_out_1_14;
    wire [35:0]     data_out_2_14;
    
    assign out_1_01 = data_out_1_01;
    assign out_2_01 = data_out_2_01;
    assign out_1_11 = data_out_1_11;
    assign out_2_11 = data_out_2_11;
    
    assign out_1_02 = data_out_1_02;
    assign out_2_02 = data_out_2_02;
    assign out_1_12 = data_out_1_12;
    assign out_2_12 = data_out_2_12;
    
    assign out_1_03 = data_out_1_03;
    assign out_2_03 = data_out_2_03;
    assign out_1_13 = data_out_1_13;
    assign out_2_13 = data_out_2_13;
    
    assign out_1_04 = data_out_1_04;
    assign out_2_04 = data_out_2_04;
    assign out_1_14 = data_out_1_14;
    assign out_2_14 = data_out_2_14;
    
    RAM_BANK_N_BU_4 RAM_BANK_N_BU_4 (
    .clk            (   clk             ),

    .enable_1_01    (   enable_1_01     ),
    .enable_2_01    (   enable_2_01     ),
    .addr_1_01      (   addr_1_01       ),
    .addr_2_01      (   addr_2_01       ),
    .data_in_1_01   (   data_in_1_01    ),
    .data_in_2_01   (   data_in_2_01    ),
    .data_out_1_01  (   data_out_1_01   ),
    .data_out_2_01  (   data_out_2_01   ),

    .enable_1_11    (   enable_1_11     ),
    .enable_2_11    (   enable_2_11     ),
    .addr_1_11      (   addr_1_11       ),
    .addr_2_11      (   addr_2_11       ),
    .data_in_1_11   (   data_in_1_11    ),
    .data_in_2_11   (   data_in_2_11    ),
    .data_out_1_11  (   data_out_1_11   ),
    .data_out_2_11  (   data_out_2_11   ),

    .enable_1_02    (   enable_1_02     ),
    .enable_2_02    (   enable_2_02     ),
    .addr_1_02      (   addr_1_02       ),
    .addr_2_02      (   addr_2_02       ),
    .data_in_1_02   (   data_in_1_02    ),
    .data_in_2_02   (   data_in_2_02    ),
    .data_out_1_02  (   data_out_1_02   ),
    .data_out_2_02  (   data_out_2_02   ),

    .enable_1_12    (   enable_1_12     ),
    .enable_2_12    (   enable_2_12     ),
    .addr_1_12      (   addr_1_12       ),
    .addr_2_12      (   addr_2_12       ),
    .data_in_1_12   (   data_in_1_12    ),
    .data_in_2_12   (   data_in_2_12    ),
    .data_out_1_12  (   data_out_1_12   ),
    .data_out_2_12  (   data_out_2_12   ),

    .enable_1_03    (   enable_1_03     ),
    .enable_2_03    (   enable_2_03     ),
    .addr_1_03      (   addr_1_03       ),
    .addr_2_03      (   addr_2_03       ),
    .data_in_1_03   (   data_in_1_03    ),
    .data_in_2_03   (   data_in_2_03    ),
    .data_out_1_03  (   data_out_1_03   ),
    .data_out_2_03  (   data_out_2_03   ),

    .enable_1_13    (   enable_1_13     ),
    .enable_2_13    (   enable_2_13     ),
    .addr_1_13      (   addr_1_13       ),
    .addr_2_13      (   addr_2_13       ),
    .data_in_1_13   (   data_in_1_13    ),
    .data_in_2_13   (   data_in_2_13    ),
    .data_out_1_13  (   data_out_1_13   ),
    .data_out_2_13  (   data_out_2_13   ),

    .enable_1_04    (   enable_1_04     ),
    .enable_2_04    (   enable_2_04     ),
    .addr_1_04      (   addr_1_04       ),
    .addr_2_04      (   addr_2_04       ),
    .data_in_1_04   (   data_in_1_04    ),
    .data_in_2_04   (   data_in_2_04    ),
    .data_out_1_04  (   data_out_1_04   ),
    .data_out_2_04  (   data_out_2_04   ),

    .enable_1_14    (   enable_1_14     ),
    .enable_2_14    (   enable_2_14     ),
    .addr_1_14      (   addr_1_14       ),
    .addr_2_14      (   addr_2_14       ),
    .data_in_1_14   (   data_in_1_14    ),
    .data_in_2_14   (   data_in_2_14    ),
    .data_out_1_14  (   data_out_1_14   ),
    .data_out_2_14  (   data_out_2_14   )
    );
    
    
    // ---- DMU ---- //
    wire [3:0] off_ram01;
    wire [3:0] off_ram02;
    wire [3:0] off_ram03;
    wire [3:0] off_ram04;
    wire [3:0] off_ram11;
    wire [3:0] off_ram12;
    wire [3:0] off_ram13;
    wire [3:0] off_ram14;
    
    assign off_ram01 = off_ram[03:00];
    assign off_ram11 = off_ram[07:04];
    assign off_ram02 = off_ram[11:08];
    assign off_ram12 = off_ram[15:12];
    
    assign off_ram03 = off_ram[19:16];
    assign off_ram13 = off_ram[23:20];
    assign off_ram04 = off_ram[27:24];
    assign off_ram14 = off_ram[31:28];
    
    wire [3:0] off_r1_dmu;
    wire [3:0] off_r2_dmu;
    wire [3:0] off_r3_dmu;
    wire [3:0] off_r4_dmu;
    assign off_r1_dmu = off_rej_dmu[3:0];
    assign off_r2_dmu = off_rej_dmu[7:4];
    assign off_r3_dmu = off_rej_dmu[11:8];
    assign off_r4_dmu = off_rej_dmu[15:12];
    
    wire [2*24-1:0] out_decoder;
    
    DMU_MASKED_N_BU_4 #(
        .N_SHARES(N_SHARES)
    )
    DMU_MASKED_N_BU_4 (
    .clk(clk),
    // CONTROL
    .control_dmu (  control_dmu ), 
    
    .off_r1   (   off_r1_dmu  ),
    .off_r2   (   off_r2_dmu  ),
    .off_r3   (   off_r3_dmu  ),
    .off_r4   (   off_r4_dmu  ),
    .off_ram01   (   off_ram01    ),
    .off_ram02   (   off_ram02    ),
    .off_ram03   (   off_ram03    ),
    .off_ram04   (   off_ram04    ),
    .off_ram11   (   off_ram11    ),
    .off_ram12   (   off_ram12    ),
    .off_ram13   (   off_ram13    ),
    .off_ram14   (   off_ram14    ),
    
    .ad_1_01    (   ad_1_01     ),
    .ad_2_01    (   ad_2_01     ),
    .ad_1_11    (   ad_1_11     ),
    .ad_2_11    (   ad_2_11     ),
    
    .ad_1_02    (   ad_1_02     ),
    .ad_2_02    (   ad_2_02     ),
    .ad_1_12    (   ad_1_12     ),
    .ad_2_12    (   ad_2_12     ),
    
    .ad_1_03    (   ad_1_03     ),
    .ad_2_03    (   ad_2_03     ),
    .ad_1_13    (   ad_1_13     ),
    .ad_2_13    (   ad_2_13     ),
    
    .ad_1_04    (   ad_1_04     ),
    .ad_2_04    (   ad_2_04     ),
    .ad_1_14    (   ad_1_14     ),
    .ad_2_14    (   ad_2_14     ),

    // SHARES
    .en_read        (   en_read_shares  ),
    .random_shares  (   random_shares   ),
    // CBD
    .en_write           (   en_write_cbd            ),
    .data_in_1_cbd      (   data_in_1_cbd           ),
    .data_in_2_cbd      (   data_in_2_cbd           ),
    .addr_1_cbd         (   addr_1_cbd              ),
    .addr_2_cbd         (   addr_2_cbd              ),
    
    
    // REJ UNIFORM
    .do_1_0_r0       (   do_1_0_r0     ),
    .do_2_0_r0       (   do_2_0_r0     ),
    .ar_1_0_r0       (   ar_1_0_r0     ),
    .ar_2_0_r0       (   ar_2_0_r0     ),
    .do_1_1_r0       (   do_1_1_r0     ),
    .do_2_1_r0       (   do_2_1_r0     ),
    .ar_1_1_r0       (   ar_1_1_r0     ),
    .ar_2_1_r0       (   ar_2_1_r0     ),
    
    .do_1_0_r1       (   do_1_0_r1     ),
    .do_2_0_r1       (   do_2_0_r1     ),
    .ar_1_0_r1       (   ar_1_0_r1     ),
    .ar_2_0_r1       (   ar_2_0_r1     ),
    .do_1_1_r1       (   do_1_1_r1     ),
    .do_2_1_r1       (   do_2_1_r1     ),
    .ar_1_1_r1       (   ar_1_1_r1     ),
    .ar_2_1_r1       (   ar_2_1_r1     ),
    
    // BU - ENGINE
    .en_ram     (   en_ram      ),
    .ad_1       (   ad_1        ),
    .ad_2       (   ad_2        ),
    .ad_3       (   ad_3        ),
    .ad_4       (   ad_4        ),
    .di_1       (   di_1        ),
    .di_2       (   di_2        ),
    .di_3       (   di_3        ),
    .di_4       (   di_4        ),
    .do_1       (   do_1        ),
    .do_2       (   do_2        ),
    .do_3       (   do_3        ),
    .do_4       (   do_4        ),
    
    // DECODER
    .input_decoder  (   out_decoder     ),
    
    // RAM BANK
    .enable_1_01    (   enable_1_01     ),
    .enable_2_01    (   enable_2_01     ),
    .addr_1_01      (   addr_1_01       ),
    .addr_2_01      (   addr_2_01       ),
    .data_in_1_01   (   data_in_1_01    ),
    .data_in_2_01   (   data_in_2_01    ),
    .data_out_1_01  (   data_out_1_01   ),
    .data_out_2_01  (   data_out_2_01   ),
    
    .enable_1_11    (   enable_1_11     ),
    .enable_2_11    (   enable_2_11     ),
    .addr_1_11      (   addr_1_11       ),
    .addr_2_11      (   addr_2_11       ),
    .data_in_1_11   (   data_in_1_11    ),
    .data_in_2_11   (   data_in_2_11    ),
    .data_out_1_11  (   data_out_1_11   ),
    .data_out_2_11  (   data_out_2_11   ),
    
    .enable_1_02    (   enable_1_02     ),
    .enable_2_02    (   enable_2_02     ),
    .addr_1_02      (   addr_1_02       ),
    .addr_2_02      (   addr_2_02       ),
    .data_in_1_02   (   data_in_1_02    ),
    .data_in_2_02   (   data_in_2_02    ),
    .data_out_1_02  (   data_out_1_02   ),
    .data_out_2_02  (   data_out_2_02   ),
    
    .enable_1_12    (   enable_1_12     ),
    .enable_2_12    (   enable_2_12     ),
    .addr_1_12      (   addr_1_12       ),
    .addr_2_12      (   addr_2_12       ),
    .data_in_1_12   (   data_in_1_12    ),
    .data_in_2_12   (   data_in_2_12    ),
    .data_out_1_12  (   data_out_1_12   ),
    .data_out_2_12  (   data_out_2_12   ),

    .enable_1_03    (   enable_1_03     ),
    .enable_2_03    (   enable_2_03     ),
    .addr_1_03      (   addr_1_03       ),
    .addr_2_03      (   addr_2_03       ),
    .data_in_1_03   (   data_in_1_03    ),
    .data_in_2_03   (   data_in_2_03    ),
    .data_out_1_03  (   data_out_1_03   ),
    .data_out_2_03  (   data_out_2_03   ),
    
    .enable_1_13    (   enable_1_13     ),
    .enable_2_13    (   enable_2_13     ),
    .addr_1_13      (   addr_1_13       ),
    .addr_2_13      (   addr_2_13       ),
    .data_in_1_13   (   data_in_1_13    ),
    .data_in_2_13   (   data_in_2_13    ),
    .data_out_1_13  (   data_out_1_13   ),
    .data_out_2_13  (   data_out_2_13   ),
    
    .enable_1_04    (   enable_1_04     ),
    .enable_2_04    (   enable_2_04     ),
    .addr_1_04      (   addr_1_04       ),
    .addr_2_04      (   addr_2_04       ),
    .data_in_1_04   (   data_in_1_04    ),
    .data_in_2_04   (   data_in_2_04    ),
    .data_out_1_04  (   data_out_1_04   ),
    .data_out_2_04  (   data_out_2_04   ),
    
    
    .enable_1_14    (   enable_1_14     ),
    .enable_2_14    (   enable_2_14     ),
    .addr_1_14      (   addr_1_14       ),
    .addr_2_14      (   addr_2_14       ),
    .data_in_1_14   (   data_in_1_14    ),
    .data_in_2_14   (   data_in_2_14    ),
    .data_out_1_14  (   data_out_1_14   ),
    .data_out_2_14  (   data_out_2_14   )
    
    );

    // --- ENCODING / DECODING --- //
    wire [16*24-1:0] input_encoder;
    assign input_encoder = {
            out_2_14[23:00], out_1_14[23:00], out_2_04[23:00], out_1_04[23:00],
            out_2_13[23:00], out_1_13[23:00], out_2_03[23:00], out_1_03[23:00],
            out_2_12[23:00], out_1_12[23:00], out_2_02[23:00], out_1_02[23:00],
            out_2_11[23:00], out_1_11[23:00], out_2_01[23:00], out_1_01[23:00]};
    
    ENCODER_COMPRESS_MASKED_N_BU_4_CLK ENCODER_COMPRESS_MASKED_N_BU_4_CLK (
        .clk        (   clk             ),
        .rst        (   rst             ),
        .start      (   start_encoder   ),
        .mode       (   mode_encdec     ),
        .d_valid    (   d_valid_encoder ),
        .input_data (   input_encoder   ),
        .out_data   (   out_encoder     )
    );

    DECODER_DECOMPRESS_4 DECODER_DECOMPRESS_4 ( // The masking is performed inside the DMU
        .clk            (   clk             ),
        .rst            (   rst             ),
        .input_data     (   input_decoder   ),
        .start_decod    (   start_decoder   ),
        .mode           (   mode_encdec     ),
        .d_valid        (   d_valid_decoder ),
        .d_ready        (   d_ready_decoder ),
        .upd_add        (   upd_add_decoder ),
        .out_data       (   out_decoder     )
    );

endmodule



module ARITHMETIC_UNIT_MASKED_N_BU_2 #(
    parameter N_BU = 2,
    parameter N_SHARES = 6,
    parameter KECCAK_TI3 = 1
)(
    input               clk,
    input               rst,
    input   [255:0]     i_seed_0, // d / rho
    input   [255:0]     i_seed_1, // r
    output  [255:0]     o_seed_0, // rho
    output  [255:0]     o_seed_1, // sigma
    input   [7:0]       i,
    input   [7:0]       j,
    input  [255:0]      i_hek,
    input  [255:0]      i_ss,
    output [255:0]      o_hek,
    output [255:0]      o_ss,
    input   [1087:0]    ek_in,
    input   [11:0]      ctl_keccak,
    output              end_op_keccak,
    input   [7:0]       ctl_cbd,
    output              end_op_cbd,
    input   [3:0]       ctl_rej,
    input   [3:0]       off_rej,
    input   [15:0]      off_rej_dmu,
    output  [3:0]       end_op_rej,
    input   [19:0]      ctl_bu,
    output  [3:0]       end_op_bu,
    input   [40:0]      control_dmu,
    input   [31:0]      off_ram,
    
    input   [15:0]          mode_encdec,
    input   [16*10-1:00]    add_ram,
    input                   start_encoder,
    output                  d_valid_encoder,
    output  [63:0]          out_encoder,
    
    input   [63:0]          input_decoder,
    input                   start_decoder,
    input                   d_valid_decoder,
    output                  d_ready_decoder,
    output                  upd_add_decoder,

    output                      en_read_shares,
    input   [N_SHARES*24-1:0]   random_shares,

    output keccak_flag,

    input wire [1599:0] rand_k_1,
    input wire [1599:0] rand_k_2
);

   wire  [35:00] out_1_01;
   wire  [35:00] out_2_01;
   wire  [35:00] out_1_11;
   wire  [35:00] out_2_11;
   wire  [35:00] out_1_02;
   wire  [35:00] out_2_02;
   wire  [35:00] out_1_12;
   wire  [35:00] out_2_12;
   
   wire  [09:00] ad_1_01;
   wire  [09:00] ad_2_01;
   wire  [09:00] ad_1_11;
   wire  [09:00] ad_2_11;
   wire  [09:00] ad_1_02;
   wire  [09:00] ad_2_02;
   wire  [09:00] ad_1_12;
   wire  [09:00] ad_2_12;
   
   assign ad_1_01 = add_ram[009:000];
   assign ad_2_01 = add_ram[019:010];
   assign ad_1_11 = add_ram[029:020];
   assign ad_2_11 = add_ram[039:030];
   assign ad_1_02 = add_ram[049:040];
   assign ad_2_02 = add_ram[059:050];
   assign ad_1_12 = add_ram[069:060];
   assign ad_2_12 = add_ram[079:070];

    // --- SHA-512/256 / SHAKE-128/256 --- //
    wire reset_gen;
    wire start_gen;
    wire load_gen;
    wire read_gen;
    wire [3:0] mode_gen;
    wire [1599:0] do_keccak;
    wire [1599:0] di_keccak;
    
    assign reset_gen    = ctl_keccak[4];  
    assign load_gen     = ctl_keccak[5];   
    assign start_gen    = ctl_keccak[6];   
    assign read_gen     = ctl_keccak[7];
    assign mode_gen     = ctl_keccak[11:8]; 
    
    // --- keccak signals --- //
    wire reset_keccak;
    wire load_keccak;
    wire start_keccak;
    wire read_keccak;
    
    wire [1599:0] keccak_out;
    
    assign reset_keccak  = ctl_keccak[0];  
    assign load_keccak   = ctl_keccak[1];   
    assign start_keccak  = ctl_keccak[2];   
    assign read_keccak   = ctl_keccak[3];

    assign do_keccak = keccak_out;

    // assign keccak_flag = start_keccak;
    reg load_keccak_clk;
    always @(posedge clk) load_keccak_clk <= load_keccak;
    assign keccak_flag = load_keccak & !load_keccak_clk;

    // --- CBD signals --- //
    wire        reset_cbd;
    wire [1:0]  eta;
    wire        scnd;
    wire        load_cbd;
    wire        start_cbd;
    wire        en_write_cbd;
    wire [23:0] data_in_1_cbd;
    wire [23:0] data_in_2_cbd;
    wire [7:0]  addr_1_cbd;
    wire [7:0]  addr_2_cbd;
    
    assign reset_cbd    = ctl_cbd[0];
    assign eta          = ctl_cbd[2:1];
    assign scnd         = ctl_cbd[3];
    assign load_cbd     = ctl_cbd[4];
    assign start_cbd    = ctl_cbd[5];

    generate
        if(KECCAK_TI3) begin 
            // --- keccak dom --- //
            wire [1599:0] keccak_out_s_1;
            wire [1599:0] keccak_out_s_2;
            wire [1599:0] keccak_out_s_3;

            wire [1599:0] di_keccak_s1;
            wire [1599:0] di_keccak_s2;
            wire [1599:0] di_keccak_s3;
            wire [1599:0] di_keccak_s4;

            gen_input_keccak_MASKED_KECCAK 
            gen_input_keccak_MASKED_KECCAK (
            .clk        (   clk                 ),
            .rst        (   rst & !reset_gen    ),
            .load       (   load_gen            ),
            .read       (   read_gen            ),
            .mode_gen   (   mode_gen            ),
            .ek_pke_in  (   ek_in               ),
            .i_seed_0   (   i_seed_0            ),
            .i_seed_1   (   i_seed_1            ),
            .o_seed_0   (   o_seed_0            ),
            .o_seed_1   (   o_seed_1            ),
            .i          (   i                   ),
            .j          (   j                   ),
            .i_hek      (   i_hek               ),
            .o_hek      (   o_hek               ),
            .i_ss       (   i_ss                ),
            .o_ss       (   o_ss                ),
            .do_keccak  (   do_keccak           ),
            .do_keccak_s1  (   keccak_out_s_1       ),
            .do_keccak_s2  (   keccak_out_s_2       ),
            .do_keccak_s3  (   keccak_out_s_3       ),
            .do_keccak_s4  (   1600'h0              ),
            .di_keccak     (   di_keccak            ),
            .di_keccak_s1  (   di_keccak_s1         ),
            .di_keccak_s2  (   di_keccak_s2         ),
            .di_keccak_s3  (   di_keccak_s3         ),
            .di_keccak_s4  (   di_keccak_s4         ),
            .random_data_1 (   rand_k_1       ),
            .random_data_2 (   rand_k_2       ),
            .random_data_3 (   1600'h0       ),
            .flag_masked_prf ( flag_masked_prf     ),
            .flag_update_keccak (!load_keccak_clk)
            );
            
            keccak_TI3 keccak_TI3 (
                .clk                (   clk                 ),        
                .rst                (   rst & !reset_keccak ),
                .load               (   load_keccak         ),        
                .start              (   start_keccak        ),  
                .read               (   read_keccak         ), 
                .input_data         (   di_keccak           ),  
                .input_data_1       (   di_keccak_s1        ),
                .input_data_2       (   di_keccak_s2        ),
                .input_data_3       (   di_keccak_s3        ),
                .flag_masked_prf    (   flag_masked_prf     ),
                .keccak_out         (   keccak_out          ), 
                .keccak_out_s_1     (   keccak_out_s_1      ),
                .keccak_out_s_2     (   keccak_out_s_2      ),
                .keccak_out_s_3     (   keccak_out_s_3      ),
                .end_op             (   end_op_keccak       ),
                .random_data_1      (   rand_k_1            ),
                .random_data_2      (   rand_k_2            )
            );
            
            

            // --- cbd --- //
            
            CBD_MASKED_TI3_SDRR CBD_MASKED_TI3_SDRR (
                .clk            (   clk                     ),
                .rst            (   rst & !reset_cbd        ),
                .eta            (   eta                     ),
                .scnd           (   scnd                    ),
                .rand_1         (   rand_k_1                ),
                .rand_2         (   rand_k_2                ),
                .in_shake_s_1   (   keccak_out_s_1[1087:0]  ),
                .in_shake_s_2   (   keccak_out_s_2[1087:0]  ),
                .in_shake_s_3   (   keccak_out_s_3[1087:0]  ),
                .load           (   load_cbd                ),
                .start          (   start_cbd               ),
                .end_op         (   end_op_cbd              ),
                .en_write       (   en_write_cbd            ),
                .data_in_1      (   data_in_1_cbd           ),
                .data_in_2      (   data_in_2_cbd           ),
                .addr_1         (   addr_1_cbd              ),
                .addr_2         (   addr_2_cbd              )
            );

        end 

        else begin

            gen_input_keccak gen_input_keccak (
                .clk        (   clk                 ),
                .rst        (   rst & !reset_gen    ),
                .load       (   load_gen            ),
                .read       (   read_gen            ),
                .mode_gen   (   mode_gen            ),
                .ek_pke_in  (   ek_in               ),
                .i_seed_0   (   i_seed_0            ),
                .i_seed_1   (   i_seed_1            ),
                .o_seed_0   (   o_seed_0            ),
                .o_seed_1   (   o_seed_1            ),
                .i          (   i                   ),
                .j          (   j                   ),
                .i_hek      (   i_hek               ),
                .o_hek      (   o_hek               ),
                .i_ss       (   i_ss                ),
                .o_ss       (   o_ss                ),
                .do_keccak  (   do_keccak           ),
                .di_keccak  (   di_keccak           )
            );
            
            
            // --- keccak --- //
            
            keccak keccak (
                .clk        (   clk                 ),        
                .rst        (   rst & !reset_keccak ),
                .load       (   load_keccak         ),        
                .start      (   start_keccak        ),  
                .read       (   read_keccak         ), 
                .input_data (   di_keccak           ),  
                .keccak_out (   keccak_out          ), 
                .end_op     (   end_op_keccak       )
            );
            

            // --- cbd --- //
            
            CBD CBD (
                .clk            (   clk                     ),
                .rst            (   rst & !reset_cbd        ),
                .eta            (   eta                     ),
                .scnd           (   scnd                    ),
                .in_shake       (   keccak_out[1087:0]      ),
                .load           (   load_cbd                ),
                .start          (   start_cbd               ),
                .end_op         (   end_op_cbd              ),
                .en_write       (   en_write_cbd            ),
                .data_in_1      (   data_in_1_cbd           ),
                .data_in_2      (   data_in_2_cbd           ),
                .addr_1         (   addr_1_cbd              ),
                .addr_2         (   addr_2_cbd              )
            );
        end
    endgenerate
    
    // --- Rej Uniform --- //
    
    wire reset_r0;
    wire selw_r0;
    wire load_r0;
    wire start_r0;
    wire end_op_r0;
    wire end_rd_r0;
    wire [3:0] off_r0;
    wire [3:0] off_r1;
    
    wire [23:00] do_1_0_r0;
    wire [23:00] do_2_0_r0;
    wire [09:00] ar_1_0_r0;
    wire [09:00] ar_2_0_r0;
    
    wire [23:00] do_1_0_r1;
    wire [23:00] do_2_0_r1;
    wire [09:00] ar_1_0_r1;
    wire [09:00] ar_2_0_r1;
    
    assign reset_rej    = ctl_rej[0];
    assign selw_rej     = ctl_rej[1];
    assign load_rej     = ctl_rej[2];
    assign start_rej    = ctl_rej[3];
    
    assign off_r0       = off_rej[3:0];
    assign off_r1       = off_rej[3:0];
    
    REJ_UNIFORM_SHORT REJ_UNIFORM_SHORT (
        .clk            (   clk                 ),
        .rst            (   rst & !reset_rej    ),
        .selw           (   selw_rej            ),
        .in_shake       (   keccak_out[1343:0]  ),
        .off_r0         (   off_r0              ),
        .off_r1         (   off_r1              ),
        .load           (   load_rej            ),
        .start          (   start_rej           ),
        .end_op         (   end_op_rej[0]       ),
        .end_read       (   end_op_rej[1]       ),
        .do_1_0         (   do_1_0_r0           ),
        .do_2_0         (   do_2_0_r0           ),
        .ar_1_0         (   ar_1_0_r0           ),
        .ar_2_0         (   ar_2_0_r0           ),
        .do_3_0         (   do_1_0_r1           ),
        .do_4_0         (   do_2_0_r1           ),
        .ar_3_0         (   ar_1_0_r1           ),
        .ar_4_0         (   ar_2_0_r1           )
    );
    
    
    // ---- BU ENGINE ---- //
    wire    [3:0]   start_bu;
    wire    [15:0]  mode_bu;
    
    assign start_bu    = ctl_bu[03:00];
    assign mode_bu     = ctl_bu[19:04]; 
    
    wire [7:0]       en_ram;   
    wire [4*24-1:0]  di_1;  
    wire [4*24-1:0]  do_1;  
    wire [4*8-1:0]   ad_1;  
    wire [4*24-1:0]  di_2;  
    wire [4*24-1:0]  do_2;  
    wire [4*8-1:0]   ad_2;  
    
    BU_ENGINE_N_BU_2 #(
        .MASKED(1)
    ) 
    BU_ENGINE_N_BU_2 (
        .clk        (   clk         ),
        .rst        (   rst         ),
        .start      (   start_bu    ),
        .mode       (   mode_bu     ),
        .end_op     (   end_op_bu   ),
        .en_ram     (   en_ram      ),
        .ad_1       (   ad_1        ),
        .ad_2       (   ad_2        ),
        .di_1       (   di_1        ),
        .di_2       (   di_2        ),
        .do_1       (   do_1        ),
        .do_2       (   do_2        )
    );

    // --- RAM BANK --- //
    wire            enable_1_01;
    wire            enable_2_01;
    wire [9:0]      addr_1_01;
    wire [9:0]      addr_2_01;
    wire [35:0]     data_in_1_01;
    wire [35:0]     data_in_2_01;
    wire [35:0]     data_out_1_01;
    wire [35:0]     data_out_2_01;
    
    wire            enable_1_11;
    wire            enable_2_11;
    wire [9:0]      addr_1_11;
    wire [9:0]      addr_2_11;
    wire [35:0]     data_in_1_11;
    wire [35:0]     data_in_2_11;
    wire [35:0]     data_out_1_11;
    wire [35:0]     data_out_2_11;
    
    wire            enable_1_02;
    wire            enable_2_02;
    wire [9:0]      addr_1_02;
    wire [9:0]      addr_2_02;
    wire [35:0]     data_in_1_02;
    wire [35:0]     data_in_2_02;
    wire [35:0]     data_out_1_02;
    wire [35:0]     data_out_2_02;
    
    wire            enable_1_12;
    wire            enable_2_12;
    wire [9:0]      addr_1_12;
    wire [9:0]      addr_2_12;
    wire [35:0]     data_in_1_12;
    wire [35:0]     data_in_2_12;
    wire [35:0]     data_out_1_12;
    wire [35:0]     data_out_2_12;
    
    assign out_1_01 = data_out_1_01;
    assign out_2_01 = data_out_2_01;
    assign out_1_11 = data_out_1_11;
    assign out_2_11 = data_out_2_11;
    
    assign out_1_02 = data_out_1_02;
    assign out_2_02 = data_out_2_02;
    assign out_1_12 = data_out_1_12;
    assign out_2_12 = data_out_2_12;
    
    
    RAM_BANK_N_BU_2 RAM_BANK_N_BU_2 (
    .clk            (   clk             ),

    .enable_1_01    (   enable_1_01     ),
    .enable_2_01    (   enable_2_01     ),
    .addr_1_01      (   addr_1_01       ),
    .addr_2_01      (   addr_2_01       ),
    .data_in_1_01   (   data_in_1_01    ),
    .data_in_2_01   (   data_in_2_01    ),
    .data_out_1_01  (   data_out_1_01   ),
    .data_out_2_01  (   data_out_2_01   ),

    .enable_1_11    (   enable_1_11     ),
    .enable_2_11    (   enable_2_11     ),
    .addr_1_11      (   addr_1_11       ),
    .addr_2_11      (   addr_2_11       ),
    .data_in_1_11   (   data_in_1_11    ),
    .data_in_2_11   (   data_in_2_11    ),
    .data_out_1_11  (   data_out_1_11   ),
    .data_out_2_11  (   data_out_2_11   ),

    .enable_1_02    (   enable_1_02     ),
    .enable_2_02    (   enable_2_02     ),
    .addr_1_02      (   addr_1_02       ),
    .addr_2_02      (   addr_2_02       ),
    .data_in_1_02   (   data_in_1_02    ),
    .data_in_2_02   (   data_in_2_02    ),
    .data_out_1_02  (   data_out_1_02   ),
    .data_out_2_02  (   data_out_2_02   ),

    .enable_1_12    (   enable_1_12     ),
    .enable_2_12    (   enable_2_12     ),
    .addr_1_12      (   addr_1_12       ),
    .addr_2_12      (   addr_2_12       ),
    .data_in_1_12   (   data_in_1_12    ),
    .data_in_2_12   (   data_in_2_12    ),
    .data_out_1_12  (   data_out_1_12   ),
    .data_out_2_12  (   data_out_2_12   )
    );
    
    
    // ---- DMU ---- //
    wire [3:0] off_ram01;
    wire [3:0] off_ram02;
    wire [3:0] off_ram11;
    wire [3:0] off_ram12;
    
    assign off_ram01 = off_ram[03:00];
    assign off_ram11 = off_ram[07:04];
    assign off_ram02 = off_ram[11:08];
    assign off_ram12 = off_ram[15:12];
    
    wire [3:0] off_r1_dmu;
    wire [3:0] off_r2_dmu;
    assign off_r1_dmu = off_rej_dmu[3:0];
    assign off_r2_dmu = off_rej_dmu[7:4];
    
    wire [2*24-1:0] out_decoder;
    
    DMU_MASKED_N_BU_2 #(
        .N_SHARES(N_SHARES)
    )
    DMU_MASKED_N_BU_2 (
    .clk(clk),
    // CONTROL
    .control_dmu (  control_dmu ), 
    
    .off_r1   (   off_r1_dmu  ),
    .off_r2   (   off_r2_dmu  ),
    .off_ram01   (   off_ram01    ),
    .off_ram02   (   off_ram02    ),
    .off_ram11   (   off_ram11    ),
    .off_ram12   (   off_ram12    ),
    
    .ad_1_01    (   ad_1_01     ),
    .ad_2_01    (   ad_2_01     ),
    .ad_1_11    (   ad_1_11     ),
    .ad_2_11    (   ad_2_11     ),
    
    .ad_1_02    (   ad_1_02     ),
    .ad_2_02    (   ad_2_02     ),
    .ad_1_12    (   ad_1_12     ),
    .ad_2_12    (   ad_2_12     ),

    // SHARES
    .en_read        (   en_read_shares  ),
    .random_shares  (   random_shares   ),
    // CBD
    .en_write           (   en_write_cbd            ),
    .data_in_1_cbd      (   data_in_1_cbd           ),
    .data_in_2_cbd      (   data_in_2_cbd           ),
    .addr_1_cbd         (   addr_1_cbd              ),
    .addr_2_cbd         (   addr_2_cbd              ),
    
    
    // REJ UNIFORM
    .do_1_0_r0       (   do_1_0_r0     ),
    .do_2_0_r0       (   do_2_0_r0     ),
    .ar_1_0_r0       (   ar_1_0_r0     ),
    .ar_2_0_r0       (   ar_2_0_r0     ),
    
    .do_1_0_r1       (   do_1_0_r1     ),
    .do_2_0_r1       (   do_2_0_r1     ),
    .ar_1_0_r1       (   ar_1_0_r1     ),
    .ar_2_0_r1       (   ar_2_0_r1     ),
    
    // BU - ENGINE
    .en_ram     (   en_ram      ),
    .ad_1       (   ad_1        ),
    .ad_2       (   ad_2        ),
    .di_1       (   di_1        ),
    .di_2       (   di_2        ),
    .do_1       (   do_1        ),
    .do_2       (   do_2        ),
    
    // DECODER
    .input_decoder  (   out_decoder     ),
    
    // RAM BANK
    .enable_1_01    (   enable_1_01     ),
    .enable_2_01    (   enable_2_01     ),
    .addr_1_01      (   addr_1_01       ),
    .addr_2_01      (   addr_2_01       ),
    .data_in_1_01   (   data_in_1_01    ),
    .data_in_2_01   (   data_in_2_01    ),
    .data_out_1_01  (   data_out_1_01   ),
    .data_out_2_01  (   data_out_2_01   ),
    
    .enable_1_11    (   enable_1_11     ),
    .enable_2_11    (   enable_2_11     ),
    .addr_1_11      (   addr_1_11       ),
    .addr_2_11      (   addr_2_11       ),
    .data_in_1_11   (   data_in_1_11    ),
    .data_in_2_11   (   data_in_2_11    ),
    .data_out_1_11  (   data_out_1_11   ),
    .data_out_2_11  (   data_out_2_11   ),
    
    .enable_1_02    (   enable_1_02     ),
    .enable_2_02    (   enable_2_02     ),
    .addr_1_02      (   addr_1_02       ),
    .addr_2_02      (   addr_2_02       ),
    .data_in_1_02   (   data_in_1_02    ),
    .data_in_2_02   (   data_in_2_02    ),
    .data_out_1_02  (   data_out_1_02   ),
    .data_out_2_02  (   data_out_2_02   ),
    
    .enable_1_12    (   enable_1_12     ),
    .enable_2_12    (   enable_2_12     ),
    .addr_1_12      (   addr_1_12       ),
    .addr_2_12      (   addr_2_12       ),
    .data_in_1_12   (   data_in_1_12    ),
    .data_in_2_12   (   data_in_2_12    ),
    .data_out_1_12  (   data_out_1_12   ),
    .data_out_2_12  (   data_out_2_12   )
    );

    // --- ENCODING / DECODING --- //
    wire [16*24-1:0] input_encoder;
    assign input_encoder = {
            24'h000000, 24'h000000, 24'h000000, 24'h000000,
            24'h000000, 24'h000000, 24'h000000, 24'h000000,
            out_2_12[23:00], out_1_12[23:00], out_2_02[23:00], out_1_02[23:00],
            out_2_11[23:00], out_1_11[23:00], out_2_01[23:00], out_1_01[23:00]};
    
    ENCODER_COMPRESS_MASKED_N_BU_2_CLK ENCODER_COMPRESS_MASKED_N_BU_2_CLK (
        .clk        (   clk             ),
        .rst        (   rst             ),
        .start      (   start_encoder   ),
        .mode       (   mode_encdec     ),
        .d_valid    (   d_valid_encoder ),
        .input_data (   input_encoder   ),
        .out_data   (   out_encoder     )
    );

    DECODER_DECOMPRESS_4 DECODER_DECOMPRESS_4 ( // The masking is performed inside the DMU
    .clk            (   clk             ),
    .rst            (   rst             ),
    .input_data     (   input_decoder   ),
    .start_decod    (   start_decoder   ),
    .mode           (   mode_encdec     ),
    .d_valid        (   d_valid_decoder ),
    .d_ready        (   d_ready_decoder ),
    .upd_add        (   upd_add_decoder ),
    .out_data       (   out_decoder     )
    );


endmodule

