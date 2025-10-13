`timescale 1ns / 1ps

module BU_ENGINE_N_BU_4 #(
    parameter MASKED = 0
)(
    input clk,
    input rst,
    input   [3:0]       start,
    input   [15:0]      mode,
    output  [3:0]       end_op,
    output  [7:0]       en_ram,
    input   [4*24-1:0]  di_1,
    output  [4*24-1:0]  do_1,
    output  [4*8-1:0]   ad_1,
    input   [4*24-1:0]  di_2,
    output  [4*24-1:0]  do_2,
    output  [4*8-1:0]   ad_2,
    input   [4*24-1:0]  di_3,
    output  [4*24-1:0]  do_3,
    output  [4*8-1:0]   ad_3,                           
    input   [4*24-1:0]  di_4,
    output  [4*24-1:0]  do_4,
    output  [4*8-1:0]   ad_4
);
    // --------------------------------------------------------------------- //
    // --- BU 1 --- //
    wire [3:0]  mode_1;
    wire        start_1;
    wire        end_op_1;
    wire        er_0_1;
    wire        er_1_1;
    wire [23:0] di_10_1;
    wire [23:0] di_20_1;
    wire [23:0] di_11_1;
    wire [23:0] di_21_1;
    wire [23:0] do_10_1;
    wire [23:0] do_20_1;
    wire [23:0] do_11_1;
    wire [23:0] do_21_1;
    wire [7:0]  ad_10_1;
    wire [7:0]  ad_20_1;
    wire [7:0]  ad_11_1;
    wire [7:0]  ad_21_1;
    
    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_1
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_1   ), 
            .mode           (   mode_1    ),
            .end_op         (   end_op_1  ),
            .enable_ram_0   (   er_0_1    ),
            .enable_ram_1   (   er_1_1    ),
            .addr_1_r0      (   ad_10_1   ),
            .addr_2_r0      (   ad_20_1   ), 
            .addr_1_r1      (   ad_11_1   ),
            .addr_2_r1      (   ad_21_1   ), 
            .data_in_1_r0   (   di_10_1   ),
            .data_in_2_r0   (   di_20_1   ),
            .data_in_1_r1   (   di_11_1   ),
            .data_in_2_r1   (   di_21_1   ),
            .data_out_1_r0  (   do_10_1   ),
            .data_out_2_r0  (   do_20_1   ),
            .data_out_1_r1  (   do_11_1   ),
            .data_out_2_r1  (   do_21_1   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_1
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_1   ), 
            .mode           (   mode_1    ),
            .end_op         (   end_op_1  ),
            .enable_ram_0   (   er_0_1    ),
            .enable_ram_1   (   er_1_1    ),
            .addr_1_r0      (   ad_10_1   ),
            .addr_2_r0      (   ad_20_1   ), 
            .addr_1_r1      (   ad_11_1   ),
            .addr_2_r1      (   ad_21_1   ), 
            .data_in_1_r0   (   di_10_1   ),
            .data_in_2_r0   (   di_20_1   ),
            .data_in_1_r1   (   di_11_1   ),
            .data_in_2_r1   (   di_21_1   ),
            .data_out_1_r0  (   do_10_1   ),
            .data_out_2_r0  (   do_20_1   ),
            .data_out_1_r1  (   do_11_1   ),
            .data_out_2_r1  (   do_21_1   )
            );
        end
    endgenerate
    
    // --------------------------------------------------------------------- //
    // --- BU 2 --- //
    wire [3:0]  mode_2;
    wire        start_2;
    wire        end_op_2;
    wire        er_0_2;
    wire        er_1_2;
    wire [23:0] di_10_2;
    wire [23:0] di_20_2;
    wire [23:0] di_11_2;
    wire [23:0] di_21_2;
    wire [23:0] do_10_2;
    wire [23:0] do_20_2;
    wire [23:0] do_11_2;
    wire [23:0] do_21_2;
    wire [7:0]  ad_10_2;
    wire [7:0]  ad_20_2;
    wire [7:0]  ad_11_2;
    wire [7:0]  ad_21_2;

    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_2
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_2   ), 
            .mode           (   mode_2    ),
            .end_op         (   end_op_2  ),
            .enable_ram_0   (   er_0_2    ),
            .enable_ram_1   (   er_1_2    ),
            .addr_1_r0      (   ad_10_2   ),
            .addr_2_r0      (   ad_20_2   ), 
            .addr_1_r1      (   ad_11_2   ),
            .addr_2_r1      (   ad_21_2   ), 
            .data_in_1_r0   (   di_10_2   ),
            .data_in_2_r0   (   di_20_2   ),
            .data_in_1_r1   (   di_11_2   ),
            .data_in_2_r1   (   di_21_2   ),
            .data_out_1_r0  (   do_10_2   ),
            .data_out_2_r0  (   do_20_2   ),
            .data_out_1_r1  (   do_11_2   ),
            .data_out_2_r1  (   do_21_2   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_2
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_2   ), 
            .mode           (   mode_2    ),
            .end_op         (   end_op_2  ),
            .enable_ram_0   (   er_0_2    ),
            .enable_ram_1   (   er_1_2    ),
            .addr_1_r0      (   ad_10_2   ),
            .addr_2_r0      (   ad_20_2   ), 
            .addr_1_r1      (   ad_11_2   ),
            .addr_2_r1      (   ad_21_2   ), 
            .data_in_1_r0   (   di_10_2   ),
            .data_in_2_r0   (   di_20_2   ),
            .data_in_1_r1   (   di_11_2   ),
            .data_in_2_r1   (   di_21_2   ),
            .data_out_1_r0  (   do_10_2   ),
            .data_out_2_r0  (   do_20_2   ),
            .data_out_1_r1  (   do_11_2   ),
            .data_out_2_r1  (   do_21_2   )
            );
        end
    endgenerate
    
    
    // --------------------------------------------------------------------- //
    // --- BU 3 --- //
    wire [3:0]  mode_3;
    wire        start_3;
    wire        end_op_3;
    wire        er_0_3;
    wire        er_1_3;
    wire [23:0] di_10_3;
    wire [23:0] di_20_3;
    wire [23:0] di_11_3;
    wire [23:0] di_21_3;
    wire [23:0] do_10_3;
    wire [23:0] do_20_3;
    wire [23:0] do_11_3;
    wire [23:0] do_21_3;
    wire [7:0]  ad_10_3;
    wire [7:0]  ad_20_3;
    wire [7:0]  ad_11_3;
    wire [7:0]  ad_21_3;

    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_3
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_3   ), 
            .mode           (   mode_3    ),
            .end_op         (   end_op_3  ),
            .enable_ram_0   (   er_0_3    ),
            .enable_ram_1   (   er_1_3    ),
            .addr_1_r0      (   ad_10_3   ),
            .addr_2_r0      (   ad_20_3   ), 
            .addr_1_r1      (   ad_11_3   ),
            .addr_2_r1      (   ad_21_3   ), 
            .data_in_1_r0   (   di_10_3   ),
            .data_in_2_r0   (   di_20_3   ),
            .data_in_1_r1   (   di_11_3   ),
            .data_in_2_r1   (   di_21_3   ),
            .data_out_1_r0  (   do_10_3   ),
            .data_out_2_r0  (   do_20_3   ),
            .data_out_1_r1  (   do_11_3   ),
            .data_out_2_r1  (   do_21_3   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_3
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_3   ), 
            .mode           (   mode_3    ),
            .end_op         (   end_op_3  ),
            .enable_ram_0   (   er_0_3    ),
            .enable_ram_1   (   er_1_3    ),
            .addr_1_r0      (   ad_10_3   ),
            .addr_2_r0      (   ad_20_3   ), 
            .addr_1_r1      (   ad_11_3   ),
            .addr_2_r1      (   ad_21_3   ), 
            .data_in_1_r0   (   di_10_3   ),
            .data_in_2_r0   (   di_20_3   ),
            .data_in_1_r1   (   di_11_3   ),
            .data_in_2_r1   (   di_21_3   ),
            .data_out_1_r0  (   do_10_3   ),
            .data_out_2_r0  (   do_20_3   ),
            .data_out_1_r1  (   do_11_3   ),
            .data_out_2_r1  (   do_21_3   )
            );
        end
    endgenerate
    
    
    
    // --------------------------------------------------------------------- //
    // --- BU 4 --- //
    wire [3:0]  mode_4;
    wire        start_4;
    wire        end_op_4;
    wire        er_0_4;
    wire        er_1_4;
    wire [23:0] di_10_4;
    wire [23:0] di_20_4;
    wire [23:0] di_11_4;
    wire [23:0] di_21_4;
    wire [23:0] do_10_4;
    wire [23:0] do_20_4;
    wire [23:0] do_11_4;
    wire [23:0] do_21_4;
    wire [7:0]  ad_10_4;
    wire [7:0]  ad_20_4;
    wire [7:0]  ad_11_4;
    wire [7:0]  ad_21_4;

    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_4
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ),  
            .start          (   start_4   ), 
            .mode           (   mode_4    ),
            .end_op         (   end_op_4  ),
            .enable_ram_0   (   er_0_4    ),
            .enable_ram_1   (   er_1_4    ),
            .addr_1_r0      (   ad_10_4   ),
            .addr_2_r0      (   ad_20_4   ), 
            .addr_1_r1      (   ad_11_4   ),
            .addr_2_r1      (   ad_21_4   ), 
            .data_in_1_r0   (   di_10_4   ),
            .data_in_2_r0   (   di_20_4   ),
            .data_in_1_r1   (   di_11_4   ),
            .data_in_2_r1   (   di_21_4   ),
            .data_out_1_r0  (   do_10_4   ),
            .data_out_2_r0  (   do_20_4   ),
            .data_out_1_r1  (   do_11_4   ),
            .data_out_2_r1  (   do_21_4   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_4
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ),  
            .start          (   start_4   ), 
            .mode           (   mode_4    ),
            .end_op         (   end_op_4  ),
            .enable_ram_0   (   er_0_4    ),
            .enable_ram_1   (   er_1_4    ),
            .addr_1_r0      (   ad_10_4   ),
            .addr_2_r0      (   ad_20_4   ), 
            .addr_1_r1      (   ad_11_4   ),
            .addr_2_r1      (   ad_21_4   ), 
            .data_in_1_r0   (   di_10_4   ),
            .data_in_2_r0   (   di_20_4   ),
            .data_in_1_r1   (   di_11_4   ),
            .data_in_2_r1   (   di_21_4   ),
            .data_out_1_r0  (   do_10_4   ),
            .data_out_2_r0  (   do_20_4   ),
            .data_out_1_r1  (   do_11_4   ),
            .data_out_2_r1  (   do_21_4   )
            );
        end
    endgenerate
    
    
    // ----------------------------------------------------------------- //
    // ---- Signal assignations ---- //
    assign mode_1 = mode[03:00];
    assign mode_2 = mode[07:04];
    assign mode_3 = mode[11:08];
    assign mode_4 = mode[15:12];
    
    assign start_1 = start[0];
    assign start_2 = start[1];
    assign start_3 = start[2];
    assign start_4 = start[3];
    
    assign end_op = {end_op_4, end_op_3, end_op_2, end_op_1};
    
    assign di_10_1 = di_1[23:00];
    assign di_20_1 = di_1[47:24];
    assign di_11_1 = di_1[71:48];
    assign di_21_1 = di_1[95:72];
    
    assign do_1 = {do_21_1, do_11_1, do_20_1, do_10_1};
    assign ad_1 = {ad_21_1, ad_11_1, ad_20_1, ad_10_1};
    
    assign di_10_2 = di_2[23:00];
    assign di_20_2 = di_2[47:24];
    assign di_11_2 = di_2[71:48];
    assign di_21_2 = di_2[95:72];
    
    assign do_2 = {do_21_2, do_11_2, do_20_2, do_10_2};
    assign ad_2 = {ad_21_2, ad_11_2, ad_20_2, ad_10_2};
    
    assign di_10_3 = di_3[23:00];
    assign di_20_3 = di_3[47:24];
    assign di_11_3 = di_3[71:48];
    assign di_21_3 = di_3[95:72];
    
    assign do_3 = {do_21_3, do_11_3, do_20_3, do_10_3};
    assign ad_3 = {ad_21_3, ad_11_3, ad_20_3, ad_10_3};
    
    assign di_10_4 = di_4[23:00];
    assign di_20_4 = di_4[47:24];
    assign di_11_4 = di_4[71:48];
    assign di_21_4 = di_4[95:72];
    
    assign do_4 = {do_21_4, do_11_4, do_20_4, do_10_4};
    assign ad_4 = {ad_21_4, ad_11_4, ad_20_4, ad_10_4};
    
    assign en_ram = {er_1_4, er_0_4, er_1_3, er_0_3, er_1_2, er_0_2, er_1_1, er_0_1};

endmodule

module BU_ENGINE_N_BU_2 #(
    parameter MASKED = 0
)(
    input clk,
    input rst,
    input   [3:0]       start,
    input   [15:0]      mode,
    output  [3:0]       end_op,
    output  [7:0]       en_ram,
    input   [4*24-1:0]  di_1,
    output  [4*24-1:0]  do_1,
    output  [4*8-1:0]   ad_1,
    input   [4*24-1:0]  di_2,
    output  [4*24-1:0]  do_2,
    output  [4*8-1:0]   ad_2
);
    // --------------------------------------------------------------------- //
    // --- BU 1 --- //
    wire [3:0]  mode_1;
    wire        start_1;
    wire        end_op_1;
    wire        er_0_1;
    wire        er_1_1;
    wire [23:0] di_10_1;
    wire [23:0] di_20_1;
    wire [23:0] di_11_1;
    wire [23:0] di_21_1;
    wire [23:0] do_10_1;
    wire [23:0] do_20_1;
    wire [23:0] do_11_1;
    wire [23:0] do_21_1;
    wire [7:0]  ad_10_1;
    wire [7:0]  ad_20_1;
    wire [7:0]  ad_11_1;
    wire [7:0]  ad_21_1;
    
    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_1
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_1   ), 
            .mode           (   mode_1    ),
            .end_op         (   end_op_1  ),
            .enable_ram_0   (   er_0_1    ),
            .enable_ram_1   (   er_1_1    ),
            .addr_1_r0      (   ad_10_1   ),
            .addr_2_r0      (   ad_20_1   ), 
            .addr_1_r1      (   ad_11_1   ),
            .addr_2_r1      (   ad_21_1   ), 
            .data_in_1_r0   (   di_10_1   ),
            .data_in_2_r0   (   di_20_1   ),
            .data_in_1_r1   (   di_11_1   ),
            .data_in_2_r1   (   di_21_1   ),
            .data_out_1_r0  (   do_10_1   ),
            .data_out_2_r0  (   do_20_1   ),
            .data_out_1_r1  (   do_11_1   ),
            .data_out_2_r1  (   do_21_1   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_1
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_1   ), 
            .mode           (   mode_1    ),
            .end_op         (   end_op_1  ),
            .enable_ram_0   (   er_0_1    ),
            .enable_ram_1   (   er_1_1    ),
            .addr_1_r0      (   ad_10_1   ),
            .addr_2_r0      (   ad_20_1   ), 
            .addr_1_r1      (   ad_11_1   ),
            .addr_2_r1      (   ad_21_1   ), 
            .data_in_1_r0   (   di_10_1   ),
            .data_in_2_r0   (   di_20_1   ),
            .data_in_1_r1   (   di_11_1   ),
            .data_in_2_r1   (   di_21_1   ),
            .data_out_1_r0  (   do_10_1   ),
            .data_out_2_r0  (   do_20_1   ),
            .data_out_1_r1  (   do_11_1   ),
            .data_out_2_r1  (   do_21_1   )
            );
        end
    endgenerate
    
    // --------------------------------------------------------------------- //
    // --- BU 2 --- //
    wire [3:0]  mode_2;
    wire        start_2;
    wire        end_op_2;
    wire        er_0_2;
    wire        er_1_2;
    wire [23:0] di_10_2;
    wire [23:0] di_20_2;
    wire [23:0] di_11_2;
    wire [23:0] di_21_2;
    wire [23:0] do_10_2;
    wire [23:0] do_20_2;
    wire [23:0] do_11_2;
    wire [23:0] do_21_2;
    wire [7:0]  ad_10_2;
    wire [7:0]  ad_20_2;
    wire [7:0]  ad_11_2;
    wire [7:0]  ad_21_2;

    generate 
        if(MASKED == 0) begin
            BUTTERFLY_UNIT BU_2
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_2   ), 
            .mode           (   mode_2    ),
            .end_op         (   end_op_2  ),
            .enable_ram_0   (   er_0_2    ),
            .enable_ram_1   (   er_1_2    ),
            .addr_1_r0      (   ad_10_2   ),
            .addr_2_r0      (   ad_20_2   ), 
            .addr_1_r1      (   ad_11_2   ),
            .addr_2_r1      (   ad_21_2   ), 
            .data_in_1_r0   (   di_10_2   ),
            .data_in_2_r0   (   di_20_2   ),
            .data_in_1_r1   (   di_11_2   ),
            .data_in_2_r1   (   di_21_2   ),
            .data_out_1_r0  (   do_10_2   ),
            .data_out_2_r0  (   do_20_2   ),
            .data_out_1_r1  (   do_11_2   ),
            .data_out_2_r1  (   do_21_2   )
            );
        end
        else begin
            BUTTERFLY_UNIT_MASKED BU_2
            (   
            .clk            (   clk       ), 
            .rst            (   rst       ), 
            .start          (   start_2   ), 
            .mode           (   mode_2    ),
            .end_op         (   end_op_2  ),
            .enable_ram_0   (   er_0_2    ),
            .enable_ram_1   (   er_1_2    ),
            .addr_1_r0      (   ad_10_2   ),
            .addr_2_r0      (   ad_20_2   ), 
            .addr_1_r1      (   ad_11_2   ),
            .addr_2_r1      (   ad_21_2   ), 
            .data_in_1_r0   (   di_10_2   ),
            .data_in_2_r0   (   di_20_2   ),
            .data_in_1_r1   (   di_11_2   ),
            .data_in_2_r1   (   di_21_2   ),
            .data_out_1_r0  (   do_10_2   ),
            .data_out_2_r0  (   do_20_2   ),
            .data_out_1_r1  (   do_11_2   ),
            .data_out_2_r1  (   do_21_2   )
            );
        end
    endgenerate
    
    
    
    // ----------------------------------------------------------------- //
    // ---- Signal assignations ---- //
    assign mode_1 = mode[03:00];
    assign mode_2 = mode[07:04];
    
    assign start_1 = start[0];
    assign start_2 = start[1];
    
    assign end_op = {1'b1, 1'b1, end_op_2, end_op_1};
    
    assign di_10_1 = di_1[23:00];
    assign di_20_1 = di_1[47:24];
    assign di_11_1 = di_1[71:48];
    assign di_21_1 = di_1[95:72];
    
    assign do_1 = {do_21_1, do_11_1, do_20_1, do_10_1};
    assign ad_1 = {ad_21_1, ad_11_1, ad_20_1, ad_10_1};
    
    assign di_10_2 = di_2[23:00];
    assign di_20_2 = di_2[47:24];
    assign di_11_2 = di_2[71:48];
    assign di_21_2 = di_2[95:72];
    
    assign do_2 = {do_21_2, do_11_2, do_20_2, do_10_2};
    assign ad_2 = {ad_21_2, ad_11_2, ad_20_2, ad_10_2};
    
    assign en_ram = {1'b0, 1'b0, 1'b0, 1'b0, er_1_2, er_0_2, er_1_1, er_0_1};

endmodule

module BU_ENGINE_N_BU_1 #(
    parameter MASKED = 0
)(
    input clk,
    input rst,
    input   [3:0]       start,
    input   [15:0]      mode,
    output  [3:0]       end_op,
    output  [7:0]       en_ram,
    input   [4*24-1:0]  di_1,
    output  [4*24-1:0]  do_1,
    output  [4*8-1:0]   ad_1
);
    // --------------------------------------------------------------------- //
    // --- BU 1 --- //
    wire [3:0]  mode_1;
    wire        start_1;
    wire        end_op_1;
    wire        er_0_1;
    wire        er_1_1;
    wire [23:0] di_10_1;
    wire [23:0] di_20_1;
    wire [23:0] di_11_1;
    wire [23:0] di_21_1;
    wire [23:0] do_10_1;
    wire [23:0] do_20_1;
    wire [23:0] do_11_1;
    wire [23:0] do_21_1;
    wire [7:0]  ad_10_1;
    wire [7:0]  ad_20_1;
    wire [7:0]  ad_11_1;
    wire [7:0]  ad_21_1;

    // We use masked version for both cases since the only change is the use of coefficients 
    
    BUTTERFLY_UNIT_MASKED BU_1
    (   
    .clk            (   clk       ), 
    .rst            (   rst       ), 
    .start          (   start_1   ), 
    .mode           (   mode_1    ),
    .end_op         (   end_op_1  ),
    .enable_ram_0   (   er_0_1    ),
    .enable_ram_1   (   er_1_1    ),
    .addr_1_r0      (   ad_10_1   ),
    .addr_2_r0      (   ad_20_1   ), 
    .addr_1_r1      (   ad_11_1   ),
    .addr_2_r1      (   ad_21_1   ), 
    .data_in_1_r0   (   di_10_1   ),
    .data_in_2_r0   (   di_20_1   ),
    .data_in_1_r1   (   di_11_1   ),
    .data_in_2_r1   (   di_21_1   ),
    .data_out_1_r0  (   do_10_1   ),
    .data_out_2_r0  (   do_20_1   ),
    .data_out_1_r1  (   do_11_1   ),
    .data_out_2_r1  (   do_21_1   )
    );
    
    // ----------------------------------------------------------------- //
    // ---- Signal assignations ---- //
    assign mode_1 = mode[03:00];
    
    assign start_1 = start[0];
    
    assign end_op = {1'b0, 1'b0, 1'b0, end_op_1};
    
    assign di_10_1 = di_1[23:00];
    assign di_20_1 = di_1[47:24];
    assign di_11_1 = di_1[71:48];
    assign di_21_1 = di_1[95:72];
    
    assign do_1 = {do_21_1, do_11_1, do_20_1, do_10_1};
    assign ad_1 = {ad_21_1, ad_11_1, ad_20_1, ad_10_1};
    
    assign en_ram = {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, er_1_1, er_0_1};

endmodule