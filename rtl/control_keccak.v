`timescale 1ns / 1ps

module CONTROL_KECCAK #(
    parameter MASKED = 0,
    parameter N_BU = 4
    )(
    input               clk,
    input               rst,
    input               start,
    input   [3:0]       mode,
    output  [11:0]      ctl_k,
    output  [7:0]       i,
    output  [7:0]       j,
    output reg          reset_cbd,
    output reg          reset_rej,
    output reg          load_cbd,
    output reg          load_rej,
    output reg          start_cbd,
    output reg          start_rej,
    output reg [1:0]    eta,
    output reg          scnd, 
    output reg          sel_rej,
    output  [34:0]      control_dmu_cbd,
    output  [15:0]      off_ram_cbd,
    output reg [3:0]    off_rej,
    input               end_op_cbd,
    input               end_op_rej,
    input               end_rd_rej,
    input               end_op_keccak,
    input   [3:0]       end_op_bu
    );
    
    localparam OFF_S    = 4'b0000;
	localparam OFF_E    = 4'b0001; // << 7 (128)
	
	localparam OFF_A00   = 4'b0000; // 0
	localparam OFF_A01   = 4'b0001; // 128
	localparam OFF_A02   = 4'b0010; // 256
	localparam OFF_A03   = 4'b0011; // 384
	
    localparam OFF_A10   = 4'b0100; // 512
	localparam OFF_A11   = 4'b0101; // 640
	localparam OFF_A12   = 4'b0110; // 768
	localparam OFF_A13   = 4'b0111; // 896
        
    reg [7:0] dmu1;
    reg [7:0] dmu2;
    reg [7:0] dmu3;
    reg [7:0] dmu4;
    
    assign control_dmu_cbd = {3'b000, dmu4, dmu3, dmu2, dmu1};
    
    reg reset_k;
    reg load_k;
    reg start_k;
    reg read_k;
    wire reset_gen;
    wire load_gen;
    wire start_gen;
    wire read_gen;
    reg [3:0] mode_gen;
    
    assign ctl_k = {mode_gen, read_gen, start_gen, load_gen, reset_gen, read_k, start_k, load_k, reset_k};
    assign read_gen     = 0;
    assign start_gen    = 0;
    assign load_gen     = 0;
    assign reset_gen    = 0;
    
    wire busy_cbd;
    wire busy_rej;
    
    assign busy_cbd = start_cbd & !end_op_cbd;
    assign busy_rej = start_rej & (!end_op_rej & !end_rd_rej);
    
    wire k_2;
    wire k_3;
    wire k_4;
    wire gen_keys;
    wire encap;
    wire decap;
    
    assign k_2          = (mode[1:0] == 2'b01) ? 1 : 0;
    assign k_3          = (mode[1:0] == 2'b10) ? 1 : 0;
    assign k_4          = (mode[1:0] == 2'b11) ? 1 : 0;
    assign gen_keys     = (mode[3:2] == 2'b01) ? 1 : 0;
    assign encap        = (mode[3:2] == 2'b10) ? 1 : 0;
    assign decap        = (mode[3:2] == 2'b11) ? 1 : 0;
    
    wire    [1:0]   op;
    reg     [7:0]   counter;
    wire    [3:0]   counter_end;
    reg     [7:0]   addr_mem;
    reg     [7:0]   off_mem;
    
    reg             busy_bu_cur;
    
    //--*** STATE declaration **--//
	localparam IDLE                = 4'h0; 
	localparam UPDATE_ADDR         = 4'h1;
	localparam UPDATE_DATA         = 4'h2;
	localparam LOAD_DATA_GEN_1     = 4'h3;
	localparam LOAD_DATA_GEN_2     = 4'h4;
	localparam LOAD_DATA_KECCAK_1  = 4'h5;
	localparam LOAD_DATA_KECCAK_2  = 4'h6;
	localparam START_KECCAK        = 4'h7;
	localparam IDLE_START          = 4'h8;
	localparam READ_KECCAK         = 4'h9; 
	localparam EVAL_COUNTER        = 4'hA; 
	localparam UPDATE_COUNTER      = 4'hB; 
	localparam IDLE_END_OP         = 4'hE; 
	localparam END_OP              = 4'hF;
	
	//--*** STATE register **--//
	reg [3:0] cs_h; // current_state
	reg [3:0] ns_h; // next_state
	
	//--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    
			     cs_h <= IDLE;
			else
			     cs_h <= ns_h;
		end
		
    //--*** STATE Transition **--//
	
	always @*
		begin
			case (cs_h)
				IDLE:
				   if (start)
				        ns_h = UPDATE_ADDR;
				   else
				        ns_h = IDLE;
				UPDATE_ADDR:
				    ns_h = UPDATE_DATA;
				UPDATE_DATA:
				    ns_h = LOAD_DATA_GEN_1;
				LOAD_DATA_GEN_1:
				    if(op == 2'b11 & !start_cbd)
				        ns_h = END_OP;
				    else if(op == 2'b11 & start_cbd)
				        ns_h = IDLE_END_OP;
				    else
				        ns_h = LOAD_DATA_GEN_2;
			    LOAD_DATA_GEN_2:
				    ns_h = LOAD_DATA_KECCAK_1;
				LOAD_DATA_KECCAK_1:
				    ns_h = LOAD_DATA_KECCAK_2;
				LOAD_DATA_KECCAK_2:
				    ns_h = START_KECCAK;
				START_KECCAK:
				    if(end_op_keccak)
				        ns_h = IDLE_START;
				    else if(end_op_rej)
				        ns_h = UPDATE_ADDR;
				    else
				        ns_h = START_KECCAK;
				IDLE_START:
				    if(op == 2'b00 & (busy_cbd))
				        ns_h = IDLE_START;
				    else if(op == 2'b01 & busy_rej)
				        ns_h = IDLE_START;
				    else if(op == 2'b10 & busy_rej)
				        ns_h = IDLE_START;
				    else
				        ns_h = READ_KECCAK;
				READ_KECCAK:
                    if(op == 2'b01 | op == 2'b10) begin
                        if(end_op_rej)
                            ns_h = UPDATE_ADDR;
                        else
                            ns_h = UPDATE_COUNTER; // It ends when end_op reachs
                    end
				    else
				        ns_h = EVAL_COUNTER; 
				EVAL_COUNTER: 
				    if(counter < counter_end)
				        ns_h = UPDATE_COUNTER;
				    else
				        ns_h = UPDATE_ADDR; 
				UPDATE_COUNTER:
				    ns_h = START_KECCAK;
				IDLE_END_OP:
				    if(end_op_cbd)
				        ns_h = END_OP;
				    else
				        ns_h = IDLE_END_OP;
				END_OP:
				        ns_h = END_OP;
				default:
					    ns_h = IDLE;
			endcase 		
		end 
    
    
    // --- signal control --- //
    wire [1:0] sel_se;
    wire [1:0] sel_ord;
    
    generate
        if(N_BU == 4 | MASKED) begin
            always @(posedge clk) begin
                if(!rst) begin
                    dmu1 <= 8'h0;
                    dmu2 <= 8'h0;
                    dmu3 <= 8'h0;
                    dmu4 <= 8'h0;
                end
                else begin
                    if(load_cbd & sel_ord == 2'b00) dmu1 <= 8'h1;
                    else if(reset_cbd)              dmu1 <= 8'h0;
                    else                            dmu1 <= dmu1;
                    
                    if(load_cbd & sel_ord == 2'b01) dmu2 <= 8'h1;
                    else if(reset_cbd)              dmu2 <= 8'h0;
                    else                            dmu2 <= dmu2;
                    
                    if(load_cbd & sel_ord == 2'b10) dmu3 <= 8'h1;
                    else if(reset_cbd)              dmu3 <= 8'h0;
                    else                            dmu3 <= dmu3;
                    
                    if(load_cbd & sel_ord == 2'b11) dmu4 <= 8'h1;
                    else if(reset_cbd)              dmu4 <= 8'h0;
                    else                            dmu4 <= dmu4;
                    
                end
            end
        end
        else if(N_BU == 2) begin
            always @(posedge clk) begin
                if(!rst) begin
                    dmu1 <= 8'h0;
                    dmu2 <= 8'h0;
                    dmu3 <= 8'h0;
                    dmu4 <= 8'h0;
                end
                else begin
                    if(load_cbd & sel_ord == 2'b00) dmu1 <= 8'h1;
                    else if(reset_cbd)              dmu1 <= 8'h0;
                    else                            dmu1 <= dmu1;
                    
                    if(load_cbd & sel_ord == 2'b01) dmu2 <= 8'h1;
                    else if(reset_cbd)              dmu2 <= 8'h0;
                    else                            dmu2 <= dmu2;
                    
                end
            end
        end
        else begin
            always @(posedge clk) begin
                if(!rst) begin
                    dmu1 <= 8'h0;
                    dmu2 <= 8'h0;
                    dmu3 <= 8'h0;
                    dmu4 <= 8'h0;
                end
                else begin
                    if(load_cbd)                    dmu1 <= 8'h1;
                    else if(reset_cbd)              dmu1 <= 8'h0;
                    else                            dmu1 <= dmu1;
                end
            end
        
        end
    endgenerate
    
    wire [1:0] eta_op;
    reg scnd_op;
    wire sel_seed;
    
    always @(posedge clk) begin
        if(!rst)                                                    mode_gen <= 4'h0;
        else begin  
                    if(cs_h == LOAD_DATA_GEN_1 & sel_seed == 1'b0)  mode_gen <= 4'h2;
            else    if(cs_h == LOAD_DATA_GEN_1 & sel_seed == 1'b1)  mode_gen <= 4'h3;
            else                                                    mode_gen <= mode_gen;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                        eta <= 2'b00;
        else begin  
            if(op == 2'b00 & load_cbd)  eta <= eta_op;
            else                        eta <= eta;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                scnd_op <= 1'b0;
        else begin  
            if(op == 2'b00 & counter == 8'h01)  scnd_op <= 1'b1;
            else                                scnd_op <= 1'b0;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                scnd <= 1'b0;
        else begin  
            if(scnd_op & end_op_cbd)            scnd <= 1'b1;
            else if(!scnd_op & end_op_cbd)      scnd <= 1'b0;
            else                                scnd <= scnd;
        end
    end
    
    // --- Control CBD --- //
    
    always @(posedge clk) begin
        if(!rst | reset_cbd)                        reset_cbd <= 1'b0;
        else begin
            if(!scnd_op & end_op_cbd)               reset_cbd <= 1'b1;
            else                                    reset_cbd <= reset_cbd;
        end
    end
    
    
    always @(posedge clk) begin
        if(!rst | load_cbd)                         load_cbd <= 1'b0;
        else begin
            if(cs_h == READ_KECCAK & op == 2'b00)   load_cbd <= 1'b1;
            else                                    load_cbd <= load_cbd;
        end
    end
    
    always @(posedge clk) begin
        if(!rst)                                            start_cbd <= 1'b0;
        else begin
            if(cs_h == READ_KECCAK & op == 2'b00)           start_cbd <= 1'b0;
            else if(load_cbd)                               start_cbd <= 1'b1;
            else if(end_op_cbd)                             start_cbd <= 1'b0;
            else                                            start_cbd <= start_cbd;
        end
    end
    
    
    
    // --- Control REJ SAMPLE --- //
    
    always @(posedge clk) begin
        if(!rst | reset_rej)                                    reset_rej <= 1'b0;
        else begin
            if(counter == 2'b00 & (end_op_rej | end_rd_rej))    reset_rej <= 1'b1;
            else                                                reset_rej <= reset_rej;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | load_rej | end_op_rej)                            load_rej <= 1'b0;
        else begin
            if(cs_h == READ_KECCAK & (op == 2'b01 | op == 2'b10))   load_rej <= 1'b1;
            else                                                    load_rej <= load_rej;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | (end_op_rej | end_rd_rej))         start_rej <= 1'b0;
        else begin                                   
            if(load_rej)                             start_rej <= 1'b1;
            else                                     start_rej <= start_rej;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | (end_op_rej | end_rd_rej))                 sel_rej <= 1'b0;
        else begin                                   
                    if(load_rej & op == 2'b01)               sel_rej    <= 1'b0; // RAM 0 & 1
            else    if(load_rej & op == 2'b10)               sel_rej    <= 1'b1; // RAM 2 & 3
            else                                             sel_rej    <= sel_rej;
        end
    end
   
   
  // --- Offset Selection --- //
    assign sel_se  = j[1:0];
    assign sel_ord = j[3:2];
    
    wire extra_off;

    generate 

        if(MASKED) begin
            reg [3:0] off_ram;
            assign off_ram_cbd = {off_ram, off_ram, off_ram, off_ram};
    
            always @(posedge clk) begin
            if(!rst)                              off_ram <= 0;
            else begin
                if(op == 2'b00 & load_cbd) begin
                    case({extra_off, sel_se})
                        3'b000: off_ram <= 4'b0000;
                        3'b001: off_ram <= 4'b0001;
                        3'b010: off_ram <= 4'b0010;
                        3'b011: off_ram <= 4'b0011;
                        3'b100: off_ram <= 4'b0100;
                        3'b101: off_ram <= 4'b0101;
                        3'b110: off_ram <= 4'b0110;
                        3'b111: off_ram <= 4'b0111;
                    endcase
                end
                else                              off_ram <= off_ram;
            end
            end
        end
    
        else begin
            if(N_BU == 4) begin
                reg [3:0] off_ram_1;
                reg [3:0] off_ram_2;
                reg [3:0] off_ram_3;
                reg [3:0] off_ram_4;
                assign off_ram_cbd = {off_ram_4, off_ram_3, off_ram_2, off_ram_1};
                
                
                
                always @(posedge clk) begin
                if(!rst)                              off_ram_1 <= 0;
                else begin
                    if(sel_ord == 2'b00 & op == 2'b00 & load_cbd) begin
                                if(sel_se == 2'b00)     off_ram_1 <= 4'b0000;
                        else  if(sel_se == 2'b01)     off_ram_1 <= 4'b0001;
                        else  if(sel_se == 2'b10)     off_ram_1 <= 4'b0010;
                        else                          off_ram_1 <= 4'b0011;
                    end
                    else                              off_ram_1 <= off_ram_1;
                end
                end
                
                always @(posedge clk) begin
                if(!rst)                        off_ram_2 <= 0;
                else begin
                    if(sel_ord == 2'b01 & op == 2'b00 & load_cbd) begin
                                if(sel_se == 2'b00)     off_ram_2 <= 4'b0000;
                        else  if(sel_se == 2'b01)     off_ram_2 <= 4'b0001;
                        else  if(sel_se == 2'b10)     off_ram_2 <= 4'b0010;
                        else                          off_ram_2 <= 4'b0011;
                    end
                    else                        off_ram_2 <= off_ram_2;
                end
                end
                
                always @(posedge clk) begin
                if(!rst)                        off_ram_3 <= 0;
                else begin
                    if(sel_ord == 2'b10 & op == 2'b00 & load_cbd) begin
                                if(sel_se == 2'b00)     off_ram_3 <= 4'b0000;
                        else  if(sel_se == 2'b01)     off_ram_3 <= 4'b0001;
                        else  if(sel_se == 2'b10)     off_ram_3 <= 4'b0010;
                        else                          off_ram_3 <= 4'b0011;
                    end
                    else                        off_ram_3 <= off_ram_3;
                end
                end
                
                always @(posedge clk) begin
                if(!rst)                        off_ram_4 <= 0;
                else begin
                    if(sel_ord == 2'b11 & op == 2'b00 & load_cbd) begin
                                if(sel_se == 2'b00)     off_ram_4 <= 4'b0000;
                        else  if(sel_se == 2'b01)     off_ram_4 <= 4'b0001;
                        else  if(sel_se == 2'b10)     off_ram_4 <= 4'b0010;
                        else                          off_ram_4 <= 4'b0011;
                    end
                    else                        off_ram_4 <= off_ram_4;
                end
                end
            end
            else if(N_BU == 2) begin
                reg [3:0] off_ram_1;
                reg [3:0] off_ram_2;
                assign off_ram_cbd = {4'h0, 4'h0, off_ram_2, off_ram_1};
                
                always @(posedge clk) begin
                if(!rst)                              off_ram_1 <= 0;
                else begin
                    if(sel_ord == 2'b00 & op == 2'b00 & load_cbd) begin
                        case({extra_off, sel_se})
                        3'b000: off_ram_1 <= 4'b0000;
                        3'b001: off_ram_1 <= 4'b0001;
                        3'b010: off_ram_1 <= 4'b0010;
                        3'b011: off_ram_1 <= 4'b0011;
                        3'b100: off_ram_1 <= 4'b0100;
                        3'b101: off_ram_1 <= 4'b0101;
                        3'b110: off_ram_1 <= 4'b0110;
                        3'b111: off_ram_1 <= 4'b0111;
                        endcase
                    end
                    else                              off_ram_1 <= off_ram_1;
                end
                end
                
                always @(posedge clk) begin
                if(!rst)                        off_ram_2 <= 0;
                else begin
                    if(sel_ord == 2'b01 & op == 2'b00 & load_cbd) begin
                        case({extra_off, sel_se})
                        3'b000: off_ram_2 <= 4'b0000;
                        3'b001: off_ram_2 <= 4'b0001;
                        3'b010: off_ram_2 <= 4'b0010;
                        3'b011: off_ram_2 <= 4'b0011;
                        3'b100: off_ram_2 <= 4'b0100;
                        3'b101: off_ram_2 <= 4'b0101;
                        3'b110: off_ram_2 <= 4'b0110;
                        3'b111: off_ram_2 <= 4'b0111;
                        endcase
                    end
                    else                        off_ram_2 <= off_ram_2;
                end
                end
            end
            else begin
                reg [3:0] off_ram_1;
                assign off_ram_cbd = {4'h0, 4'h0, 4'h0, off_ram_1};
                
                always @(posedge clk) begin
                if(!rst)                              off_ram_1 <= 0;
                else begin
                    if(op == 2'b00 & load_cbd) begin
                        case({extra_off, sel_se})
                        3'b000: off_ram_1 <= 4'b0000;
                        3'b001: off_ram_1 <= 4'b0001;
                        3'b010: off_ram_1 <= 4'b0010;
                        3'b011: off_ram_1 <= 4'b0011;
                        3'b100: off_ram_1 <= 4'b0100;
                        3'b101: off_ram_1 <= 4'b0101;
                        3'b110: off_ram_1 <= 4'b0110;
                        3'b111: off_ram_1 <= 4'b0111;
                        endcase
                    end
                    else                              off_ram_1 <= off_ram_1;
                end
                end

            end
        end
    
    endgenerate


    wire [2:0] sel_off_rej = (gen_keys) ? {j[0],i[1:0]} : {i[0], j[1:0]};
    
    always @(posedge clk) begin
      if(!rst)                        off_rej <= 0;
      else begin
          if(end_op_keccak & (op == 2'b01 | op == 2'b10)) begin
                case(sel_off_rej)
                    3'b000: off_rej <= OFF_A00;
                    3'b001: off_rej <= OFF_A01;
                    3'b010: off_rej <= OFF_A02;
                    3'b011: off_rej <= OFF_A03;
                    3'b100: off_rej <= OFF_A10;
                    3'b101: off_rej <= OFF_A11;
                    3'b110: off_rej <= OFF_A12;
                    3'b111: off_rej <= OFF_A13;
                endcase
          end
          else              off_rej <= off_rej;
      end
    end
    
    
    // --- Prog control --- //
    
    always @(posedge clk) begin
        if(!rst | cs_h == UPDATE_ADDR)  counter <= 0;
        else if(cs_h == UPDATE_COUNTER) counter <= counter + 1;
        else                            counter <= counter;
    end
    
    always @(posedge clk) begin
        if(!rst)                        addr_mem <= 0;
        else if(cs_h == IDLE & start)   addr_mem <= off_mem;
        else if(cs_h == UPDATE_ADDR)    addr_mem <= addr_mem + 1;
        else                            addr_mem <= addr_mem;
    end
    
    generate 
        if(MASKED) begin
            always @(posedge clk) begin
                if(!rst)                        off_mem <= 0;
                else if(k_2 & gen_keys)         off_mem <= 0;
                else if(k_3 & gen_keys)         off_mem <= 9;
                else if(k_4 & gen_keys)         off_mem <= 25;
                else if(k_2 & encap)            off_mem <= 50;
                else if(k_3 & encap)            off_mem <= 62;
                else if(k_4 & encap)            off_mem <= 79;
                else if(k_2 & decap)            off_mem <= 121;
                else if(k_3 & decap)            off_mem <= 121;
                else if(k_4 & decap)            off_mem <= 121;
                else                            off_mem <= 0;
            end
        end
        else begin
            if(N_BU == 4) begin
                always @(posedge clk) begin
                    if(!rst)                        off_mem <= 0;
                    else if(k_2 & gen_keys)         off_mem <= 0;
                    else if(k_3 & gen_keys)         off_mem <= 9;
                    else if(k_4 & gen_keys)         off_mem <= 25;
                    else if(k_2 & encap)            off_mem <= 50;
                    else if(k_3 & encap)            off_mem <= 62;
                    else if(k_4 & encap)            off_mem <= 79;
                    else if(k_2 & decap)            off_mem <= 105;
                    else if(k_3 & decap)            off_mem <= 105;
                    else if(k_4 & decap)            off_mem <= 105;
                    else                            off_mem <= 0;
                end
            end
            else if(N_BU == 2) begin
                always @(posedge clk) begin
                    if(!rst)                        off_mem <= 0;
                    else if(k_2 & gen_keys)         off_mem <= 0;
                    else if(k_3 & gen_keys)         off_mem <= 9;
                    else if(k_4 & gen_keys)         off_mem <= 25;
                    else if(k_2 & encap)            off_mem <= 50;
                    else if(k_3 & encap)            off_mem <= 62;
                    else if(k_4 & encap)            off_mem <= 79;
                    else if(k_2 & decap)            off_mem <= 105;
                    else if(k_3 & decap)            off_mem <= 105;
                    else if(k_4 & decap)            off_mem <= 105;
                    else                            off_mem <= 0;
                end
            end
            else begin // N_BU == 1
                always @(posedge clk) begin
                    if(!rst)                        off_mem <= 0;
                    else if(k_2 & gen_keys)         off_mem <= 0;
                    else if(k_3 & gen_keys)         off_mem <= 9;
                    else if(k_4 & gen_keys)         off_mem <= 25;
                    else if(k_2 & encap)            off_mem <= 50;
                    else if(k_3 & encap)            off_mem <= 62;
                    else if(k_4 & encap)            off_mem <= 79;
                    else if(k_2 & decap)            off_mem <= 121;
                    else if(k_3 & decap)            off_mem <= 121;
                    else if(k_4 & decap)            off_mem <= 121;
                    else                            off_mem <= 0;
                end
            end
        end
    endgenerate
    
    always @* begin
        case(cs_h)
            IDLE:           begin
                                reset_k = 1;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            UPDATE_ADDR:    begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            UPDATE_DATA:    begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end
            LOAD_DATA_GEN_1:  begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            LOAD_DATA_GEN_2:  begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end
            LOAD_DATA_KECCAK_1: begin
                                reset_k = 0;
                                load_k  = 1;
                                start_k = 0;
                                read_k  = 0;
                            end 
            LOAD_DATA_KECCAK_2: begin
                                reset_k = 0;
                                load_k  = 1;
                                start_k = 0;
                                read_k  = 0;
                            end 
            START_KECCAK:   begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            IDLE_START:     begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            READ_KECCAK:    begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end 
            EVAL_COUNTER:   begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end 
            UPDATE_COUNTER: begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end 
            END_OP:         begin
                                reset_k = 1;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            default:        begin
                                reset_k = 0;
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end

        endcase
    end
    
    generate
        if(MASKED) begin
            MEM_CONTROL_SHAKE_MASKED MEM_CONTROL_SHAKE_MASKED 
            (
            .clk            (   clk         ),
            .addr_mem       (   addr_mem    ),
            .i              (   i           ),
            .j              (   j           ),
            .sel_seed       (   sel_seed    ),
            .sel_op         (   op          ),
            .eta            (   eta_op      ),
            .upd            (   extra_off   ),
            .counter_end    (   counter_end )
            );
        end
        else begin
            if(N_BU == 4) begin
                MEM_CONTROL_SHAKE_N_BU_4 MEM_CONTROL_SHAKE_N_BU_4 
                (
                .clk            (   clk         ),
                .addr_mem       (   addr_mem    ),
                .i              (   i           ),
                .j              (   j           ),
                .sel_seed       (   sel_seed    ),
                .sel_op         (   op          ),
                .eta            (   eta_op      ),
                .upd            (               ),
                .counter_end    (   counter_end )
                );
            end
            else if(N_BU == 2) begin
                MEM_CONTROL_SHAKE_N_BU_2 MEM_CONTROL_SHAKE_N_BU_2 // We can use the same implementation 
                (
                    .clk            (   clk         ),
                    .addr_mem       (   addr_mem    ),
                    .i              (   i           ),
                    .j              (   j           ),
                    .sel_seed       (   sel_seed    ),
                    .sel_op         (   op          ),
                    .eta            (   eta_op      ),
                    .upd            (   extra_off   ),
                    .counter_end    (   counter_end )
                );    
            end
            else begin
                MEM_CONTROL_SHAKE_MASKED MEM_CONTROL_SHAKE_N_BU_1 // We can use the same implementation 
                (
                    .clk            (   clk         ),
                    .addr_mem       (   addr_mem    ),
                    .i              (   i           ),
                    .j              (   j           ),
                    .sel_seed       (   sel_seed    ),
                    .sel_op         (   op          ),
                    .eta            (   eta_op      ),
                    .upd            (   extra_off   ),
                    .counter_end    (   counter_end )
                    );
            end
        end
    endgenerate
    
endmodule



module MEM_CONTROL_SHAKE_N_BU_4 (
    input clk,
    input   [7:0]   addr_mem,
    output  [7:0]   i,
    output  [7:0]   j,
    output          sel_seed,
    output  [1:0]   sel_op,
    output  [1:0]   eta,
    output          upd,
    output  [3:0]   counter_end
    );
    
    // (* ram_style =  "registers" *)
    
    reg [15:0] q_reg;
    
	// Declare the ROM variable
	reg [15:0] rom [0:106];
	
    always @ (posedge clk)
	begin
		q_reg <= rom[addr_mem];
	end
	
	assign sel_op      = q_reg[1:0];
	assign counter_end = q_reg[3:2];
	assign sel_seed    = q_reg[4];
	assign eta         = q_reg[6:5];
	assign upd         = q_reg[7];
	assign i           = {4'b0000, q_reg[11:8]};
	assign j           = {4'b0000, q_reg[15:12]};  
	
	// sel_seed = 0 RHO
	// sel_seed = 1 SIGMA
	
	// op == 2'b00 CBD
	// op == 2'b01 R0
	// op == 2'b10 R1
	// op == 2'b11 END
	
	initial begin
	   rom[0]  = 16'b0000_0000_0_00_0_00_00;
	   
	   // k = 2, gen_keys
	   //        j/sel_e   i  XX et sed cnt op
	   rom[1]  = 16'b0000_0000_0_11_1_01_00; // s(0) *2 times max* eta == 3
	   rom[2]  = 16'b0100_0001_0_11_1_01_00; // s(1) *2 times max* eta == 3
	   rom[3]  = 16'b1000_0010_0_11_1_01_00; // e(0) *2 times max* eta == 3
	   rom[4]  = 16'b1100_0011_0_11_1_01_00; // e(1) *2 times max* eta == 3
	   rom[5]  = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[6]  = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[7]  = 16'b0001_0000_0_00_0_11_10; // a(1,0) *4 times max*
	   rom[8]  = 16'b0001_0001_0_00_0_11_10; // a(1,1) *4 times max*
	   rom[9]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, gen_keys
	   rom[10] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[11] = 16'b0100_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[12] = 16'b1000_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[13] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[14] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[15] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[16] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[17] = 16'b0001_0011_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[18] = 16'b0101_0100_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[19] = 16'b1001_0101_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[20] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[21] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[22] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[23] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[24] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[25] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 4, gen_keys
	   rom[26] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[27] = 16'b0100_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[28] = 16'b1000_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[29] = 16'b1100_0011_0_10_1_00_00; // s(3) *1 times max* eta == 2
	   rom[30] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[31] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[32] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[33] = 16'b0000_0011_0_00_0_11_01; // a(0,3) *4 times max*
	   rom[34] = 16'b0001_0100_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[35] = 16'b0101_0101_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[36] = 16'b1001_0110_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[37] = 16'b1101_0111_0_10_1_00_00; // e(3) *1 times max* eta == 2
	   rom[38] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[39] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[40] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[41] = 16'b0001_0011_0_00_0_11_01; // a(1,3) *4 times max*
	   rom[42] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[43] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[44] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[45] = 16'b0010_0011_0_00_0_11_10; // a(2,3) *4 times max*
	   rom[46] = 16'b0011_0000_0_00_0_11_10; // a(3,0) *4 times max*
	   rom[47] = 16'b0011_0001_0_00_0_11_10; // a(3,1) *4 times max*
	   rom[48] = 16'b0011_0010_0_00_0_11_10; // a(3,2) *4 times max*
	   rom[49] = 16'b0011_0011_0_00_0_11_10; // a(3,3) *4 times max*
	   rom[50] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 2, encaps
	   //        j/sel_e   i  XX et sed cnt op
	   rom[51]  = 16'b0000_0000_0_11_1_01_00; // y(0) *2 times max* eta == 3 (CBD for AT)
	   rom[52]  = 16'b0100_0001_0_11_1_01_00; // y(1) *2 times max* eta == 3
	   rom[53]  = 16'b1010_0000_0_11_1_01_00; // y(0) *2 times max* eta == 3 (CBD for t)
	   rom[54]  = 16'b1110_0001_0_11_1_01_00; // y(1) *2 times max* eta == 3
	   rom[55]  = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[56]  = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[57]  = 16'b0000_0001_0_00_0_11_10; // aT(1,0) *4 times max*
	   rom[58]  = 16'b0001_0001_0_00_0_11_10; // aT(1,1) *4 times max*
	   rom[59]  = 16'b1000_0010_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[60]  = 16'b1001_0011_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[61]  = 16'b1111_0100_1_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[62]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, encaps
	   rom[63] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[64] = 16'b0100_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
	   rom[65] = 16'b1000_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
	   rom[66] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[67] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[68] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[69] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[70] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[71] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[72] = 16'b0011_0011_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[73] = 16'b0111_0100_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[74] = 16'b1011_0101_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[75] = 16'b1111_0110_0_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[76] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[77] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[78] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[79] = 16'b0000_0000_0_00_0_00_11; // END
	  
	   // k = 4, encap
	   rom[80] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[81] = 16'b0100_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
	   rom[82] = 16'b1000_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
	   rom[83] = 16'b1100_0011_0_10_1_00_00; // y(3) *1 times max* eta == 2
	   rom[84] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[85] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[86] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[87] = 16'b0011_0000_0_00_0_11_01; // aT(0,3) *4 times max*
	   rom[88] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[89] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[90] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[91] = 16'b0011_0001_0_00_0_11_01; // aT(1,3) *4 times max*
	   rom[92] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[93] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[94] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[95] = 16'b0011_0010_0_00_0_11_10; // aT(2,3) *4 times max*
	   rom[96] = 16'b0000_0011_0_00_0_11_10; // aT(3,0) *4 times max*
	   rom[97] = 16'b0001_0011_0_00_0_11_10; // aT(3,1) *4 times max*
	   rom[98] = 16'b0010_0011_0_00_0_11_10; // aT(3,2) *4 times max*
	   rom[99] = 16'b0011_0011_0_00_0_11_10; // aT(3,3) *4 times max*
	   rom[100] = 16'b0010_0100_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[101] = 16'b0110_0101_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[102] = 16'b1010_0110_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[103] = 16'b1110_0111_0_10_1_00_00; // e(3) *1 times max* eta == 2
	   rom[104] = 16'b1111_1000_0_10_1_00_00; // e2 *1 times max* eta == 2
	   rom[105] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   rom[106] = 16'b0000_0000_0_00_0_00_11; // END
	   
	end

endmodule

module MEM_CONTROL_SHAKE_N_BU_2 (
    input clk,
    input   [7:0]   addr_mem,
    output  [7:0]   i,
    output  [7:0]   j,
    output          sel_seed,
    output  [1:0]   sel_op,
    output  [1:0]   eta,
    output          upd,
    output  [3:0]   counter_end
    );
    
    // (* ram_style =  "registers" *)
    
    reg [15:0] q_reg;
    
	// Declare the ROM variable
	reg [15:0] rom [0:106];
	
    always @ (posedge clk)
	begin
		q_reg <= rom[addr_mem];
	end
	
	assign sel_op      = q_reg[1:0];
	assign counter_end = q_reg[3:2];
	assign sel_seed    = q_reg[4];
	assign eta         = q_reg[6:5];
	assign upd         = q_reg[7];
	assign i           = {4'b0000, q_reg[11:8]};
	assign j           = {4'b0000, q_reg[15:12]};  
	
	// sel_seed = 0 RHO
	// sel_seed = 1 SIGMA
	
	// op == 2'b00 CBD
	// op == 2'b01 R0
	// op == 2'b10 R1
	// op == 2'b11 END
	
	initial begin
	   rom[0]  = 16'b0000_0000_0_00_0_00_00;
	   
	   // k = 2, gen_keys
	   //        j/sel_e   i  EF et sed cnt op
	   rom[1]  = 16'b0000_0000_0_11_1_01_00; // s(0) *2 times max* eta == 3
	   rom[2]  = 16'b0100_0001_0_11_1_01_00; // s(1) *2 times max* eta == 3
	   rom[3]  = 16'b0010_0010_0_11_1_01_00; // e(0) *2 times max* eta == 3
	   rom[4]  = 16'b0110_0011_0_11_1_01_00; // e(1) *2 times max* eta == 3
	   rom[5]  = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[6]  = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[7]  = 16'b0001_0000_0_00_0_11_10; // a(1,0) *4 times max*
	   rom[8]  = 16'b0001_0001_0_00_0_11_10; // a(1,1) *4 times max*
	   rom[9]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, gen_keys
	   rom[10] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[11] = 16'b0100_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[12] = 16'b0001_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[13] = 16'b0010_0011_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[14] = 16'b0110_0100_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[15] = 16'b0011_0101_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[16] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[17] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[18] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[19] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[20] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[21] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[22] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[23] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[24] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[25] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 4, gen_keys
	   rom[26] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[27] = 16'b0100_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[28] = 16'b0001_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[29] = 16'b0101_0011_0_10_1_00_00; // s(3) *1 times max* eta == 2
	   rom[30] = 16'b0010_0100_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[31] = 16'b0110_0101_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[32] = 16'b0011_0110_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[33] = 16'b0111_0111_0_10_1_00_00; // e(3) *1 times max* eta == 2
	   rom[34] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[35] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[36] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[37] = 16'b0000_0011_0_00_0_11_01; // a(0,3) *4 times max*
	   rom[38] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[39] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[40] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[41] = 16'b0001_0011_0_00_0_11_01; // a(1,3) *4 times max*
	   rom[42] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[43] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[44] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[45] = 16'b0010_0011_0_00_0_11_10; // a(2,3) *4 times max*
	   rom[46] = 16'b0011_0000_0_00_0_11_10; // a(3,0) *4 times max*
	   rom[47] = 16'b0011_0001_0_00_0_11_10; // a(3,1) *4 times max*
	   rom[48] = 16'b0011_0010_0_00_0_11_10; // a(3,2) *4 times max*
	   rom[49] = 16'b0011_0011_0_00_0_11_10; // a(3,3) *4 times max*
	   rom[50] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 2, encaps
	   //        j/sel_e   i  XX et sed cnt op
	   rom[51]  = 16'b0000_0000_0_11_1_01_00; // y(0) *2 times max* eta == 3 
	   rom[52]  = 16'b0100_0001_0_11_1_01_00; // y(1) *2 times max* eta == 3
       rom[53]  = 16'b0010_0010_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[54]  = 16'b0110_0011_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[55]  = 16'b0000_0100_1_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[56]  = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[57]  = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[58]  = 16'b0000_0001_0_00_0_11_10; // aT(1,0) *4 times max*
	   rom[59]  = 16'b0001_0001_0_00_0_11_10; // aT(1,1) *4 times max*
	   rom[60]  = 16'b0000_0000_0_00_0_00_11; // END
       rom[61]  = 16'b0000_0000_0_00_0_00_11; // END
       rom[62]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, encaps
	   rom[63] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[64] = 16'b0100_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
	   rom[65] = 16'b0001_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
       rom[66] = 16'b0010_0011_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[67] = 16'b0110_0100_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[68] = 16'b0011_0101_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[69] = 16'b0000_0110_1_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[70] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[71] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[72] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[73] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[74] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[75] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[76] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[77] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[78] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[79] = 16'b0000_0000_0_00_0_00_11; // END
	  
	   // k = 4, encap
	   rom[80] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[81] = 16'b0100_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
       rom[82] = 16'b0001_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
       rom[83] = 16'b0101_0011_0_10_1_00_00; // y(3) *1 times max* eta == 2
       rom[84] = 16'b0010_0100_0_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[85] = 16'b0110_0101_0_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[86] = 16'b0011_0110_0_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[87] = 16'b0111_0111_0_10_1_00_00; // e(3) *1 times max* eta == 2
       rom[88] = 16'b0000_1000_1_10_1_00_00; // e2 *1 times max* eta == 2
	   rom[89] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[90] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[91] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[92] = 16'b0011_0000_0_00_0_11_01; // aT(0,3) *4 times max*
	   rom[93] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[94] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[95] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[96] = 16'b0011_0001_0_00_0_11_01; // aT(1,3) *4 times max*
	   rom[97] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[98] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[99] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[100] = 16'b0011_0010_0_00_0_11_10; // aT(2,3) *4 times max*
	   rom[101] = 16'b0000_0011_0_00_0_11_10; // aT(3,0) *4 times max*
	   rom[102] = 16'b0001_0011_0_00_0_11_10; // aT(3,1) *4 times max*
	   rom[103] = 16'b0010_0011_0_00_0_11_10; // aT(3,2) *4 times max*
	   rom[104] = 16'b0011_0011_0_00_0_11_10; // aT(3,3) *4 times max*
	   rom[105] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   rom[106] = 16'b0000_0000_0_00_0_00_11; // END
	   
	end

endmodule

module MEM_CONTROL_SHAKE_MASKED (
    input clk,
    input   [7:0]   addr_mem,
    output  [7:0]   i,
    output  [7:0]   j,
    output          sel_seed,
    output  [1:0]   sel_op,
    output  [1:0]   eta,
    output          upd,
    output  [3:0]   counter_end
    );
    
    // (* ram_style =  "registers" *)
    
    reg [15:0] q_reg;
    
	// Declare the ROM variable
	reg [15:0] rom [0:122];
	
    always @ (posedge clk)
	begin
		q_reg <= rom[addr_mem];
	end
	
	assign sel_op      = q_reg[1:0];
	assign counter_end = q_reg[3:2];
	assign sel_seed    = q_reg[4];
	assign eta         = q_reg[6:5];
	assign upd         = q_reg[7];
	assign i           = {4'b0000, q_reg[11:8]};
	assign j           = {4'b0000, q_reg[15:12]};  
	
	// sel_seed = 0 RHO
	// sel_seed = 1 SIGMA
	
	// op == 2'b00 CBD
	// op == 2'b01 R0
	// op == 2'b10 R1
	// op == 2'b11 END
	
	initial begin
	   rom[0]  = 16'b0000_0000_0_00_0_00_00;
	   
	   // k = 2, gen_keys
	   //        j/sel_e   i  EF et sed cnt op
	   rom[1]  = 16'b0000_0000_0_11_1_01_00; // s(0) *2 times max* eta == 3
	   rom[2]  = 16'b0001_0001_0_11_1_01_00; // s(1) *2 times max* eta == 3
	   rom[3]  = 16'b0010_0010_0_11_1_01_00; // e(0) *2 times max* eta == 3
	   rom[4]  = 16'b0011_0011_0_11_1_01_00; // e(1) *2 times max* eta == 3
	   rom[5]  = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[6]  = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[7]  = 16'b0001_0000_0_00_0_11_10; // a(1,0) *4 times max*
	   rom[8]  = 16'b0001_0001_0_00_0_11_10; // a(1,1) *4 times max*
	   rom[9]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, gen_keys
	   rom[10] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[11] = 16'b0001_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[12] = 16'b0010_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[13] = 16'b0000_0011_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[14] = 16'b0001_0100_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[15] = 16'b0010_0101_1_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[16] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[17] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[18] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[19] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[20] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[21] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[22] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[23] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[24] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[25] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 4, gen_keys
	   rom[26] = 16'b0000_0000_0_10_1_00_00; // s(0) *1 times max* eta == 2
	   rom[27] = 16'b0001_0001_0_10_1_00_00; // s(1) *1 times max* eta == 2
	   rom[28] = 16'b0010_0010_0_10_1_00_00; // s(2) *1 times max* eta == 2
	   rom[29] = 16'b0011_0011_0_10_1_00_00; // s(3) *1 times max* eta == 2
	   rom[30] = 16'b0000_0100_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[31] = 16'b0001_0101_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[32] = 16'b0010_0110_1_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[33] = 16'b0011_0111_1_10_1_00_00; // e(3) *1 times max* eta == 2
	   rom[34] = 16'b0000_0000_0_00_0_11_01; // a(0,0) *4 times max*
	   rom[35] = 16'b0000_0001_0_00_0_11_01; // a(0,1) *4 times max*
	   rom[36] = 16'b0000_0010_0_00_0_11_01; // a(0,2) *4 times max*
	   rom[37] = 16'b0000_0011_0_00_0_11_01; // a(0,3) *4 times max*
	   rom[38] = 16'b0001_0000_0_00_0_11_01; // a(1,0) *4 times max*
	   rom[39] = 16'b0001_0001_0_00_0_11_01; // a(1,1) *4 times max*
	   rom[40] = 16'b0001_0010_0_00_0_11_01; // a(1,2) *4 times max*
	   rom[41] = 16'b0001_0011_0_00_0_11_01; // a(1,3) *4 times max*
	   rom[42] = 16'b0010_0000_0_00_0_11_10; // a(2,0) *4 times max*
	   rom[43] = 16'b0010_0001_0_00_0_11_10; // a(2,1) *4 times max*
	   rom[44] = 16'b0010_0010_0_00_0_11_10; // a(2,2) *4 times max*
	   rom[45] = 16'b0010_0011_0_00_0_11_10; // a(2,3) *4 times max*
	   rom[46] = 16'b0011_0000_0_00_0_11_10; // a(3,0) *4 times max*
	   rom[47] = 16'b0011_0001_0_00_0_11_10; // a(3,1) *4 times max*
	   rom[48] = 16'b0011_0010_0_00_0_11_10; // a(3,2) *4 times max*
	   rom[49] = 16'b0011_0011_0_00_0_11_10; // a(3,3) *4 times max*
	   rom[50] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 2, encaps
	   //        j/sel_e   i  XX et sed cnt op
	   rom[51]  = 16'b0000_0000_0_11_1_01_00; // y(0) *2 times max* eta == 3 
	   rom[52]  = 16'b0001_0001_0_11_1_01_00; // y(1) *2 times max* eta == 3
       rom[53]  = 16'b0000_0010_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[54]  = 16'b0001_0011_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[55]  = 16'b0011_0100_1_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[56]  = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[57]  = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[58]  = 16'b0000_0001_0_00_0_11_10; // aT(1,0) *4 times max*
	   rom[59]  = 16'b0001_0001_0_00_0_11_10; // aT(1,1) *4 times max*
	   rom[60]  = 16'b0000_0000_0_00_0_00_11; // END
       rom[61]  = 16'b0000_0000_0_00_0_00_11; // END
       rom[62]  = 16'b0000_0000_0_00_0_00_11; // END
	   
	   // k = 3, encaps
	   rom[63] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[64] = 16'b0001_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
	   rom[65] = 16'b0010_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
       rom[66] = 16'b0000_0011_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[67] = 16'b0001_0100_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[68] = 16'b0010_0101_1_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[69] = 16'b0011_0110_1_10_1_00_00; // e2   *1 times max* eta == 2
	   rom[70] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[71] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[72] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[73] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[74] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[75] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[76] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[77] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[78] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[79] = 16'b0000_0000_0_00_0_00_11; // END
	  
	   // k = 4, encap
	   rom[80] = 16'b0000_0000_0_10_1_00_00; // y(0) *1 times max* eta == 2
	   rom[81] = 16'b0001_0001_0_10_1_00_00; // y(1) *1 times max* eta == 2
       rom[82] = 16'b0010_0010_0_10_1_00_00; // y(2) *1 times max* eta == 2
	   rom[83] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max*
	   rom[84] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[85] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[86] = 16'b0011_0000_0_00_0_11_01; // aT(0,3) *4 times max*
	   rom[87] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[88] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[89] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[90] = 16'b0011_0001_0_00_0_11_01; // aT(1,3) *4 times max*
	   rom[91] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[92] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[93] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[94] = 16'b0011_0010_0_00_0_11_10; // aT(2,3) *4 times max*
	   rom[95] = 16'b0000_0011_0_00_0_11_10; // aT(3,0) *4 times max*
	   rom[96] = 16'b0001_0011_0_00_0_11_10; // aT(3,1) *4 times max*
	   rom[97] = 16'b0010_0011_0_00_0_11_10; // aT(3,2) *4 times max*
	   rom[98] = 16'b0011_0011_0_00_0_11_10; // aT(3,3) *4 times max*
	   rom[99] = 16'b0000_0000_0_00_0_11_01; // aT(0,0) *4 times max* // Second Time to give time to BU's to finish
	   rom[100] = 16'b0001_0000_0_00_0_11_01; // aT(0,1) *4 times max*
	   rom[101] = 16'b0010_0000_0_00_0_11_01; // aT(0,2) *4 times max*
	   rom[102] = 16'b0011_0000_0_00_0_11_01; // aT(0,3) *4 times max*
	   rom[103] = 16'b0000_0001_0_00_0_11_01; // aT(1,0) *4 times max*
	   rom[104] = 16'b0001_0001_0_00_0_11_01; // aT(1,1) *4 times max*
	   rom[105] = 16'b0010_0001_0_00_0_11_01; // aT(1,2) *4 times max*
	   rom[106] = 16'b0011_0001_0_00_0_11_01; // aT(1,3) *4 times max*
	   rom[107] = 16'b0000_0010_0_00_0_11_10; // aT(2,0) *4 times max*
	   rom[108] = 16'b0001_0010_0_00_0_11_10; // aT(2,1) *4 times max*
	   rom[109] = 16'b0010_0010_0_00_0_11_10; // aT(2,2) *4 times max*
	   rom[110] = 16'b0011_0010_0_00_0_11_10; // aT(2,3) *4 times max*
	   rom[111] = 16'b0000_0011_0_00_0_11_10; // aT(3,0) *4 times max*
	   rom[112] = 16'b0001_0011_0_00_0_11_10; // aT(3,1) *4 times max*
	   rom[113] = 16'b0010_0011_0_00_0_11_10; // aT(3,2) *4 times max*
	   rom[114] = 16'b0011_0011_0_00_0_11_10; // aT(3,3) *4 times max*
       rom[115] = 16'b0000_0011_0_10_1_00_00; // y(3) *1 times max* eta == 2
	   rom[116] = 16'b0000_0100_1_10_1_00_00; // e(0) *1 times max* eta == 2
	   rom[117] = 16'b0001_0101_1_10_1_00_00; // e(1) *1 times max* eta == 2
	   rom[118] = 16'b0010_0110_1_10_1_00_00; // e(2) *1 times max* eta == 2
	   rom[119] = 16'b0011_0111_1_10_1_00_00; // e(3) *1 times max* eta == 2
	   rom[120] = 16'b0010_1000_0_10_1_00_00; // e2 *1 times max* eta == 2
	   rom[121] = 16'b0000_0000_0_00_0_00_11; // END
	   
	   rom[122] = 16'b0000_0000_0_00_0_00_11; // END
	   
	end

endmodule
