`timescale 1ns / 1ps

module CONTROL_BU #(
    parameter UNIT = 1,
    parameter N_UNITS = 4
    )(
    input                   clk,
    input                   rst,
    input       [3:0]       mode,
    input                   start,
    input                   start_ed,
    // input                   busy_cbd,
    input                   busy_r0,
    input                   busy_r1,
    input                   end_op_bu,
    input       [3:0]       busy_bu,
    output      [3:0]       mode_bu,
    output reg              start_bu,
    output reg  [7:0]       control_dmu,
    output      [7:0]       off_ram,
    output      [3:0]       off_rej,
    output                  end_op
    );
    
    // -- Mode signals -- //
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
    
    //--*** STATE declaration **--//
	localparam IDLE            = 4'h0;
	localparam FETCH_INST      = 4'h1; 
	localparam LOAD_INST       = 4'h2;
	localparam START_BU        = 4'h3;
	localparam START_BU_IDLE_0 = 4'h4;
	localparam START_BU_IDLE_1 = 4'h5;
	localparam UPDATE_INST     = 4'h6;
	localparam DELAY           = 4'h7;
	localparam END_DELAY       = 4'h8;
	localparam END_OP          = 4'hF;
    
    //--*** STATE register **--//
	reg [3:0] cs_bu; // current_state
	reg [3:0] ns_bu; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    cs_bu <= IDLE;
			else         cs_bu <= ns_bu;
		end
    
    assign end_op = (cs_bu == END_OP) ? 1 : 0;
    
    //--*** STATE Transition **--//
	
	wire [19:0] inst;
	
	// --- Decoder --- //
	/*
	       op BU
		  <000>   RESET
		  <001>   NTT
		  <010>   INTT
		  <011>   PWM
		  <100>   ADD
		  <101>   SUB
		  
		  SEL_RAM -> Read RAM
		  0: read 0, write 1
		  1: read 1, write 0
		  
		  CONTROL_DMU
		  <0000>  CBD
		  <0001>  NTT / INTT
		  <0010>  PWM_R0
		  <0011>  PWM_R1
		  <0100>  ADD_SUB_N1
		  <0101>  ADD_SUB_N2
		  <0110>  ADD_SUB_N3
		  <0111>  ADD_SUB_N4
		  
		  OFF_RAM
		  <0000>  0
		  <0001>  128
		  <0010>  256
		  <0011>  384
		  <0100>  512
		  <0101>  640
		  <0110>  768
		  <0111>  897
		  <1000>  960
		  
		  INST = <OFF_REJ, OFF_RAM_1, OFF_RAM_0, CONTROL_DMU, {SEL_RAM, OP BU}>
	*/
    
    
    reg [11:0]   counter_delay;
    reg          end_counter_delay;
    
    always @(posedge clk) begin
        if(!rst | cs_bu == UPDATE_INST) counter_delay <= 0;
        else begin
            if(cs_bu == DELAY)  counter_delay <= counter_delay + 1;
            else                counter_delay <= 0;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | cs_bu == UPDATE_INST) end_counter_delay <= 1'b0;
        else begin
            if(cs_bu == DELAY & counter_delay == inst[19:08])   end_counter_delay <= 1'b1;
            else                                                end_counter_delay <= end_counter_delay;
        end
    end
    
    wire [3:0] sel_dmu;
    
    generate 
        if(N_UNITS == 4) begin
            always @* begin
               if(cs_bu == FETCH_INST)
                       control_dmu = 8'b0000_0000;
               else begin
                   case(sel_dmu)
                        4'b0000: control_dmu = 8'b0000_0001;
                        4'b0001: control_dmu = 8'b0000_0010;
                        4'b0010: control_dmu = 8'b0000_0100;
                        4'b0011: control_dmu = 8'b0000_1000;
                        4'b0100: control_dmu = 8'b0001_0000;
                        4'b0101: control_dmu = 8'b0010_0000;
                        4'b0110: control_dmu = 8'b0100_0000;
                        4'b0111: control_dmu = 8'b1000_0000;
                        4'b1000: control_dmu = 8'b0000_1100; // PWM R0 & R1 
                        default: control_dmu = 8'b0000_0000;
                   endcase
               end
            end
        end
        else if(N_UNITS == 2) begin
            always @* begin
               if(cs_bu == FETCH_INST)
                       control_dmu = 8'b0000_0000;
               else begin
                   case(sel_dmu)
                        4'b0000: control_dmu = 8'b0000_0001;
                        4'b0001: control_dmu = 8'b0000_0010;
                        4'b0010: control_dmu = 8'b0000_0100;
                        4'b0011: control_dmu = 8'b0000_1000;
                        4'b0100: control_dmu = 8'b0001_0000;
                        4'b0101: control_dmu = 8'b0010_0000;
                        4'b0110:    begin
                                        if(UNIT == 1)       control_dmu = 8'b1110_0000; // MOVE
                                        else if(UNIT == 2)  control_dmu = 8'b1101_0000; // MOVE
                                        else                control_dmu = 8'b0011_0000; // MOVE  
                                    end 
                        4'b1000: control_dmu = 8'b0000_1100; // PWM R0 & R1 
                        default: control_dmu = 8'b0000_0000;
                   endcase
               end
            end
        end
        else begin
            always @* begin
               if(cs_bu == FETCH_INST)
                       control_dmu = 8'b0000_0000;
               else begin
                   case(sel_dmu)
                        4'b0000: control_dmu = 8'b0000_0001;
                        4'b0001: control_dmu = 8'b0000_0010;
                        4'b0010: control_dmu = 8'b0000_0100;
                        4'b0011: control_dmu = 8'b0000_1000;
                        4'b0100: control_dmu = 8'b1111_0000; // ADD & SUB
                        4'b0101:    begin
                                        if(UNIT == 1) control_dmu = 8'b1110_0000; // MOVE
                                        else          control_dmu = 8'b0001_0000; // MOVE  
                                    end 
                        4'b1000: control_dmu = 8'b0000_1100; // PWM R0 & R1 
                        default: control_dmu = 8'b0000_0000;
                   endcase
               end
            end
        end
	endgenerate
	
	wire [3:0] off_ram_0;
    wire [3:0] off_ram_1;
    assign off_ram = {off_ram_1, off_ram_0};
	
	assign mode_bu     = (cs_bu == IDLE | cs_bu == UPDATE_INST) ? 4'b0000 : inst[03:00];
	// assign mode_bu     = (cs_bu == IDLE) ? 4'b0000 : inst[03:00];
	assign sel_dmu     = inst[07:04];
	assign off_ram_0   = inst[11:08];
	assign off_ram_1   = inst[15:12];
	assign off_rej     = inst[19:16];
	
	generate
	if(N_UNITS == 4) begin
           always @* begin
                case (cs_bu)
                    IDLE:
                       if (start)
                            ns_bu = FETCH_INST;
                       else
                            ns_bu = IDLE;
                    FETCH_INST:
                            if  (mode_bu[2:0] == 3'b001 | mode_bu[2:0] == 3'b010)
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b111)
                                ns_bu = END_OP;  
                      else  if  (mode_bu[2:0] == 3'b110)
                                ns_bu = DELAY;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0010 & !busy_r0) // PWM_R0
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0011 & !busy_r1) // PWM_R1
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b1000) // PWM over MOD
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0100 & !busy_bu[0]) // ADD_SUB_N1
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0101 & !busy_bu[1]) // ADD_SUB_N2
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0110 & !busy_bu[2]) // ADD_SUB_N3
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0111 & !busy_bu[3]) // ADD_SUB_N4
                                ns_bu = LOAD_INST;
                      else
                                ns_bu = FETCH_INST;
                    LOAD_INST:
                         ns_bu = START_BU;
                    START_BU:
                         if(end_op_bu)
                            ns_bu = START_BU_IDLE_0;
                        else
                            ns_bu = START_BU;
                    START_BU_IDLE_0:
                        if(start)
                            ns_bu = START_BU_IDLE_1;
                        else
                            ns_bu = START_BU_IDLE_0;
                    START_BU_IDLE_1:
                        if(start)
                            ns_bu = UPDATE_INST;
                        else
                            ns_bu = START_BU_IDLE_1;
                    DELAY:
                        if(end_counter_delay)
                            ns_bu = END_DELAY;
                      else
                            ns_bu = DELAY;
                    END_DELAY:
                            ns_bu = UPDATE_INST;
                    UPDATE_INST:
                            ns_bu = FETCH_INST;
                    END_OP:
                            ns_bu = END_OP;
                    default:
                            ns_bu = IDLE;
                endcase 		
            end 
       end
       else if (N_UNITS == 2) begin
       always @* begin
                case (cs_bu)
                    IDLE:
                       if (start)
                            ns_bu = FETCH_INST;
                       else
                            ns_bu = IDLE;
                    FETCH_INST:
                            if  (mode_bu[2:0] == 3'b001 | mode_bu[2:0] == 3'b010)
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b111)
                                ns_bu = END_OP;  
                      else  if  (mode_bu[2:0] == 3'b110)
                                ns_bu = DELAY;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0010 & !busy_r0) // PWM_R0
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0011 & !busy_r1) // PWM_R1
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b1000) // PWM over MOD
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0100 & !busy_bu[0]) // ADD_SUB_N1
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0101 & !busy_bu[1]) // ADD_SUB_N2
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0110) // MOVE
                                ns_bu = LOAD_INST;
                      else
                                ns_bu = FETCH_INST;
                    LOAD_INST:
                         ns_bu = START_BU;
                    START_BU:
                         if(end_op_bu)
                            ns_bu = START_BU_IDLE_0;
                        else
                            ns_bu = START_BU;
                    START_BU_IDLE_0:
                        if(start)
                            ns_bu = START_BU_IDLE_1;
                        else
                            ns_bu = START_BU_IDLE_0;
                    START_BU_IDLE_1:
                        if(start)
                            ns_bu = UPDATE_INST;
                        else
                            ns_bu = START_BU_IDLE_1;
                    DELAY:
                        if(end_counter_delay)
                            ns_bu = END_DELAY;
                      else
                            ns_bu = DELAY;
                    END_DELAY:
                            ns_bu = UPDATE_INST;
                    UPDATE_INST:
                            ns_bu = FETCH_INST;
                    END_OP:
                            ns_bu = END_OP;
                    default:
                            ns_bu = IDLE;
                endcase 		
            end 
       
       end
       else begin
            always @* begin
                case (cs_bu)
                    IDLE:
                       if (start)
                            ns_bu = FETCH_INST;
                       else
                            ns_bu = IDLE;
                    FETCH_INST:
                            if  (mode_bu[2:0] == 3'b001 | mode_bu[2:0] == 3'b010)
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b111)
                                ns_bu = END_OP;  
                      else  if  (mode_bu[2:0] == 3'b110)
                                ns_bu = DELAY;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0010 & !busy_r0) // PWM_R0
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b0011 & !busy_r1) // PWM_R1
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2:0] == 3'b011 & sel_dmu == 4'b1000) // PWM over MOD
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0100) // ADD_SUB
                                ns_bu = LOAD_INST;
                      else  if  (mode_bu[2] == 1'b1 & sel_dmu == 4'b0101) // CLEAN
                                ns_bu = LOAD_INST;
                      else
                                ns_bu = FETCH_INST;
                    LOAD_INST:
                         ns_bu = START_BU;
                    START_BU:
                         if(end_op_bu)
                            ns_bu = START_BU_IDLE_0;
                        else
                            ns_bu = START_BU;
                    START_BU_IDLE_0:
                        if(start)
                            ns_bu = START_BU_IDLE_1;
                        else
                            ns_bu = START_BU_IDLE_0;
                    START_BU_IDLE_1:
                        if(start)
                            ns_bu = UPDATE_INST;
                        else
                            ns_bu = START_BU_IDLE_1;
                    DELAY:
                        if(end_counter_delay)
                            ns_bu = END_DELAY;
                      else
                            ns_bu = DELAY;
                    END_DELAY:
                            ns_bu = UPDATE_INST;
                    UPDATE_INST:
                            ns_bu = FETCH_INST;
                    END_OP:
                            ns_bu = END_OP;
                    default:
                            ns_bu = IDLE;
                endcase 		
            end 
       
       end
	   endgenerate
		
	   
	   always @(posedge clk) begin
	       if(!rst | cs_bu == UPDATE_INST | cs_bu == END_OP)      start_bu <= 1'b0;
	       else if(    cs_bu == START_BU)                         start_bu <= 1'b1;
	       else                                                   start_bu <= start_bu;
	   end
	  
	   wire [1139:0] PROG_1 [0:11];
	   wire [719:0] PROG_2 [0:11];
	   wire [459:0]  PROG [0:11];
	   
       generate
            if(N_UNITS == 4)  begin 
                reg  [459:0] c_inst;
	            assign inst = c_inst[19:0];
		
                always @(posedge clk) begin
                  if(!rst | cs_bu == IDLE) begin
                              if(k_2 & gen_keys)  c_inst <= PROG[0];
                      else    if(k_3 & gen_keys)  c_inst <= PROG[1];
                      else    if(k_4 & gen_keys)  c_inst <= PROG[2];
                      else    if(k_2 & start_ed)  c_inst <= PROG[9];  // encap from decap
                      else    if(k_3 & start_ed)  c_inst <= PROG[10]; // encap from decap
                      else    if(k_4 & start_ed)  c_inst <= PROG[11]; // encap from decap
                      else    if(k_2 & encap)     c_inst <= PROG[3];
                      else    if(k_3 & encap)     c_inst <= PROG[4];
                      else    if(k_4 & encap)     c_inst <= PROG[5];
                      else    if(k_2 & decap)     c_inst <= PROG[6];
                      else    if(k_3 & decap)     c_inst <= PROG[7];
                      else    if(k_4 & decap)     c_inst <= PROG[8];
                      else                        c_inst <= 0;
                  end
                  else begin
                      if(cs_bu == UPDATE_INST)    c_inst <= c_inst >> 20;
                      else                        c_inst <= c_inst;
                  end
                end
            end
            else if(N_UNITS == 2) begin
                reg  [719:0] c_inst;
	            assign inst = c_inst[19:0];
		
                always @(posedge clk) begin
                  if(!rst | cs_bu == IDLE) begin
                              if(k_2 & gen_keys)  c_inst <= PROG_2[0];
                      else    if(k_3 & gen_keys)  c_inst <= PROG_2[1];
                      else    if(k_4 & gen_keys)  c_inst <= PROG_2[2];
                      else    if(k_2 & start_ed)  c_inst <= PROG_2[9];  // encap from decap
                      else    if(k_3 & start_ed)  c_inst <= PROG_2[10]; // encap from decap
                      else    if(k_4 & start_ed)  c_inst <= PROG_2[11]; // encap from decap
                      else    if(k_2 & encap)     c_inst <= PROG_2[3];
                      else    if(k_3 & encap)     c_inst <= PROG_2[4];
                      else    if(k_4 & encap)     c_inst <= PROG_2[5];
                      else    if(k_2 & decap)     c_inst <= PROG_2[6];
                      else    if(k_3 & decap)     c_inst <= PROG_2[7];
                      else    if(k_4 & decap)     c_inst <= PROG_2[8];
                      else                        c_inst <= 0;
                  end
                  else begin
                      if(cs_bu == UPDATE_INST)    c_inst <= c_inst >> 20;
                      else                        c_inst <= c_inst;
                  end
               end
            end 
            else begin
                reg  [1139:0] c_inst;
	            assign inst = c_inst[19:0];
		
                always @(posedge clk) begin
                  if(!rst | cs_bu == IDLE) begin
                              if(k_2 & gen_keys)  c_inst <= PROG_1[0];
                      else    if(k_3 & gen_keys)  c_inst <= PROG_1[1];
                      else    if(k_4 & gen_keys)  c_inst <= PROG_1[2];
                      else    if(k_2 & start_ed)  c_inst <= PROG_1[9];  // encap from decap
                      else    if(k_3 & start_ed)  c_inst <= PROG_1[10]; // encap from decap
                      else    if(k_4 & start_ed)  c_inst <= PROG_1[11]; // encap from decap
                      else    if(k_2 & encap)     c_inst <= PROG_1[3];
                      else    if(k_3 & encap)     c_inst <= PROG_1[4];
                      else    if(k_4 & encap)     c_inst <= PROG_1[5];
                      else    if(k_2 & decap)     c_inst <= PROG_1[6];
                      else    if(k_3 & decap)     c_inst <= PROG_1[7];
                      else    if(k_4 & decap)     c_inst <= PROG_1[8];
                      else                        c_inst <= 0;
                  end
                  else begin
                      if(cs_bu == UPDATE_INST)    c_inst <= c_inst >> 20;
                      else                        c_inst <= c_inst;
                  end
                end
            end
		endgenerate
		
		/*
		localparam IDLE            = 4'h0;
        localparam FETCH_INST      = 4'h1; 
        localparam NTT_S           = 4'h2;
        localparam NTT_E           = 4'h3;
        localparam NTT_E2          = 4'h4;
        localparam PWM_A0          = 4'h5;
        localparam PWM_A1          = 4'h6;
        localparam PWM_A2          = 4'h7;
        localparam PWM_A3          = 4'h8;
        localparam ADD             = 4'h9;
        localparam SUB             = 4'hA;
        localparam UPDATE_INST     = 4'hB;
        localparam END_OP          = 4'hF;
        */
		
		/* 
		localparam OFF_S    = 4'b0000; // 0;
	   localparam OFF_E    = 4'b0001; // 128;
	   localparam OFF_A0   = 4'b0010; // 256;
	   localparam OFF_A1   = 4'b0011; // 384;
	   localparam OFF_A2   = 4'b0100; // 512;
	   localparam OFF_A3   = 4'b0101; // 640;
	   localparam OFF_EK   = 4'b0110; // 768;
	   localparam OFF_DK   = 4'b0111; // 897;
	   localparam OFF_CT   = 4'b1000; // 960;
		
		  op BU
		  <000>   RESET
		  <001>   NTT
		  <010>   INTT
		  <011>   PWM
		  <100>   ADD
		  <101>   SUB
		  
		  SEL_RAM -> Read RAM
		  0: read 0, write 1
		  1: read 1, write 0
		  
		  CONTROL_DMU
		  <0000>  CBD
		  <0001>  NTT / INTT
		  <0010>  PWM_R0
		  <0011>  PWM_R1
		  <0100>  ADD_SUB_N1
		  <0101>  ADD_SUB_N2
		  <0110>  ADD_SUB_N3
		  <0111>  ADD_SUB_N4
		  
		  OFF_RAM
		  <0000>  0
		  <0001>  128
		  <0010>  256
		  <0011>  384
		  <0100>  512
		  <0101>  640
		  <0110>  768
		  <0111>  897
		  <1000>  960
		  
		  INST = <OFF_REJ, OFF_RAM_1, OFF_RAM_0, CONTROL_DMU, {SEL_RAM, OP BU}>
		  
		  FFFFFF -> END
		  
		  //-- KeyGen --//
		  NTT(S): OFF_REJ     = 0
		          OFF_RAM_1   = 0
		          OFF_RAM_0   = 0
		          CONTROL_DMU = 0001 = 1
		          SEL_RAM     = 0 (CBD is here)
		          OP_BU       = 001 => 0001 = 1 (010 - INTT) 1010 A (INTT sel 1)
		          00011
		  NTT(E): OFF_REJ     = 0
		          OFF_RAM_1   = 1
		          OFF_RAM_0   = 1
		          CONTROL_DMU = 0001 = 1
		          SEL_RAM     = 0 (CBD is here)
		          OP_BU       = 001 => 0001 = 1 (010 - INTT) 1010 A (INTT sel 1)
		          01111
		PWM(A*S): OFF_REJ     = 0/1/2/3/4/5/6/7 (A00, A01, A02, A03, A10, A11, A12, A13)
		          OFF_RAM_1   = 0
		          OFF_RAM_0   = 0/1/2/3/4/5/6/7 (A00, A01, A02, A03, A10, A11, A12, A13)
		          CONTROL_DMU = 0010 = 2 (R0) / 3 (R1) / 8 (R0 & R1)
		          SEL_RAM     = 1 
		          OP_BU       = 011 => 1011 = B
		          {0}0{0}{2}B
    ADD(AX0+AX1): OFF_REJ     = 0
		          OFF_RAM_1   = 0/1/2/3/4/5/6/7 (A00, A01, A02, A03, A10, A11, A12, A13) // use for add selection 
		          OFF_RAM_0   = 0/1/2/3/4/5/6/7 (A00, A01, A02, A03, A10, A11, A12, A13)  
		          CONTROL_DMU = 0100 (4) ADD_N1 // 0101 (5) ADD_N2 // 0110 (6) ADD_N3 // 0111 (7) ADD_N4
		          SEL_RAM     = 1 / 0 
		          OP_BU       = 100 => 1100 = C // 0100 = 4
		          0{0}{0}{4}C
		          
		          SUB = 101 -> 1101 (D) / 0101 = 5       
		                
	   DELAYED: {CYCLES}{0110} = {CYCLES}{6}

		*/
		
		generate
		  if(N_UNITS == 4) begin
              if(UNIT == 1) begin
                  assign PROG[0]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4013B_0002B_040F6_00011_090F6; // k = 2, keygen, NTT(S0), PWM(A00*S0), PWM(A10*S0) END
                  assign PROG[1]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4105C_130F6_2446C_24254_040F6_0023B_4012B_0002B_01111_07AF6_00011_07EF6; // k = 3, keygen, NTT(S0), NTT(E0), PWM(A00*S0), PWM(A10*S0), PWM(A20*S0), ADD(A20*S0 + A21*S1), ADD(t2 + A22*S2), ADD(t0 + E0) END
                  assign PROG[2]  = 460'h00000_00000_00000_00000_00000_00000_00000_FFFFF_01074_4105C_0B0F6_3447C_34354_4033B_0023B_2C0F6_4012B_0002B_0B0F6_01111_0DAF6_00011_082F6; // k = 4, keygen, NTT(S0), NTT(E0), PWM(A00*S0), PWM(A10*S0), PWM(A20*S0), PWM(A30*S0) END
                  assign PROG[3]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_04DF6_00054_066F6_4013B_0002B_132F6_00011_140F6; // k = 2, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG[4]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3206C_02212_0B0F6_0447C_071F6_2226C_22254_0023B_4012B_0002B_19DF6_3038B_00011_189F6; // k = 3, encap, NTT(Y0), PWM(T0*Y0), PWM(AT00*Y0), PWM(AT10*Y0), PWM(AT20*Y0), ADD(AT20*Y0 + AT21*Y1), ADD(S2 + A22*Y2), INTT(S2), ADD(S2 + E2), END
                  assign PROG[5]  = 460'h00000_00000_00000_00000_00000_FFFFF_60254_0661A_047F6_56664_0A0F6_5667C_56554_4053B_0043B_1F4F6_4012B_0002B_3337C_3C0F6_2038B_00011_1ECF6; // k = 4, encap, NTT(Y0), PWM(T0*Y0), PWM(AT00*Y0), PWM(AT10*Y0), PWM(AT20*Y0), PWM(AT30*Y0) END
                  assign PROG[6]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0108B_01111; // k = 2, decap, NTT(U0), PWM(S0*U0) END
                  assign PROG[7]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0108B_01111; // k = 3, decap, NTT(U0), PWM(S0*U0) END
                  assign PROG[8]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0108B_01111; // k = 4, decap, NTT(U0), PWM(S0*U0) END
                  assign PROG[9]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_04DF6_00054_066F6_4013B_0002B_132F6_00011_06EF6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG[10] = 460'h00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3206C_02212_0B0F6_0447C_071F6_2226C_22254_0023B_4012B_0002B_19DF6_3038B_00011_05EF6; // k = 3, decap - encap, NTT(Y0), PWM(T0*Y0), PWM(AT00*Y0), PWM(AT10*Y0), PWM(AT20*Y0), ADD(AT20*Y0 + AT21*Y1), ADD(S2 + A22*Y2), INTT(S2), ADD(S2 + E2), END
                  assign PROG[11] = 460'h00000_00000_00000_00000_00000_FFFFF_60254_0661A_047F6_56664_0A0F6_5667C_56554_4053B_0043B_1F4F6_4012B_0002B_3337C_3C0F6_2038B_00011_068F6; // k = 4, decap - encap, NTT(Y0), PWM(T0*Y0), PWM(AT00*Y0), PWM(AT10*Y0), PWM(AT20*Y0), PWM(AT30*Y0) END
              end
              else if (UNIT == 2) begin
                  assign PROG[0]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_5013B_1002B_040F6_00011_0E4F6; // k = 2, keygen, NTT(S1), PWM(A01*S1), PWM(A11*S1) END
                  assign PROG[1]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4106C_0E1F6_0446C_04044_097F6_1023B_5012B_1002B_01111_07AF6_00011_0C0F6; // k = 3, keygen, NTT(S1), NTT(E1), PWM(A21*S1), PWM(A01*S1), PWM(A11*S1), ADD(E0 + A00*S0), ADD(A01 * S1) ADD(A02 + S2) END
                  assign PROG[2]  = 460'h00000_00000_00000_00000_00000_00000_FFFFF_11044_4106C_0B0F6_0444C_04064_0A0F6_5033B_1023B_27FF6_5012B_1002B_0AFF6_01111_0DAF6_00011_0C4F6; // k = 4, keygen, NTT(S1), NTT(E1), PWM(A01*S1), PWM(A11*S1), PWM(A21*S1), PWM(A31*S1) END
                  assign PROG[3]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_10144_05CF6_5013B_1002B_144F6_00011_18AF6; // k = 2, encap,  NTT(Y1), PWM(AT01*Y1), PWM(AT11*Y1), ADD(AT10*Y0 + A11*Y1), INTT(Ay) END
                  assign PROG[4]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3004C_04CF6_00012_0DDF6_0006C_00044_054F6_1023B_5012B_1002B_15BF6_3038B_00011_1CBF6; // k = 3, encap,  NTT(Y1), PWM(T1*Y1), PWM(AT01*Y1), PWM(AT11*Y1), PWM(AT21*Y1), ADD(AT00*Y0 + AT01*Y1), ADD(S0 + A02*Y2), INTT(S0), ADD(S0 + E0), END
                  assign PROG[5]  = 460'h00000_00000_00000_00000_00000_FFFFF_60264_046F6_0661A_047F6_06674_0664C_06064_0A0F6_5053B_1043B_1F4F6_5012B_1002B_3CAF6_2038B_00011_22EF6; // k = 4, encap,  NTT(Y1), PWM(T1*Y1), PWM(AT01*Y1), PWM(AT11*Y1), PWM(AT21*Y1), PWM(AT31*Y1) END
                  assign PROG[6]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_1111A_01044_0108B_01111; // k = 2, decap, NTT(U1), PWM(S1*U1), ADD(S0*U0 + S1*U1), NTT-1(SU) END
                  assign PROG[7]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0106C_01044_0108B_01111; // k = 3, decap, NTT(U0), PWM(S0*U0) CLEAN, END
                  assign PROG[8]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_00074_0006C_00044_0108B_01111; // k = 4, decap, NTT(U0), PWM(S0*U0) END
                  assign PROG[9]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_10144_05CF6_5013B_1002B_144F6_00011_0B8F6; // k = 2, decap - encap,  NTT(Y1), PWM(AT01*Y1), PWM(AT11*Y1), ADD(AT10*Y0 + A11*Y1), INTT(Ay) END
                  assign PROG[10] = 460'h00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3004C_04CF6_00012_0DDF6_0006C_00044_054F6_1023B_5012B_1002B_15BF6_3038B_00011_0A0F6; // k = 3, decap - encap,  NTT(Y1), PWM(T1*Y1), PWM(AT01*Y1), PWM(AT11*Y1), PWM(AT21*Y1), ADD(AT00*Y0 + AT01*Y1), ADD(S0 + A02*Y2), INTT(S0), ADD(S0 + E0), END
                  assign PROG[11] = 460'h00000_00000_00000_00000_00000_FFFFF_60264_046F6_0661A_047F6_06674_0664C_06064_0A0F6_5053B_1043B_1F4F6_5012B_1002B_3CAF6_2038B_00011_0AAF6; // k = 4, decap - encap,  NTT(Y1), PWM(T1*Y1), PWM(AT01*Y1), PWM(AT11*Y1), PWM(AT21*Y1), PWM(AT31*Y1) END
              end
              else if (UNIT == 3) begin
                  assign PROG[0]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00054_0004C_0BCF6_00011_140F6; // k = 2, keygen, NTT(E0), ADD(A00*S0 + E0) (31), ADD(A0 + A01*S1)(32) END
                  assign PROG[1]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4104C_090F6_1445C_14144_0F0F6_2023B_6012B_2002B_01111_07AF6_00011_102F6; // k = 3, keygen, NTT(S2), NTT(E2), PWM(A22*S2), PWM(A02*S2), PWM(A12*S2), ADD(E0 + A00*S0), ADD(A01 * S1) ADD(A02 + S2) END
                  assign PROG[2]  = 460'h00000_00000_00000_00000_00000_00000_00000_FFFFF_21054_4107C_0AEF6_1445C_14174_6033B_2023B_23EF6_6012B_2002B_0AEF6_01111_0DAF6_00011_106F6; // k = 4, keygen, NTT(S2), NTT(E2), PWM(A02*S2), PWM(A12*S2), PWM(A22*S2), PWM(A32*S2) END
                  assign PROG[3]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00074_04CF6_3007C_02154_01044_140F6_00212_3028B_0F2F6_00211_1DCF6; // k = 2, encap, NTT(Y0), PWM(T0*y0),  END
                  assign PROG[4]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3105C_09DF6_01112_1114C_11154_172F6_2023B_6012B_2002B_11AF6_3038B_00011_20CF6; // k = 3, encap,  NTT(Y3), PWM(T2*Y2), PWM(AT02*Y2), PWM(AT12*Y2), PWM(AT22*Y2), ADD(AT10*Y0 + AT11*Y1), ADD(S1 + A12*Y2), INTT(S1), ADD(S1 + E1), END
                  assign PROG[5]  = 460'h00000_00000_00000_00000_00000_00000_00000_FFFFF_60274_0661A_16644_0EAF6_1665C_16174_6053B_2043B_1F4F6_6012B_2002B_388F6_2038B_00011_270F6; // k = 4, encap,  NTT(Y2), PWM(T2*Y2), PWM(AT02*Y2), PWM(AT12*Y2), PWM(AT22*Y2), PWM(AT32*Y2) END
                  assign PROG[6]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF; // k = 2, decap, END
                  assign PROG[7]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0001A_00054_0006C_090F6_0108B_01111; // k = 3, decap, END
                  assign PROG[8]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0108B_01111; // k = 4, decap, END
                  assign PROG[9]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00074_04CF6_3007C_02154_01044_140F6_00212_3028B_0F2F6_00211_10AF6; // k = 2, decap - encap, NTT(Y0), PWM(T0*y0),  END
                  assign PROG[10] = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3105C_09DF6_01112_1114C_11154_172F6_2023B_6012B_2002B_11AF6_3038B_00011_0E2F6; // k = 3, decap - encap,  NTT(Y3), PWM(T2*Y2), PWM(AT02*Y2), PWM(AT12*Y2), PWM(AT22*Y2), ADD(AT10*Y0 + AT11*Y1), ADD(S1 + A12*Y2), INTT(S1), ADD(S1 + E1), END
                  assign PROG[11] = 460'h00000_00000_00000_00000_00000_00000_00000_FFFFF_60274_0661A_16644_0EAF6_1665C_16174_6053B_2043B_1F4F6_6012B_2002B_388F6_2038B_00011_0ECF6; // k = 4, decap - encap,  NTT(Y2), PWM(T2*Y2), PWM(AT02*Y2), PWM(AT12*Y2), PWM(AT22*Y2), PWM(AT32*Y2) END
              end
              else begin
                  assign PROG[0]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_10054_1004C_0B8F6_00011_190F6; // k = 2, keygen, NTT(E1), ADD(A11*S1 + E1) (42), ADD(A1 + A10*S0) (41) END
                  assign PROG[1]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF; // k = 3, keygen, 
                  assign PROG[2]  = 460'h00000_00000_00000_00000_00000_00000_FFFFF_31064_4104C_0AEF6_2446C_24244_0A0F6_7033B_3023B_1FCF6_7012B_3002B_0AEF6_01111_0DAF6_00011_148F6; // k = 4, keygen, NTT(S3), NTT(E3), PWM(A03*S3), PWM(A13*S3), PWM(A23*S3), PWM(A33*S3) END
                  assign PROG[3]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3006C_1E2F6_00012_3008B_0E0F6_00211_22EF6; // k = 2, encap, NTT(Y1), PWM(T1*y1), ADD(T0Y0 + T1Y1), INTT(ty) END
                  assign PROG[4]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_40344_0F8F6_0001A_0B8F6_30064_3005C_30044_0007C_3ECF6; // k = 3, encap, CLEAN(ADD), This probably create some problems in synthesis if RAM is not at 0
                  assign PROG[5]  = 460'hFFFFF_33344_60244_046F6_0661A_46654_045F6_4666C_46444_0A0F6_7053B_3043B_1F4F6_7012B_3002B_047F6_0331A_33364_3335C_33344_2038B_00011_2B2F6; // k = 4, encap,  NTT(Y3), PWM(T3*Y3), PWM(AT03*Y3), PWM(AT13*Y3), PWM(AT23*Y3), PWM(AT33*Y3) END
                  assign PROG[6]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_10255_516F6; // k = 2, decap, SUB(v - NTT-1(SU)) END
                  assign PROG[7]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00265_5FDF6; // k = 3, decap, SUB(v - NTT-1(SU)) END
                  assign PROG[8]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00255_2FBF6_0108B_01111; // k = 4, decap, SUB(v - NTT-1(SU)) END
                  assign PROG[9]  = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3006C_1E2F6_00012_3008B_0E0F6_00211_15CF6; // k = 2, decap - encap, NTT(Y1), PWM(T1*y1), ADD(T0Y0 + T1Y1), INTT(ty) END
                  assign PROG[10] = 460'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_40344_0F8F6_0001A_0B8F6_30064_3005C_30044_0007C_2C1F6; // k = 3, decap - encap, CLEAN(ADD), This probably create some problems in synthesis if RAM is not at 0
                  assign PROG[11] = 460'hFFFFF_33344_60244_046F6_0661A_46654_045F6_4666C_46444_0A0F6_7053B_3043B_1F4F6_7012B_3002B_047F6_0331A_33364_3335C_33344_2038B_00011_12EF6; // k = 4, decap - encap,  NTT(Y3), PWM(T3*Y3), PWM(AT03*Y3), PWM(AT13*Y3), PWM(AT23*Y3), PWM(AT33*Y3) END
              end
		  end
		  if(N_UNITS == 2) begin
		      if(UNIT == 1) begin
		          assign PROG_2[0]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4205C_050F6_12154_050F6_0244C_4013B_0002B_02211_00011_170F6; // k = 2, keygen, NTT(S0), NTT(E0), PWM(A00*S0), PWM(A10*S0), E0 + A00*S0, END
                  assign PROG_2[1]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_6315C_4444C_54554_4205C_17CF6_2163B_6152B_2142B_0023B_4012B_0002B_03311_02211_01111_00011_1C6F6; // k = 3, keygen, NTT(S0), NTT(S2), NTT(E0)
                  assign PROG_2[2]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_05754_050F6_7605C_36354_04554_050F6_5605C_16154_045F6_0305C_0E8F6_0205C_090F6_6173B_2163B_6152B_2142B_4033B_0023B_4012B_0002B_03311_02211_01111_00011_260F6; // k = 4, keygen, NTT(S0), NTT(S2), NTT(E0), NTT(E2), END
                  assign PROG_2[3]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00254_0201A_044F6_12154_4013B_0002B_2FAF6_5058B_00011_270F6; // k = 2, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[4]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_1111A_11154_0E0F6_2143B_6112B_2102B_0E0F6_0043B_4012B_0002B_345F6_6168B_5058B_01111_00011_320F6; // k = 3, encap, NTT(Y0), NTT(y2), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[5]   = 720'h00000_00000_00000_00000_00000_FFFFF_3415C_2005C_44412_00012_5545C_1405C_1CCF6_7744C_6604C_47454_06054_6153B_2143B_6112B_2102B_096F6_55554_14154_4053B_0043B_4012B_0002B_349F6_0454C_54554_6168B_5058B_01111_00011_400F6; // k = 4, encap, NTT(Y0), NTT(Y2)
                  assign PROG_2[6]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_70055_0001A_00054_4008B_00011; // k = 2, decap, NTT(U0), U0*S0, , US, v - US, PWM(S0*U0) END
                  assign PROG_2[7]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00755_300F6_5118B_4008B_01111_00011; // k = 3, decap, NTT(U0), NTT(U2), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                  assign PROG_2[8]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00755_300F6_0004C_00054_5118B_4008B_01111_00011; // k = 4, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                  assign PROG_2[9]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00254_0201A_044F6_12154_4013B_0002B_2FAF6_5058B_00011_1A9F6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[10]  = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_1111A_11154_0E0F6_2143B_6112B_2102B_0E0F6_0043B_4012B_0002B_345F6_6168B_5058B_01111_00011_250F6; // k = 3, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[11]  = 720'h00000_00000_00000_00000_00000_FFFFF_3415C_2005C_44412_00012_5545C_1405C_1CCF6_7744C_6604C_47454_06054_6153B_2143B_6112B_2102B_096F6_55554_14154_4053B_0043B_4012B_0002B_349F6_0454C_54554_6168B_5058B_01111_00011_284F6; // k = 4, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
		      end
		      else begin
		          assign PROG_2[0]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4204C_050F6_02044_0245C_5013B_1002B_02211_00011_170F6; // k = 2, keygen, NTT(S1), NTT(E1), PWM(A01*S1), PWM(A11*S1), E0 + A00*S0, END
                  assign PROG_2[1]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_42144_128F6_1254C_6664C_26244_4444C_04044_5F0F6_1023B_5012B_1002B_02211_00011_1C6F6; // k = 3, keygen, NTT(S1), NTT(E1), PWM(A01*S1), PWM(A11*S1), NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                  assign PROG_2[2]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0304C_0E8F6_0204C_096F6_05644_045F6_6504C_25244_04444_045F6_4404C_04044_7173B_3163B_7152B_3142B_5033B_1023B_5012B_1002B_03311_02211_01111_00011_260F6; // k = 4, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                  assign PROG_2[3]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00244_040F6_0201A_02044_040F6_5013B_1002B_7574C_45544_0551A_55544_5058B_00011_270F6; // k = 2, encap, NTT(Y1), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[4]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3444C_11244_2004C_44412_00012_050F6_4444C_1115C_0004C_1B0F6_44444_11144_00044_1043B_5012B_1002B_77544_4554C_05512_6554C_55544_2A8F6_5058B_00011_320F6; // k = 3, encap, NTT(Y1), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[5]   = 720'hFFFFF_3414C_2004C_097F6_44412_00012_097F6_5555C_4415C_55544_14144_4544C_0404C_130F6_7153B_3143B_7112B_3102B_45444_04044_096F6_5053B_1043B_5012B_1002B_47744_7474C_04412_6444C_54644_096F6_6168B_5058B_01111_00011_400F6; // k = 4, encap, NTT(Y1), NTT(Y3)
                  assign PROG_2[6]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_4008B_00011; // k = 2, decap, NTT(U1), U1*S1 END
                  assign PROG_2[7]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_0005C_00012_1004C_00044_2A8F6_4008B_00011; // k = 3, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                  assign PROG_2[8]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_300F6_0005C_00012_1004C_00144_096F6_5118B_4008B_01111_00011; // k = 4, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                  assign PROG_2[9]   = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00244_040F6_0201A_02044_040F6_5013B_1002B_7574C_45544_0551A_55544_5058B_00011_1A9F6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[10]  = 720'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_3444C_11244_2004C_44412_00012_050F6_4444C_1115C_0004C_1B0F6_44444_11144_00044_1043B_5012B_1002B_77544_4554C_05512_6554C_55544_2A8F6_5058B_00011_250F6; // k = 3, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                  assign PROG_2[11]  = 720'hFFFFF_3414C_2004C_097F6_44412_00012_097F6_5555C_4415C_55544_14144_4544C_0404C_130F6_7153B_3143B_7112B_3102B_45444_04044_096F6_5053B_1043B_5012B_1002B_47744_7474C_04412_6444C_54644_096F6_6168B_5058B_01111_00011_284F6; // k = 4, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
		      
		      end
		  end
		  else begin
                    assign PROG_1[0]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_5314C_4204C_75644_54444_5173B_4063B_1152B_0042B_03311_02211_01111_00011_170F6; // k = 2, keygen, NTT(S0), NTT(S1), NTT(E0), NTT(E1), PWM(A00*S0), PWM(A01*S1), PWM(A10*S0), PWM(A11*S1), E0 + A00*S0, END
                    assign PROG_1[1]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_26044_6704C_06611_17044_2223B_1113B_0003B_25044_5704C_05511_17044_6222B_5112B_4002B_24044_4704C_04411_17044_2222B_1112B_0002B_02211_01111_00011_200F6; // k = 3, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                    assign PROG_1[2]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_7674C_06054_37244_6704C_07711_16044_7333B_6223B_5113B_4003B_7664C_06054_37244_6704C_06611_17044_3333B_2223B_1113B_0003B_7554C_05054_37244_5704C_05511_17044_7332B_6222B_5112B_4002B_7444C_04054_37244_4704C_04411_17044_3332B_2222B_1112B_0002B_03311_02211_01111_00011_260F6; // k = 4, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                    assign PROG_1[3]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_270F6; // k = 2, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                    assign PROG_1[4]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_360F6; // k = 3, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                    assign PROG_1[5]   = 1140'hFFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_A30F6_02211_01111_00011_270F6; // k = 4, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                    assign PROG_1[6]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00245_0001A_10044_5118B_4008B_11111_00011; // k = 2, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                    assign PROG_1[7]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00345_0001A_20044_0005C_10044_6228B_5118B_4008B_22211_11111_00011; // k = 3, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                    assign PROG_1[8]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00445_0001A_00054_0104C_31244_10044_7338B_6228B_5118B_4008B_33311_22211_11111_00011; // k = 4, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                    assign PROG_1[9]   = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_1A9F6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                    assign PROG_1[10]  = 1140'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_250F6; // k = 3, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                    assign PROG_1[11]  = 1140'hFFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_A30F6_02211_01111_00011_0F4F6; // k = 4, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
            end
		endgenerate
endmodule


module PRIORITY_ENCODER (
    input       [3:0]   busy_bu,
    input               cond1,
    input               cond2,
    input               cond3,
    input               cond4,
    output reg  [3:0]   busy_bu_N
    );

    // -- Priority Encoder -- //
    wire    [3:0]   busy_bu_1 = busy_bu;

    always @* begin
        if(busy_bu[0])      busy_bu_N[0] = 1;
        else begin  
            if(cond1)       busy_bu_N[0] = 1;
            else            busy_bu_N[0] = 0;
        end
        
        if(busy_bu[1])      busy_bu_N[1] = 1;
        else begin  
            if(cond2)       busy_bu_N[1] = 1;
            else            busy_bu_N[1] = 0;
        end
        
        if(busy_bu[2])      busy_bu_N[2] = 1;
        else begin  
            if(cond3)       busy_bu_N[2] = 1;
            else            busy_bu_N[2] = 0;
        end
        
        if(busy_bu[3])      busy_bu_N[3] = 1;
        else begin  
            if(cond4)       busy_bu_N[3] = 1;
            else            busy_bu_N[3] = 0;
        end
        
    end
    
endmodule
