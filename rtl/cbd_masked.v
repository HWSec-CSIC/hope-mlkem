`timescale 1ns / 1ps

module CBD_MASKED_DOM #(
    parameter Q = 3329
    )(
    input clk,
    input rst,
    input load,
    input start,
    input   [1:0] eta,
    input   scnd,
    input [1599:0] rand_1,
    input [1599:0] rand_2,
    input [1599:0] rand_3,
    input [1087:0] in_shake_s_1,
    input [1087:0] in_shake_s_2,
    input [1087:0] in_shake_s_3,
    input [1087:0] in_shake_s_4,
    output reg end_op,
    output          en_write,
    output [23:0]   data_in_1,
    output [23:0]   data_in_2,
    output [7:0]    addr_1,  
    output [7:0]    addr_2 
    );
    
    reg load_clk;
    always @(posedge clk) load_clk <= load;
    
    reg start_clk;
    always @(posedge clk) start_clk <= start;
    
    reg sel_s;
    always @(posedge clk) begin
        if(!rst | load)     sel_s <= 1'b0;
        else if(start_clk)  sel_s <= ~sel_s;
        else                sel_s <= sel_s;
    end
    
    reg [3:0] rand_op;
    always @(posedge clk) begin
        if(!rst)        rand_op <= 4'b0000;
        else if(load)   rand_op <= rand_1[3:0] ^ rand_2[3:0];
        else            rand_op <= rand_op;
    end
    // assign rand_op = rand_1[3:0] ^ rand_2[3:0]; // Randomization of shares
    // assign rand_op = 4'b0000;
    
    wire sel_e_1, sel_e_2, sel_o_1, sel_o_2;
    assign sel_e_1 = (rand_op[0]) ? sel_s : !sel_s;
    assign sel_e_2 = (rand_op[1]) ? sel_s : !sel_s;
    assign sel_o_1 = (rand_op[2]) ? sel_s : !sel_s;
    assign sel_o_2 = (rand_op[3]) ? sel_s : !sel_s;
    
    reg signed [1095:0] mask;
    always @(posedge clk) begin
        if(!rst) mask <= 0;
        else begin
            if(load) begin
                if(scnd)                    mask <= 0;
                else                        mask <= {8'hFF, {1088{1'b0}}};
            end                 
            else if(start_clk & !end_op & !sel_s) begin // We use start cycle to update
                if(eta == 2'b11)            mask <= {24'hFFFFFF,    mask[1095:24]};
                else                        mask <= {16'hFFFF,      mask[1095:16]};
            end           
            else                            mask <= mask;
        end
    end
    
    reg [1095:0] reg_shake_s_1;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_1 <= {2{rand_1[547:0]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_1 <= {in_shake_s_1, reg_shake_s_1[7:0]};
                else                        reg_shake_s_1 <= {8'h00, in_shake_s_1};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_1 <= (reg_shake_s_1 >> 24) ^ (mask & {2{rand_1[547:0]}});
                else                        reg_shake_s_1 <= (reg_shake_s_1 >> 16) ^ (mask & {2{rand_1[547:0]}});
            end           
            else                            reg_shake_s_1 <= reg_shake_s_1;
        end
    end

    reg [1095:0] reg_shake_s_2;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_2 <= {2{rand_1[1095:548]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_2 <= {in_shake_s_2, reg_shake_s_2[7:0]};
                else                        reg_shake_s_2 <= {8'h00, in_shake_s_2};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_2 <= (reg_shake_s_2 >> 24) ^ (mask & {2{rand_1[1095:548]}});
                else                        reg_shake_s_2 <= (reg_shake_s_2 >> 16) ^ (mask & {2{rand_1[1095:548]}});
            end           
            else                            reg_shake_s_2 <= reg_shake_s_2;
        end
    end
    
    reg [1095:0] reg_shake_s_3;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_3 <= {rand_2[1095:0], rand_1[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_3 <= {in_shake_s_3, reg_shake_s_3[7:0]};
                else                        reg_shake_s_3 <= {8'h00, in_shake_s_3};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_3 <= (reg_shake_s_3 >> 24) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
                else                        reg_shake_s_3 <= (reg_shake_s_3 >> 16) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
            end           
            else                            reg_shake_s_3 <= reg_shake_s_3;
        end
    end
    
    reg [1095:0] reg_shake_s_4;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_4 <= {rand_3[1095:0], rand_2[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_4 <= {in_shake_s_4, reg_shake_s_4[7:0]};
                else                        reg_shake_s_4 <= {8'h00, in_shake_s_4};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_4 <= (reg_shake_s_4 >> 24) ^ (mask & {rand_3[1095:0], rand_2[1599:1096]});
                else                        reg_shake_s_4 <= (reg_shake_s_4 >> 16) ^ (mask & {rand_3[1095:0], rand_2[1599:1096]});
            end           
            else                            reg_shake_s_4 <= reg_shake_s_4;
        end
    end

    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load | load_clk)      counter_shake <= 0;
        else begin
            if(start_clk & sel_s)       counter_shake <= counter_shake + 1;
            else                        counter_shake <= counter_shake;
        end
    end

    wire [23:0] reg_shake; 
    assign reg_shake = (start_clk) ? reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0] ^ reg_shake_s_4[23:0] : (rand_1[23:00] ^ rand_2[23:00] ^ rand_3[23:00]);
    (* DONT_TOUCH = "TRUE" *) wire [23:0] reg_shake_h; 
    assign reg_shake_h = ~reg_shake;
    
    reg [15:0] x_e_1;
    reg [15:0] y_e_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_1_h, y_e_1_h;
    always @* begin
        if(sel_e_1) begin
            if(eta == 2'b11) begin 
                x_e_1 = reg_shake[0] + reg_shake[1] + reg_shake[2];
                y_e_1 = reg_shake[3] + reg_shake[4] + reg_shake[5];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
            else begin
                x_e_1 = reg_shake[0] + reg_shake[1];
                y_e_1 = reg_shake[2] + reg_shake[3];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
        end
        else begin
            x_e_1 = x_e_1;
            y_e_1 = y_e_1;
            x_e_1_h = ~x_e_1;
            y_e_1_h = ~y_e_1;
        end
    end
    /*
    wire [15:0] x_e_1;
    wire [15:0] y_e_1;
    assign x_e_1 = (eta == 2'b11) ? (reg_shake[0] + reg_shake[1] + reg_shake[2]) : (reg_shake[0] + reg_shake[1]);
    assign y_e_1 = (eta == 2'b11) ? (reg_shake[3] + reg_shake[4] + reg_shake[5]) : (reg_shake[2] + reg_shake[3]);
    wire [15:0] S_e_1;
    wire [15:0] d_e_1;
    assign S_e_1 = x_e_1 - y_e_1;
    assign d_e_1    = (S_e_1[15]) ? S_e_1 + Q : S_e_1;
    */
  
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_1, d_e_1_comp;
    always @* begin
        case({x_e_1[1:0],y_e_1[1:0]})
            4'b0000: d_e_1 = 16'h0000;
            4'b0001: d_e_1 = 16'h0d00;
            4'b0010: d_e_1 = 16'h0cff;
            4'b0011: d_e_1 = 16'h0cfe;
            4'b0100: d_e_1 = 16'h0001;
            4'b0101: d_e_1 = 16'h0000;
            4'b0110: d_e_1 = 16'h0d00;
            4'b0111: d_e_1 = 16'h0cff;
            4'b1000: d_e_1 = 16'h0002;
            4'b1001: d_e_1 = 16'h0001;
            4'b1010: d_e_1 = 16'h0000;
            4'b1011: d_e_1 = 16'h0d00;
            4'b1100: d_e_1 = 16'h0003;
            4'b1101: d_e_1 = 16'h0002;
            4'b1110: d_e_1 = 16'h0001;
            4'b1111: d_e_1 = 16'h0000;
        endcase
        
        d_e_1_comp = ~d_e_1; // Complementary operation
    end
    
    reg [15:0] x_e_2;
    reg [15:0] y_e_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_2_h, y_e_2_h;
    always @* begin
        if(sel_e_2) begin
            if(eta == 2'b11) begin 
                x_e_2 = reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12];
                y_e_2 = reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
            else begin
                x_e_2 = reg_shake[0+8] + reg_shake[1+8];
                y_e_2 = reg_shake[2+8] + reg_shake[3+8];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
        end
        else begin
            x_e_2 = x_e_2;
            y_e_2 = y_e_2;
            x_e_2_h = ~x_e_2;
            y_e_2_h = ~y_e_2;
        end
    end
    
    /*
    wire [15:0] x_e_2;
    wire [15:0] y_e_2;
    assign x_e_2 = (eta == 2'b11) ? (reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12]) : (reg_shake[0+8] + reg_shake[1+8]);
    assign y_e_2 = (eta == 2'b11) ? (reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12]) : (reg_shake[2+8] + reg_shake[3+8]);
    wire [15:0] S_e_2;
    wire [15:0] d_e_2;
    assign S_e_2 = x_e_2 - y_e_2;
    assign d_e_2 = (S_e_2[15]) ? S_e_2 + Q : S_e_2;
    */
    
     (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_2, d_e_2_comp;
    always @* begin
        case({x_e_2[1:0],y_e_2[1:0]})
            4'b0000: d_e_2 = 16'h0000;
            4'b0001: d_e_2 = 16'h0d00;
            4'b0010: d_e_2 = 16'h0cff;
            4'b0011: d_e_2 = 16'h0cfe;
            4'b0100: d_e_2 = 16'h0001;
            4'b0101: d_e_2 = 16'h0000;
            4'b0110: d_e_2 = 16'h0d00;
            4'b0111: d_e_2 = 16'h0cff;
            4'b1000: d_e_2 = 16'h0002;
            4'b1001: d_e_2 = 16'h0001;
            4'b1010: d_e_2 = 16'h0000;
            4'b1011: d_e_2 = 16'h0d00;
            4'b1100: d_e_2 = 16'h0003;
            4'b1101: d_e_2 = 16'h0002;
            4'b1110: d_e_2 = 16'h0001;
            4'b1111: d_e_2 = 16'h0000;
        endcase
        
        d_e_2_comp = ~d_e_2; // Complementary operation
    end
    
    reg [15:0] x_o_1;
    reg [15:0] y_o_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_1_h, y_o_1_h;
    always @* begin
        if(sel_o_1) begin
            if(eta == 2'b11) begin 
                x_o_1 = reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6];
                y_o_1 = reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
            else begin
                x_o_1 = reg_shake[0+4] + reg_shake[1+4];
                y_o_1 = reg_shake[2+4] + reg_shake[3+4];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
        end
        else begin
            x_o_1 = x_o_1;
            y_o_1 = y_o_1;
            x_o_1_h = ~x_o_1;
            y_o_1_h = ~y_o_1;
        end
    end
    /*
    wire [15:0] x_o_1;
    wire [15:0] y_o_1;
    assign x_o_1 = (eta == 2'b11) ? (reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6]) : (reg_shake[0+4] + reg_shake[1+4]);
    assign y_o_1 = (eta == 2'b11) ? (reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6]) : (reg_shake[2+4] + reg_shake[3+4]);
    wire [15:0] S_o_1;
    wire [15:0] d_o_1;
    assign S_o_1 = x_o_1 - y_o_1;
    assign d_o_1 = (S_o_1[15]) ? S_o_1 + Q : S_o_1;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_1, d_o_1_comp;
    always @* begin
        case({x_o_1[1:0],y_o_1[1:0]})
            4'b0000: d_o_1 = 16'h0000;
            4'b0001: d_o_1 = 16'h0d00;
            4'b0010: d_o_1 = 16'h0cff;
            4'b0011: d_o_1 = 16'h0cfe;
            4'b0100: d_o_1 = 16'h0001;
            4'b0101: d_o_1 = 16'h0000;
            4'b0110: d_o_1 = 16'h0d00;
            4'b0111: d_o_1 = 16'h0cff;
            4'b1000: d_o_1 = 16'h0002;
            4'b1001: d_o_1 = 16'h0001;
            4'b1010: d_o_1 = 16'h0000;
            4'b1011: d_o_1 = 16'h0d00;
            4'b1100: d_o_1 = 16'h0003;
            4'b1101: d_o_1 = 16'h0002;
            4'b1110: d_o_1 = 16'h0001;
            4'b1111: d_o_1 = 16'h0000;
        endcase
        
        d_o_1_comp = ~d_o_1; // Complementary operation
    end
    
    
    reg [15:0] x_o_2;
    reg [15:0] y_o_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_2_h, y_o_2_h;
    always @* begin
        if(sel_o_2) begin
            if(eta == 2'b11) begin 
                x_o_2 = reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18];
                y_o_2 = reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
            else begin
                x_o_2 = reg_shake[0+12] + reg_shake[1+12];
                y_o_2 = reg_shake[2+12] + reg_shake[3+12];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
        end
        else begin
            x_o_2 = x_o_2;
            y_o_2 = y_o_2;
            x_o_2_h = ~x_o_2;
            y_o_2_h = ~y_o_2;
        end
    end
    
    /*
    wire [15:0] x_o_2;
    wire [15:0] y_o_2;
    assign x_o_2 = (eta == 2'b11) ? (reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18]) : (reg_shake[0+12] + reg_shake[1+12]);
    assign y_o_2 = (eta == 2'b11) ? (reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18]) : (reg_shake[2+12] + reg_shake[3+12]);
    wire [15:0] S_o_2;
    wire [15:0] d_o_2;
    assign S_o_2 = x_o_2 - y_o_2;
    assign d_o_2 = (S_o_2[15]) ? S_o_2 + Q : S_o_2;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_2, d_o_2_comp;
    always @* begin
        case({x_o_2[1:0],y_o_2[1:0]})
            4'b0000: d_o_2 = 16'h0000;
            4'b0001: d_o_2 = 16'h0d00;
            4'b0010: d_o_2 = 16'h0cff;
            4'b0011: d_o_2 = 16'h0cfe;
            4'b0100: d_o_2 = 16'h0001;
            4'b0101: d_o_2 = 16'h0000;
            4'b0110: d_o_2 = 16'h0d00;
            4'b0111: d_o_2 = 16'h0cff;
            4'b1000: d_o_2 = 16'h0002;
            4'b1001: d_o_2 = 16'h0001;
            4'b1010: d_o_2 = 16'h0000;
            4'b1011: d_o_2 = 16'h0d00;
            4'b1100: d_o_2 = 16'h0003;
            4'b1101: d_o_2 = 16'h0002;
            4'b1110: d_o_2 = 16'h0001;
            4'b1111: d_o_2 = 16'h0000;
        endcase
        
        d_o_2_comp = ~d_o_2; // Complementary operation
    end
    
    assign en_write = start;
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst)                                            ad_wr <= 0;
        else begin
            if(start_clk & en_write & !end_op & sel_s)      ad_wr <= ad_wr + 2;
            else                                            ad_wr <= ad_wr;
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst | load | load_clk)                                              end_op <= 1'b0;
        else begin
            if(eta == 2'b10 & ad_wr == 126 & !sel_s)                            end_op <= 1'b1;
       else if(eta == 2'b11 & ((ad_wr == 126 & !sel_s) | (counter_shake == 44 & sel_s)))    end_op <= 1'b1;
            else                                                                end_op <= end_op;
        end
    
    end
    
    assign data_in_1 = {d_o_1[11:0], d_e_1[11:0]};
    assign data_in_2 = {d_o_2[11:0], d_e_2[11:0]};
    
    assign addr_1   = ad_wr;
    assign addr_2   = ad_wr + 1;   
endmodule

module CBD_MASKED_DOM_DPL #(
    parameter Q = 3329
    )(
    input clk,
    input rst,
    input load,
    input start,
    input   [1:0] eta,
    input   scnd,
    input [1599:0] rand_1,
    input [1599:0] rand_2,
    input [1599:0] rand_3,
    input [1087:0] in_shake_s_1,
    input [1087:0] in_shake_s_2,
    input [1087:0] in_shake_s_3,
    input [1087:0] in_shake_s_4,
    output reg      end_op,
    output          en_write,
    output [23:0]   data_in_1,
    output [23:0]   data_in_2,
    output [7:0]    addr_1,  
    output [7:0]    addr_2 
    );
    
    reg load_clk;
    always @(posedge clk) load_clk <= load;
    
    reg start_clk;
    always @(posedge clk) start_clk <= start;
    
    reg [1:0] sel_s;
    always @(posedge clk) begin
        if(!rst | load)     sel_s <= 2'b00;
        else if(start_clk) begin 
            case(sel_s)
                2'b00: sel_s <= 2'b10;
                2'b10: sel_s <= 2'b11;
                2'b11: sel_s <= 2'b00;
              default: sel_s <= 2'b00;
            endcase
        end
        else                sel_s <= sel_s;
    end
    
    // wire [3:0] rand_op = 4'b1111; // Mandatory in DRL mode, we use sel_s to precharge
    
    reg [3:0] rand_op;
    always @(posedge clk) begin
        if(!rst)        rand_op <= 4'b0000;
        else if(load)   rand_op <= rand_1[3:0] ^ rand_2[3:0];
        else            rand_op <= rand_op;
    end
    
    wire sel_e_1, sel_e_2, sel_o_1, sel_o_2;
    assign sel_e_1 = (rand_op[0] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_e_2 = (rand_op[1] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_o_1 = (rand_op[2] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_o_2 = (rand_op[3] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    
    
    reg signed [1095:0] mask;
    always @(posedge clk) begin
        if(!rst) mask <= 0;
        else begin
            if(load) begin
                if(scnd)                    mask <= 0;
                else                        mask <= {8'hFF, {1088{1'b0}}};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b00)) begin // We use start cycle to update
                if(eta == 2'b11)            mask <= {24'hFFFFFF,    mask[1095:24]};
                else                        mask <= {16'hFFFF,      mask[1095:16]};
            end           
            else                            mask <= mask;
        end
    end
    
    reg [1095:0] reg_shake_s_1;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_1 <= {2{rand_1[547:0]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_1 <= {in_shake_s_1, reg_shake_s_1[7:0]};
                else                        reg_shake_s_1 <= {8'h00, in_shake_s_1};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_1 <= (reg_shake_s_1 >> 24) ^ (mask & {2{rand_1[547:0]}});
                else                        reg_shake_s_1 <= (reg_shake_s_1 >> 16) ^ (mask & {2{rand_1[547:0]}});
            end           
            else                            reg_shake_s_1 <= reg_shake_s_1;
        end
    end

    reg [1095:0] reg_shake_s_2;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_2 <= {2{rand_1[1095:548]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_2 <= {in_shake_s_2, reg_shake_s_2[7:0]};
                else                        reg_shake_s_2 <= {8'h00, in_shake_s_2};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_2 <= (reg_shake_s_2 >> 24) ^ (mask & {2{rand_1[1095:548]}});
                else                        reg_shake_s_2 <= (reg_shake_s_2 >> 16) ^ (mask & {2{rand_1[1095:548]}});
            end           
            else                            reg_shake_s_2 <= reg_shake_s_2;
        end
    end
    
    reg [1095:0] reg_shake_s_3;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_3 <= {rand_2[1095:0], rand_1[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_3 <= {in_shake_s_3, reg_shake_s_3[7:0]};
                else                        reg_shake_s_3 <= {8'h00, in_shake_s_3};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_3 <= (reg_shake_s_3 >> 24) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
                else                        reg_shake_s_3 <= (reg_shake_s_3 >> 16) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
            end           
            else                            reg_shake_s_3 <= reg_shake_s_3;
        end
    end
    
    reg [1095:0] reg_shake_s_4;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_4 <= {rand_3[1095:0], rand_2[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_4 <= {in_shake_s_4, reg_shake_s_4[7:0]};
                else                        reg_shake_s_4 <= {8'h00, in_shake_s_4};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_4 <= (reg_shake_s_4 >> 24) ^ (mask & {rand_3[1095:0], rand_2[1599:1096]});
                else                        reg_shake_s_4 <= (reg_shake_s_4 >> 16) ^ (mask & {rand_3[1095:0], rand_2[1599:1096]});
            end           
            else                            reg_shake_s_4 <= reg_shake_s_4;
        end
    end

    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load | load_clk)      counter_shake <= 0;
        else begin
            if(start_clk & (sel_s == 2'b11))       counter_shake <= counter_shake + 1;
            else                            counter_shake <= counter_shake;
        end
    end
    

    (* DONT_TOUCH = "TRUE" *) reg [23:0] reg_shake, reg_shake_h;
    always @(posedge clk) begin
        if(!rst | !start_clk | (sel_s == 2'b11)) begin
            reg_shake   <= 0; 
            reg_shake_h <= 0;
        end
        else begin
            reg_shake   <= reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0] ^ reg_shake_s_4[23:0] ;
            reg_shake_h <= ~(reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0] ^ reg_shake_s_4[23:0]);
        end
    end
    
    reg [15:0] x_e_1;
    reg [15:0] y_e_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_1_h, y_e_1_h;
    always @* begin
        if(sel_e_1) begin
            if(eta == 2'b11) begin 
                x_e_1 = reg_shake[0] + reg_shake[1] + reg_shake[2];
                y_e_1 = reg_shake[3] + reg_shake[4] + reg_shake[5];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
            else begin
                x_e_1 = reg_shake[0] + reg_shake[1];
                y_e_1 = reg_shake[2] + reg_shake[3];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
        end
        else begin
            x_e_1 = x_e_1;
            y_e_1 = y_e_1;
            x_e_1_h = ~x_e_1;
            y_e_1_h = ~y_e_1;
        end
    end
    /*
    wire [15:0] x_e_1;
    wire [15:0] y_e_1;
    assign x_e_1 = (eta == 2'b11) ? (reg_shake[0] + reg_shake[1] + reg_shake[2]) : (reg_shake[0] + reg_shake[1]);
    assign y_e_1 = (eta == 2'b11) ? (reg_shake[3] + reg_shake[4] + reg_shake[5]) : (reg_shake[2] + reg_shake[3]);
    wire [15:0] S_e_1;
    wire [15:0] d_e_1;
    assign S_e_1 = x_e_1 - y_e_1;
    assign d_e_1    = (S_e_1[15]) ? S_e_1 + Q : S_e_1;
    */
  
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_1, d_e_1_comp;
    always @* begin
        case({x_e_1[1:0],y_e_1[1:0]})
            4'b0000: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b0001: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b0010: d_e_1 = 16'h0cff; // 0000_1100_1111_1111
            4'b0011: d_e_1 = 16'h0cfe; // 0000_1100_1111_1110
            4'b0100: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b0101: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b0110: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b0111: d_e_1 = 16'h0cff; // 0000_1100_1111_1111
            4'b1000: d_e_1 = 16'h0002; // 0000_0000_0000_0010
            4'b1001: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b1010: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b1011: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b1100: d_e_1 = 16'h0003; // 0000_0000_0000_0011
            4'b1101: d_e_1 = 16'h0002; // 0000_0000_0000_0010
            4'b1110: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b1111: d_e_1 = 16'h0000; // 0000_0000_0000_0000
        endcase
        
        d_e_1_comp = ~d_e_1; // Complementary operation
    end
    
    reg [15:0] x_e_2;
    reg [15:0] y_e_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_2_h, y_e_2_h;
    always @* begin
        if(sel_e_2) begin
            if(eta == 2'b11) begin 
                x_e_2 = reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12];
                y_e_2 = reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
            else begin
                x_e_2 = reg_shake[0+8] + reg_shake[1+8];
                y_e_2 = reg_shake[2+8] + reg_shake[3+8];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
        end
        else begin
            x_e_2 = x_e_2;
            y_e_2 = y_e_2;
            x_e_2_h = ~x_e_2;
            y_e_2_h = ~y_e_2;
        end
    end
    
    /*
    wire [15:0] x_e_2;
    wire [15:0] y_e_2;
    assign x_e_2 = (eta == 2'b11) ? (reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12]) : (reg_shake[0+8] + reg_shake[1+8]);
    assign y_e_2 = (eta == 2'b11) ? (reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12]) : (reg_shake[2+8] + reg_shake[3+8]);
    wire [15:0] S_e_2;
    wire [15:0] d_e_2;
    assign S_e_2 = x_e_2 - y_e_2;
    assign d_e_2 = (S_e_2[15]) ? S_e_2 + Q : S_e_2;
    */
    
     (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_2, d_e_2_comp;
    always @* begin
        case({x_e_2[1:0],y_e_2[1:0]})
            4'b0000: d_e_2 = 16'h0000;
            4'b0001: d_e_2 = 16'h0d00;
            4'b0010: d_e_2 = 16'h0cff;
            4'b0011: d_e_2 = 16'h0cfe;
            4'b0100: d_e_2 = 16'h0001;
            4'b0101: d_e_2 = 16'h0000;
            4'b0110: d_e_2 = 16'h0d00;
            4'b0111: d_e_2 = 16'h0cff;
            4'b1000: d_e_2 = 16'h0002;
            4'b1001: d_e_2 = 16'h0001;
            4'b1010: d_e_2 = 16'h0000;
            4'b1011: d_e_2 = 16'h0d00;
            4'b1100: d_e_2 = 16'h0003;
            4'b1101: d_e_2 = 16'h0002;
            4'b1110: d_e_2 = 16'h0001;
            4'b1111: d_e_2 = 16'h0000;
        endcase
        
        d_e_2_comp = ~d_e_2; // Complementary operation
    end
    
    reg [15:0] x_o_1;
    reg [15:0] y_o_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_1_h, y_o_1_h;
    always @* begin
        if(sel_o_1) begin
            if(eta == 2'b11) begin 
                x_o_1 = reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6];
                y_o_1 = reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
            else begin
                x_o_1 = reg_shake[0+4] + reg_shake[1+4];
                y_o_1 = reg_shake[2+4] + reg_shake[3+4];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
        end
        else begin
            x_o_1 = x_o_1;
            y_o_1 = y_o_1;
            x_o_1_h = ~x_o_1;
            y_o_1_h = ~y_o_1;
        end
    end
    /*
    wire [15:0] x_o_1;
    wire [15:0] y_o_1;
    assign x_o_1 = (eta == 2'b11) ? (reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6]) : (reg_shake[0+4] + reg_shake[1+4]);
    assign y_o_1 = (eta == 2'b11) ? (reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6]) : (reg_shake[2+4] + reg_shake[3+4]);
    wire [15:0] S_o_1;
    wire [15:0] d_o_1;
    assign S_o_1 = x_o_1 - y_o_1;
    assign d_o_1 = (S_o_1[15]) ? S_o_1 + Q : S_o_1;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_1, d_o_1_comp;
    always @* begin
        case({x_o_1[1:0],y_o_1[1:0]})
            4'b0000: d_o_1 = 16'h0000;
            4'b0001: d_o_1 = 16'h0d00;
            4'b0010: d_o_1 = 16'h0cff;
            4'b0011: d_o_1 = 16'h0cfe;
            4'b0100: d_o_1 = 16'h0001;
            4'b0101: d_o_1 = 16'h0000;
            4'b0110: d_o_1 = 16'h0d00;
            4'b0111: d_o_1 = 16'h0cff;
            4'b1000: d_o_1 = 16'h0002;
            4'b1001: d_o_1 = 16'h0001;
            4'b1010: d_o_1 = 16'h0000;
            4'b1011: d_o_1 = 16'h0d00;
            4'b1100: d_o_1 = 16'h0003;
            4'b1101: d_o_1 = 16'h0002;
            4'b1110: d_o_1 = 16'h0001;
            4'b1111: d_o_1 = 16'h0000;
        endcase
        
        d_o_1_comp = ~d_o_1; // Complementary operation
    end
    
    
    reg [15:0] x_o_2;
    reg [15:0] y_o_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_2_h, y_o_2_h;
    always @* begin
        if(sel_o_2) begin
            if(eta == 2'b11) begin 
                x_o_2 = reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18];
                y_o_2 = reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
            else begin
                x_o_2 = reg_shake[0+12] + reg_shake[1+12];
                y_o_2 = reg_shake[2+12] + reg_shake[3+12];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
        end
        else begin
            x_o_2 = x_o_2;
            y_o_2 = y_o_2;
            x_o_2_h = ~x_o_2;
            y_o_2_h = ~y_o_2;
        end
    end
    
    /*
    wire [15:0] x_o_2;
    wire [15:0] y_o_2;
    assign x_o_2 = (eta == 2'b11) ? (reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18]) : (reg_shake[0+12] + reg_shake[1+12]);
    assign y_o_2 = (eta == 2'b11) ? (reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18]) : (reg_shake[2+12] + reg_shake[3+12]);
    wire [15:0] S_o_2;
    wire [15:0] d_o_2;
    assign S_o_2 = x_o_2 - y_o_2;
    assign d_o_2 = (S_o_2[15]) ? S_o_2 + Q : S_o_2;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_2, d_o_2_comp;
    always @* begin
        case({x_o_2[1:0],y_o_2[1:0]})
            4'b0000: d_o_2 = 16'h0000;
            4'b0001: d_o_2 = 16'h0d00;
            4'b0010: d_o_2 = 16'h0cff;
            4'b0011: d_o_2 = 16'h0cfe;
            4'b0100: d_o_2 = 16'h0001;
            4'b0101: d_o_2 = 16'h0000;
            4'b0110: d_o_2 = 16'h0d00;
            4'b0111: d_o_2 = 16'h0cff;
            4'b1000: d_o_2 = 16'h0002;
            4'b1001: d_o_2 = 16'h0001;
            4'b1010: d_o_2 = 16'h0000;
            4'b1011: d_o_2 = 16'h0d00;
            4'b1100: d_o_2 = 16'h0003;
            4'b1101: d_o_2 = 16'h0002;
            4'b1110: d_o_2 = 16'h0001;
            4'b1111: d_o_2 = 16'h0000;
        endcase
        
        d_o_2_comp = ~d_o_2; // Complementary operation
    end
    
    assign en_write = start;
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst)                                                    ad_wr <= 0;
        else begin
            if(start_clk & en_write & !end_op & (sel_s == 2'b11))   ad_wr <= ad_wr + 2;
            else                                                    ad_wr <= ad_wr;
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst | load | load_clk)                                                                              end_op <= 1'b0;
        else begin
            if(eta == 2'b10 & ad_wr == 126 & (sel_s == 2'b10))                                                  end_op <= 1'b1;
       else if(eta == 2'b11 & ((ad_wr == 126 & (sel_s == 2'b10)) | (counter_shake == 44 & (sel_s == 2'b11))))   end_op <= 1'b1;
            else                                                                                                end_op <= end_op;
        end
    
    end
    
    assign data_in_1 = {d_o_1[11:0], d_e_1[11:0]};
    assign data_in_2 = {d_o_2[11:0], d_e_2[11:0]};
    
    assign addr_1   = ad_wr;
    assign addr_2   = ad_wr + 1;   
endmodule


module CBD_MASKED_TI3 #(
    parameter Q = 3329
    )(
    input clk,
    input rst,
    input load,
    input start,
    input   [1:0] eta,
    input   scnd,
    input [1599:0] rand_1,
    input [1599:0] rand_2,
    input [1087:0] in_shake_s_1,
    input [1087:0] in_shake_s_2,
    input [1087:0] in_shake_s_3,
    output reg      end_op,
    output          en_write,
    output [23:0]   data_in_1,
    output [23:0]   data_in_2,
    output [7:0]    addr_1,  
    output [7:0]    addr_2 
    );
    
    reg load_clk;
    always @(posedge clk) load_clk <= load;
    
    reg start_clk;
    always @(posedge clk) start_clk <= start;
    
    reg sel_s;
    always @(posedge clk) begin
        if(!rst | load)     sel_s <= 1'b0;
        else if(start_clk)  sel_s <= ~sel_s;
        else                sel_s <= sel_s;
    end
    
    reg [3:0] rand_op;
    always @(posedge clk) begin
        if(!rst)        rand_op <= 4'b0000;
        else if(load)   rand_op <= rand_1[3:0] ^ rand_2[3:0];
        else            rand_op <= rand_op;
    end
    // assign rand_op = rand_1[3:0] ^ rand_2[3:0]; // Randomization of shares
    // assign rand_op = 4'b0000;
    
    wire sel_e_1, sel_e_2, sel_o_1, sel_o_2;
    assign sel_e_1 = (rand_op[0]) ? sel_s : !sel_s;
    assign sel_e_2 = (rand_op[1]) ? sel_s : !sel_s;
    assign sel_o_1 = (rand_op[2]) ? sel_s : !sel_s;
    assign sel_o_2 = (rand_op[3]) ? sel_s : !sel_s;
    
    reg signed [1095:0] mask;
    always @(posedge clk) begin
        if(!rst) mask <= 0;
        else begin
            if(load) begin
                if(scnd)                    mask <= 0;
                else                        mask <= {8'hFF, {1088{1'b0}}};
            end                 
            else if(start_clk & !end_op & !sel_s) begin // We use start cycle to update
                if(eta == 2'b11)            mask <= {24'hFFFFFF,    mask[1095:24]};
                else                        mask <= {16'hFFFF,      mask[1095:16]};
            end           
            else                            mask <= mask;
        end
    end
    
    reg [1095:0] reg_shake_s_1;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_1 <= {2{rand_1[547:0]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_1 <= {in_shake_s_1, reg_shake_s_1[7:0]};
                else                        reg_shake_s_1 <= {8'h00, in_shake_s_1};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_1 <= (reg_shake_s_1 >> 24) ^ (mask & {2{rand_1[547:0]}});
                else                        reg_shake_s_1 <= (reg_shake_s_1 >> 16) ^ (mask & {2{rand_1[547:0]}});
            end           
            else                            reg_shake_s_1 <= reg_shake_s_1;
        end
    end

    reg [1095:0] reg_shake_s_2;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_2 <= {2{rand_1[1095:548]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_2 <= {in_shake_s_2, reg_shake_s_2[7:0]};
                else                        reg_shake_s_2 <= {8'h00, in_shake_s_2};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_2 <= (reg_shake_s_2 >> 24) ^ (mask & {2{rand_1[1095:548]}});
                else                        reg_shake_s_2 <= (reg_shake_s_2 >> 16) ^ (mask & {2{rand_1[1095:548]}});
            end           
            else                            reg_shake_s_2 <= reg_shake_s_2;
        end
    end
    
    reg [1095:0] reg_shake_s_3;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_3 <= {rand_2[1095:0], rand_1[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_3 <= {in_shake_s_3, reg_shake_s_3[7:0]};
                else                        reg_shake_s_3 <= {8'h00, in_shake_s_3};
            end                 
            else if(start_clk & !end_op & sel_s) begin
                if(eta == 2'b11)            reg_shake_s_3 <= (reg_shake_s_3 >> 24) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
                else                        reg_shake_s_3 <= (reg_shake_s_3 >> 16) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
            end           
            else                            reg_shake_s_3 <= reg_shake_s_3;
        end
    end

    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load | load_clk)      counter_shake <= 0;
        else begin
            if(start_clk & sel_s)       counter_shake <= counter_shake + 1;
            else                        counter_shake <= counter_shake;
        end
    end

    wire [23:0] reg_shake; 
    assign reg_shake = (start_clk) ? reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0] : (rand_1[23:00] ^ rand_2[23:00]);
    (* DONT_TOUCH = "TRUE" *) wire [23:0] reg_shake_h; 
    assign reg_shake_h = ~reg_shake;
    
    reg [15:0] x_e_1;
    reg [15:0] y_e_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_1_h, y_e_1_h;
    always @* begin
        if(sel_e_1) begin
            if(eta == 2'b11) begin 
                x_e_1 = reg_shake[0] + reg_shake[1] + reg_shake[2];
                y_e_1 = reg_shake[3] + reg_shake[4] + reg_shake[5];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
            else begin
                x_e_1 = reg_shake[0] + reg_shake[1];
                y_e_1 = reg_shake[2] + reg_shake[3];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
        end
        else begin
            x_e_1 = x_e_1;
            y_e_1 = y_e_1;
            x_e_1_h = ~x_e_1;
            y_e_1_h = ~y_e_1;
        end
    end
    /*
    wire [15:0] x_e_1;
    wire [15:0] y_e_1;
    assign x_e_1 = (eta == 2'b11) ? (reg_shake[0] + reg_shake[1] + reg_shake[2]) : (reg_shake[0] + reg_shake[1]);
    assign y_e_1 = (eta == 2'b11) ? (reg_shake[3] + reg_shake[4] + reg_shake[5]) : (reg_shake[2] + reg_shake[3]);
    wire [15:0] S_e_1;
    wire [15:0] d_e_1;
    assign S_e_1 = x_e_1 - y_e_1;
    assign d_e_1    = (S_e_1[15]) ? S_e_1 + Q : S_e_1;
    */
  
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_1, d_e_1_comp;
    always @* begin
        case({x_e_1[1:0],y_e_1[1:0]})
            4'b0000: d_e_1 = 16'h0000;
            4'b0001: d_e_1 = 16'h0d00;
            4'b0010: d_e_1 = 16'h0cff;
            4'b0011: d_e_1 = 16'h0cfe;
            4'b0100: d_e_1 = 16'h0001;
            4'b0101: d_e_1 = 16'h0000;
            4'b0110: d_e_1 = 16'h0d00;
            4'b0111: d_e_1 = 16'h0cff;
            4'b1000: d_e_1 = 16'h0002;
            4'b1001: d_e_1 = 16'h0001;
            4'b1010: d_e_1 = 16'h0000;
            4'b1011: d_e_1 = 16'h0d00;
            4'b1100: d_e_1 = 16'h0003;
            4'b1101: d_e_1 = 16'h0002;
            4'b1110: d_e_1 = 16'h0001;
            4'b1111: d_e_1 = 16'h0000;
        endcase
        
        d_e_1_comp = ~d_e_1; // Complementary operation
    end
    
    reg [15:0] x_e_2;
    reg [15:0] y_e_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_2_h, y_e_2_h;
    always @* begin
        if(sel_e_2) begin
            if(eta == 2'b11) begin 
                x_e_2 = reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12];
                y_e_2 = reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
            else begin
                x_e_2 = reg_shake[0+8] + reg_shake[1+8];
                y_e_2 = reg_shake[2+8] + reg_shake[3+8];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
        end
        else begin
            x_e_2 = x_e_2;
            y_e_2 = y_e_2;
            x_e_2_h = ~x_e_2;
            y_e_2_h = ~y_e_2;
        end
    end
    
    /*
    wire [15:0] x_e_2;
    wire [15:0] y_e_2;
    assign x_e_2 = (eta == 2'b11) ? (reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12]) : (reg_shake[0+8] + reg_shake[1+8]);
    assign y_e_2 = (eta == 2'b11) ? (reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12]) : (reg_shake[2+8] + reg_shake[3+8]);
    wire [15:0] S_e_2;
    wire [15:0] d_e_2;
    assign S_e_2 = x_e_2 - y_e_2;
    assign d_e_2 = (S_e_2[15]) ? S_e_2 + Q : S_e_2;
    */
    
     (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_2, d_e_2_comp;
    always @* begin
        case({x_e_2[1:0],y_e_2[1:0]})
            4'b0000: d_e_2 = 16'h0000;
            4'b0001: d_e_2 = 16'h0d00;
            4'b0010: d_e_2 = 16'h0cff;
            4'b0011: d_e_2 = 16'h0cfe;
            4'b0100: d_e_2 = 16'h0001;
            4'b0101: d_e_2 = 16'h0000;
            4'b0110: d_e_2 = 16'h0d00;
            4'b0111: d_e_2 = 16'h0cff;
            4'b1000: d_e_2 = 16'h0002;
            4'b1001: d_e_2 = 16'h0001;
            4'b1010: d_e_2 = 16'h0000;
            4'b1011: d_e_2 = 16'h0d00;
            4'b1100: d_e_2 = 16'h0003;
            4'b1101: d_e_2 = 16'h0002;
            4'b1110: d_e_2 = 16'h0001;
            4'b1111: d_e_2 = 16'h0000;
        endcase
        
        d_e_2_comp = ~d_e_2; // Complementary operation
    end
    
    reg [15:0] x_o_1;
    reg [15:0] y_o_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_1_h, y_o_1_h;
    always @* begin
        if(sel_o_1) begin
            if(eta == 2'b11) begin 
                x_o_1 = reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6];
                y_o_1 = reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
            else begin
                x_o_1 = reg_shake[0+4] + reg_shake[1+4];
                y_o_1 = reg_shake[2+4] + reg_shake[3+4];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
        end
        else begin
            x_o_1 = x_o_1;
            y_o_1 = y_o_1;
            x_o_1_h = ~x_o_1;
            y_o_1_h = ~y_o_1;
        end
    end
    /*
    wire [15:0] x_o_1;
    wire [15:0] y_o_1;
    assign x_o_1 = (eta == 2'b11) ? (reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6]) : (reg_shake[0+4] + reg_shake[1+4]);
    assign y_o_1 = (eta == 2'b11) ? (reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6]) : (reg_shake[2+4] + reg_shake[3+4]);
    wire [15:0] S_o_1;
    wire [15:0] d_o_1;
    assign S_o_1 = x_o_1 - y_o_1;
    assign d_o_1 = (S_o_1[15]) ? S_o_1 + Q : S_o_1;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_1, d_o_1_comp;
    always @* begin
        case({x_o_1[1:0],y_o_1[1:0]})
            4'b0000: d_o_1 = 16'h0000;
            4'b0001: d_o_1 = 16'h0d00;
            4'b0010: d_o_1 = 16'h0cff;
            4'b0011: d_o_1 = 16'h0cfe;
            4'b0100: d_o_1 = 16'h0001;
            4'b0101: d_o_1 = 16'h0000;
            4'b0110: d_o_1 = 16'h0d00;
            4'b0111: d_o_1 = 16'h0cff;
            4'b1000: d_o_1 = 16'h0002;
            4'b1001: d_o_1 = 16'h0001;
            4'b1010: d_o_1 = 16'h0000;
            4'b1011: d_o_1 = 16'h0d00;
            4'b1100: d_o_1 = 16'h0003;
            4'b1101: d_o_1 = 16'h0002;
            4'b1110: d_o_1 = 16'h0001;
            4'b1111: d_o_1 = 16'h0000;
        endcase
        
        d_o_1_comp = ~d_o_1; // Complementary operation
    end
    
    
    reg [15:0] x_o_2;
    reg [15:0] y_o_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_2_h, y_o_2_h;
    always @* begin
        if(sel_o_2) begin
            if(eta == 2'b11) begin 
                x_o_2 = reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18];
                y_o_2 = reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
            else begin
                x_o_2 = reg_shake[0+12] + reg_shake[1+12];
                y_o_2 = reg_shake[2+12] + reg_shake[3+12];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
        end
        else begin
            x_o_2 = x_o_2;
            y_o_2 = y_o_2;
            x_o_2_h = ~x_o_2;
            y_o_2_h = ~y_o_2;
        end
    end
    
    /*
    wire [15:0] x_o_2;
    wire [15:0] y_o_2;
    assign x_o_2 = (eta == 2'b11) ? (reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18]) : (reg_shake[0+12] + reg_shake[1+12]);
    assign y_o_2 = (eta == 2'b11) ? (reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18]) : (reg_shake[2+12] + reg_shake[3+12]);
    wire [15:0] S_o_2;
    wire [15:0] d_o_2;
    assign S_o_2 = x_o_2 - y_o_2;
    assign d_o_2 = (S_o_2[15]) ? S_o_2 + Q : S_o_2;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_2, d_o_2_comp;
    always @* begin
        case({x_o_2[1:0],y_o_2[1:0]})
            4'b0000: d_o_2 = 16'h0000;
            4'b0001: d_o_2 = 16'h0d00;
            4'b0010: d_o_2 = 16'h0cff;
            4'b0011: d_o_2 = 16'h0cfe;
            4'b0100: d_o_2 = 16'h0001;
            4'b0101: d_o_2 = 16'h0000;
            4'b0110: d_o_2 = 16'h0d00;
            4'b0111: d_o_2 = 16'h0cff;
            4'b1000: d_o_2 = 16'h0002;
            4'b1001: d_o_2 = 16'h0001;
            4'b1010: d_o_2 = 16'h0000;
            4'b1011: d_o_2 = 16'h0d00;
            4'b1100: d_o_2 = 16'h0003;
            4'b1101: d_o_2 = 16'h0002;
            4'b1110: d_o_2 = 16'h0001;
            4'b1111: d_o_2 = 16'h0000;
        endcase
        
        d_o_2_comp = ~d_o_2; // Complementary operation
    end
    
    assign en_write = start;
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst)                                            ad_wr <= 0;
        else begin
            if(start_clk & en_write & !end_op & sel_s)      ad_wr <= ad_wr + 2;
            else                                            ad_wr <= ad_wr;
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst | load | load_clk)                                                          end_op <= 1'b0;
        else begin
            if(eta == 2'b10 & ad_wr == 126 & !sel_s)                                        end_op <= 1'b1;
       else if(eta == 2'b11 & ((ad_wr == 126 & !sel_s) | (counter_shake == 44 & sel_s)))    end_op <= 1'b1;
            else                                                                            end_op <= end_op;
        end
    
    end
    
    assign data_in_1 = {d_o_1[11:0], d_e_1[11:0]};
    assign data_in_2 = {d_o_2[11:0], d_e_2[11:0]};
    
    assign addr_1   = ad_wr;
    assign addr_2   = ad_wr + 1;   
endmodule


module CBD_MASKED_TI3_DPL #(
    parameter Q = 3329
    )(
    input clk,
    input rst,
    input load,
    input start,
    input   [1:0] eta,
    input   scnd,
    input [1599:0] rand_1,
    input [1599:0] rand_2,
    input [1087:0] in_shake_s_1,
    input [1087:0] in_shake_s_2,
    input [1087:0] in_shake_s_3,
    output reg      end_op,
    output          en_write,
    output [23:0]   data_in_1,
    output [23:0]   data_in_2,
    output [7:0]    addr_1,  
    output [7:0]    addr_2 
    );
    
    reg load_clk;
    always @(posedge clk) load_clk <= load;
    
    reg start_clk;
    always @(posedge clk) start_clk <= start;
    
    reg [1:0] sel_s;
    always @(posedge clk) begin
        if(!rst | load)     sel_s <= 2'b00;
        else if(start_clk) begin 
            case(sel_s)
                2'b00: sel_s <= 2'b10;
                2'b10: sel_s <= 2'b11;
                2'b11: sel_s <= 2'b00;
              default: sel_s <= 2'b00;
            endcase
        end
        else                sel_s <= sel_s;
    end
    
    reg sel_mask;
    always @(posedge clk) begin
        if(!rst | load)         sel_mask <= 1'b0;
        else if(sel_s == 2'b11) sel_mask <= ~sel_mask;
        else                    sel_mask <= sel_mask;
    end
    
    reg [3:0] rand_op;
    always @(posedge clk) begin
        if(!rst)        rand_op <= 4'b0000;
        else if(load)   rand_op <= rand_1[3:0] ^ rand_2[3:0];
        else            rand_op <= rand_op;
    end
    
    wire sel_e_1, sel_e_2, sel_o_1, sel_o_2;
    assign sel_e_1 = (rand_op[0] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_e_2 = (rand_op[1] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_o_1 = (rand_op[2] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    assign sel_o_2 = (rand_op[3] & sel_s[1]) ? sel_s[0] : !sel_s[0];
    
    reg signed [1095:0] mask;
    always @(posedge clk) begin
        if(!rst) mask <= 0;
        else begin
            if(load) begin
                if(scnd)                    mask <= 0;
                else                        mask <= {8'hFF, {1088{1'b0}}};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b00)) begin // We use start cycle to update
                if(eta == 2'b11)            mask <= {24'hFFFFFF,    mask[1095:24]};
                else                        mask <= {16'hFFFF,      mask[1095:16]};
            end           
            else                            mask <= mask;
        end
    end
    
    reg [1095:0] reg_shake_s_1;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_1 <= {2{rand_1[547:0]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_1 <= {in_shake_s_1, reg_shake_s_1[7:0]};
                else                        reg_shake_s_1 <= {8'h00, in_shake_s_1};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_1 <= (reg_shake_s_1 >> 24) ^ (mask & {2{rand_1[547:0]}});
                else                        reg_shake_s_1 <= (reg_shake_s_1 >> 16) ^ (mask & {2{rand_1[547:0]}});
            end           
            else                            reg_shake_s_1 <= reg_shake_s_1;
        end
    end

    reg [1095:0] reg_shake_s_2;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_2 <= {2{rand_1[1095:548]}};
        else begin
            if(load) begin
                if(scnd)                    reg_shake_s_2 <= {in_shake_s_2, reg_shake_s_2[7:0]};
                else                        reg_shake_s_2 <= {8'h00, in_shake_s_2};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_2 <= (reg_shake_s_2 >> 24) ^ (mask & {2{rand_1[1095:548]}});
                else                        reg_shake_s_2 <= (reg_shake_s_2 >> 16) ^ (mask & {2{rand_1[1095:548]}});
            end           
            else                            reg_shake_s_2 <= reg_shake_s_2;
        end
    end
    
    reg [1095:0] reg_shake_s_3;
    always @(posedge clk) begin
        if(!rst) reg_shake_s_3 <= {rand_2[1095:0], rand_1[1599:1096]};
        else begin
            if(load_clk) begin
                if(scnd)                    reg_shake_s_3 <= {in_shake_s_3, reg_shake_s_3[7:0]};
                else                        reg_shake_s_3 <= {8'h00, in_shake_s_3};
            end                 
            else if(start_clk & !end_op & (sel_s == 2'b11)) begin
                if(eta == 2'b11)            reg_shake_s_3 <= (reg_shake_s_3 >> 24) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
                else                        reg_shake_s_3 <= (reg_shake_s_3 >> 16) ^ (mask & {rand_2[1095:0], rand_1[1599:1096]});
            end           
            else                            reg_shake_s_3 <= reg_shake_s_3;
        end
    end

    reg [7:0] counter_shake;
    always @(posedge clk) begin
        if(!rst | load | load_clk)      counter_shake <= 0;
        else begin
            if(start_clk & (sel_s == 2'b11))       counter_shake <= counter_shake + 1;
            else                            counter_shake <= counter_shake;
        end
    end
    
    wire [31:0] lfsr_out_1;
    lfsr32x32 #(.SEED(32'h1234_5678) )
    lfsr32x32_1 (
        .clk        (   clk         ),
        .rst        (   !rst        ),
        .enable     (   1'b1        ),
        .lfsr_out   (   lfsr_out_1  )
    );  
    
    wire [31:0] lfsr_out_2;
    lfsr32x32 #(.SEED(32'h8765_4321) )
    lfsr32x32_2 (
        .clk        (   clk         ),
        .rst        (   !rst        ),
        .enable     (   1'b1        ),
        .lfsr_out   (   lfsr_out_2  )
    );  

    (* DONT_TOUCH = "TRUE" *) reg [23:0] reg_shake, reg_shake_h;
    always @(posedge clk) begin
        if(!rst | !start_clk | (sel_s == 2'b11)) begin
            reg_shake   <= rand_1[23:00] ^ lfsr_out_1; 
            reg_shake_h <= rand_2[23:00] ^ lfsr_out_2; 
        end
        else begin
            reg_shake   <= reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0];
            reg_shake_h <= ~(reg_shake_s_1[23:0] ^ reg_shake_s_2[23:0] ^ reg_shake_s_3[23:0]);
        end
    end
    
    reg [15:0] x_e_1;
    reg [15:0] y_e_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_1_h, y_e_1_h;
    always @* begin
        if(sel_e_1) begin
            if(eta == 2'b11) begin 
                x_e_1 = reg_shake[0] + reg_shake[1] + reg_shake[2];
                y_e_1 = reg_shake[3] + reg_shake[4] + reg_shake[5];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
            else begin
                x_e_1 = reg_shake[0] + reg_shake[1];
                y_e_1 = reg_shake[2] + reg_shake[3];
                x_e_1_h = ~x_e_1;
                y_e_1_h = ~y_e_1;
            end
        end
        else begin
            x_e_1 = x_e_1;
            y_e_1 = y_e_1;
            x_e_1_h = ~x_e_1;
            y_e_1_h = ~y_e_1;
        end
    end
    /*
    wire [15:0] x_e_1;
    wire [15:0] y_e_1;
    assign x_e_1 = (eta == 2'b11) ? (reg_shake[0] + reg_shake[1] + reg_shake[2]) : (reg_shake[0] + reg_shake[1]);
    assign y_e_1 = (eta == 2'b11) ? (reg_shake[3] + reg_shake[4] + reg_shake[5]) : (reg_shake[2] + reg_shake[3]);
    wire [15:0] S_e_1;
    wire [15:0] d_e_1;
    assign S_e_1 = x_e_1 - y_e_1;
    assign d_e_1    = (S_e_1[15]) ? S_e_1 + Q : S_e_1;
    */
  
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_1, d_e_1_comp;
    always @* begin
        case({x_e_1[1:0],y_e_1[1:0]})
            4'b0000: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b0001: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b0010: d_e_1 = 16'h0cff; // 0000_1100_1111_1111
            4'b0011: d_e_1 = 16'h0cfe; // 0000_1100_1111_1110
            4'b0100: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b0101: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b0110: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b0111: d_e_1 = 16'h0cff; // 0000_1100_1111_1111
            4'b1000: d_e_1 = 16'h0002; // 0000_0000_0000_0010
            4'b1001: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b1010: d_e_1 = 16'h0000; // 0000_0000_0000_0000
            4'b1011: d_e_1 = 16'h0d00; // 0000_1101_0000_0000
            4'b1100: d_e_1 = 16'h0003; // 0000_0000_0000_0011
            4'b1101: d_e_1 = 16'h0002; // 0000_0000_0000_0010
            4'b1110: d_e_1 = 16'h0001; // 0000_0000_0000_0001
            4'b1111: d_e_1 = 16'h0000; // 0000_0000_0000_0000
        endcase
        
        d_e_1_comp = ~d_e_1; // Complementary operation
    end
    
    reg [15:0] x_e_2;
    reg [15:0] y_e_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_e_2_h, y_e_2_h;
    always @* begin
        if(sel_e_2) begin
            if(eta == 2'b11) begin 
                x_e_2 = reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12];
                y_e_2 = reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
            else begin
                x_e_2 = reg_shake[0+8] + reg_shake[1+8];
                y_e_2 = reg_shake[2+8] + reg_shake[3+8];
                x_e_2_h = ~x_e_2;
                y_e_2_h = ~y_e_2;
            end
        end
        else begin
            x_e_2 = x_e_2;
            y_e_2 = y_e_2;
            x_e_2_h = ~x_e_2;
            y_e_2_h = ~y_e_2;
        end
    end
    
    /*
    wire [15:0] x_e_2;
    wire [15:0] y_e_2;
    assign x_e_2 = (eta == 2'b11) ? (reg_shake[0+12] + reg_shake[1+12] + reg_shake[2+12]) : (reg_shake[0+8] + reg_shake[1+8]);
    assign y_e_2 = (eta == 2'b11) ? (reg_shake[3+12] + reg_shake[4+12] + reg_shake[5+12]) : (reg_shake[2+8] + reg_shake[3+8]);
    wire [15:0] S_e_2;
    wire [15:0] d_e_2;
    assign S_e_2 = x_e_2 - y_e_2;
    assign d_e_2 = (S_e_2[15]) ? S_e_2 + Q : S_e_2;
    */
    
     (* DONT_TOUCH = "TRUE" *) reg [15:0] d_e_2, d_e_2_comp;
    always @* begin
        case({x_e_2[1:0],y_e_2[1:0]})
            4'b0000: d_e_2 = 16'h0000;
            4'b0001: d_e_2 = 16'h0d00;
            4'b0010: d_e_2 = 16'h0cff;
            4'b0011: d_e_2 = 16'h0cfe;
            4'b0100: d_e_2 = 16'h0001;
            4'b0101: d_e_2 = 16'h0000;
            4'b0110: d_e_2 = 16'h0d00;
            4'b0111: d_e_2 = 16'h0cff;
            4'b1000: d_e_2 = 16'h0002;
            4'b1001: d_e_2 = 16'h0001;
            4'b1010: d_e_2 = 16'h0000;
            4'b1011: d_e_2 = 16'h0d00;
            4'b1100: d_e_2 = 16'h0003;
            4'b1101: d_e_2 = 16'h0002;
            4'b1110: d_e_2 = 16'h0001;
            4'b1111: d_e_2 = 16'h0000;
        endcase
        
        d_e_2_comp = ~d_e_2; // Complementary operation
    end
    
    reg [15:0] x_o_1;
    reg [15:0] y_o_1;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_1_h, y_o_1_h;
    always @* begin
        if(sel_o_1) begin
            if(eta == 2'b11) begin 
                x_o_1 = reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6];
                y_o_1 = reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
            else begin
                x_o_1 = reg_shake[0+4] + reg_shake[1+4];
                y_o_1 = reg_shake[2+4] + reg_shake[3+4];
                x_o_1_h = ~x_o_1;
                y_o_1_h = ~y_o_1;
            end
        end
        else begin
            x_o_1 = x_o_1;
            y_o_1 = y_o_1;
            x_o_1_h = ~x_o_1;
            y_o_1_h = ~y_o_1;
        end
    end
    /*
    wire [15:0] x_o_1;
    wire [15:0] y_o_1;
    assign x_o_1 = (eta == 2'b11) ? (reg_shake[0+6] + reg_shake[1+6] + reg_shake[2+6]) : (reg_shake[0+4] + reg_shake[1+4]);
    assign y_o_1 = (eta == 2'b11) ? (reg_shake[3+6] + reg_shake[4+6] + reg_shake[5+6]) : (reg_shake[2+4] + reg_shake[3+4]);
    wire [15:0] S_o_1;
    wire [15:0] d_o_1;
    assign S_o_1 = x_o_1 - y_o_1;
    assign d_o_1 = (S_o_1[15]) ? S_o_1 + Q : S_o_1;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_1, d_o_1_comp;
    always @* begin
        case({x_o_1[1:0],y_o_1[1:0]})
            4'b0000: d_o_1 = 16'h0000;
            4'b0001: d_o_1 = 16'h0d00;
            4'b0010: d_o_1 = 16'h0cff;
            4'b0011: d_o_1 = 16'h0cfe;
            4'b0100: d_o_1 = 16'h0001;
            4'b0101: d_o_1 = 16'h0000;
            4'b0110: d_o_1 = 16'h0d00;
            4'b0111: d_o_1 = 16'h0cff;
            4'b1000: d_o_1 = 16'h0002;
            4'b1001: d_o_1 = 16'h0001;
            4'b1010: d_o_1 = 16'h0000;
            4'b1011: d_o_1 = 16'h0d00;
            4'b1100: d_o_1 = 16'h0003;
            4'b1101: d_o_1 = 16'h0002;
            4'b1110: d_o_1 = 16'h0001;
            4'b1111: d_o_1 = 16'h0000;
        endcase
        
        d_o_1_comp = ~d_o_1; // Complementary operation
    end
    
    
    reg [15:0] x_o_2;
    reg [15:0] y_o_2;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] x_o_2_h, y_o_2_h;
    always @* begin
        if(sel_o_2) begin
            if(eta == 2'b11) begin 
                x_o_2 = reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18];
                y_o_2 = reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
            else begin
                x_o_2 = reg_shake[0+12] + reg_shake[1+12];
                y_o_2 = reg_shake[2+12] + reg_shake[3+12];
                x_o_2_h = ~x_o_2;
                y_o_2_h = ~y_o_2;
            end
        end
        else begin
            x_o_2 = x_o_2;
            y_o_2 = y_o_2;
            x_o_2_h = ~x_o_2;
            y_o_2_h = ~y_o_2;
        end
    end
    
    /*
    wire [15:0] x_o_2;
    wire [15:0] y_o_2;
    assign x_o_2 = (eta == 2'b11) ? (reg_shake[0+18] + reg_shake[1+18] + reg_shake[2+18]) : (reg_shake[0+12] + reg_shake[1+12]);
    assign y_o_2 = (eta == 2'b11) ? (reg_shake[3+18] + reg_shake[4+18] + reg_shake[5+18]) : (reg_shake[2+12] + reg_shake[3+12]);
    wire [15:0] S_o_2;
    wire [15:0] d_o_2;
    assign S_o_2 = x_o_2 - y_o_2;
    assign d_o_2 = (S_o_2[15]) ? S_o_2 + Q : S_o_2;
    */
    (* DONT_TOUCH = "TRUE" *) reg [15:0] d_o_2, d_o_2_comp;
    always @* begin
        case({x_o_2[1:0],y_o_2[1:0]})
            4'b0000: d_o_2 = 16'h0000;
            4'b0001: d_o_2 = 16'h0d00;
            4'b0010: d_o_2 = 16'h0cff;
            4'b0011: d_o_2 = 16'h0cfe;
            4'b0100: d_o_2 = 16'h0001;
            4'b0101: d_o_2 = 16'h0000;
            4'b0110: d_o_2 = 16'h0d00;
            4'b0111: d_o_2 = 16'h0cff;
            4'b1000: d_o_2 = 16'h0002;
            4'b1001: d_o_2 = 16'h0001;
            4'b1010: d_o_2 = 16'h0000;
            4'b1011: d_o_2 = 16'h0d00;
            4'b1100: d_o_2 = 16'h0003;
            4'b1101: d_o_2 = 16'h0002;
            4'b1110: d_o_2 = 16'h0001;
            4'b1111: d_o_2 = 16'h0000;
        endcase
        
        d_o_2_comp = ~d_o_2; // Complementary operation
    end
    
    assign en_write = start;
    
    reg [7:0] ad_wr;
    always @(posedge clk) begin
        if(!rst)                                                    ad_wr <= 0;
        else begin
            if(start_clk & en_write & !end_op & (sel_s == 2'b11))   ad_wr <= ad_wr + 2;
            else                                                    ad_wr <= ad_wr;
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst | load | load_clk)                                                                              end_op <= 1'b0;
        else begin
            if(eta == 2'b10 & ad_wr == 126 & (sel_s == 2'b10))                                                  end_op <= 1'b1;
       else if(eta == 2'b11 & ((ad_wr == 126 & (sel_s == 2'b10)) | (counter_shake == 44 & (sel_s == 2'b11))))   end_op <= 1'b1;
            else                                                                                                end_op <= end_op;
        end
    
    end
    
    assign data_in_1 = {d_o_1[11:0], d_e_1[11:0]};
    assign data_in_2 = {d_o_2[11:0], d_e_2[11:0]};
    
    assign addr_1   = ad_wr;
    assign addr_2   = ad_wr + 1;   
endmodule