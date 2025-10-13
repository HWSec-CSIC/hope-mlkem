`timescale 1ns / 1ps

// ping-pong design -> change every stage

module BUTTERFLY_UNIT_MASKED (
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
    assign as_in_a10 = 0;
    assign as_in_a11 = 0;
    
    assign as_in_b00 = data_in_2_r0[11:00];
    assign as_in_b01 = data_in_2_r0[23:12];
    assign as_in_b10 = 0;
    assign as_in_b11 = 0;
    
    // data out
    assign data_out_1_r0 = (add | sub) ? {as_out_h01, as_out_h00} : ((pwm) ? {h1, h0} : {h2, h0});
    assign data_out_1_r1 = (add | sub) ? {as_out_h01, as_out_h00} : ((pwm) ? {h1, h0} : {h2, h0});
    assign data_out_2_r0 = (add | sub) ? {as_out_h01, as_out_h00} : {h3, h1};
    assign data_out_2_r1 = (add | sub) ? {as_out_h01, as_out_h00} : {h3, h1};
    
    // --------------------
    // gen addresses module
    // --------------------
    
    wire [7:0] j;
    wire [7:0] len;
    wire [7:0] k;
    wire end_add;
    gen_add_masked gen_add_masked 
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
    
    assign addr_1_r0        = (end_op | !start) ? 0 : ((~sel_ram) ? j        : ( (add | sub) ? j_pipe_5 : j_pipe_12 ));
    assign addr_2_r0        = (end_op | !start) ? 0 : ((~sel_ram) ? j + len  : ( (add | sub) ? jlen_pipe_5 : jlen_pipe_12 ));
    assign addr_1_r1        = (end_op | !start) ? 0 : (( sel_ram) ? j        : ( (add | sub) ? j_pipe_5 : j_pipe_12 ));
    assign addr_2_r1        = (end_op | !start) ? 0 : (( sel_ram) ? j + len  : ( (add | sub) ? jlen_pipe_5 : jlen_pipe_12 ));
endmodule


module gen_add_masked #(
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
                j           <= j + 1;
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
                if(j == 127)                            end_op <= 1;
                else                                    end_op <= end_op;
            end
        
        end
    
    end

endmodule

