`timescale 1ns / 1ps

module CONTROL_BU_MASKED #(
    parameter UNIT = 1,
    parameter KECCAK_PROT = 1,
    parameter N_BU = 2,
    parameter SHUFF_DELAY = 539
)(
    input                   clk,
    input                   rst,
    input       [3:0]       mode,
    input                   start,
    input                   start_ed,
    input       [3:0]       random_op,
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
    
    /*
    assign reset    = (ctl_bu[2:0] == 3'b000) ? 1 : 0;
    assign ntt      = (ctl_bu[2:0] == 3'b001) ? 1 : 0;
    assign intt     = (ctl_bu[2:0] == 3'b010) ? 1 : 0;
    assign pwm      = (ctl_bu[2:0] == 3'b011) ? 1 : 0;
    assign add      = (ctl_bu[2:0] == 3'b100) ? 1 : 0;
    assign sub      = (ctl_bu[2:0] == 3'b101) ? 1 : 0;
    */
    
    //--*** STATE declaration **--//
	localparam IDLE                 = 4'h0;
	localparam FETCH_INST           = 4'h1; 
	localparam LOAD_INST            = 4'h2;
	localparam START_BU             = 4'h3;
	localparam START_BU_IDLE_0      = 4'h4;
	localparam START_BU_IDLE_1      = 4'h5;
	localparam UPDATE_INST          = 4'h6;
	localparam DELAY                = 4'h7;
	localparam END_DELAY            = 4'h8;
    localparam RANDOM_STOP          = 4'h9;
    localparam RESET_RANDOM_CNT     = 4'hA;
	localparam END_OP               = 4'hF;
    
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
    
    reg [15:0]   random_delay;

    localparam SHUFF_DELAY_CYCLES_0 = 0 * SHUFF_DELAY;
    localparam SHUFF_DELAY_CYCLES_1 = 1 * SHUFF_DELAY;
    localparam SHUFF_DELAY_CYCLES_2 = 2 * SHUFF_DELAY;
    localparam SHUFF_DELAY_CYCLES_3 = 3 * SHUFF_DELAY;

    always @(posedge clk) begin
        if(!rst)                                        random_delay <= 0;
        else begin
            
            /*
            case(random_op[1:0])
                2'b00: random_delay <= 12'h000;
                2'b01: random_delay <= 12'h21B;
                2'b10: random_delay <= 12'h436;
                2'b11: random_delay <= 12'h651;
            endcase
            */
            
            case(random_op[1:0])
                2'b00: random_delay <= SHUFF_DELAY_CYCLES_0;
                2'b01: random_delay <= SHUFF_DELAY_CYCLES_1;
                2'b10: random_delay <= SHUFF_DELAY_CYCLES_2;
                2'b11: random_delay <= SHUFF_DELAY_CYCLES_3;
            endcase
            
            // random_delay <= (UNIT-1) * 16'h0CE5; // 3301 cycles
            // random_delay <= (UNIT-1) * 16'h1260;    // 4704 cycles
        end
    end
    
    reg [15:0]   counter_delay;
    reg          end_counter_delay;
    
    always @(posedge clk) begin
        if(!rst | cs_bu == UPDATE_INST)                 counter_delay <= 0;
        else begin
            if(cs_bu == DELAY | cs_bu == RANDOM_STOP)   counter_delay <= counter_delay + 1;
            else                                        counter_delay <= 0;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | cs_bu == UPDATE_INST | cs_bu == RESET_RANDOM_CNT)         end_counter_delay <= 1'b0;
        else begin
            if(cs_bu == DELAY & counter_delay == {5'b0000,inst[19:08]})               end_counter_delay <= 1'b1;
            else if(cs_bu == RANDOM_STOP & counter_delay == random_delay)   end_counter_delay <= 1'b1;
            else                                                            end_counter_delay <= end_counter_delay;
        end
    end
    

    wire [3:0] sel_dmu;
    
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
	
	wire [3:0] off_ram_0;
    wire [3:0] off_ram_1;
    assign off_ram = {off_ram_1, off_ram_0};
	
	assign mode_bu     = (cs_bu == IDLE | cs_bu == UPDATE_INST) ? 4'b0000 : inst[03:00];
	// assign mode_bu     = (cs_bu == IDLE) ? 4'b0000 : inst[03:00];
	assign sel_dmu     = inst[07:04];
	assign off_ram_0   = inst[11:08];
	assign off_ram_1   = inst[15:12];
	assign off_rej     = inst[19:16];
	
	always @* begin
        case (cs_bu)
            IDLE:
                if (start)
                    ns_bu = RANDOM_STOP;
                else
                    ns_bu = IDLE;
            RANDOM_STOP:
                if(end_counter_delay)
                    ns_bu = RESET_RANDOM_CNT;
                else
                    ns_bu = RANDOM_STOP;
            RESET_RANDOM_CNT:
                ns_bu = FETCH_INST;
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
		
	   
	   always @(posedge clk) begin
	       if(!rst | cs_bu == UPDATE_INST | cs_bu == END_OP)      start_bu <= 1'b0;
	       else if(    cs_bu == START_BU)                         start_bu <= 1'b1;
	       else                                                   start_bu <= start_bu;
	   end
	  
	    wire [1199:0] PROG_MASKED [0:11];
	   
        reg  [1199:0] c_inst;
        assign inst = c_inst[19:0];

        always @(posedge clk) begin
            if(!rst | cs_bu == IDLE) begin
                        if(k_2 & gen_keys)  c_inst <= PROG_MASKED[0];
                else    if(k_3 & gen_keys)  c_inst <= PROG_MASKED[1];
                else    if(k_4 & gen_keys)  c_inst <= PROG_MASKED[2];
                else    if(k_2 & start_ed)  c_inst <= PROG_MASKED[9];  // encap from decap
                else    if(k_3 & start_ed)  c_inst <= PROG_MASKED[10]; // encap from decap
                else    if(k_4 & start_ed)  c_inst <= PROG_MASKED[11]; // encap from decap
                else    if(k_2 & encap)     c_inst <= PROG_MASKED[3];
                else    if(k_3 & encap)     c_inst <= PROG_MASKED[4];
                else    if(k_4 & encap)     c_inst <= PROG_MASKED[5];
                else    if(k_2 & decap)     c_inst <= PROG_MASKED[6];
                else    if(k_3 & decap)     c_inst <= PROG_MASKED[7];
                else    if(k_4 & decap)     c_inst <= PROG_MASKED[8];
                else                        c_inst <= 0;
            end
            else begin
                if(cs_bu == UPDATE_INST)    c_inst <= c_inst >> 20;
                else                        c_inst <= c_inst;
            end
        end
		
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
            if(N_BU != 1 & KECCAK_PROT) begin
                assign PROG_MASKED[0]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_5314C_4204C_75644_54444_5173B_4063B_1152B_0042B_03311_02211_01111_00011_360F6; // k = 2, keygen, NTT(S0), NTT(S1), NTT(E0), NTT(E1), PWM(A00*S0), PWM(A01*S1), PWM(A10*S0), PWM(A11*S1), E0 + A00*S0, END
                assign PROG_MASKED[1]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_26044_6704C_06611_17044_2223B_1113B_0003B_25044_5704C_05511_17044_6222B_5112B_4002B_24044_4704C_04411_17044_2222B_1112B_0002B_02211_01111_00011_4E0F6; // k = 3, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                assign PROG_MASKED[2]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_7674C_06054_37244_6704C_07711_16044_7333B_6223B_5113B_4003B_7664C_06054_37244_6704C_06611_17044_3333B_2223B_1113B_0003B_7554C_05054_37244_5704C_05511_17044_7332B_6222B_5112B_4002B_7444C_04054_37244_4704C_04411_17044_3332B_2222B_1112B_0002B_03311_02211_01111_00011_660F6; // k = 4, keygen, NTT(S0), NTT(S1), NTT(S2), NTT(S3), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), PWM(A03*S3), ADD(T0_1), NTT(E0), ADD(T0_2), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                assign PROG_MASKED[3]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_4D0F6; // k = 2, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[4]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_6B0F6; // k = 3, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[5]   = 1200'h00000_00000_00000_FFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_CD0F6_02211_01111_00011_440F6; // k = 4, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[6]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00245_0001A_10044_5118B_4008B_11111_00011; // k = 2, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[7]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00345_0001A_20044_0005C_10044_6228B_5118B_4008B_22211_11111_00011; // k = 3, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[8]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00445_0001A_00054_0104C_31244_10044_7338B_6228B_5118B_4008B_33311_22211_11111_00011; // k = 4, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[9]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_400F6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[10]  = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_580F6; // k = 3, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[11]  = 1200'h00000_00000_00000_FFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_C00F6_02211_01111_00011_360F6; // k = 4, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
            end
            else begin
                assign PROG_MASKED[0]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_5314C_4204C_75644_54444_5173B_4063B_1152B_0042B_03311_02211_01111_00011_170F6; // k = 2, keygen, NTT(S0), NTT(S1), NTT(E0), NTT(E1), PWM(A00*S0), PWM(A01*S1), PWM(A10*S0), PWM(A11*S1), E0 + A00*S0, END
                assign PROG_MASKED[1]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_26044_6704C_06611_17044_2223B_1113B_0003B_25044_5704C_05511_17044_6222B_5112B_4002B_24044_4704C_04411_17044_2222B_1112B_0002B_02211_01111_00011_200F6; // k = 3, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                assign PROG_MASKED[2]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_7674C_06054_37244_6704C_07711_16044_7333B_6223B_5113B_4003B_7664C_06054_37244_6704C_06611_17044_3333B_2223B_1113B_0003B_7554C_05054_37244_5704C_05511_17044_7332B_6222B_5112B_4002B_7444C_04054_37244_4704C_04411_17044_3332B_2222B_1112B_0002B_03311_02211_01111_00011_260F6; // k = 4, keygen, NTT(S0), NTT(S1), NTT(S2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), NTT(E0), ADD(T0_2), NTT(E1), NTT(E2), PWM(A00*S0), PWM(A01*S1), PWM(A02*S2), ADD(T0_1), ADD(T0_2), ADD(T0_3), PWM(A10*S0), PWM(A11*S1), PWM(A12*S2), PWM(A20*S0), PWM(A21*S1), PWM(A22*S2), END
                assign PROG_MASKED[3]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_270F6; // k = 2, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[4]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_360F6; // k = 3, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[5]   = 1200'h00000_00000_00000_FFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_A30F6_02211_01111_00011_270F6; // k = 4, encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[6]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00245_0001A_10044_5118B_4008B_11111_00011; // k = 2, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[7]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00345_0001A_20044_0005C_10044_6228B_5118B_4008B_22211_11111_00011; // k = 3, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[8]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_00445_0001A_00054_0104C_31244_10044_7338B_6228B_5118B_4008B_33311_22211_11111_00011; // k = 4, decap, NTT(U0), NTT(U1), U0*S0, U1*S1, US, v - US, PWM(S0*U0) END
                assign PROG_MASKED[9]   = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_15044_0515C_0401A_75344_14044_5118B_4008B_57144_0711A_17044_5113B_4003B_46044_0601A_16044_1112B_0002B_01111_00011_1A9F6; // k = 2, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[10]  = 1200'h00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_00000_FFFFF_66044_0601A_26044_0605C_16044_2223B_1113B_0003B_55044_0501A_25044_0505C_15044_6222B_5112B_4002B_44044_0401A_24044_0405C_14044_2222B_1112B_0002B_77044_0775C_77344_0601A_26044_0605C_16044_6228B_5118B_4008B_02211_01111_00011_250F6; // k = 3, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
                assign PROG_MASKED[11]  = 1200'h00000_00000_00000_FFFFF_77044_0705C_07012_0704C_10044_7313B_6203B_17044_5113B_4003B_66044_0605C_06012_7604C_17044_3313B_2203B_16044_1113B_0003B_55044_0505C_05012_6504C_16044_7312B_6202B_15044_5112B_4002B_44044_0405C_04012_5404C_15044_3312B_2202B_14044_1112B_0002B_4534C_35244_04012_5404C_15044_7318B_6208B_14044_5118B_4008B_03011_A30F6_02211_01111_00011_0F4F6; // k = 4, decap - encap, NTT(Y0), PWM(AT00*Y0), PWM(AT10*Y0), ADD(AT00*Y0 + A01*Y1), INTT(Ay) END
            end
        endgenerate
endmodule
