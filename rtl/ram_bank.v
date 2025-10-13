`timescale 1ns / 1ps

module RAM_BANK_N_BU_4(
    input clk,
    
    input              enable_1_01,
    input              enable_2_01,
    input   [9:0]      addr_1_01,
    input   [9:0]      addr_2_01,
    input   [35:0]     data_in_1_01,
    input   [35:0]     data_in_2_01,
    output  [35:0]     data_out_1_01,
    output  [35:0]     data_out_2_01,
    
    input              enable_1_11,
    input              enable_2_11,
    input   [9:0]      addr_1_11,
    input   [9:0]      addr_2_11,
    input   [35:0]     data_in_1_11,
    input   [35:0]     data_in_2_11,
    output  [35:0]     data_out_1_11,
    output  [35:0]     data_out_2_11,
    
    input              enable_1_02,
    input              enable_2_02,
    input   [9:0]      addr_1_02,
    input   [9:0]      addr_2_02,
    input   [35:0]     data_in_1_02,
    input   [35:0]     data_in_2_02,
    output  [35:0]     data_out_1_02,
    output  [35:0]     data_out_2_02,
    
    input              enable_1_12,
    input              enable_2_12,
    input   [9:0]      addr_1_12,
    input   [9:0]      addr_2_12,
    input   [35:0]     data_in_1_12,
    input   [35:0]     data_in_2_12,
    output  [35:0]     data_out_1_12,
    output  [35:0]     data_out_2_12,
    
    input              enable_1_03,
    input              enable_2_03,
    input   [9:0]      addr_1_03,
    input   [9:0]      addr_2_03,
    input   [35:0]     data_in_1_03,
    input   [35:0]     data_in_2_03,
    output  [35:0]     data_out_1_03,
    output  [35:0]     data_out_2_03,
    
    input              enable_1_13,
    input              enable_2_13,
    input   [9:0]      addr_1_13,
    input   [9:0]      addr_2_13,
    input   [35:0]     data_in_1_13,
    input   [35:0]     data_in_2_13,
    output  [35:0]     data_out_1_13,
    output  [35:0]     data_out_2_13,
    
    input              enable_1_04,
    input              enable_2_04,
    input   [9:0]      addr_1_04,
    input   [9:0]      addr_2_04,
    input   [35:0]     data_in_1_04,
    input   [35:0]     data_in_2_04,
    output  [35:0]     data_out_1_04,
    output  [35:0]     data_out_2_04,
    
    input              enable_1_14,
    input              enable_2_14,
    input   [9:0]      addr_1_14,
    input   [9:0]      addr_2_14,
    input   [35:0]     data_in_1_14,
    input   [35:0]     data_in_2_14,
    output  [35:0]     data_out_1_14,
    output  [35:0]     data_out_2_14
    
    );
    
    // --------------------------------------------------------------------- //
    
    // --- RAM 01 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_01     ),     
    .enable_2   (   enable_2_01     ), 
    .addr_1     (   addr_1_01       ),              
    .addr_2     (   addr_2_01       ), 
    .data_in_1  (   data_in_1_01    ),
    .data_in_2  (   data_in_2_01    ),
    .data_out_1 (   data_out_1_01   ),
    .data_out_2 (   data_out_2_01   )
    );
    
    // --- RAM 11 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_11     ),     
    .enable_2   (   enable_2_11     ), 
    .addr_1     (   addr_1_11       ),              
    .addr_2     (   addr_2_11       ), 
    .data_in_1  (   data_in_1_11    ),
    .data_in_2  (   data_in_2_11    ),
    .data_out_1 (   data_out_1_11   ),
    .data_out_2 (   data_out_2_11   )
    );
    
    // --------------------------------------------------------------------- //
    // --- RAM 02 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_2
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_02     ),     
    .enable_2   (   enable_2_02     ), 
    .addr_1     (   addr_1_02       ),              
    .addr_2     (   addr_2_02       ), 
    .data_in_1  (   data_in_1_02    ),
    .data_in_2  (   data_in_2_02    ),
    .data_out_1 (   data_out_1_02   ),
    .data_out_2 (   data_out_2_02   )
    );
    
    // --- RAM 12 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_2
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_12     ),     
    .enable_2   (   enable_2_12     ), 
    .addr_1     (   addr_1_12       ),              
    .addr_2     (   addr_2_12       ), 
    .data_in_1  (   data_in_1_12    ),
    .data_in_2  (   data_in_2_12    ),
    .data_out_1 (   data_out_1_12   ),
    .data_out_2 (   data_out_2_12   )
    );
    
    // --------------------------------------------------------------------- //
    
    // --- RAM 03 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_3
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_03     ),     
    .enable_2   (   enable_2_03     ), 
    .addr_1     (   addr_1_03       ),              
    .addr_2     (   addr_2_03       ), 
    .data_in_1  (   data_in_1_03    ),
    .data_in_2  (   data_in_2_03    ),
    .data_out_1 (   data_out_1_03   ),
    .data_out_2 (   data_out_2_03   )
    );
    
    // --- RAM 13 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_3
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_13     ),     
    .enable_2   (   enable_2_13     ), 
    .addr_1     (   addr_1_13       ),              
    .addr_2     (   addr_2_13       ), 
    .data_in_1  (   data_in_1_13    ),
    .data_in_2  (   data_in_2_13    ),
    .data_out_1 (   data_out_1_13   ),
    .data_out_2 (   data_out_2_13   )
    );
    
    
    // --------------------------------------------------------------------- //
    
    // --- RAM 04 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_4
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_04     ),     
    .enable_2   (   enable_2_04     ), 
    .addr_1     (   addr_1_04       ),              
    .addr_2     (   addr_2_04       ), 
    .data_in_1  (   data_in_1_04    ),
    .data_in_2  (   data_in_2_04    ),
    .data_out_1 (   data_out_1_04   ),
    .data_out_2 (   data_out_2_04   )
    );
    
    // --- RAM 14 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_4
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_14     ),     
    .enable_2   (   enable_2_14     ), 
    .addr_1     (   addr_1_14       ),              
    .addr_2     (   addr_2_14       ), 
    .data_in_1  (   data_in_1_14    ),
    .data_in_2  (   data_in_2_14    ),
    .data_out_1 (   data_out_1_14   ),
    .data_out_2 (   data_out_2_14   )
    );
endmodule


module RAM_BANK_N_BU_2(
    input clk,
    
    input              enable_1_01,
    input              enable_2_01,
    input   [9:0]      addr_1_01,
    input   [9:0]      addr_2_01,
    input   [35:0]     data_in_1_01,
    input   [35:0]     data_in_2_01,
    output  [35:0]     data_out_1_01,
    output  [35:0]     data_out_2_01,
    
    input              enable_1_11,
    input              enable_2_11,
    input   [9:0]      addr_1_11,
    input   [9:0]      addr_2_11,
    input   [35:0]     data_in_1_11,
    input   [35:0]     data_in_2_11,
    output  [35:0]     data_out_1_11,
    output  [35:0]     data_out_2_11,
    
    input              enable_1_02,
    input              enable_2_02,
    input   [9:0]      addr_1_02,
    input   [9:0]      addr_2_02,
    input   [35:0]     data_in_1_02,
    input   [35:0]     data_in_2_02,
    output  [35:0]     data_out_1_02,
    output  [35:0]     data_out_2_02,
    
    input              enable_1_12,
    input              enable_2_12,
    input   [9:0]      addr_1_12,
    input   [9:0]      addr_2_12,
    input   [35:0]     data_in_1_12,
    input   [35:0]     data_in_2_12,
    output  [35:0]     data_out_1_12,
    output  [35:0]     data_out_2_12
    
    );
    
    // --------------------------------------------------------------------- //
    
    // --- RAM 01 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_01     ),     
    .enable_2   (   enable_2_01     ), 
    .addr_1     (   addr_1_01       ),              
    .addr_2     (   addr_2_01       ), 
    .data_in_1  (   data_in_1_01    ),
    .data_in_2  (   data_in_2_01    ),
    .data_out_1 (   data_out_1_01   ),
    .data_out_2 (   data_out_2_01   )
    );
    
    // --- RAM 11 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_11     ),     
    .enable_2   (   enable_2_11     ), 
    .addr_1     (   addr_1_11       ),              
    .addr_2     (   addr_2_11       ), 
    .data_in_1  (   data_in_1_11    ),
    .data_in_2  (   data_in_2_11    ),
    .data_out_1 (   data_out_1_11   ),
    .data_out_2 (   data_out_2_11   )
    );
    
    // --------------------------------------------------------------------- //
    // --- RAM 02 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_2
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_02     ),     
    .enable_2   (   enable_2_02     ), 
    .addr_1     (   addr_1_02       ),              
    .addr_2     (   addr_2_02       ), 
    .data_in_1  (   data_in_1_02    ),
    .data_in_2  (   data_in_2_02    ),
    .data_out_1 (   data_out_1_02   ),
    .data_out_2 (   data_out_2_02   )
    );
    
    // --- RAM 12 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_2
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_12     ),     
    .enable_2   (   enable_2_12     ), 
    .addr_1     (   addr_1_12       ),              
    .addr_2     (   addr_2_12       ), 
    .data_in_1  (   data_in_1_12    ),
    .data_in_2  (   data_in_2_12    ),
    .data_out_1 (   data_out_1_12   ),
    .data_out_2 (   data_out_2_12   )
    );
endmodule


module RAM_BANK_N_BU_1(
    input clk,
    
    input              enable_1_01,
    input              enable_2_01,
    input   [9:0]      addr_1_01,
    input   [9:0]      addr_2_01,
    input   [35:0]     data_in_1_01,
    input   [35:0]     data_in_2_01,
    output  [35:0]     data_out_1_01,
    output  [35:0]     data_out_2_01,
    
    input              enable_1_11,
    input              enable_2_11,
    input   [9:0]      addr_1_11,
    input   [9:0]      addr_2_11,
    input   [35:0]     data_in_1_11,
    input   [35:0]     data_in_2_11,
    output  [35:0]     data_out_1_11,
    output  [35:0]     data_out_2_11
    
    );
    
    // --------------------------------------------------------------------- //
    
    // --- RAM 01 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_0_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_01     ),     
    .enable_2   (   enable_2_01     ), 
    .addr_1     (   addr_1_01       ),              
    .addr_2     (   addr_2_01       ), 
    .data_in_1  (   data_in_1_01    ),
    .data_in_2  (   data_in_2_01    ),
    .data_out_1 (   data_out_1_01   ),
    .data_out_2 (   data_out_2_01   )
    );
    
    // --- RAM 11 --- //
    
    RAM_DUAL #(.SIZE(1024), .WIDTH(36)) RAM_1_1
    (.clk       (   clk             ), 
    .enable_1   (   enable_1_11     ),     
    .enable_2   (   enable_2_11     ), 
    .addr_1     (   addr_1_11       ),              
    .addr_2     (   addr_2_11       ), 
    .data_in_1  (   data_in_1_11    ),
    .data_in_2  (   data_in_2_11    ),
    .data_out_1 (   data_out_1_11   ),
    .data_out_2 (   data_out_2_11   )
    );
    
endmodule