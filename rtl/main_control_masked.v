`timescale 1ns / 1ps

module MAIN_CONTROL_MASKED #(
    parameter KECCAK_PROT = 1,
    parameter N_BU = 2,
    parameter SHUFF_DELAY = 539
    
)(
    input           clk,
    input           rst,
    input   [7:0]   control,
    input           start_core,
    output          end_op_core,

    output  [7:0]   i,
    output  [7:0]   j,
    
    output  [11:0]  ctl_keccak,
    input           end_op_keccak,
    output  [7:0]   ctl_cbd,
    input           end_op_cbd,
    output  [3:0]   ctl_rej,
    output  [3:0]   off_rej,
    output  [15:0]  off_rej_dmu,
    input   [1:0]   end_op_rej,
    output  [19:0]  ctl_bu,
    input   [3:0]   end_op_bu,
    output  [40:0]  control_dmu,
    output  [31:0]  off_ram,

    output          start_read_ek,
    input           start_hek,
    input           last_hek,

    input           gmh_decap,
    input           start_ed,

    input   [23:0]  random_op
    
    );
    
    // --- GLOBAL CONTROL --- //
    
    wire end_op_op;
    wire end_op_bu_1;
    wire end_op_bu_2;
    wire end_op_bu_3;
    wire end_op_bu_4;
    
    assign end_op_op = end_op_bu_1 & end_op_bu_2 & end_op_bu_3 & end_op_bu_4;
    
    wire [11:0]             ctl_k_global;
    wire [7:0]              i_global;
    wire start_op;
    wire sel_global;
        
    GLOBAL_CONTROL  GLOBAL_CONTROL  (
    .clk                (   clk             ),
    .rst                (   rst             ),
    .control            (   control         ),
    .start_op           (   start_op        ),
    .i_global           (   i_global        ),
    .start_core         (   start_core      ),
    .end_op_core        (   end_op_op       ),
    .end_op_keccak      (   end_op_keccak   ),
    .control_keccak     (   ctl_k_global    ),
    .sel_global         (   sel_global      ),
    .start_read_ek      (   start_read_ek   ),
    .start_hek          (   start_hek       ),
    .last_hek           (   last_hek        ),
    .end_op             (   end_op_core     ),
    .gmh                (   gmh_decap       ),
    .start_ed           (   start_ed        )
    );
    
    // --- CONTROL KECCAK+CBD+REJ--- //
    wire [11:0] ctl_k;
    wire [7:0] i_k;
    wire  [34:0]  control_dmu_cbd;
    wire  [15:0]  off_ram_cbd;
    
    wire [1:0]  eta;
    wire scnd;
    wire sel_rej;

    wire [3:0] busy_bu;

    wire reset_cbd;
    wire reset_rej;
    wire load_cbd;
    wire load_rej;
    wire start_cbd;
    wire start_rej;
    
    CONTROL_KECCAK #(
        .MASKED(1)
    )
    CONTROL_KECCAK (
        .clk                (   clk             ),
        .rst                (   rst             ),
        .start              (   start_op        ),
        .mode               (   control[7:4]    ),
        .ctl_k              (   ctl_k           ),
        .i                  (   i_k             ),
        .j                  (   j               ),
        .reset_cbd          (   reset_cbd       ),
        .reset_rej          (   reset_rej       ),
        .load_cbd           (   load_cbd        ),
        .load_rej           (   load_rej        ),
        .start_cbd          (   start_cbd       ),
        .start_rej          (   start_rej       ),
        .eta                (   eta             ),    
        .scnd               (   scnd            ),
        .sel_rej            (   sel_rej         ),
        .control_dmu_cbd    (   control_dmu_cbd ),
        .off_ram_cbd        (   off_ram_cbd     ),
        .off_rej            (   off_rej         ),
        .end_op_cbd         (   end_op_cbd      ),
        .end_op_rej         (   end_op_rej[0]   ),
        .end_rd_rej         (   end_op_rej[1]   ),
        .end_op_keccak      (   end_op_keccak   ),
        .end_op_bu         (   end_op_bu      )
    );
   
    
    assign ctl_keccak   = (sel_global) ? ctl_k_global   : ctl_k;
    assign i            = (sel_global) ? i_global : i_k;
    
    assign ctl_cbd      = {start_cbd, load_cbd, scnd, eta, reset_cbd};
    assign ctl_rej      = {start_rej, load_rej, sel_rej, reset_rej}; 
    
    
    // --- CONTROL BUTTERFLY UNIT --- //
    
    wire  [34:0]  control_dmu_bu;
    wire  [31:0]  off_ram_bu;
    
    wire start_bu_1;
    wire start_bu_2;
    wire start_bu_3;
    wire start_bu_4;
    wire [3:0] mode_bu_1;
    wire [3:0] mode_bu_2;
    wire [3:0] mode_bu_3;
    wire [3:0] mode_bu_4;    
    
    wire busy_cbd   = start_cbd & !end_op_cbd;
    wire busy_r0    = start_rej & !sel_rej & !end_op_rej[1];
    wire busy_r1    = start_rej &  sel_rej & !end_op_rej[1];
 
    assign busy_bu[0] = start_bu_1 & !end_op_bu[0];
    assign busy_bu[1] = start_bu_2 & !end_op_bu[1];
    assign busy_bu[2] = start_bu_3 & !end_op_bu[2];
    assign busy_bu[3] = start_bu_4 & !end_op_bu[3];
    
    wire [3:0] read_1 = {control_dmu_bu[28], control_dmu_bu[20], control_dmu_bu[12], control_dmu_bu[4]};
    wire [3:0] read_2 = {control_dmu_bu[29], control_dmu_bu[21], control_dmu_bu[13], control_dmu_bu[5]};
    wire [3:0] read_3 = {control_dmu_bu[30], control_dmu_bu[22], control_dmu_bu[14], control_dmu_bu[6]};
    wire [3:0] read_4 = {control_dmu_bu[31], control_dmu_bu[23], control_dmu_bu[15], control_dmu_bu[7]};
    
    // -- Priority Encoder -- //
    wire    [3:0]   busy_bu_1, busy_bu_2, busy_bu_3, busy_bu_4;
    reg     [3:0]   busy_bu_1_reg, busy_bu_2_reg, busy_bu_3_reg;
    always @(posedge clk) begin
        busy_bu_1_reg <= busy_bu_1;
        busy_bu_2_reg <= busy_bu_2;
        busy_bu_3_reg <= busy_bu_3;
    end
    
    PRIORITY_ENCODER PE1 (
        .busy_bu(busy_bu),
        .cond1(read_1[0]),
        .cond2(read_2[0]),
        .cond3(read_3[0]),
        .cond4(read_4[0]),
        .busy_bu_N(busy_bu_1)
    );
    PRIORITY_ENCODER PE2 (
        .busy_bu(busy_bu_1_reg),
        // .busy_bu(busy_bu_1),
        .cond1(read_1[1] | read_1[0]),
        .cond2(read_2[1] | read_2[0]),
        .cond3(read_3[1] | read_3[0]),
        .cond4(read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_2)
    );
    PRIORITY_ENCODER PE3 (
        .busy_bu(busy_bu_2_reg),
        .cond1(read_1[2] | read_1[1] | read_1[0]),
        .cond2(read_2[2] | read_2[1] | read_2[0]),
        .cond3(read_3[2] | read_3[1] | read_3[0]),
        .cond4(read_4[2] | read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_3)
    );
    PRIORITY_ENCODER PE4 (
        .busy_bu(busy_bu_3_reg),
        .cond1(read_1[3] | read_1[2] | read_1[1] | read_1[0]),
        .cond2(read_2[3] | read_2[2] | read_2[1] | read_2[0]),
        .cond3(read_3[3] | read_3[2] | read_3[1] | read_3[0]),
        .cond4(read_4[3] | read_4[2] | read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_4)
    );

    
    CONTROL_BU_MASKED #(.UNIT(1), .KECCAK_PROT(KECCAK_PROT), .N_BU(N_BU), .SHUFF_DELAY(SHUFF_DELAY)) 
    CONTROL_BU_1 
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .random_op      (   random_op[3:0]      ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_1           ),
        .end_op_bu      (   end_op_bu[0]       ),
        .start_bu       (   start_bu_1          ),
        .mode_bu        (   mode_bu_1           ),
        .control_dmu    (   control_dmu_bu[7:0] ),
        .off_ram        (   off_ram_bu[7:0]     ),
        .off_rej        (   off_rej_dmu[3:0]    ),
        .end_op         (   end_op_bu_1         ),
        .start_ed       (   start_ed            )
    );
    
    CONTROL_BU_MASKED #(.UNIT(2), .KECCAK_PROT(KECCAK_PROT), .N_BU(N_BU), .SHUFF_DELAY(SHUFF_DELAY)) 
    CONTROL_BU_2
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .random_op      (   random_op[7:4]      ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_2           ),
        .end_op_bu      (   end_op_bu[1]       ),
        .start_bu       (   start_bu_2          ),
        .mode_bu        (   mode_bu_2           ),
        .control_dmu    (   control_dmu_bu[15:8] ),
        .off_ram        (   off_ram_bu[15:8]    ),
        .off_rej        (   off_rej_dmu[7:4]    ),
        .end_op         (   end_op_bu_2         ),
        .start_ed       (   start_ed        )
    );
    
    generate
        if(N_BU == 4) begin
            CONTROL_BU_MASKED #(.UNIT(3), .KECCAK_PROT(KECCAK_PROT), .N_BU(N_BU), .SHUFF_DELAY(SHUFF_DELAY)) 
            CONTROL_BU_3
            (
                .clk            (   clk                 ),
                .rst            (   rst                 ),
                .mode           (   control[7:4]        ),
                .start          (   start_core          ),
                .random_op      (   random_op[11:8]     ),
                .busy_r0        (   busy_r0             ),
                .busy_r1        (   busy_r1             ),
                .busy_bu        (   busy_bu_3           ),
                .end_op_bu      (   end_op_bu[2]       ),
                .start_bu       (   start_bu_3          ),
                .mode_bu        (   mode_bu_3           ),
                .control_dmu    (   control_dmu_bu[23:16]    ),
                .off_ram        (   off_ram_bu[23:16]        ),
                .off_rej        (   off_rej_dmu[11:8]       ),
                .end_op         (   end_op_bu_3         ),
                .start_ed       (   start_ed        )
            );
            
            CONTROL_BU_MASKED #(.UNIT(4), .KECCAK_PROT(KECCAK_PROT), .N_BU(N_BU), .SHUFF_DELAY(SHUFF_DELAY)) 
            CONTROL_BU_4
            (
                .clk            (   clk                 ),
                .rst            (   rst                 ),
                .mode           (   control[7:4]        ),
                .start          (   start_core          ),
                .random_op      (   random_op[15:12]    ),
                .busy_r0        (   busy_r0             ),
                .busy_r1        (   busy_r1             ),
                .busy_bu        (   busy_bu_4           ),
                .end_op_bu      (   end_op_bu[3]       ),
                .start_bu       (   start_bu_4          ),
                .mode_bu        (   mode_bu_4           ),
                .control_dmu    (   control_dmu_bu[31:24]   ),
                .off_ram        (   off_ram_bu[31:24]       ),
                .off_rej        (   off_rej_dmu[15:12]      ),
                .end_op         (   end_op_bu_4         ),
                .start_ed       (   start_ed        )
            );
        end
        else begin
            assign start_bu_3 = 0;
            assign start_bu_4 = 0;
            assign end_op_bu_3 = 1;
            assign end_op_bu_4 = 1;
        end
    endgenerate
    
    
    assign control_dmu[07:00] = (start_bu_1) ? control_dmu_bu[07:00] : control_dmu_cbd[07:00];
    assign control_dmu[15:08] = (start_bu_2) ? control_dmu_bu[15:08] : control_dmu_cbd[15:08];
    assign control_dmu[23:16] = (start_bu_3) ? control_dmu_bu[23:16] : control_dmu_cbd[23:16];
    assign control_dmu[31:24] = (start_bu_4) ? control_dmu_bu[31:24] : control_dmu_cbd[31:24];
    assign control_dmu[40:32] = 9'b000000000;
    
    assign off_ram[03:00] = (start_bu_1) ? off_ram_bu[03:00] : off_ram_cbd[03:00];  // off_ram_01
    assign off_ram[07:04] = (start_bu_1) ? off_ram_bu[07:04] : off_ram_cbd[03:00];  // off_ram_11
    
    assign off_ram[11:08] = (start_bu_2) ? off_ram_bu[11:08] : off_ram_cbd[07:04];  // off_ram_02
    assign off_ram[15:12] = (start_bu_2) ? off_ram_bu[15:12] : off_ram_cbd[07:04];  // off_ram_12
    
    assign off_ram[19:16] = (start_bu_3) ? off_ram_bu[19:16] : off_ram_cbd[11:08];  // off_ram_03
    assign off_ram[23:20] = (start_bu_3) ? off_ram_bu[23:20] : off_ram_cbd[11:08];  // off_ram_13
    
    assign off_ram[27:24] = (start_bu_4) ? off_ram_bu[27:24] : off_ram_cbd[15:12];  // off_ram_04
    assign off_ram[31:28] = (start_bu_4) ? off_ram_bu[31:28] : off_ram_cbd[15:12];  // off_ram_14
    
    
    assign ctl_bu = {  mode_bu_4,  mode_bu_3,  mode_bu_2,  mode_bu_1, 
                        start_bu_4, start_bu_3, start_bu_2, start_bu_1};
    
endmodule

