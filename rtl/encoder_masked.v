`timescale 1ns / 1ps


module ENCODER_COMPRESS_MASKED_N_BU_2_CLK (
    input                           clk,
    input                           rst,
    input                           start,
    input           [15:0]          mode, 
    input           [16*24-1:0]     input_data,
    output  reg                     d_valid,
    output          [63:0]          out_data
    );
    
    wire [7:0] mode_encoder;
    wire [7:0] mode_compress;
    
    assign mode_encoder     = mode[07:00];
    assign mode_compress    = mode[15:08];
    
    reg [7:0] mode_reg;
    reg [7:0] mode_reg_1, mode_reg_2;
    always @(posedge clk) mode_reg   <= mode_encoder;
    always @(posedge clk) mode_reg_1 <= mode_reg;
    always @(posedge clk) mode_reg_2 <= mode_reg_1;
    
    reg start_reg_0, start_reg;
    always @(posedge clk) start_reg_0   <= start; // to sync
    always @(posedge clk) start_reg     <= start_reg_0; // to sync
    
    reg [47:00] input_register;

    wire [47:0] data_0_0 = input_data[(02*24)-1:(00*24)];
    wire [47:0] data_1_0 = input_data[(04*24)-1:(02*24)];
    wire [47:0] data_0_1 = input_data[(06*24)-1:(04*24)];
    wire [47:0] data_1_1 = input_data[(08*24)-1:(06*24)];

    wire case_0 = ~mode_reg_1[1] & mode_reg_1[0]; //01
    wire case_1 =  mode_reg_1[1] & mode_reg_1[0]; //11

    wire [11:0] in_0_0;
    wire [11:0] in_0_1;
    wire [11:0] in_0_2;
    wire [11:0] in_0_3;
    wire [11:0] in_1_0;
    wire [11:0] in_1_1;
    wire [11:0] in_1_2;
    wire [11:0] in_1_3;
    
    mod_add mod_add_0_0 (.a(data_0_0[11:00]), .b(data_0_1[11:00]), .c(in_0_0));
    mod_add mod_add_0_1 (.a(data_0_0[23:12]), .b(data_0_1[23:12]), .c(in_0_1));
    mod_add mod_add_0_2 (.a(data_0_0[35:24]), .b(data_0_1[35:24]), .c(in_0_2));
    mod_add mod_add_0_3 (.a(data_0_0[47:36]), .b(data_0_1[47:36]), .c(in_0_3));

    mod_add mod_add_1_0 (.a(data_1_0[11:00]), .b(data_1_1[11:00]), .c(in_1_0));
    mod_add mod_add_1_1 (.a(data_1_0[23:12]), .b(data_1_1[23:12]), .c(in_1_1));
    mod_add mod_add_1_2 (.a(data_1_0[35:24]), .b(data_1_1[35:24]), .c(in_1_2));
    mod_add mod_add_1_3 (.a(data_1_0[47:36]), .b(data_1_1[47:36]), .c(in_1_3));


    always @(posedge clk) begin
        if(case_0)  input_register <= {in_0_3, in_0_2, in_0_1, in_0_0};
        else        input_register <= {in_1_3, in_1_2, in_1_1, in_1_0};
    end
    
    
    // --- COMPRESS MODULES --- //
    
    wire [3:0] b;
    assign b = mode_compress[3:0];
    
    wire [11:0] c_0, c_1, c_2, c_3;
    COMPRESS COMPRESS_0 (.clk(clk), .b(b), .x(input_register[11:00]), .o(c_0));
    COMPRESS COMPRESS_1 (.clk(clk), .b(b), .x(input_register[23:12]), .o(c_1));
    COMPRESS COMPRESS_2 (.clk(clk), .b(b), .x(input_register[35:24]), .o(c_2));
    COMPRESS COMPRESS_3 (.clk(clk), .b(b), .x(input_register[47:36]), .o(c_3));
    
    wire [10:0] c_11_0, c_11_1, c_11_2, c_11_3;
    wire [09:0] c_10_0, c_10_1, c_10_2, c_10_3;
    wire [04:0] c_05_0, c_05_1, c_05_2, c_05_3;
    wire [03:0] c_04_0, c_04_1, c_04_2, c_04_3;
    wire        c_01_0, c_01_1, c_01_2, c_01_3;
    
    assign c_11_0 = c_0[10:00];
    assign c_11_1 = c_1[10:00];
    assign c_11_2 = c_2[10:00];
    assign c_11_3 = c_3[10:00];
    
    assign c_10_0 = c_0[09:00];
    assign c_10_1 = c_1[09:00];
    assign c_10_2 = c_2[09:00];
    assign c_10_3 = c_3[09:00];
    
    assign c_05_0 = c_0[04:00];
    assign c_05_1 = c_1[04:00];
    assign c_05_2 = c_2[04:00];
    assign c_05_3 = c_3[04:00];
    
    assign c_04_0 = c_0[03:00];
    assign c_04_1 = c_1[03:00];
    assign c_04_2 = c_2[03:00];
    assign c_04_3 = c_3[03:00];
    
    assign c_01_0 = c_0[0];
    assign c_01_1 = c_1[0];
    assign c_01_2 = c_2[0];
    assign c_01_3 = c_3[0];
    
    wire [11*4-1:0] c_11;
    wire [10*4-1:0] c_10;
    wire [05*4-1:0] c_05;
    wire [04*4-1:0] c_04;
    wire [3:0]      c_01;
    assign c_11 = {c_11_3, c_11_2, c_11_1, c_11_0};
    assign c_10 = {c_10_3, c_10_2, c_10_1, c_10_0};
    assign c_05 = {c_05_3, c_05_2, c_05_1, c_05_0};
    assign c_04 = {c_04_3, c_04_2, c_04_1, c_04_0};
    assign c_01 = {c_01_3, c_01_2, c_01_1, c_01_0};
    
    reg [12*4-1:0] c_12_0;
    reg [12*4-1:0] c_12_1;
    reg [12*4-1:0] c_12_2;
    reg [12*4-1:0] c_12_3;
    wire [12*4-1:0] c_12;
    always @(posedge clk) begin
        c_12_0 <= input_register;
        c_12_1 <= c_12_0;
        c_12_2 <= c_12_1;
        c_12_3 <= c_12_2;
    end
    assign c_12 = c_12_3;
    
    reg [3:0] state;
    // ----
    // mode_encoder = 4'b0000 (0)
    // 0 : 48
    // 1 : dvalid, rest 32
    // 2 : dvalid, rest 16
    // 3 : dvalid, rest 0
    // ----
    // mode_encoder = 4'b0100 (4)
    // 0 : 16
    // 1 : 32
    // 2 : 48
    // 3 : dvalid, 64
    // ----
    // mode_encoder = 4'b0101 (5)
    // 0 : 20
    // 1 : 40
    // 2 : 60
    // 3 : 64  dvalid,  rest 16
    // 4 : 20,          rest 16
    // 5 : 40,          rest 16 
    // 6 : 64, dvalid   rest 12
    // 7 : 20,          rest 12
    // 8 : 40,          rest 12 
    // 9 : 64, dvalid   rest 8
    // 10 : 20,          rest 8
    // 11 : 40,          rest 8 
    // 12 : 64, dvalid   rest 4
    // 13 : 20,          rest 4
    // 14 : 40,          rest 4 
    // 15 : 64, dvalid   rest 0
    // ----
    // mode_encoder = 4'b1010 (10)
    // 0 : 40
    // 1 : 64       dvalid      rest 16
    // 2 : 40                   rest 16
    // 3 : 64       dvalid,     rest 32
    // 4 : (40) 64  dvalid,     rest 8
    // 5 : 40                   rest 8
    // 6 : 64       dvalid,     rest 24
    // 7 : (40) 64  dvalid,     rest 0
    // ----
    // mode_encoder = 4'b1011 (11)
    // 0 : 44
    // 1 : 64       dvalid      rest 24
    // 2 : (44) 64  dvalid      rest 4
    // 3 : 44                   rest 4
    // 4 : 64       dvalid,     rest 28
    // 5 : (44) 64  dvalid      rest 8
    // 6 : 44                   rest 8
    // 7 : 64       dvalid,     rest 32
    // 8 : (44) 64  dvalid      rest 12
    // 9 : 44                   rest 12
    //10 : 64       dvalid,     rest 36
    //11 : (44) 64  dvalid      rest 16
    //12 : 44                   rest 16
    //13 : 64       dvalid,     rest 40
    //14 : (44) 64  dvalid      rest 20
    //15 : (44) 64  dvalid      rest 0
       
    reg [63:0] register;
    reg [63:0] save_register;
    assign out_data = register;
    
    always @(posedge clk) begin
        if(!rst | !start_reg)            register <= 0;
        else begin
            case(b)
            4'b0001: 
                // mode_encoder = 4'b0001 (4)
                // 0 : 4
                // 1 : 8
                // 2 : 12
                // 3 : 16
                // 4 : 20
                // 5 : 24
                // 6 : 28
                // 7 : 32
                // 8 : 36
                // 9 : 40
                // 10 : 44
                // 11 : 48
                // 12 : 52
                // 13 : 56
                // 14 : 60
                // 15 : dvalid, 64
                begin
                    case(state)
                        4'b0000: register <= {60'h000_0000_0000_0000, c_01};
                        4'b0001: register <= {56'h00_0000_0000_0000, c_01, register[03:00]}; 
                        4'b0010: register <= {52'h0_0000_0000_0000, c_01, register[07:00]};
                        4'b0011: register <= {48'h0000_0000_0000, c_01, register[11:00]};
                        4'b0100: register <= {44'h000_0000_0000, c_01, register[15:00]};
                        4'b0101: register <= {40'h00_0000_0000, c_01, register[19:00]}; 
                        4'b0110: register <= {36'h0_0000_0000, c_01, register[23:00]}; 
                        4'b0111: register <= {32'h0000_0000, c_01, register[27:00]}; 
                        4'b1000: register <= {28'h000_0000, c_01, register[31:00]}; 
                        4'b1001: register <= {24'h00_0000, c_01, register[35:00]}; 
                        4'b1010: register <= {20'h0_0000, c_01, register[39:00]};
                        4'b1011: register <= {16'h0000, c_01, register[43:00]};
                        4'b1100: register <= {12'h000, c_01, register[47:00]};
                        4'b1101: register <= {8'h00, c_01, register[51:00]}; 
                        4'b1110: register <= {4'h0, c_01, register[55:00]}; 
                        4'b1111: register <= {c_01, register[59:00]}; 
                        default: register <= {60'h000_0000_0000_0000, c_01};
                    endcase
                end
            
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: register <= {48'h0000_0000_0000, c_04};
                        4'b0001: register <= {32'h0000_0000, c_04, register[15:00]}; 
                        4'b0010: register <= {16'h0000, c_04, register[31:00]};
                        4'b0011: register <= {c_04, register[47:00]};
                        default: register <= {48'h0000_0000_0000, c_04};
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: register <= {44'h000_0000_0000, c_05};
                        4'b0001: register <= {24'h00_0000, c_05, register[19:00]}; 
                        4'b0010: register <= {4'h0, c_05, register[39:00]};
                        4'b0011: register <= {c_05[03:00], register[59:00]};
                        4'b0100: register <= {28'h000_0000, c_05, save_register[15:00]};
                        4'b0101: register <= {8'h00, c_05, register[35:00]}; 
                        4'b0110: register <= {c_05[07:00], register[55:00]};
                        4'b0111: register <= {32'h0000_0000, c_05, save_register[11:00]};
                        4'b1000: register <= {12'h000, c_05, register[31:00]}; 
                        4'b1001: register <= {c_05[11:00], register[51:00]};
                        4'b1010: register <= {36'h0000_0000, c_05, save_register[07:00]};
                        4'b1011: register <= {16'h0000, c_05, register[27:00]}; 
                        4'b1100: register <= {c_05[15:00], register[47:00]};
                        4'b1101: register <= {40'h0000_0000, c_05, save_register[03:00]};
                        4'b1110: register <= {20'h0000, c_05, register[23:00]}; 
                        4'b1111: register <= {c_05, register[43:00]};
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: register <= {24'h00_0000, c_10};
                        4'b0001: register <= {c_10[23:00], register[39:00]}; 
                        4'b0010: register <= {8'h00, c_10, save_register[15:00]};
                        4'b0011: register <= {c_10[07:00], register[55:00]};
                        4'b0100: register <= {c_10[31:00], save_register[31:00]};
                        4'b0101: register <= {16'h0000, c_10, save_register[07:00]}; 
                        4'b0110: register <= {c_10[15:00], register[47:00]};
                        4'b0111: register <= {c_10, save_register[23:00]};
                        default: register <= {24'h00_0000, c_10};
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: register <= {20'h0_0000, c_11};
                        4'b0001: register <= {c_11[19:00], register[43:00]}; 
                        4'b0010: register <= {c_11[39:00], save_register[23:00]};
                        4'b0011: register <= {16'h0000, c_11, save_register[03:00]};
                        4'b0100: register <= {c_11[15:00], register[47:00]};
                        4'b0101: register <= {c_11[35:00], save_register[27:00]}; 
                        4'b0110: register <= {12'h000, c_11, save_register[07:00]};
                        4'b0111: register <= {c_11[11:00], register[51:00]};
                        4'b1000: register <= {c_11[31:00], save_register[31:00]}; 
                        4'b1001: register <= {8'h00, c_11, save_register[11:00]};
                        4'b1010: register <= {c_11[07:00], register[55:00]};
                        4'b1011: register <= {c_11[27:00], save_register[35:00]}; 
                        4'b1100: register <= {4'h0 , c_11, save_register[15:00]};
                        4'b1101: register <= {c_11[03:00], register[59:00]};
                        4'b1110: register <= {c_11[23:00], save_register[39:00]}; 
                        4'b1111: register <= {c_11, save_register[19:00]}; 
                    endcase
                end
                
                default:
                    case(state)
                        4'b0000: register <= {16'h0000, c_12};
                        4'b0001: register <= {c_12[15:00], register[47:00]}; // save register
                        4'b0010: register <= {c_12[31:00], save_register[31:00]};
                        4'b0011: register <= {c_12, save_register[15:00]};
                        default: register <= {16'h0000, c_12};
                    endcase
            endcase
        end
    end
    
    always @(posedge clk) begin
        if(!rst | !start_reg)                save_register <= 0;
        else begin
            case(b)
            4'b0001: 
                        save_register <= 64'h0000_0000_0000_0000;
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= 64'h0000_0000_0000_0000;
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= 64'h0000_0000_0000_0000;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= 64'h0000_0000_0000_0000; 
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= {48'h0000_0000_0000, c_05[19:04]};
                        4'b0100: save_register <= 64'h0000_0000_0000_0000;
                        4'b0101: save_register <= 64'h0000_0000_0000_0000;
                        4'b0110: save_register <= {52'h0_0000_0000_0000, c_05[19:08]};
                        4'b0111: save_register <= 64'h0000_0000_0000_0000;
                        4'b1000: save_register <= 64'h0000_0000_0000_0000;
                        4'b1001: save_register <= {56'h00_0000_0000_0000, c_05[19:12]};
                        4'b1010: save_register <= 64'h0000_0000_0000_0000;
                        4'b1011: save_register <= 64'h0000_0000_0000_0000;
                        4'b1100: save_register <= {60'h000_0000_0000, c_05[19:16]};
                        4'b1101: save_register <= 64'h0000_0000_0000_0000;
                        4'b1110: save_register <= 64'h0000_0000_0000_0000; 
                        4'b1111: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= {48'h0000_0000_0000, c_10[39:24]};
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= {32'h0000_0000, c_10[39:08]};
                        4'b0100: save_register <= {56'h00_0000_0000_0000, c_10[39:32]};
                        4'b0101: save_register <= 64'h0000_0000_0000_0000;
                        4'b0110: save_register <= {40'h00_0000_0000, c_10[39:16]};
                        4'b0111: save_register <= 64'h0000_0000_0000_0000;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= {40'h00_0000_0000, c_11[43:20]};
                        4'b0010: save_register <= {60'h000_0000_0000_0000, c_11[43:40]};
                        4'b0011: save_register <= 64'h0000_0000_0000_0000;
                        4'b0100: save_register <= {36'h0_0000_0000, c_11[43:16]};
                        4'b0101: save_register <= {56'h00_0000_0000_0000, c_11[43:36]};
                        4'b0110: save_register <= 64'h0000_0000_0000_0000;
                        4'b0111: save_register <= {32'h0000_0000, c_11[43:12]};
                        4'b1000: save_register <= {52'h0_0000_0000_0000, c_11[43:32]};
                        4'b1001: save_register <= 64'h0000_0000_0000_0000;
                        4'b1010: save_register <= {28'h000_0000, c_11[43:08]};
                        4'b1011: save_register <= {48'h0000_0000_0000, c_11[43:28]};
                        4'b1100: save_register <= 64'h0000_0000_0000_0000;
                        4'b1101: save_register <= {24'h00_0000, c_11[43:04]};
                        4'b1110: save_register <= {44'h000_0000_0000, c_11[43:24]};
                        4'b1111: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
                
                default:
                    case(state)
                        4'b0000: save_register <= 0;
                        4'b0001: save_register <= {32'h0000_0000, c_12[47:16]}; // save register
                        4'b0010: save_register <= {48'h0000_0000_0000, c_12[47:32]};
                        4'b0011: save_register <= 0;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
            endcase
        end
    end

    always @(posedge clk) begin
        if(!rst | !start | !start_reg | !start_reg_0) d_valid <= 1'b0;
        else begin
            case(b)
            4'b0001: 
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b0;
                        4'b0100: d_valid <= 1'b0;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b0;
                        4'b0111: d_valid <= 1'b0;
                        4'b1000: d_valid <= 1'b0;
                        4'b1001: d_valid <= 1'b0;
                        4'b1010: d_valid <= 1'b0;
                        4'b1011: d_valid <= 1'b0;
                        4'b1100: d_valid <= 1'b0;
                        4'b1101: d_valid <= 1'b0;
                        4'b1110: d_valid <= 1'b0;
                        4'b1111: d_valid <= 1'b1;
                    endcase
                end
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        4'b0100: d_valid <= 1'b0;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b1;
                        4'b0111: d_valid <= 1'b0;
                        4'b1000: d_valid <= 1'b0;
                        4'b1001: d_valid <= 1'b1;
                        4'b1010: d_valid <= 1'b0;
                        4'b1011: d_valid <= 1'b0;
                        4'b1100: d_valid <= 1'b1;
                        4'b1101: d_valid <= 1'b0;
                        4'b1110: d_valid <= 1'b0;
                        4'b1111: d_valid <= 1'b1;
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        4'b0100: d_valid <= 1'b1;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b1;
                        4'b0111: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1;
                        4'b0010: d_valid <= 1'b1;
                        4'b0011: d_valid <= 1'b0;
                        4'b0100: d_valid <= 1'b1;
                        4'b0101: d_valid <= 1'b1;
                        4'b0110: d_valid <= 1'b0;
                        4'b0111: d_valid <= 1'b1;
                        4'b1000: d_valid <= 1'b1;
                        4'b1001: d_valid <= 1'b0;
                        4'b1010: d_valid <= 1'b1;
                        4'b1011: d_valid <= 1'b1;
                        4'b1100: d_valid <= 1'b0;
                        4'b1101: d_valid <= 1'b1;
                        4'b1110: d_valid <= 1'b1;
                        4'b1111: d_valid <= 1'b1;
                    endcase      
                end
                
                default:
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1; // save register
                        4'b0010: d_valid <= 1'b1;
                        4'b0011: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
            endcase
        end
    end
    
    reg [3:0] state_0;
    reg [3:0] state_1;
    reg [3:0] state_2;
    // new pipeline
    reg [3:0] state_3;
    reg [3:0] state_4;
    reg [3:0] state_5;
    
    always @(posedge clk) begin
        if(!rst | !start_reg)                               state_0 <= 4'b0000;
        // if(!rst | !start)                                   state_0 <= 4'b0000;
        else begin
                    if(b == 4'b0001 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 1
            else    if(b == 4'b0100 & state_0 == 4'b0011)   state_0 <= 4'b0000; // b = 4
            else    if(b == 4'b0101 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 5
            else    if(b == 4'b1010 & state_0 == 4'b0111)   state_0 <= 4'b0000; // b = 10
            else    if(b == 4'b1011 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 11
            else    if(b == 4'b1100 & state_0 == 4'b0011)   state_0 <= 4'b0000; // b = 12
            else    if(b == 4'b0000 & state_0 == 4'b0011)   state_0 <= 4'b0000;
            else                                            state_0 <= state_0 + 1;
        end                
    end
    
    always @(posedge clk) begin
        if(!start_reg)  state_1 <= 0;
        // if(!start)      state_1 <= 0;
        else            state_1 <= state_0;
        
        if(!start_reg)  state_2 <= 0;
        // if(!start)      state_2 <= 0;
        else            state_2 <= state_1;
        
        if(!start_reg)  state_3 <= 0;
        // if(!start)      state_3 <= 0;
        else            state_3 <= state_2;
        
        if(!start_reg)  state_4 <= 0;
        // if(!start)      state_4 <= 0;
        else            state_4 <= state_3;
        
        if(!start_reg)  state_5 <= 0;
        // if(!start)      state_5 <= 0;
        else            state_5 <= state_4;
        
        if(!start_reg)  state <= 0;
        // if(!start)      state <= 0;
        else            state <= state_4;
         
    end 
endmodule

module ENCODER_COMPRESS_MASKED_N_BU_4_CLK (
    input                           clk,
    input                           rst,
    input                           start,
    input           [15:0]          mode, 
    input           [16*24-1:0]     input_data,
    output  reg                     d_valid,
    output          [63:0]          out_data
    );
    
    wire [7:0] mode_encoder;
    wire [7:0] mode_compress;
    
    assign mode_encoder     = mode[07:00];
    assign mode_compress    = mode[15:08];
    
    reg [7:0] mode_reg;
    reg [7:0] mode_reg_1, mode_reg_2;
    always @(posedge clk) mode_reg   <= mode_encoder;
    always @(posedge clk) mode_reg_1 <= mode_reg;
    always @(posedge clk) mode_reg_2 <= mode_reg_1;
    
    reg start_reg_1, start_reg_0, start_reg;
    always @(posedge clk) start_reg_0   <= start; // to sync
    always @(posedge clk) start_reg_1   <= start_reg_0; // to sync
    always @(posedge clk) start_reg     <= start_reg_1; // to sync
    
    reg [47:00] input_register;

    wire [47:0] data_0_0 = input_data[(02*24)-1:(00*24)];
    wire [47:0] data_1_0 = input_data[(04*24)-1:(02*24)];
    wire [47:0] data_0_1 = input_data[(06*24)-1:(04*24)];
    wire [47:0] data_1_1 = input_data[(08*24)-1:(06*24)];
    wire [47:0] data_0_2 = input_data[(10*24)-1:(08*24)];
    wire [47:0] data_1_2 = input_data[(12*24)-1:(10*24)];
    wire [47:0] data_0_3 = input_data[(14*24)-1:(12*24)];
    wire [47:0] data_1_3 = input_data[(16*24)-1:(14*24)];

    wire case_0 = ~mode_reg_2[1] & mode_reg_2[0]; //01
    wire case_1 =  mode_reg_2[1] & mode_reg_2[0]; //11

    
    wire [11:00] data_0_a; reg [11:0] data_0_a_clk; always @(posedge clk) data_0_a_clk <= data_0_a;
    wire [11:00] data_0_b; reg [11:0] data_0_b_clk; always @(posedge clk) data_0_b_clk <= data_0_b;
    mod_add mod_add_0_a (.a(data_0_0[11:00]), .b(data_0_1[11:00]), .c(data_0_a));
    mod_add mod_add_0_b (.a(data_0_2[11:00]), .b(data_0_3[11:00]), .c(data_0_b));
    wire [11:00] data_0_c; reg [11:0] data_0_c_clk; always @(posedge clk) data_0_c_clk <= data_0_c;
    wire [11:00] data_0_d; reg [11:0] data_0_d_clk; always @(posedge clk) data_0_d_clk <= data_0_d;
    mod_add mod_add_0_c (.a(data_0_0[23:12]), .b(data_0_1[23:12]), .c(data_0_c));
    mod_add mod_add_0_d (.a(data_0_2[23:12]), .b(data_0_3[23:12]), .c(data_0_d));
    wire [11:00] data_0_e; reg [11:0] data_0_e_clk; always @(posedge clk) data_0_e_clk <= data_0_e;
    wire [11:00] data_0_f; reg [11:0] data_0_f_clk; always @(posedge clk) data_0_f_clk <= data_0_f;
    mod_add mod_add_0_e (.a(data_0_0[35:24]), .b(data_0_1[35:24]), .c(data_0_e));
    mod_add mod_add_0_f (.a(data_0_2[35:24]), .b(data_0_3[35:24]), .c(data_0_f));
    wire [11:00] data_0_g; reg [11:0] data_0_g_clk; always @(posedge clk) data_0_g_clk <= data_0_g;
    wire [11:00] data_0_h; reg [11:0] data_0_h_clk; always @(posedge clk) data_0_h_clk <= data_0_h;
    mod_add mod_add_0_g (.a(data_0_0[47:36]), .b(data_0_1[47:36]), .c(data_0_g));
    mod_add mod_add_0_h (.a(data_0_2[47:36]), .b(data_0_3[47:36]), .c(data_0_h));

    wire [11:00] data_1_a;  reg [11:0] data_1_a_clk; always @(posedge clk) data_1_a_clk <= data_1_a;
    wire [11:00] data_1_b;  reg [11:0] data_1_b_clk; always @(posedge clk) data_1_b_clk <= data_1_b;
    mod_add mod_add_1_a (.a(data_1_0[11:00]), .b(data_1_1[11:00]), .c(data_1_a));
    mod_add mod_add_1_b (.a(data_1_2[11:00]), .b(data_1_3[11:00]), .c(data_1_b));
    wire [11:00] data_1_c; reg [11:0] data_1_c_clk; always @(posedge clk) data_1_c_clk <= data_1_c;
    wire [11:00] data_1_d; reg [11:0] data_1_d_clk; always @(posedge clk) data_1_d_clk <= data_1_d;
    mod_add mod_add_1_c (.a(data_1_0[23:12]), .b(data_1_1[23:12]), .c(data_1_c));
    mod_add mod_add_1_d (.a(data_1_2[23:12]), .b(data_1_3[23:12]), .c(data_1_d));
    wire [11:00] data_1_e; reg [11:0] data_1_e_clk; always @(posedge clk) data_1_e_clk <= data_1_e;
    wire [11:00] data_1_f; reg [11:0] data_1_f_clk; always @(posedge clk) data_1_f_clk <= data_1_f;
    mod_add mod_add_1_e (.a(data_1_0[35:24]), .b(data_1_1[35:24]), .c(data_1_e));
    mod_add mod_add_1_f (.a(data_1_2[35:24]), .b(data_1_3[35:24]), .c(data_1_f));
    wire [11:00] data_1_g; reg [11:0] data_1_g_clk; always @(posedge clk) data_1_g_clk <= data_1_g;
    wire [11:00] data_1_h; reg [11:0] data_1_h_clk; always @(posedge clk) data_1_h_clk <= data_1_h;
    mod_add mod_add_1_g (.a(data_1_0[47:36]), .b(data_1_1[47:36]), .c(data_1_g));
    mod_add mod_add_1_h (.a(data_1_2[47:36]), .b(data_1_3[47:36]), .c(data_1_h));

    wire [11:0] in_0_0;
    wire [11:0] in_0_1;
    wire [11:0] in_0_2;
    wire [11:0] in_0_3;
    mod_add mod_add_0_0 (.a(data_0_a_clk), .b(data_0_b_clk), .c(in_0_0));
    mod_add mod_add_0_1 (.a(data_0_c_clk), .b(data_0_d_clk), .c(in_0_1));
    mod_add mod_add_0_2 (.a(data_0_e_clk), .b(data_0_f_clk), .c(in_0_2));
    mod_add mod_add_0_3 (.a(data_0_g_clk), .b(data_0_h_clk), .c(in_0_3));

    wire [11:0] in_1_0;
    wire [11:0] in_1_1;
    wire [11:0] in_1_2;
    wire [11:0] in_1_3;
    mod_add mod_add_1_0 (.a(data_1_a_clk), .b(data_1_b_clk), .c(in_1_0));
    mod_add mod_add_1_1 (.a(data_1_c_clk), .b(data_1_d_clk), .c(in_1_1));
    mod_add mod_add_1_2 (.a(data_1_e_clk), .b(data_1_f_clk), .c(in_1_2));
    mod_add mod_add_1_3 (.a(data_1_g_clk), .b(data_1_h_clk), .c(in_1_3));

    /*
    wire [11:0] in_0_0_p;
    wire [11:0] in_0_1_p;
    wire [11:0] in_0_2_p;
    wire [11:0] in_0_3_p;

    assign in_0_0_p = data_0_0[11:00] ^ data_0_1[11:00] ^ data_0_2[11:00] ^ data_0_3[11:00];
    assign in_0_1_p = data_0_0[23:12] ^ data_0_1[23:12] ^ data_0_2[23:12] ^ data_0_3[23:12];
    assign in_0_2_p = data_0_0[35:24] ^ data_0_1[35:24] ^ data_0_2[35:24] ^ data_0_3[35:24];
    assign in_0_3_p = data_0_0[47:36] ^ data_0_1[47:36] ^ data_0_2[47:36] ^ data_0_3[47:36];

    wire [11:0] in_1_0_p;
    wire [11:0] in_1_1_p;
    wire [11:0] in_1_2_p;
    wire [11:0] in_1_3_p;

    assign in_1_0_p = data_1_0[11:00] ^ data_1_1[11:00] ^ data_1_2[11:00] ^ data_1_3[11:00];
    assign in_1_1_p = data_1_0[23:12] ^ data_1_1[23:12] ^ data_1_2[23:12] ^ data_1_3[23:12];
    assign in_1_2_p = data_1_0[35:24] ^ data_1_1[35:24] ^ data_1_2[35:24] ^ data_1_3[35:24];
    assign in_1_3_p = data_1_0[47:36] ^ data_1_1[47:36] ^ data_1_2[47:36] ^ data_1_3[47:36];

    localparam Q = 3329;

    wire [11:0] in_0_0;
    wire [11:0] in_0_1;
    wire [11:0] in_0_2;
    wire [11:0] in_0_3;

    assign in_0_0 = (in_0_0_p < Q) ? in_0_0_p : in_0_0_p - Q;
    assign in_0_1 = (in_0_1_p < Q) ? in_0_1_p : in_0_1_p - Q;
    assign in_0_2 = (in_0_2_p < Q) ? in_0_2_p : in_0_2_p - Q;
    assign in_0_3 = (in_0_3_p < Q) ? in_0_3_p : in_0_3_p - Q;

    wire [11:0] in_1_0;
    wire [11:0] in_1_1;
    wire [11:0] in_1_2;
    wire [11:0] in_1_3;

    assign in_1_0 = (in_1_0_p < Q) ? in_1_0_p : in_1_0_p - Q;
    assign in_1_1 = (in_1_1_p < Q) ? in_1_1_p : in_1_1_p - Q;
    assign in_1_2 = (in_1_2_p < Q) ? in_1_2_p : in_1_2_p - Q;
    assign in_1_3 = (in_1_3_p < Q) ? in_1_3_p : in_1_3_p - Q;
    */

    always @(posedge clk) begin
        if(case_0)  input_register <= {in_0_3, in_0_2, in_0_1, in_0_0};
        else        input_register <= {in_1_3, in_1_2, in_1_1, in_1_0};
    end
    
    
    // --- COMPRESS MODULES --- //
    
    wire [3:0] b;
    assign b = mode_compress[3:0];
    
    wire [11:0] c_0, c_1, c_2, c_3;
    COMPRESS COMPRESS_0 (.clk(clk), .b(b), .x(input_register[11:00]), .o(c_0));
    COMPRESS COMPRESS_1 (.clk(clk), .b(b), .x(input_register[23:12]), .o(c_1));
    COMPRESS COMPRESS_2 (.clk(clk), .b(b), .x(input_register[35:24]), .o(c_2));
    COMPRESS COMPRESS_3 (.clk(clk), .b(b), .x(input_register[47:36]), .o(c_3));
    
    wire [10:0] c_11_0, c_11_1, c_11_2, c_11_3;
    wire [09:0] c_10_0, c_10_1, c_10_2, c_10_3;
    wire [04:0] c_05_0, c_05_1, c_05_2, c_05_3;
    wire [03:0] c_04_0, c_04_1, c_04_2, c_04_3;
    wire        c_01_0, c_01_1, c_01_2, c_01_3;
    
    assign c_11_0 = c_0[10:00];
    assign c_11_1 = c_1[10:00];
    assign c_11_2 = c_2[10:00];
    assign c_11_3 = c_3[10:00];
    
    assign c_10_0 = c_0[09:00];
    assign c_10_1 = c_1[09:00];
    assign c_10_2 = c_2[09:00];
    assign c_10_3 = c_3[09:00];
    
    assign c_05_0 = c_0[04:00];
    assign c_05_1 = c_1[04:00];
    assign c_05_2 = c_2[04:00];
    assign c_05_3 = c_3[04:00];
    
    assign c_04_0 = c_0[03:00];
    assign c_04_1 = c_1[03:00];
    assign c_04_2 = c_2[03:00];
    assign c_04_3 = c_3[03:00];
    
    assign c_01_0 = c_0[0];
    assign c_01_1 = c_1[0];
    assign c_01_2 = c_2[0];
    assign c_01_3 = c_3[0];
    
    wire [11*4-1:0] c_11;
    wire [10*4-1:0] c_10;
    wire [05*4-1:0] c_05;
    wire [04*4-1:0] c_04;
    wire [3:0]      c_01;
    assign c_11 = {c_11_3, c_11_2, c_11_1, c_11_0};
    assign c_10 = {c_10_3, c_10_2, c_10_1, c_10_0};
    assign c_05 = {c_05_3, c_05_2, c_05_1, c_05_0};
    assign c_04 = {c_04_3, c_04_2, c_04_1, c_04_0};
    assign c_01 = {c_01_3, c_01_2, c_01_1, c_01_0};
    
    reg [12*4-1:0] c_12_0;
    reg [12*4-1:0] c_12_1;
    reg [12*4-1:0] c_12_2;
    reg [12*4-1:0] c_12_3;
    reg [12*4-1:0] c_12_4;
    wire [12*4-1:0] c_12;
    always @(posedge clk) begin
        c_12_0 <= input_register;
        c_12_1 <= c_12_0;
        c_12_2 <= c_12_1;
        c_12_3 <= c_12_2;
        c_12_4 <= c_12_3;
    end
    assign c_12 = c_12_3;
    
    reg [3:0] state;
    // ----
    // mode_encoder = 4'b0000 (0)
    // 0 : 48
    // 1 : dvalid, rest 32
    // 2 : dvalid, rest 16
    // 3 : dvalid, rest 0
    // ----
    // mode_encoder = 4'b0100 (4)
    // 0 : 16
    // 1 : 32
    // 2 : 48
    // 3 : dvalid, 64
    // ----
    // mode_encoder = 4'b0101 (5)
    // 0 : 20
    // 1 : 40
    // 2 : 60
    // 3 : 64  dvalid,  rest 16
    // 4 : 20,          rest 16
    // 5 : 40,          rest 16 
    // 6 : 64, dvalid   rest 12
    // 7 : 20,          rest 12
    // 8 : 40,          rest 12 
    // 9 : 64, dvalid   rest 8
    // 10 : 20,          rest 8
    // 11 : 40,          rest 8 
    // 12 : 64, dvalid   rest 4
    // 13 : 20,          rest 4
    // 14 : 40,          rest 4 
    // 15 : 64, dvalid   rest 0
    // ----
    // mode_encoder = 4'b1010 (10)
    // 0 : 40
    // 1 : 64       dvalid      rest 16
    // 2 : 40                   rest 16
    // 3 : 64       dvalid,     rest 32
    // 4 : (40) 64  dvalid,     rest 8
    // 5 : 40                   rest 8
    // 6 : 64       dvalid,     rest 24
    // 7 : (40) 64  dvalid,     rest 0
    // ----
    // mode_encoder = 4'b1011 (11)
    // 0 : 44
    // 1 : 64       dvalid      rest 24
    // 2 : (44) 64  dvalid      rest 4
    // 3 : 44                   rest 4
    // 4 : 64       dvalid,     rest 28
    // 5 : (44) 64  dvalid      rest 8
    // 6 : 44                   rest 8
    // 7 : 64       dvalid,     rest 32
    // 8 : (44) 64  dvalid      rest 12
    // 9 : 44                   rest 12
    //10 : 64       dvalid,     rest 36
    //11 : (44) 64  dvalid      rest 16
    //12 : 44                   rest 16
    //13 : 64       dvalid,     rest 40
    //14 : (44) 64  dvalid      rest 20
    //15 : (44) 64  dvalid      rest 0
       
    reg [63:0] register;
    reg [63:0] save_register;
    assign out_data = register;
    
    always @(posedge clk) begin
        if(!rst | !start_reg)            register <= 0;
        else begin
            case(b)
            4'b0001: 
                // mode_encoder = 4'b0001 (4)
                // 0 : 4
                // 1 : 8
                // 2 : 12
                // 3 : 16
                // 4 : 20
                // 5 : 24
                // 6 : 28
                // 7 : 32
                // 8 : 36
                // 9 : 40
                // 10 : 44
                // 11 : 48
                // 12 : 52
                // 13 : 56
                // 14 : 60
                // 15 : dvalid, 64
                begin
                    case(state)
                        4'b0000: register <= {60'h000_0000_0000_0000, c_01};
                        4'b0001: register <= {56'h00_0000_0000_0000, c_01, register[03:00]}; 
                        4'b0010: register <= {52'h0_0000_0000_0000, c_01, register[07:00]};
                        4'b0011: register <= {48'h0000_0000_0000, c_01, register[11:00]};
                        4'b0100: register <= {44'h000_0000_0000, c_01, register[15:00]};
                        4'b0101: register <= {40'h00_0000_0000, c_01, register[19:00]}; 
                        4'b0110: register <= {36'h0_0000_0000, c_01, register[23:00]}; 
                        4'b0111: register <= {32'h0000_0000, c_01, register[27:00]}; 
                        4'b1000: register <= {28'h000_0000, c_01, register[31:00]}; 
                        4'b1001: register <= {24'h00_0000, c_01, register[35:00]}; 
                        4'b1010: register <= {20'h0_0000, c_01, register[39:00]};
                        4'b1011: register <= {16'h0000, c_01, register[43:00]};
                        4'b1100: register <= {12'h000, c_01, register[47:00]};
                        4'b1101: register <= {8'h00, c_01, register[51:00]}; 
                        4'b1110: register <= {4'h0, c_01, register[55:00]}; 
                        4'b1111: register <= {c_01, register[59:00]}; 
                        default: register <= {60'h000_0000_0000_0000, c_01};
                    endcase
                end
            
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: register <= {48'h0000_0000_0000, c_04};
                        4'b0001: register <= {32'h0000_0000, c_04, register[15:00]}; 
                        4'b0010: register <= {16'h0000, c_04, register[31:00]};
                        4'b0011: register <= {c_04, register[47:00]};
                        default: register <= {48'h0000_0000_0000, c_04};
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: register <= {44'h000_0000_0000, c_05};
                        4'b0001: register <= {24'h00_0000, c_05, register[19:00]}; 
                        4'b0010: register <= {4'h0, c_05, register[39:00]};
                        4'b0011: register <= {c_05[03:00], register[59:00]};
                        4'b0100: register <= {28'h000_0000, c_05, save_register[15:00]};
                        4'b0101: register <= {8'h00, c_05, register[35:00]}; 
                        4'b0110: register <= {c_05[07:00], register[55:00]};
                        4'b0111: register <= {32'h0000_0000, c_05, save_register[11:00]};
                        4'b1000: register <= {12'h000, c_05, register[31:00]}; 
                        4'b1001: register <= {c_05[11:00], register[51:00]};
                        4'b1010: register <= {36'h0000_0000, c_05, save_register[07:00]};
                        4'b1011: register <= {16'h0000, c_05, register[27:00]}; 
                        4'b1100: register <= {c_05[15:00], register[47:00]};
                        4'b1101: register <= {40'h0000_0000, c_05, save_register[03:00]};
                        4'b1110: register <= {20'h0000, c_05, register[23:00]}; 
                        4'b1111: register <= {c_05, register[43:00]};
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: register <= {24'h00_0000, c_10};
                        4'b0001: register <= {c_10[23:00], register[39:00]}; 
                        4'b0010: register <= {8'h00, c_10, save_register[15:00]};
                        4'b0011: register <= {c_10[07:00], register[55:00]};
                        4'b0100: register <= {c_10[31:00], save_register[31:00]};
                        4'b0101: register <= {16'h0000, c_10, save_register[07:00]}; 
                        4'b0110: register <= {c_10[15:00], register[47:00]};
                        4'b0111: register <= {c_10, save_register[23:00]};
                        default: register <= {24'h00_0000, c_10};
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: register <= {20'h0_0000, c_11};
                        4'b0001: register <= {c_11[19:00], register[43:00]}; 
                        4'b0010: register <= {c_11[39:00], save_register[23:00]};
                        4'b0011: register <= {16'h0000, c_11, save_register[03:00]};
                        4'b0100: register <= {c_11[15:00], register[47:00]};
                        4'b0101: register <= {c_11[35:00], save_register[27:00]}; 
                        4'b0110: register <= {12'h000, c_11, save_register[07:00]};
                        4'b0111: register <= {c_11[11:00], register[51:00]};
                        4'b1000: register <= {c_11[31:00], save_register[31:00]}; 
                        4'b1001: register <= {8'h00, c_11, save_register[11:00]};
                        4'b1010: register <= {c_11[07:00], register[55:00]};
                        4'b1011: register <= {c_11[27:00], save_register[35:00]}; 
                        4'b1100: register <= {4'h0 , c_11, save_register[15:00]};
                        4'b1101: register <= {c_11[03:00], register[59:00]};
                        4'b1110: register <= {c_11[23:00], save_register[39:00]}; 
                        4'b1111: register <= {c_11, save_register[19:00]}; 
                    endcase
                end
                
                default:
                    case(state)
                        4'b0000: register <= {16'h0000, c_12};
                        4'b0001: register <= {c_12[15:00], register[47:00]}; // save register
                        4'b0010: register <= {c_12[31:00], save_register[31:00]};
                        4'b0011: register <= {c_12, save_register[15:00]};
                        default: register <= {16'h0000, c_12};
                    endcase
            endcase
        end
    end
    
    always @(posedge clk) begin
        if(!rst | !start_reg)                save_register <= 0;
        else begin
            case(b)
            4'b0001: 
                        save_register <= 64'h0000_0000_0000_0000;
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= 64'h0000_0000_0000_0000;
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= 64'h0000_0000_0000_0000;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= 64'h0000_0000_0000_0000; 
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= {48'h0000_0000_0000, c_05[19:04]};
                        4'b0100: save_register <= 64'h0000_0000_0000_0000;
                        4'b0101: save_register <= 64'h0000_0000_0000_0000;
                        4'b0110: save_register <= {52'h0_0000_0000_0000, c_05[19:08]};
                        4'b0111: save_register <= 64'h0000_0000_0000_0000;
                        4'b1000: save_register <= 64'h0000_0000_0000_0000;
                        4'b1001: save_register <= {56'h00_0000_0000_0000, c_05[19:12]};
                        4'b1010: save_register <= 64'h0000_0000_0000_0000;
                        4'b1011: save_register <= 64'h0000_0000_0000_0000;
                        4'b1100: save_register <= {60'h000_0000_0000, c_05[19:16]};
                        4'b1101: save_register <= 64'h0000_0000_0000_0000;
                        4'b1110: save_register <= 64'h0000_0000_0000_0000; 
                        4'b1111: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= {48'h0000_0000_0000, c_10[39:24]};
                        4'b0010: save_register <= 64'h0000_0000_0000_0000;
                        4'b0011: save_register <= {32'h0000_0000, c_10[39:08]};
                        4'b0100: save_register <= {56'h00_0000_0000_0000, c_10[39:32]};
                        4'b0101: save_register <= 64'h0000_0000_0000_0000;
                        4'b0110: save_register <= {40'h00_0000_0000, c_10[39:16]};
                        4'b0111: save_register <= 64'h0000_0000_0000_0000;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: save_register <= 64'h0000_0000_0000_0000;
                        4'b0001: save_register <= {40'h00_0000_0000, c_11[43:20]};
                        4'b0010: save_register <= {60'h000_0000_0000_0000, c_11[43:40]};
                        4'b0011: save_register <= 64'h0000_0000_0000_0000;
                        4'b0100: save_register <= {36'h0_0000_0000, c_11[43:16]};
                        4'b0101: save_register <= {56'h00_0000_0000_0000, c_11[43:36]};
                        4'b0110: save_register <= 64'h0000_0000_0000_0000;
                        4'b0111: save_register <= {32'h0000_0000, c_11[43:12]};
                        4'b1000: save_register <= {52'h0_0000_0000_0000, c_11[43:32]};
                        4'b1001: save_register <= 64'h0000_0000_0000_0000;
                        4'b1010: save_register <= {28'h000_0000, c_11[43:08]};
                        4'b1011: save_register <= {48'h0000_0000_0000, c_11[43:28]};
                        4'b1100: save_register <= 64'h0000_0000_0000_0000;
                        4'b1101: save_register <= {24'h00_0000, c_11[43:04]};
                        4'b1110: save_register <= {44'h000_0000_0000, c_11[43:24]};
                        4'b1111: save_register <= 64'h0000_0000_0000_0000;
                    endcase
                end
                
                default:
                    case(state)
                        4'b0000: save_register <= 0;
                        4'b0001: save_register <= {32'h0000_0000, c_12[47:16]}; // save register
                        4'b0010: save_register <= {48'h0000_0000_0000, c_12[47:32]};
                        4'b0011: save_register <= 0;
                        default: save_register <= 64'h0000_0000_0000_0000;
                    endcase
            endcase
        end
    end

    always @(posedge clk) begin
        if(!rst | !start | !start_reg | !start_reg_0  | !start_reg_1) d_valid <= 1'b0;
        else begin
            case(b)
            4'b0001: 
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b0;
                        4'b0100: d_valid <= 1'b0;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b0;
                        4'b0111: d_valid <= 1'b0;
                        4'b1000: d_valid <= 1'b0;
                        4'b1001: d_valid <= 1'b0;
                        4'b1010: d_valid <= 1'b0;
                        4'b1011: d_valid <= 1'b0;
                        4'b1100: d_valid <= 1'b0;
                        4'b1101: d_valid <= 1'b0;
                        4'b1110: d_valid <= 1'b0;
                        4'b1111: d_valid <= 1'b1;
                    endcase
                end
            4'b0100: 
                // mode_encoder = 4'b0100 (4)
                // 0 : 16
                // 1 : 32
                // 2 : 48
                // 3 : dvalid, 64
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
                end
            4'b0101: 
                // mode_encoder = 4'b0101 (5)
                // 0 : 20
                // 1 : 40
                // 2 : 60
                // 3 : 64  dvalid,  rest 16
                // 4 : 36,          rest 0
                // 5 : 56,          rest 0 
                // 6 : 64, dvalid   rest 12
                // 7 : 32,          rest 0
                // 8 : 52,          rest 0 
                // 9 : 64, dvalid   rest 8
                // 10 : 28,          rest 0
                // 11 : 48,          rest 0 
                // 12 : 64, dvalid   rest 4
                // 13 : 24,          rest 0
                // 14 : 44,          rest 0 
                // 15 : 64, dvalid   rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b0;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        4'b0100: d_valid <= 1'b0;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b1;
                        4'b0111: d_valid <= 1'b0;
                        4'b1000: d_valid <= 1'b0;
                        4'b1001: d_valid <= 1'b1;
                        4'b1010: d_valid <= 1'b0;
                        4'b1011: d_valid <= 1'b0;
                        4'b1100: d_valid <= 1'b1;
                        4'b1101: d_valid <= 1'b0;
                        4'b1110: d_valid <= 1'b0;
                        4'b1111: d_valid <= 1'b1;
                    endcase
                end
            4'b1010: 
                // mode_encoder = 4'b1010 (10)
                // 0 : 40
                // 1 : 64       dvalid      rest 16
                // 2 : 56                   rest 0
                // 3 : 64       dvalid,     rest 32
                // 4 : (40) 64  dvalid,     rest 8
                // 5 : 48                   rest 0
                // 6 : 64       dvalid,     rest 24
                // 7 : (40) 64  dvalid,     rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1;
                        4'b0010: d_valid <= 1'b0;
                        4'b0011: d_valid <= 1'b1;
                        4'b0100: d_valid <= 1'b1;
                        4'b0101: d_valid <= 1'b0;
                        4'b0110: d_valid <= 1'b1;
                        4'b0111: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
                end
                
            4'b1011: 
                // mode_encoder = 4'b1011 (11)
                // 0 : 44
                // 1 : 64       dvalid      rest 24
                // 2 : (44) 64  dvalid      rest 4
                // 3 : 48                   rest 0
                // 4 : 64       dvalid,     rest 28
                // 5 : (44) 64  dvalid      rest 8
                // 6 : 52                   rest 0
                // 7 : 64       dvalid,     rest 32
                // 8 : (44) 64  dvalid      rest 12
                // 9 : 56                   rest 0
                //10 : 64       dvalid,     rest 36
                //11 : (44) 64  dvalid      rest 16
                //12 : 60                   rest 0
                //13 : 64       dvalid,     rest 40
                //14 : (44) 64  dvalid      rest 20
                //15 : (44) 64  dvalid      rest 0
                begin
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1;
                        4'b0010: d_valid <= 1'b1;
                        4'b0011: d_valid <= 1'b0;
                        4'b0100: d_valid <= 1'b1;
                        4'b0101: d_valid <= 1'b1;
                        4'b0110: d_valid <= 1'b0;
                        4'b0111: d_valid <= 1'b1;
                        4'b1000: d_valid <= 1'b1;
                        4'b1001: d_valid <= 1'b0;
                        4'b1010: d_valid <= 1'b1;
                        4'b1011: d_valid <= 1'b1;
                        4'b1100: d_valid <= 1'b0;
                        4'b1101: d_valid <= 1'b1;
                        4'b1110: d_valid <= 1'b1;
                        4'b1111: d_valid <= 1'b1;
                    endcase      
                end
                
                default:
                    case(state)
                        4'b0000: d_valid <= 1'b0;
                        4'b0001: d_valid <= 1'b1; // save register
                        4'b0010: d_valid <= 1'b1;
                        4'b0011: d_valid <= 1'b1;
                        default: d_valid <= 1'b0;
                    endcase
            endcase
        end
    end
    
    reg [3:0] state_0;
    reg [3:0] state_1;
    reg [3:0] state_2;
    // new pipeline
    reg [3:0] state_3;
    reg [3:0] state_4;
    reg [3:0] state_5;
    
    always @(posedge clk) begin
        if(!rst | !start_reg)                               state_0 <= 4'b0000;
        // if(!rst | !start)                                   state_0 <= 4'b0000;
        else begin
                    if(b == 4'b0001 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 1
            else    if(b == 4'b0100 & state_0 == 4'b0011)   state_0 <= 4'b0000; // b = 4
            else    if(b == 4'b0101 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 5
            else    if(b == 4'b1010 & state_0 == 4'b0111)   state_0 <= 4'b0000; // b = 10
            else    if(b == 4'b1011 & state_0 == 4'b1111)   state_0 <= 4'b0000; // b = 11
            else    if(b == 4'b1100 & state_0 == 4'b0011)   state_0 <= 4'b0000; // b = 12
            else    if(b == 4'b0000 & state_0 == 4'b0011)   state_0 <= 4'b0000;
            else                                            state_0 <= state_0 + 1;
        end                
    end
    
    always @(posedge clk) begin
        if(!start_reg)  state_1 <= 0;
        // if(!start)      state_1 <= 0;
        else            state_1 <= state_0;
        
        if(!start_reg)  state_2 <= 0;
        // if(!start)      state_2 <= 0;
        else            state_2 <= state_1;
        
        if(!start_reg)  state_3 <= 0;
        // if(!start)      state_3 <= 0;
        else            state_3 <= state_2;
        
        if(!start_reg)  state_4 <= 0;
        // if(!start)      state_4 <= 0;
        else            state_4 <= state_3;
        
        if(!start_reg)  state_5 <= 0;
        // if(!start)      state_5 <= 0;
        else            state_5 <= state_4;
        
        if(!start_reg)  state <= 0;
        // if(!start)      state <= 0;
        else            state <= state_4;
         
    end 
endmodule