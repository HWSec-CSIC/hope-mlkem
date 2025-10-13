`timescale 1ns / 1ps

// ping-pong design -> change every stage

module BUTTERFLY_UNIT (
    input           clk,
    input           rst,
    input           start,
    input   [3:0]   mode,
    output          end_op,
    output          enable_ram_0,
    output          enable_ram_1,
    output  [7:0]   addr_1_r0,
    output  [7:0]   addr_2_r0,
    output  [7:0]   addr_1_r1,
    output  [7:0]   addr_2_r1,
    input   [23:0]  data_in_1_r0,
    input   [23:0]  data_in_2_r0,
    input   [23:0]  data_in_1_r1,
    input   [23:0]  data_in_2_r1,
    output  [23:0]  data_out_1_r0,
    output  [23:0]  data_out_2_r0,
    output  [23:0]  data_out_1_r1,
    output  [23:0]  data_out_2_r1
    );
    
    wire reset;
    wire ntt;
    wire intt;
    wire pwm;
    wire add;
    wire sub;
    
    assign reset    = (mode[2:0] == 3'b000) ? 1 : 0;
    assign ntt      = (mode[2:0] == 3'b001) ? 1 : 0;
    assign intt     = (mode[2:0] == 3'b010) ? 1 : 0;
    assign pwm      = (mode[2:0] == 3'b011) ? 1 : 0;
    assign add      = (mode[2:0] == 3'b100) ? 1 : 0;
    assign sub      = (mode[2:0] == 3'b101) ? 1 : 0;
    
    wire sel_ram; // read sel_ram (first mode[3]) normally, 0 and then 1
    
    // wire    [6:0]  addr_zeta;
    reg     [6:0]  addr_zeta;
    reg     [6:0]  addr_zeta_1;
    reg     [11:0] zeta;
    wire    [35:0] do_zeta;
    
    // --- mem zetas --- //
    MEM_ZETAS_COMPLETE 
    MEM_ZETAS_COMPLETE (
    .clk            (   clk         ), 
    // .addr_zeta      (   addr_zeta   ), 
    .addr_zeta      (   addr_zeta_1  ), 
    .data_out_zeta  (   do_zeta     )
    );
    
    always @* begin
        if(ntt)         zeta = do_zeta[11:0];
        else if(intt)   zeta = do_zeta[23:12];
        else            zeta = do_zeta[35:24];
    end
    
    // ---- BU ---- //
    wire [11:0] a0, a1;
    wire [11:0] b0, b1;
    wire [11:0] h0, h1;
    wire [11:0] h2, h3;
    
    wire [11:0] as_in_a00, as_in_a01;
    wire [11:0] as_in_a10, as_in_a11;
    wire [11:0] as_in_b00, as_in_b01;
    wire [11:0] as_in_b10, as_in_b11;
    wire [11:0] as_out_h00, as_out_h01;
    wire [11:0] as_out_h10, as_out_h11;
    
    NTT_PWM_PIPE NTT_PWM_PIPE
     (
    .clk        (   clk             ),
    .mode       (   mode[2:0]       ),
    .a0         (   a0              ),
    .a1         (   a1              ),
    .b0         (   b0              ),
    .b1         (   b1              ),
    .h0         (   h0              ),
    .h1         (   h1              ),
    .h2         (   h2              ),
    .h3         (   h3              ),
    .zeta       (   zeta            ),
    .as_in_a00  (   as_in_a00       ),
    .as_in_a01  (   as_in_a01       ),
    .as_in_a10  (   as_in_a10       ),
    .as_in_a11  (   as_in_a11       ),
    .as_in_b00  (   as_in_b00       ),
    .as_in_b01  (   as_in_b01       ),
    .as_in_b10  (   as_in_b10       ),
    .as_in_b11  (   as_in_b11       ),
    .as_out_h00 (   as_out_h00      ),
    .as_out_h01 (   as_out_h01      ),
    .as_out_h10 (   as_out_h10      ),
    .as_out_h11 (   as_out_h11      )
    );
    
    assign a0  = (sel_ram) ? data_in_1_r1[11:0]     :   data_in_1_r0[11:0];
    assign b0  = (sel_ram) ? data_in_2_r1[11:0]     :   data_in_2_r0[11:0];
    assign a1  = (sel_ram) ? data_in_1_r1[23:12]    :   data_in_1_r0[23:12];
    assign b1  = (sel_ram) ? data_in_2_r1[23:12]    :   data_in_2_r0[23:12];
    
    assign as_in_a00 = data_in_1_r0[11:00];
    assign as_in_a01 = data_in_1_r0[23:12];
    assign as_in_a10 = data_in_2_r0[11:00];
    assign as_in_a11 = data_in_2_r0[23:12];
    
    assign as_in_b00 = data_in_1_r1[11:00];
    assign as_in_b01 = data_in_1_r1[23:12];
    assign as_in_b10 = data_in_2_r1[11:00];
    assign as_in_b11 = data_in_2_r1[23:12];
    
    // data out
    assign data_out_1_r0 = (add | sub) ? {as_out_h01, as_out_h00} : ((pwm) ? {h1, h0} : {h2, h0});
    assign data_out_1_r1 = (add | sub) ? {as_out_h01, as_out_h00} : ((pwm) ? {h1, h0} : {h2, h0});
    assign data_out_2_r0 = (add | sub) ? {as_out_h11, as_out_h10} : {h3, h1};
    assign data_out_2_r1 = (add | sub) ? {as_out_h11, as_out_h10} : {h3, h1};
    
    // --------------------
    // gen addresses module
    // --------------------
    
    wire [7:0] j;
    wire [7:0] len;
    wire [7:0] k;
    wire end_add;
    gen_add gen_add 
    (   .clk        (   clk             ),
        .rst        (   rst & !reset    ),
        .start      (   start           ),
        .mode       (   mode            ),
        .end_op     (   end_add         ),
        .j          (   j               ),
        .len        (   len             ),
        .k          (   k               ),
        .sel_ram    (   sel_ram         )
    );
    
    assign enable_ram_0     =   ( sel_ram & start & !end_op & !reset) ? 1 : 0; // write in 0 when sel_ram = 1
    assign enable_ram_1     =   (~sel_ram & start & !end_op & !reset) ? 1 : 0; // write in 1 when sel_ram = 0
    
    
    // ---- pipeline stage ---- //
    reg [7:0]  j_pipe_1, j_pipe_2, j_pipe_3, j_pipe_4, j_pipe_5, j_pipe_6, j_pipe_7, j_pipe_8, j_pipe_9, j_pipe_10, j_pipe_11, j_pipe_12;
    reg [7:0]  jlen_pipe_1, jlen_pipe_2, jlen_pipe_3, jlen_pipe_4, jlen_pipe_5, jlen_pipe_6, jlen_pipe_7, jlen_pipe_8, jlen_pipe_9, jlen_pipe_10, jlen_pipe_11, jlen_pipe_12;
    always @(posedge clk) begin
        if(reset) begin
        j_pipe_1    <=  0;
        j_pipe_2    <=  0;
        j_pipe_3    <=  0;
        j_pipe_4    <=  0;
        j_pipe_5    <=  0;
        j_pipe_6    <=  0;
        j_pipe_7    <=  0;
        j_pipe_8    <=  0;
        j_pipe_9    <=  0;
        j_pipe_10   <=  0;
        j_pipe_11   <=  0;
        j_pipe_12   <=  0;
        
        jlen_pipe_1     <= len;
        jlen_pipe_2     <= len;
        jlen_pipe_3     <= len;
        jlen_pipe_4     <= len;
        jlen_pipe_5     <= len;
        jlen_pipe_6     <= len;
        jlen_pipe_7     <= len;
        jlen_pipe_8     <= len;
        jlen_pipe_9     <= len;
        jlen_pipe_10    <= len;
        jlen_pipe_11    <= len;
        jlen_pipe_12    <= len;
        
        end
        else begin
        j_pipe_1    <=  j;
        j_pipe_2    <=  j_pipe_1;
        j_pipe_3    <=  j_pipe_2;
        j_pipe_4    <=  j_pipe_3;
        j_pipe_5    <=  j_pipe_4;
        j_pipe_6    <=  j_pipe_5;
        j_pipe_7    <=  j_pipe_6;
        j_pipe_8    <=  j_pipe_7;
        j_pipe_9    <=  j_pipe_8;
        j_pipe_10   <=  j_pipe_9;
        j_pipe_11   <=  j_pipe_10;
        j_pipe_12   <=  j_pipe_11;
        
        jlen_pipe_1     <= j + len;
        jlen_pipe_2     <= jlen_pipe_1;
        jlen_pipe_3     <= jlen_pipe_2;
        jlen_pipe_4     <= jlen_pipe_3;
        jlen_pipe_5     <= jlen_pipe_4;
        jlen_pipe_6     <= jlen_pipe_5;
        jlen_pipe_7     <= jlen_pipe_6;
        jlen_pipe_8     <= jlen_pipe_7;
        jlen_pipe_9     <= jlen_pipe_8;
        jlen_pipe_10    <= jlen_pipe_9;
        jlen_pipe_11    <= jlen_pipe_10;
        jlen_pipe_12    <= jlen_pipe_11;
        end
    end
    
    reg end_op_1, end_op_2, end_op_3, end_op_4, end_op_5, end_op_6, end_op_7, end_op_8, end_op_9, end_op_10, end_op_11, end_op_12;
    always @(posedge clk) begin
        if(reset) begin
            end_op_1    <= 0;
            end_op_2    <= 0;
            end_op_3    <= 0;
            end_op_4    <= 0;
            end_op_5    <= 0;
            end_op_6    <= 0;
            end_op_7    <= 0;
            end_op_8    <= 0;
            end_op_9    <= 0;
            end_op_10   <= 0;
            end_op_11   <= 0;
            end_op_12   <= 0;
        end
        else begin
            end_op_1    <= end_add;
            end_op_2    <= end_op_1;
            end_op_3    <= end_op_2;
            end_op_4    <= end_op_3;
            end_op_5    <= end_op_4;
            end_op_6    <= end_op_5;
            end_op_7    <= end_op_6;
            end_op_8    <= end_op_7;
            end_op_9    <= end_op_8;
            end_op_10   <= end_op_9;
            end_op_11   <= end_op_10;
            end_op_12   <= end_op_11;
        end
    end
    
    
    // --- assignations --- //
    assign end_op = (add | sub) ? end_op_5 : end_op_12;
    
    always @(posedge clk)  begin 
        addr_zeta       <= k[6:0];
        addr_zeta_1     <= addr_zeta;
    end
    
    assign addr_1_r0        = (~sel_ram) ? j        : ( (add | sub) ? j_pipe_5 : j_pipe_12 );
    assign addr_2_r0        = (~sel_ram) ? j + len  : ( (add | sub) ? jlen_pipe_5 : jlen_pipe_12 );
    assign addr_1_r1        = ( sel_ram) ? j        : ( (add | sub) ? j_pipe_5 : j_pipe_12 );
    assign addr_2_r1        = ( sel_ram) ? j + len  : ( (add | sub) ? jlen_pipe_5 : jlen_pipe_12 );
endmodule


module gen_add #(
    parameter N = 128
    )(
    input               clk,
    input               rst,
    input               start,
    input   [3:0]       mode,
    output  reg         end_op,
    output  reg [7:0]       j,
    output  reg [7:0]       len,
    output  reg [7:0]       k,
    output  reg             sel_ram
    );
    
    wire reset;
    wire ntt;
    wire intt;
    wire pwm;
    wire add;
    wire sub;
    
    assign reset    = (mode[2:0] == 3'b000) ? 1 : 0;
    assign ntt      = (mode[2:0] == 3'b001) ? 1 : 0;
    assign intt     = (mode[2:0] == 3'b010) ? 1 : 0;
    assign pwm      = (mode[2:0] == 3'b011) ? 1 : 0;
    assign add      = (mode[2:0] == 3'b100) ? 1 : 0;
    assign sub      = (mode[2:0] == 3'b101) ? 1 : 0;
    
    reg start_pipe;
    reg end_pipe;
    reg [3:0] pipe;
    
    reg [7:0] counter_j;
    
    always @(posedge clk) begin
        if(!rst | !start | end_op) begin
            if(ntt) begin
                j           <= 0;
                len         <= 64; // 128
                k           <= 1;
                sel_ram     <= mode[3];
                start_pipe  <= 0;
                counter_j   <= 0;
            end
            else if(intt) begin
                j           <= 0;
                len         <= 1;
                k           <= 1;
                sel_ram     <= mode[3];
                start_pipe  <= 0;
                counter_j   <= 0;
            end
            else if(pwm) begin
                j           <= 0;
                len         <= 1; // to avoid to write in the same address in the RAM
                k           <= 0;
                sel_ram     <= mode[3];
                start_pipe  <= 0;
                counter_j   <= 0;
            end
            else if(add | sub) begin
                j           <= 0;
                len         <= 1;
                k           <= 0;
                sel_ram     <= mode[3];
                start_pipe  <= 0;
                counter_j   <= 0;
            end
            else begin
                j           <= 0;
                len         <= 1; // to avoid to write in the same address in the RAM
                k           <= 0;
                sel_ram     <= mode[3];
                start_pipe  <= 0;
                counter_j   <= 0;
            end
            
        end
        else begin
            if(ntt) begin
                if (start_pipe & !end_pipe) begin
                    j           <=  j;
                    len         <=  len;
                    k           <=  k;
                    sel_ram     <=  sel_ram;
                    start_pipe  <=  start_pipe;
                    counter_j   <= 0;
                end
                else if (start_pipe & end_pipe) begin
                    j           <=  j;
                    len         <=  len;
                    k           <=  k;
                    sel_ram     <=  ~sel_ram;
                    start_pipe  <=  0;
                    counter_j   <=  0;
                end
                else if      ((j + len) ==  (N-1) )              begin
                    j           <= 0;
                    len         <= len >> 1;
                    k           <= k + 1;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 1;
                    counter_j   <= 0;
                end 
                else if (counter_j == len - 1) begin
                    j           <= j + 1 + len;
                    len         <= len;
                    k           <= k + 1;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 0;
                    counter_j   <= 0;
                end
                else begin
                    j           <= j + 1;
                    len         <= len;
                    k           <= k;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 0;
                    counter_j   <= counter_j + 1;
                end
            end
            
            else if(intt) begin
                if (start_pipe & !end_pipe) begin
                    j           <=  j;
                    len         <=  len;
                    k           <=  k;
                    sel_ram     <=  sel_ram;
                    start_pipe  <=  start_pipe;
                    counter_j   <= 0;
                end
                else if (start_pipe & end_pipe) begin
                    j           <=  j;
                    len         <=  len;
                    k           <=  k;
                    sel_ram     <=  ~sel_ram;
                    start_pipe  <=  0;
                    counter_j   <=  0;
                end
                else if      ((j + len) ==  (N-1) )              begin
                    j           <= 0;
                    len         <= len << 1;
                    k           <= k + 1;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 1;
                    counter_j   <= 0;
                end 
                else if (counter_j == len - 1) begin
                    j           <= j + 1 + len;
                    len         <= len;
                    k           <= k + 1;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 0;
                    counter_j   <= 0;
                end
                else begin
                    j           <= j + 1;
                    len         <= len;
                    k           <= k;
                    sel_ram     <= sel_ram;
                    start_pipe  <= 0;
                    counter_j   <= counter_j + 1;
                end
            end
            
            else if(pwm) begin
                j           <= j + 1;
                len         <= len;
                k           <= k + 1;
                sel_ram     <= sel_ram;
                start_pipe  <= start_pipe;
            end
            
             else if(add | sub) begin
                j           <= j + 2;
                len         <= 1;
                k           <= k;
                sel_ram     <= sel_ram;
                start_pipe  <= start_pipe;
            end
            
            else begin
                j           <= j;
                len         <= len;
                k           <= k;
                sel_ram     <= sel_ram;
                start_pipe  <= start_pipe;
            
            end
        
        end
    
    end
    
    always @(posedge clk) begin
        if(!rst | reset | !start_pipe)  pipe <= 0;
        else                            pipe <= pipe + 1;
    end
    
    always @(posedge clk) begin
        if(!rst | reset | !start_pipe)  end_pipe <= 0;
        // else if(pipe == 4'b1000)        end_pipe <= 1;
        else if(pipe == 4'b1010)        end_pipe <= 1;
        else                            end_pipe <= end_pipe;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)                                end_op <= 0;
        else begin
            if(ntt) begin
                if(len == 8'h01 & (j + len) == (N-1))   end_op <= 1;
                else                                    end_op <= end_op;
            end
            else if(intt) begin
                if(len == 8'h40 & (j + len) == (N-1))   end_op <= 1;
                else                                    end_op <= end_op;
            end
            else if (pwm) begin
                if(j == 127)                            end_op <= 1;
                else                                    end_op <= end_op;
            end
            else begin
                if(j == 126)                            end_op <= 1;
                else                                    end_op <= end_op;
            end
        
        end
    
    end

endmodule


module NTT_PWM_PIPE(
    input           clk,
    input [2:0]     mode,
    input [11:0]    a0, // ntt -> even(j)
    input [11:0]    a1, // ntt -> odd(j)
    input [11:0]    b0, // ntt -> even(j+len)
    input [11:0]    b1, // ntt -> odd(j+len)
    input [11:0]    zeta,
    output [11:0]   h0, // ntt -> even(j)
    output [11:0]   h1, // ntt -> even(j+len)
    output [11:0]   h2, // ntt -> odd(j)
    output [11:0]   h3, // ntt -> odd(j+len)
    
    // Only for ADD & SUB -> Reduce to 64 CCs
    input [11:0]    as_in_a00,
    input [11:0]    as_in_a01,
    input [11:0]    as_in_a10,
    input [11:0]    as_in_a11,
    input [11:0]    as_in_b00,
    input [11:0]    as_in_b01,
    input [11:0]    as_in_b10,
    input [11:0]    as_in_b11,
    output [11:0]    as_out_h00,
    output [11:0]    as_out_h01,
    output [11:0]    as_out_h10,
    output [11:0]    as_out_h11
    );
    
    // ---- NTT ---- //
    // 1 stage: 
    // fqmult_mod: b0 * z
    // fqmult_mod: b1 * z
    // 2 stage: 
    // fqmult_mod: mod_red(b0 * z) -> m0
    // fqmult_mod: mod_red(b1 * z) -> m1
    // 3 stage:
    // a + b*z / a - b*z
    
    // ---- INTT ---- //
    // 1 stage: 
    // add0 = (a0 + b0) mod q
    // sub0 = (a0 - b0) mod q
    // 2 stage
    // fqmult_mod: sub0 * z
    // fqmult_mod: sub1 * z
    // 3 stage: 
    // fqmult_mod: mod_red(sub0 * z) -> m0
    // fqmult_mod: mod_red(sub1 * z) -> m1
    // 3 stage:
    // ((a+b) << 1) / ((a - b) * z) << 1
    
    
    // ---- PWM ---- //
    // 1 stage: 
    // fqmult_mod: a0 * b0
    // fqmult_mod: a1 * b1
    // 2 stage: 
    // fqmult_mod: mod_red(a0 * b0) -> m0
    // fqmult_mod: mod_red(a1 * b1) -> m1
    // s0 = a0 + a1
    // m0 = a0 * b0
    // s1 = b0 + b1
    // m1 = a1 * b1
    // 3 stage
    // fqmult_mod: s0 * s1 = a0b0 + a0b1 + a1b0 + a1b1
    // fqmult_mod: m1 * z  = a1*b1*z
    // 4 stage
    // fqmult_mod: mod_red(s0 * s1)
    // fqmult_mod: mod_red(m1 * z) 
    // 5 stage
    // h0 = m0 + (m1*z)         = a0b0 + a1b1z
    // h1 = (s0*s1) - m0 - m1   = a0b0 + a0b1 + a1b0 + a1b1 - a0b0 - a1b1 = 
    //                          = a0b1 + a1b0
    
    wire reset;
    wire ntt;
    wire intt;
    wire pwm;
    wire add;
    wire sub;
    
    assign reset    = (mode[2:0] == 3'b000) ? 1 : 0;
    assign ntt      = (mode[2:0] == 3'b001) ? 1 : 0;
    assign intt     = (mode[2:0] == 3'b010) ? 1 : 0;
    assign pwm      = (mode[2:0] == 3'b011) ? 1 : 0;
    assign add      = (mode[2:0] == 3'b100) ? 1 : 0;
    assign sub      = (mode[2:0] == 3'b101) ? 1 : 0;
    
    reg [11:0] a0_reg;
    reg [11:0] a1_reg;
    reg [11:0] b0_reg;
    reg [11:0] b1_reg;
    
    always @(posedge clk) begin
        a0_reg <= (add | sub) ? as_in_a00 : a0;
        a1_reg <= (add | sub) ? as_in_a01 : a1;
        b0_reg <= (add | sub) ? as_in_b00 : b0;
        b1_reg <= (add | sub) ? as_in_b01 : b1;
    end
    
    reg sel_mux0, sel_mux1, sel_mux2, sel_mux3;
    reg sel_mux4, sel_mux5, sel_mux6, sel_mux7;
    
    reg [11:0] z1, z2, z3, z4;
    reg [11:0] zeta_reg;
    always @(posedge clk) begin
        zeta_reg    <= zeta;
        z1          <= zeta_reg;
        z2          <= z1;
        z3          <= z2;
        z4          <= z3;
    end
    
    // --------------------- //
    // --- Upper AU part --- //
    // --------------------- //
    
    // First MUX
    wire [11:0] add_0;
    wire [11:0] sub_0;
    wire [11:0] in_0, in_1;
    assign in_0 = (pwm) ? a0_reg : a0_reg;
    assign in_1 = (pwm) ? a1_reg : b0_reg;
    mod_add     mod_add_0 (.a(in_0), .b(in_1), .c(add_0));
    mod_sub     mod_sub_0 (.a(in_0), .b(in_1), .c(sub_0));
    
    reg [11:0] mux0, mux1;
    always @* begin
        if(sel_mux0)    mux0 = add_0;
        else            mux0 = in_0;
        
        if(sel_mux1)    mux1 = sub_0;
        else            mux1 = in_1;
    end
    
    // 1 Stage
    reg [11:0] reg_u01, reg_u11;
    always @(posedge clk) begin
        reg_u01 <= mux0;
        reg_u11 <= mux1;
    end
    
    // 2 - 4  Stage
    wire    [11:0]  m0_wire;
    reg     [11:0]  reg_u02, reg_u03, reg_u04, reg_u14;
    reg     [11:0]  in_fq0;
    fqmult_mod fqmult0  (.clk(clk), .a(reg_u11),  .b(in_fq0),      .t(m0_wire));
    always @(posedge clk) begin
        reg_u02 <= reg_u01;
        reg_u03 <= reg_u02;
        reg_u04 <= (add | sub) ? as_in_a10 : reg_u03;
        reg_u14 <= (add | sub) ? as_in_b10 : m0_wire;
    end
    
    // 5 Stage NTT/INTT
    // Second MUX
    wire [11:0] add_1;
    wire [11:0] sub_1;
    mod_add     mod_add_1 (.a(reg_u04), .b(reg_u14), .c(add_1));
    mod_sub     mod_sub_1 (.a(reg_u04), .b(reg_u14), .c(sub_1));
    
    reg [11:0] mux2, mux3;
    always @* begin
        if(sel_mux2)    mux2 = add_1;
        else            mux2 = (reg_u04[0]) ? ((reg_u04 >> 1) + 1665) : ((reg_u04 >> 1)); // Div2
        
        if(sel_mux3)    mux3 = sub_1;
        else            mux3 = (reg_u14[0]) ? ((reg_u14 >> 1) + 1665) : ((reg_u14 >> 1)); // Div2
    end
    
    reg [11:0] reg_u05, reg_u15;
    always @(posedge clk) begin
        reg_u05 <= mux2;
        reg_u15 <= mux3;
    end
    
    // 6 - 8 Stages
    reg [11:0] reg_u06, reg_u16;
    reg [11:0] reg_u07, reg_u17;
    reg [11:0] reg_u08, reg_u18;
    always @(posedge clk) begin
        reg_u06 <= reg_u05;
        reg_u07 <= reg_u06;
        reg_u08 <= reg_u07;
        reg_u16 <= reg_u15;
        reg_u17 <= reg_u16;
        reg_u18 <= reg_u17;
    end
    
    
    // --------------------- //
    // --- Lower AU part --- //
    // --------------------- //
    
    // First MUX
    wire [11:0] add_2;
    wire [11:0] sub_2;
    wire [11:0] in_2, in_3;
    assign in_2 = (pwm) ? b1_reg : a1_reg;
    assign in_3 = (pwm) ? b0_reg : b1_reg;
    mod_add     mod_add_2 (.a(in_2), .b(in_3), .c(add_2));
    mod_sub     mod_sub_2 (.a(in_2), .b(in_3), .c(sub_2));
    
    reg [11:0] mux4, mux5;
    always @* begin
        if(sel_mux4)    mux4 = add_2;
        else            mux4 = in_2;
        
        if(sel_mux5)    mux5 = sub_2;
        else            mux5 = in_3;
    end
    
    // 1 Stage
    reg [11:0] reg_l01, reg_l11;
    always @(posedge clk) begin
        reg_l01 <= mux4;
        reg_l11 <= mux5;
    end
    
    // 2 - 4  Stage
    wire    [11:0]  m1_wire;
    reg     [11:0]  reg_l02, reg_l03, reg_l04, reg_l14;
    reg     [11:0]  in_fq1;
    fqmult_mod fqmult1  (.clk(clk), .a(reg_l11),  .b(in_fq1),      .t(m1_wire));
    always @(posedge clk) begin
        reg_l02 <= reg_l01;
        reg_l03 <= reg_l02;
        reg_l04 <= (add | sub) ? as_in_a11 : reg_l03;
        reg_l14 <= (add | sub) ? as_in_b11 : m1_wire;
    end
    
    // 5 Stage NTT/INTT
    // Second MUX
    wire [11:0] add_3;
    wire [11:0] sub_3;
    mod_add     mod_add_3 (.a(reg_l04), .b(reg_l14), .c(add_3));
    mod_sub     mod_sub_3 (.a(reg_l04), .b(reg_l14), .c(sub_3));
    
    reg [11:0] mux6, mux7;
    always @* begin
        if(sel_mux6)    mux6 = add_3;
        else            mux6 = (reg_l04[0]) ? ((reg_l04 >> 1) + 1665) : ((reg_l04 >> 1)); // Div2
        
        if(sel_mux7)    mux7 = sub_3;
        else            mux7 = (reg_l14[0]) ? ((reg_l14 >> 1) + 1665) : ((reg_l14 >> 1)); // Div2
    end
    
    reg [11:0] reg_l05, reg_l15;
    always @(posedge clk) begin
        reg_l05 <= mux6;
        reg_l15 <= mux7;
    end
    
    // 6 - 8 Stages
    reg [11:0] reg_l06, reg_l16;
    reg [11:0] reg_l07, reg_l17;
    reg [11:0] reg_l08, reg_l18;
    always @(posedge clk) begin
        reg_l06 <= reg_l05;
        reg_l07 <= reg_l06;
        reg_l08 <= reg_l07;
        reg_l16 <= reg_l15;
        reg_l17 <= reg_l16;
        reg_l18 <= reg_l17;
    end
    
    // ---------------- //
    // ----- PWM ------ //
    // ---------------- //
    // 5-7 Stage PWM
    wire [11:0] m2_wire;
    fqmult_mod fqmult2  (.clk(clk), .a(reg_u04),  .b(reg_l04),      .t(m2_wire)); // s0 * s1
    wire [11:0] m3_wire;
    fqmult_mod fqmult3  (.clk(clk), .a(reg_u14),  .b(z4),           .t(m3_wire)); // m1 * z
    
    wire [11:0] add_4;
    reg  [11:0] reg_m5, reg_m6, reg_m7; 
    reg  [11:0] reg_p5, reg_p6, reg_p70, reg_p71, reg_p72;
    mod_add     mod_add_4 (.a(reg_u14), .b(reg_l14), .c(add_4));
    always @(posedge clk) begin
        reg_m5  <= reg_l14; // m0
        reg_m6  <= reg_m5; // m0
        reg_m7  <= reg_m6; // m0
        reg_p5  <= add_4; // m0 + m1
        reg_p6  <= reg_p5; // m0 + m1
        reg_p70 <= reg_p6;
        reg_p71 <= m2_wire;
        reg_p72 <= m3_wire;
    end
    // 8 Stage PWM
    wire [11:0] add_5, sub_4;
    mod_add     mod_add_5 (.a(reg_m7),  .b(reg_p72), .c(add_5)); // m0 + (m1*z)
    mod_sub     mod_sub_4 (.a(reg_p71), .b(reg_p70), .c(sub_4)); // (s0*s1) - (m0+m1)
    reg [11:0] reg_p80, reg_p81;
    always @(posedge clk) begin
        reg_p80 <= add_5;
        reg_p81 <= sub_4;
    end
    
    // --- Selection MUX --- //
    always @* begin
            if(ntt)     {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b1100_1100;
    else    if(intt)    {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b0011_0011;
    else    if(pwm)     {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b0001_0001;
    else    if(add)     {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b0101_0101;
    else    if(sub)     {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b1010_1010;
    else                {sel_mux7, sel_mux6, sel_mux5, sel_mux4, sel_mux3, sel_mux2, sel_mux1, sel_mux0} = 8'b0000_0000;
    end
    
    // --- Input fqmul sel --- //
    /*
    always @* begin
            if(ntt)     {in_fq1, in_fq0} = {z1,z1};
    else    if(intt)    {in_fq1, in_fq0} = {z1,z1};
    else                {in_fq1, in_fq0} = {fq1,fq0};
    end
    */
    
     always @(posedge clk) begin
            if(ntt)     {in_fq1, in_fq0} <= {zeta_reg,zeta_reg}; // zeta_reg
    else    if(intt)    {in_fq1, in_fq0} <= {zeta_reg,zeta_reg};
    else                {in_fq1, in_fq0} <= {a0_reg, b1_reg};
    end
    
    // --- Output selection --- //
    
    assign h0 = (pwm) ? reg_p80 : reg_u08;
    assign h1 = (pwm) ? reg_p81 : reg_u18;
    assign h2 = reg_l08;
    assign h3 = reg_l18;
    
    assign as_out_h00 = (add) ? reg_u01 : reg_u11;
    assign as_out_h01 = (add) ? reg_l01 : reg_l11;
    assign as_out_h10 = (add) ? reg_u05 : reg_u15;
    assign as_out_h11 = (add) ? reg_l05 : reg_l15;
    
endmodule