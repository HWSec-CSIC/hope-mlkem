`timescale 1ns / 1ps

module REJ_UNIFORM #(
    parameter Q = 3329
    )(
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           selw,
    input [1343:0]  in_shake,
    output          end_op,
    output          end_read,
    input   [3:0]   off_r0,
    input   [3:0]   off_r1,
    input   [9:0]   ar_1_0,
    input   [9:0]   ar_1_1,
    input   [9:0]   ar_2_0,
    input   [9:0]   ar_2_1,
    input   [9:0]   ar_3_0,
    input   [9:0]   ar_3_1,
    input   [9:0]   ar_4_0,
    input   [9:0]   ar_4_1,
    output [23:0]   do_1_0,
    output [23:0]   do_1_1,
    output [23:0]   do_2_0,
    output [23:0]   do_2_1,
    output [23:0]   do_3_0,
    output [23:0]   do_3_1,
    output [23:0]   do_4_0,
    output [23:0]   do_4_1
    );
    
    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load) counter_shake <= 0;
        else begin
            if(start)   counter_shake <= counter_shake + 4;
            else        counter_shake <= counter_shake;
        end
    end
    
    reg [1343:0] reg_shake;
    always @(posedge clk) begin
        if(!rst) reg_shake <= 0;
        else begin
            if(load)                            reg_shake <= in_shake;                 
            else if(start & !end_op)            reg_shake <= reg_shake >> 48;
            else                                reg_shake <= reg_shake;
        end
    end
    
    wire [11:0] d0;
    assign d0 = reg_shake[11:00];
    wire [11:0] d1;
    assign d1 = reg_shake[23:12];
    wire [11:0] d2;
    assign d2 = reg_shake[35:24];
    wire [11:0] d3;
    assign d3 = reg_shake[47:36];
    
    wire en_w0;
    assign en_w0 = (d0 < Q) ? 1 : 0;
    wire en_w1;
    assign en_w1 = (d1 < Q) ? 1 : 0;
    wire en_w2;
    assign en_w2 = (d2 < Q) ? 1 : 0;
    wire en_w3;
    assign en_w3 = (d3 < Q) ? 1 : 0;
    
    reg [47:00] in_ram;
    
    wire [47:00] d0_d;
    wire [47:00] d1_d;
    wire [47:00] d2_d;
    wire [47:00] d3_d;
    
    wire en_d0_d_0;
    wire en_d1_d_0;
    wire en_d1_d_1;
    wire en_d2_d_0;
    wire en_d2_d_1;
    wire en_d2_d_2;
    wire en_d3_d_0;
    wire en_d3_d_1;
    wire en_d3_d_2;
    wire en_d3_d_3;
    
    assign en_d0_d_0 = en_w0;
    assign en_d1_d_0 = !en_w0 & en_w1;
    assign en_d1_d_1 =  en_w0 & en_w1;
    assign en_d2_d_0 = !en_w0 & !en_w1 & en_w2;
    assign en_d2_d_1 = (en_w0 ^ en_w1) & en_w2;
    assign en_d2_d_2 =  en_w0 & en_w1 & en_w2;
    assign en_d3_d_0 = !en_w0 & !en_w1 & !en_w2 & en_w3;
    assign en_d3_d_1 = ((!en_w0 & !en_w1 & en_w2) | (!en_w0 & en_w1 & !en_w2) | (en_w0 & !en_w1 & !en_w2)) & en_w3;
    assign en_d3_d_2 = ((!en_w0 &  en_w1 & en_w2) | ( en_w0 & en_w1 & !en_w2) | (en_w0 & !en_w1 &  en_w2)) & en_w3;
    assign en_d3_d_3 =  en_w0 & en_w1 & en_w2 & en_w3;
    
    assign d0_d = {36'h000_000_000, d0 & {12{en_d0_d_0}}};
    assign d1_d = {24'h000_000, d1 & {12{en_d1_d_1}}, d1 & {12{en_d1_d_0}}};
    assign d2_d = { 12'h000, 
                    d2 & {12{en_d2_d_2}}, 
                    d2 & {12{en_d2_d_1}},
                    d2 & {12{en_d2_d_0}}};
    assign d3_d = { d3 & {12{en_d3_d_3}}, 
                    d3 & {12{en_d3_d_2}}, 
                    d3 & {12{en_d3_d_1}},
                    d3 & {12{en_d3_d_0}}};
    
    wire [47:00] input_d;
    assign input_d = d3_d ^ d2_d ^ d1_d ^ d0_d;
    
    reg [47:00] save;
    
    reg [1:0] pos;
    
    always @* begin
        case(pos)
            2'b00: in_ram = input_d;
            2'b01: in_ram = {input_d[35:00], save[11:00]};
            2'b10: in_ram = {input_d[23:00], save[23:00]};
            2'b11: in_ram = {input_d[11:00], save[35:00]};
        endcase
    end
    
    wire [1:0] next_pos;
    
    wire [2:0] count; 
    assign count = (start) ? en_w3 + en_w2 + en_w1 + en_w0 : 3'b000;
    
    wire [2:0] sum;
    assign sum = pos + count;
    assign next_pos = sum[1:0];
    
    always @(posedge clk) begin
        if(!rst) save <= 0;
        else begin
            case(sum)
                3'b000: save <= save;
                3'b001: save <= in_ram;
                3'b010: save <= in_ram;
                3'b011: save <= in_ram;
                3'b100: save <= 0;
                3'b101: begin 
                            if(pos == 2'b01)        save <= {36'h000_0000_000, input_d[47:36]};   
                            else if(pos == 2'b11)   save <= {12'h000, input_d[47:12]};
                            else                    save <= {24'h000_000, input_d[47:24]};    
                        end 
                3'b110: begin
                            if(pos == 2'b11)    save <= {12'h000, input_d[47:12]};
                            else                save <= {24'h000_000, input_d[47:24]}; 
                        end
                3'b111: begin 
                            if(pos == 2'b11)    save <= {12'h000, input_d[47:12]};
                            else                save <= input_d;
                        end
            endcase
        end     
    end

    wire end_op_shake;
    reg end_op_wr;
    assign end_op   = end_op_wr;
    assign end_read = end_op_shake;
    
    assign end_op_shake = (load) ? 1'b0 : ((counter_shake == 108 | counter_shake == 112) ? 1'b1 : 1'b0);
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst | (end_op_wr))          ad_wr <= 0;
        else begin
            if(ad_wr == 63)             ad_wr <= ad_wr; // to avoid overflow
            else if(start & sum[2])     ad_wr <= ad_wr + 1;
            else                        ad_wr <= ad_wr;     
        end
    end
    
    always @(posedge clk) begin
        if(!rst | (end_op_wr & load))                   end_op_wr <= 0;
        else begin
            if(ad_wr == 63 & sum[2])                    end_op_wr <= 1;
            else                                        end_op_wr <= end_op_wr;
        end
    end

    always @(posedge clk) begin
        if(!rst | end_op_wr)    pos <= 0;
        else if(start)          pos <= next_pos;
        else                    pos <= pos;
    end
     
    // --- RAM 0 --- //
    wire            en_w_r0; 
    wire [9:0]      addr_1_0;
    wire [9:0]      addr_2_0;
    
    assign addr_1_0 = (start & !selw) ? ( ((ad_wr << 1) + 0) + (off_r0 << 7) ) : ar_1_0 ;
    assign addr_2_0 = (start & !selw) ? ( ((ad_wr << 1) + 1) + (off_r0 << 7) ) : ar_2_0 ;
    assign en_w_r0  = start & !selw & sum[2] & !end_op_wr;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_0 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r0         ),     
        .enable_2   (   en_w_r0         ), 
        .addr_1     (   addr_1_0        ),              
        .addr_2     (   addr_2_0        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_1_0          ),
        .data_out_2 (   do_2_0          )  
    );
    
    // --- RAM 1 --- // 
    wire [9:0]      addr_1_1;
    wire [9:0]      addr_2_1;
    
    assign addr_1_1 = (start & !selw) ? ( ((ad_wr << 1) + 0) + (off_r0 << 7) ) : ar_1_1 ;
    assign addr_2_1 = (start & !selw) ? ( ((ad_wr << 1) + 1) + (off_r0 << 7) ) : ar_2_1 ;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_1 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r0         ),     
        .enable_2   (   en_w_r0         ), 
        .addr_1     (   addr_1_1        ),              
        .addr_2     (   addr_2_1        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_1_1          ),
        .data_out_2 (   do_2_1          )  
    );
    
    // --- RAM 2 --- //
    wire            en_w_r1; 
    wire [9:0]      addr_3_0;
    wire [9:0]      addr_4_0;
    
    assign addr_3_0 = (start & selw) ? ( ((ad_wr << 1) + 0) + (off_r1 << 7) ) : ar_3_0 ;
    assign addr_4_0 = (start & selw) ? ( ((ad_wr << 1) + 1) + (off_r1 << 7) ) : ar_4_0 ;
    assign en_w_r1  = start & selw & sum[2] & !end_op_wr;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_2 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r1         ),     
        .enable_2   (   en_w_r1         ), 
        .addr_1     (   addr_3_0        ),              
        .addr_2     (   addr_4_0        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_3_0          ),
        .data_out_2 (   do_4_0          )  
    );
    
    // --- RAM 3 --- // 
    wire [9:0]      addr_3_1;
    wire [9:0]      addr_4_1;
    
    assign addr_3_1 = (start & selw) ? ( ((ad_wr << 1) + 0) + (off_r1 << 7) ) : ar_3_1 ;
    assign addr_4_1 = (start & selw) ? ( ((ad_wr << 1) + 1) + (off_r1 << 7) ) : ar_4_1 ;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_3 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r1         ),     
        .enable_2   (   en_w_r1         ), 
        .addr_1     (   addr_3_1        ),              
        .addr_2     (   addr_4_1        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_3_1          ),
        .data_out_2 (   do_4_1          )  
    );
    
endmodule

module REJ_UNIFORM_SHORT #(
    parameter Q = 3329
    )(
    input           clk,
    input           rst,
    input           load,
    input           start,
    input           selw,
    input [1343:0]  in_shake,
    output          end_op,
    output          end_read,
    input   [3:0]   off_r0,
    input   [3:0]   off_r1,
    input   [9:0]   ar_1_0,
    input   [9:0]   ar_2_0,
    input   [9:0]   ar_3_0,
    input   [9:0]   ar_4_0,
    output [23:0]   do_1_0,
    output [23:0]   do_2_0,
    output [23:0]   do_3_0,
    output [23:0]   do_4_0
    );
    
    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load) counter_shake <= 0;
        else begin
            if(start)   counter_shake <= counter_shake + 4;
            else        counter_shake <= counter_shake;
        end
    end
    
    reg [1343:0] reg_shake;
    always @(posedge clk) begin
        if(!rst) reg_shake <= 0;
        else begin
            if(load)                            reg_shake <= in_shake;                 
            else if(start & !end_op)            reg_shake <= reg_shake >> 48;
            else                                reg_shake <= reg_shake;
        end
    end
    
    wire [11:0] d0;
    assign d0 = reg_shake[11:00];
    wire [11:0] d1;
    assign d1 = reg_shake[23:12];
    wire [11:0] d2;
    assign d2 = reg_shake[35:24];
    wire [11:0] d3;
    assign d3 = reg_shake[47:36];
    
    wire en_w0;
    assign en_w0 = (d0 < Q) ? 1 : 0;
    wire en_w1;
    assign en_w1 = (d1 < Q) ? 1 : 0;
    wire en_w2;
    assign en_w2 = (d2 < Q) ? 1 : 0;
    wire en_w3;
    assign en_w3 = (d3 < Q) ? 1 : 0;
    
    reg [47:00] in_ram;
    
    wire [47:00] d0_d;
    wire [47:00] d1_d;
    wire [47:00] d2_d;
    wire [47:00] d3_d;
    
    wire en_d0_d_0;
    wire en_d1_d_0;
    wire en_d1_d_1;
    wire en_d2_d_0;
    wire en_d2_d_1;
    wire en_d2_d_2;
    wire en_d3_d_0;
    wire en_d3_d_1;
    wire en_d3_d_2;
    wire en_d3_d_3;
    
    assign en_d0_d_0 = en_w0;
    assign en_d1_d_0 = !en_w0 & en_w1;
    assign en_d1_d_1 =  en_w0 & en_w1;
    assign en_d2_d_0 = !en_w0 & !en_w1 & en_w2;
    assign en_d2_d_1 = (en_w0 ^ en_w1) & en_w2;
    assign en_d2_d_2 =  en_w0 & en_w1 & en_w2;
    assign en_d3_d_0 = !en_w0 & !en_w1 & !en_w2 & en_w3;
    assign en_d3_d_1 = ((!en_w0 & !en_w1 & en_w2) | (!en_w0 & en_w1 & !en_w2) | (en_w0 & !en_w1 & !en_w2)) & en_w3;
    assign en_d3_d_2 = ((!en_w0 &  en_w1 & en_w2) | ( en_w0 & en_w1 & !en_w2) | (en_w0 & !en_w1 &  en_w2)) & en_w3;
    assign en_d3_d_3 =  en_w0 & en_w1 & en_w2 & en_w3;
    
    assign d0_d = {36'h000_000_000, d0 & {12{en_d0_d_0}}};
    assign d1_d = {24'h000_000, d1 & {12{en_d1_d_1}}, d1 & {12{en_d1_d_0}}};
    assign d2_d = { 12'h000, 
                    d2 & {12{en_d2_d_2}}, 
                    d2 & {12{en_d2_d_1}},
                    d2 & {12{en_d2_d_0}}};
    assign d3_d = { d3 & {12{en_d3_d_3}}, 
                    d3 & {12{en_d3_d_2}}, 
                    d3 & {12{en_d3_d_1}},
                    d3 & {12{en_d3_d_0}}};
    
    wire [47:00] input_d;
    assign input_d = d3_d ^ d2_d ^ d1_d ^ d0_d;
    
    reg [47:00] save;
    
    reg [1:0] pos;
    
    always @* begin
        case(pos)
            2'b00: in_ram = input_d;
            2'b01: in_ram = {input_d[35:00], save[11:00]};
            2'b10: in_ram = {input_d[23:00], save[23:00]};
            2'b11: in_ram = {input_d[11:00], save[35:00]};
        endcase
    end
    
    wire [1:0] next_pos;
    
    wire [2:0] count; 
    assign count = (start) ? en_w3 + en_w2 + en_w1 + en_w0 : 3'b000;
    
    wire [2:0] sum;
    assign sum = pos + count;
    assign next_pos = sum[1:0];
    
    always @(posedge clk) begin
        if(!rst) save <= 0;
        else begin
            case(sum)
                3'b000: save <= save;
                3'b001: save <= in_ram;
                3'b010: save <= in_ram;
                3'b011: save <= in_ram;
                3'b100: save <= 0;
                3'b101: begin 
                            if(pos == 2'b01)        save <= {36'h000_0000_000, input_d[47:36]};   
                            else if(pos == 2'b11)   save <= {12'h000, input_d[47:12]};
                            else                    save <= {24'h000_000, input_d[47:24]};    
                        end 
                3'b110: begin
                            if(pos == 2'b11)    save <= {12'h000, input_d[47:12]};
                            else                save <= {24'h000_000, input_d[47:24]}; 
                        end
                3'b111: begin 
                            if(pos == 2'b11)    save <= {12'h000, input_d[47:12]};
                            else                save <= input_d;
                        end
            endcase
        end     
    end

    wire end_op_shake;
    reg end_op_wr;
    assign end_op   = end_op_wr;
    assign end_read = end_op_shake;
    
    assign end_op_shake = (load) ? 1'b0 : ((counter_shake == 108 | counter_shake == 112) ? 1'b1 : 1'b0);
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst | (end_op_wr))          ad_wr <= 0;
        else begin
            if(ad_wr == 63)             ad_wr <= ad_wr; // to avoid overflow
            else if(start & sum[2])     ad_wr <= ad_wr + 1;
            else                        ad_wr <= ad_wr;     
        end
    end
    
    always @(posedge clk) begin
        if(!rst | (end_op_wr & load))                   end_op_wr <= 0;
        else begin
            if(ad_wr == 63 & sum[2])                    end_op_wr <= 1;
            else                                        end_op_wr <= end_op_wr;
        end
    end

    always @(posedge clk) begin
        if(!rst | end_op_wr)    pos <= 0;
        else if(start)          pos <= next_pos;
        else                    pos <= pos;
    end
     
    // --- RAM 0 --- //
    wire            en_w_r0; 
    wire [9:0]      addr_1_0;
    wire [9:0]      addr_2_0;
    
    assign addr_1_0 = (start & !selw) ? ( ((ad_wr << 1) + 0) + (off_r0 << 7) ) : ar_1_0 ;
    assign addr_2_0 = (start & !selw) ? ( ((ad_wr << 1) + 1) + (off_r0 << 7) ) : ar_2_0 ;
    assign en_w_r0  = start & !selw & sum[2] & !end_op_wr;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_0 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r0         ),     
        .enable_2   (   en_w_r0         ), 
        .addr_1     (   addr_1_0        ),              
        .addr_2     (   addr_2_0        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_1_0          ),
        .data_out_2 (   do_2_0          )  
    );
    
    
    // --- RAM 2 --- //
    wire            en_w_r1; 
    wire [9:0]      addr_3_0;
    wire [9:0]      addr_4_0;
    
    assign addr_3_0 = (start & selw) ? ( ((ad_wr << 1) + 0) + (off_r1 << 7) ) : ar_3_0 ;
    assign addr_4_0 = (start & selw) ? ( ((ad_wr << 1) + 1) + (off_r1 << 7) ) : ar_4_0 ;
    assign en_w_r1  = start & selw & sum[2] & !end_op_wr;
    
    RAM_DUAL #(
        .SIZE(1024), 
        .WIDTH(24)
    ) 
    RAM_2 (
        .clk        (   clk             ), 
        .enable_1   (   en_w_r1         ),     
        .enable_2   (   en_w_r1         ), 
        .addr_1     (   addr_3_0        ),              
        .addr_2     (   addr_4_0        ), 
        .data_in_1  (   in_ram[23:00]   ),
        .data_in_2  (   in_ram[47:24]   ),
        .data_out_1 (   do_3_0          ),
        .data_out_2 (   do_4_0          )  
    );

    
endmodule