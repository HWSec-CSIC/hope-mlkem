`timescale 1ns / 1ps

    module TOP_MLKEM_MASKED #(
        parameter N_BU = 4,
        parameter N_SHARES = (N_BU-1)*2,
        parameter SHUFF_DELAY = 539,
        parameter KECCAK_PROT = 1
        )(
        input                   clk,
        input                   rst,
        input       [7:0]       control,

        // Control signals
        input                   start_core,
        output                  end_op_core,
        input                   sel_io,

        // Control keccak
	    output                  start_keccak,
        output                  start_read_ek,
        input                   start_hek,
        input                   last_hek,
        
        // Input keccak
        input   [255:0]         i_seed_0, // d / rho
        input   [255:0]         i_seed_1, // r
        output  [255:0]         o_seed_0, // rho
        output  [255:0]         o_seed_1, // sigma
        input   [255:0]         i_hek,
        input   [255:0]         i_ss,
        output  [255:0]         o_hek,
        output  [255:0]         o_ss,
        input   [1087:0]        ek_in,

        // Encoder/Decoder signals
        input   [15:0]          mode_encdec,
        output                  d_valid_encoder,
        input                   start_encoder,
        input                   start_decoder,
        output                  d_ready_decoder,
        input                   d_valid_decoder,
        output                  upd_add_decoder,
        input   [16*10-1:0]     add_ram,
        output  [63:0]          out_encoder,
        input   [63:0]          input_decoder,

        // DMU
        input   [40:0]          control_dmu_io,

        // Encap/Decap signals
        input                   rst_ed,
        input                   gmh_decap,
        input                   start_encap_decap,

        // Shares
        output                      en_read_shares,
        input   [23:0]              random_op,
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
    
    
    // -------------------------------------------------------------------//
    // ---- ARITHMETIC UNIT ---- //

    // Signals for the arithmetic unit
    
    // Input keccak
    wire    [7:0]           i, j;

    // keccak signals
    wire    [11:0]          ctl_keccak;
    wire                    end_op_keccak;
    // CBD signals
    wire    [7:0]           ctl_cbd;
    wire                    end_op_cbd;
    // Rejection Sampler signals
    wire    [3:0]           ctl_rej, off_rej;
    wire    [15:0]          off_rej_dmu;
    wire    [3:0]           end_op_rej;
    // BU signals
    wire    [19:0]          ctl_bu;
    wire    [3:0]           end_op_bu;
    // DMU signals
    wire    [31:0]          off_ram;
    wire    [40:0]          control_dmu;


    // Module instantiation
    generate 
        if(N_BU == 4) begin
            ARITHMETIC_UNIT_MASKED_N_BU_4 #(
                .N_BU(N_BU),
                .N_SHARES(N_SHARES),
                .KECCAK_DOM(KECCAK_PROT)
            )
            ARITHMETIC_UNIT_MASKED_N_BU_4 (
                .clk                (   clk             ),
                .rst                (   rst             ),
                
                // Input keccak
                .i_seed_0           (   i_seed_0        ),
                .i_seed_1           (   i_seed_1        ),
                .o_seed_0           (   o_seed_0        ),
                .o_seed_1           (   o_seed_1        ),
                .i                  (   i               ),
                .j                  (   j               ),
                .i_hek              (   i_hek           ),
                .o_hek              (   o_hek           ),
                .i_ss               (   i_ss            ),
                .o_ss               (   o_ss            ),
                .ek_in              (   ek_in           ),
                
                // keccak signals
                .ctl_keccak         (   ctl_keccak      ),
                .end_op_keccak      (   end_op_keccak   ),
        
                // CBD signals
                .ctl_cbd            (   ctl_cbd         ),
                .end_op_cbd         (   end_op_cbd      ),
        
                // Rejection Sampler signals
                .ctl_rej            (   ctl_rej         ),
                .off_rej            (   off_rej         ),
                .off_rej_dmu        (   off_rej_dmu     ),
                .end_op_rej         (   end_op_rej      ),
        
                // BU signals
                .ctl_bu        	    (   ctl_bu          ),
                .end_op_bu     	    (   end_op_bu       ),
        
                // DMU signals
                .control_dmu        (   control_dmu     ),
                .off_ram            (   off_ram         ),
                
                // Encoder signals
                .mode_encdec        (   mode_encdec     ),
                .add_ram            (   add_ram         ),
                .start_encoder      (   start_encoder   ),
                .d_valid_encoder    (   d_valid_encoder ),
                .out_encoder        (   out_encoder     ),
                
                // Decoder signals
                .input_decoder      (   input_decoder   ),
                .start_decoder      (   start_decoder   ),
                .d_valid_decoder    (   d_valid_decoder ),
                .d_ready_decoder    (   d_ready_decoder ),
                .upd_add_decoder    (   upd_add_decoder ),
        
                // shares
                .en_read_shares     (   en_read_shares  ),
                .random_shares      (   random_shares   ),

                .keccak_flag (   keccak_flag   ),

                .rand_k_1 (   rand_k_1      ),
                .rand_k_2 (   rand_k_2      ),
                .rand_k_3 (   rand_k_3      ),
                .rand_chi_1 (   rand_chi_1      ),  //  random share 1
                .rand_chi_2 (   rand_chi_2      ),  //  random share 2
                .rand_chi_3 (   rand_chi_3      ),  //  random share 3
                .rand_chi_4 (   rand_chi_4      ),  //  random share 4
                .rand_chi_5 (   rand_chi_5      ),  //  random share 5
                .rand_chi_6 (   rand_chi_6      )   //  random share 6
            );
        end
        else begin
        
            ARITHMETIC_UNIT_MASKED_N_BU_2 #(
                .N_BU(N_BU),
                .N_SHARES(N_SHARES),
                .KECCAK_TI3(KECCAK_PROT)
            )
            ARITHMETIC_UNIT_MASKED_N_BU_2 (
                .clk                (   clk             ),
                .rst                (   rst             ),
                
                // Input keccak
                .i_seed_0           (   i_seed_0        ),
                .i_seed_1           (   i_seed_1        ),
                .o_seed_0           (   o_seed_0        ),
                .o_seed_1           (   o_seed_1        ),
                .i                  (   i               ),
                .j                  (   j               ),
                .i_hek              (   i_hek           ),
                .o_hek              (   o_hek           ),
                .i_ss               (   i_ss            ),
                .o_ss               (   o_ss            ),
                .ek_in              (   ek_in           ),
                
                // keccak signals
                .ctl_keccak         (   ctl_keccak      ),
                .end_op_keccak      (   end_op_keccak   ),
        
                // CBD signals
                .ctl_cbd            (   ctl_cbd         ),
                .end_op_cbd         (   end_op_cbd      ),
        
                // Rejection Sampler signals
                .ctl_rej            (   ctl_rej         ),
                .off_rej            (   off_rej         ),
                .off_rej_dmu        (   off_rej_dmu     ),
                .end_op_rej         (   end_op_rej      ),
        
                // BU signals
                .ctl_bu        	    (   ctl_bu          ),
                .end_op_bu     	    (   end_op_bu       ),
        
                // DMU signals
                .control_dmu        (   control_dmu     ),
                .off_ram            (   off_ram         ),
                
                // Encoder signals
                .mode_encdec        (   mode_encdec     ),
                .add_ram            (   add_ram         ),
                .start_encoder      (   start_encoder   ),
                .d_valid_encoder    (   d_valid_encoder ),
                .out_encoder        (   out_encoder     ),
                
                // Decoder signals
                .input_decoder      (   input_decoder   ),
                .start_decoder      (   start_decoder   ),
                .d_valid_decoder    (   d_valid_decoder ),
                .d_ready_decoder    (   d_ready_decoder ),
                .upd_add_decoder    (   upd_add_decoder ),
        
                // shares
                .en_read_shares     (   en_read_shares  ),
                .random_shares      (   random_shares   ),

                .keccak_flag (   keccak_flag   ),

                .rand_k_1 (   rand_k_1      ),
                .rand_k_2 (   rand_k_2      )
            );

        end
    endgenerate

    // -------------------------------------------------------------------//
    // ---- MAIN CONTROL ---- //
    // Signals for the main control
    wire [40:0]     control_dmu_core;

    // rst & !g_reset &!g_reset_encap_decap
    // CONTROL
    MAIN_CONTROL_MASKED #(
        .KECCAK_PROT(KECCAK_PROT),
        .N_BU(N_BU),
        .SHUFF_DELAY(SHUFF_DELAY)
    )
    MAIN_CONTROL_MASKED (
        // Control signals
        .clk                (   clk                 ),
        .rst                (   rst & !rst_ed       ),
        .control            (   control             ),
        .start_core         (   start_core          ),
        .end_op_core        (   end_op_core         ),

        // Input keccak
        .i                  (   i                   ),
        .j                  (   j                   ),

        // Keccak signals
        .ctl_keccak         (   ctl_keccak          ),
        .end_op_keccak      (   end_op_keccak       ),
        // CBD signals
        .ctl_cbd            (   ctl_cbd             ),
        .end_op_cbd         (   end_op_cbd          ),
        // Rejection Sampler signals
        .ctl_rej            (   ctl_rej             ),
        .off_rej            (   off_rej             ),
        .off_rej_dmu        (   off_rej_dmu         ),
        .end_op_rej         (   end_op_rej          ),
        // BU signals
        .ctl_bu             (   ctl_bu              ),
        .end_op_bu          (   end_op_bu           ),
        // DMU signals
        .control_dmu        (   control_dmu_core    ),
        .off_ram            (   off_ram             ),
        
        // hek signals
        .start_read_ek      (   start_read_ek       ),
        .start_hek          (   start_hek           ),
        .last_hek           (   last_hek            ),

        // Encap from decap signals
        .gmh_decap          (   gmh_decap           ),
        .start_ed           (   start_encap_decap   ),
        
        // Randomization of the BU operations
        .random_op          (   random_op           )
    );

    // -------------------------------------------------------------------
    // --- Signals assignment

    assign control_dmu  = (sel_io) ? control_dmu_io : control_dmu_core;
    
    assign start_keccak = ctl_keccak[2];

    endmodule