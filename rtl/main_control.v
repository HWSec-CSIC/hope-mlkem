`timescale 1ns / 1ps

module MAIN_CONTROL #(
    parameter N_BU = 4
)(
    input           clk,
    input           rst,
    input   [7:0]   control,
    input           start_core,
    output          end_op_core,

    output  [7:0]   i,
    output  [7:0]   j,
    
    output  [11:0]  ctl_keccak,
    input           end_op_keccak,
    output  [7:0]   ctl_cbd,
    input           end_op_cbd,
    output  [3:0]   ctl_rej,
    output  [3:0]   off_rej,
    output  [15:0]  off_rej_dmu,
    input   [1:0]   end_op_rej,
    output  [19:0]  ctl_bu,
    input   [3:0]   end_op_bu,
    output  [40:0]  control_dmu,
    output  [31:0]  off_ram,

    output          start_read_ek,
    input           start_hek,
    input           last_hek,

    input           gmh_decap,
    input           start_ed
    
    );
    
    // --- GLOBAL CONTROL --- //
    
    wire end_op_op;
    wire end_op_bu_1;
    wire end_op_bu_2;
    wire end_op_bu_3;
    wire end_op_bu_4;
    
    generate
    if(N_BU == 4) 
        assign end_op_op = end_op_bu_1 & end_op_bu_2 & end_op_bu_3 & end_op_bu_4;
    else if(N_BU == 2)
        assign end_op_op = end_op_bu_1 & end_op_bu_2;
    else
        assign end_op_op = end_op_bu_1;
    endgenerate
    wire [11:0]             ctl_k_global;
    wire [7:0]              i_global;
    wire start_op;
    wire sel_global;
        
    GLOBAL_CONTROL  GLOBAL_CONTROL  (
    .clk                (   clk             ),
    .rst                (   rst             ),
    .control            (   control         ),
    .start_op           (   start_op        ),
    .i_global           (   i_global        ),
    .start_core         (   start_core      ),
    .end_op_core        (   end_op_op       ),
    .end_op_keccak      (   end_op_keccak   ),
    .control_keccak     (   ctl_k_global    ),
    .sel_global         (   sel_global      ),
    .start_read_ek      (   start_read_ek   ),
    .start_hek          (   start_hek       ),
    .last_hek           (   last_hek        ),
    .end_op             (   end_op_core     ),
    .gmh                (   gmh_decap       ),
    .start_ed           (   start_ed        )
    );
    
    // --- CONTROL KECCAK+CBD+REJ--- //
    wire [11:0] ctl_k;
    wire [7:0] i_k;
    wire  [34:0]  control_dmu_cbd;
    wire  [15:0]  off_ram_cbd;
    
    wire [1:0]  eta;
    wire scnd;
    wire sel_rej;

    wire [3:0] busy_bu;

    wire reset_cbd;
    wire reset_rej;
    wire load_cbd;
    wire load_rej;
    wire start_cbd;
    wire start_rej;
    
    CONTROL_KECCAK #(
        .MASKED(0),
        .N_BU(N_BU)
    )
    CONTROL_KECCAK (
        .clk                (   clk             ),
        .rst                (   rst             ),
        .start              (   start_op        ),
        .mode               (   control[7:4]    ),
        .ctl_k              (   ctl_k           ),
        .i                  (   i_k             ),
        .j                  (   j               ),
        .reset_cbd          (   reset_cbd       ),
        .reset_rej          (   reset_rej       ),
        .load_cbd           (   load_cbd        ),
        .load_rej           (   load_rej        ),
        .start_cbd          (   start_cbd       ),
        .start_rej          (   start_rej       ),
        .eta                (   eta             ),    
        .scnd               (   scnd            ),
        .sel_rej            (   sel_rej         ),
        .control_dmu_cbd    (   control_dmu_cbd ),
        .off_ram_cbd        (   off_ram_cbd     ),
        .off_rej            (   off_rej         ),
        .end_op_cbd         (   end_op_cbd      ),
        .end_op_rej         (   end_op_rej[0]   ),
        .end_rd_rej         (   end_op_rej[1]   ),
        .end_op_keccak      (   end_op_keccak   ),
        .end_op_bu         (   end_op_bu      )
    );
   
    
    assign ctl_keccak   = (sel_global) ? ctl_k_global   : ctl_k;
    assign i            = (sel_global) ? i_global : i_k;
    
    assign ctl_cbd      = {start_cbd, load_cbd, scnd, eta, reset_cbd};
    assign ctl_rej      = {start_rej, load_rej, sel_rej, reset_rej}; 
    
    
    // --- CONTROL BUTTERFLY UNIT --- //
    
    wire  [34:0]  control_dmu_bu;
    wire  [31:0]  off_ram_bu;
    
    wire start_bu_1;
    wire start_bu_2;
    wire start_bu_3;
    wire start_bu_4;
    wire [3:0] mode_bu_1;
    wire [3:0] mode_bu_2;
    wire [3:0] mode_bu_3;
    wire [3:0] mode_bu_4;    
    
    wire busy_cbd   = start_cbd & !end_op_cbd;
    wire busy_r0    = start_rej & !sel_rej & !end_op_rej[1];
    wire busy_r1    = start_rej &  sel_rej & !end_op_rej[1];
 
    assign busy_bu[0] = start_bu_1 & !end_op_bu[0];
    assign busy_bu[1] = start_bu_2 & !end_op_bu[1];
    assign busy_bu[2] = start_bu_3 & !end_op_bu[2];
    assign busy_bu[3] = start_bu_4 & !end_op_bu[3];
    
    wire [3:0] read_1 = {control_dmu_bu[28], control_dmu_bu[20], control_dmu_bu[12], control_dmu_bu[4]};
    wire [3:0] read_2 = {control_dmu_bu[29], control_dmu_bu[21], control_dmu_bu[13], control_dmu_bu[5]};
    wire [3:0] read_3 = {control_dmu_bu[30], control_dmu_bu[22], control_dmu_bu[14], control_dmu_bu[6]};
    wire [3:0] read_4 = {control_dmu_bu[31], control_dmu_bu[23], control_dmu_bu[15], control_dmu_bu[7]};
    
    // -- Priority Encoder -- //
    wire    [3:0]   busy_bu_1, busy_bu_2, busy_bu_3, busy_bu_4;
    reg     [3:0]   busy_bu_1_reg, busy_bu_2_reg, busy_bu_3_reg;
    always @(posedge clk) begin
        busy_bu_1_reg <= busy_bu_1;
        busy_bu_2_reg <= busy_bu_2;
        busy_bu_3_reg <= busy_bu_3;
    end
    
    PRIORITY_ENCODER PE1 (
        .busy_bu(busy_bu),
        .cond1(read_1[0]),
        .cond2(read_2[0]),
        .cond3(read_3[0]),
        .cond4(read_4[0]),
        .busy_bu_N(busy_bu_1)
    );
    PRIORITY_ENCODER PE2 (
        .busy_bu(busy_bu_1_reg),
        // .busy_bu(busy_bu_1),
        .cond1(read_1[1] | read_1[0]),
        .cond2(read_2[1] | read_2[0]),
        .cond3(read_3[1] | read_3[0]),
        .cond4(read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_2)
    );
    PRIORITY_ENCODER PE3 (
        .busy_bu(busy_bu_2_reg),
        .cond1(read_1[2] | read_1[1] | read_1[0]),
        .cond2(read_2[2] | read_2[1] | read_2[0]),
        .cond3(read_3[2] | read_3[1] | read_3[0]),
        .cond4(read_4[2] | read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_3)
    );
    PRIORITY_ENCODER PE4 (
        .busy_bu(busy_bu_3_reg),
        .cond1(read_1[3] | read_1[2] | read_1[1] | read_1[0]),
        .cond2(read_2[3] | read_2[2] | read_2[1] | read_2[0]),
        .cond3(read_3[3] | read_3[2] | read_3[1] | read_3[0]),
        .cond4(read_4[3] | read_4[2] | read_4[1] | read_4[0]),
        .busy_bu_N(busy_bu_4)
    );

    
    CONTROL_BU #(.UNIT(1), .N_UNITS(N_BU)) CONTROL_BU_1 
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_1           ),
        .end_op_bu      (   end_op_bu[0]       ),
        .start_bu       (   start_bu_1          ),
        .mode_bu        (   mode_bu_1           ),
        .control_dmu    (   control_dmu_bu[7:0] ),
        .off_ram        (   off_ram_bu[7:0]     ),
        .off_rej        (   off_rej_dmu[3:0]    ),
        .end_op         (   end_op_bu_1         ),
        .start_ed       (   start_ed            )
    );
    
    CONTROL_BU #(.UNIT(2), .N_UNITS(N_BU)) CONTROL_BU_2 
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_2           ),
        .end_op_bu      (   end_op_bu[1]       ),
        .start_bu       (   start_bu_2          ),
        .mode_bu        (   mode_bu_2           ),
        .control_dmu    (   control_dmu_bu[15:8] ),
        .off_ram        (   off_ram_bu[15:8]    ),
        .off_rej        (   off_rej_dmu[7:4]    ),
        .end_op         (   end_op_bu_2         ),
        .start_ed       (   start_ed        )
    );
    
    CONTROL_BU #(.UNIT(3), .N_UNITS(N_BU)) CONTROL_BU_3 
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_3           ),
        .end_op_bu      (   end_op_bu[2]       ),
        .start_bu       (   start_bu_3          ),
        .mode_bu        (   mode_bu_3           ),
        .control_dmu    (   control_dmu_bu[23:16]    ),
        .off_ram        (   off_ram_bu[23:16]        ),
        .off_rej        (   off_rej_dmu[11:8]       ),
        .end_op         (   end_op_bu_3         ),
        .start_ed       (   start_ed        )
    );
    
    CONTROL_BU #(.UNIT(4), .N_UNITS(N_BU)) CONTROL_BU_4 
    (
        .clk            (   clk                 ),
        .rst            (   rst                 ),
        .mode           (   control[7:4]        ),
        .start          (   start_core          ),
        .busy_r0        (   busy_r0             ),
        .busy_r1        (   busy_r1             ),
        .busy_bu        (   busy_bu_4           ),
        .end_op_bu      (   end_op_bu[3]       ),
        .start_bu       (   start_bu_4          ),
        .mode_bu        (   mode_bu_4           ),
        .control_dmu    (   control_dmu_bu[31:24]   ),
        .off_ram        (   off_ram_bu[31:24]       ),
        .off_rej        (   off_rej_dmu[15:12]      ),
        .end_op         (   end_op_bu_4         ),
        .start_ed       (   start_ed        )
    );
    
    
    assign control_dmu[07:00] = (start_bu_1) ? control_dmu_bu[07:00] : control_dmu_cbd[07:00];
    assign control_dmu[15:08] = (start_bu_2) ? control_dmu_bu[15:08] : control_dmu_cbd[15:08];
    assign control_dmu[23:16] = (start_bu_3) ? control_dmu_bu[23:16] : control_dmu_cbd[23:16];
    assign control_dmu[31:24] = (start_bu_4) ? control_dmu_bu[31:24] : control_dmu_cbd[31:24];
    assign control_dmu[40:32] = 9'b000000000;
    
    assign off_ram[03:00] = (start_bu_1) ? off_ram_bu[03:00] : off_ram_cbd[03:00];  // off_ram_01
    assign off_ram[07:04] = (start_bu_1) ? off_ram_bu[07:04] : off_ram_cbd[03:00];  // off_ram_11
    
    assign off_ram[11:08] = (start_bu_2) ? off_ram_bu[11:08] : off_ram_cbd[07:04];  // off_ram_02
    assign off_ram[15:12] = (start_bu_2) ? off_ram_bu[15:12] : off_ram_cbd[07:04];  // off_ram_12
    
    assign off_ram[19:16] = (start_bu_3) ? off_ram_bu[19:16] : off_ram_cbd[11:08];  // off_ram_03
    assign off_ram[23:20] = (start_bu_3) ? off_ram_bu[23:20] : off_ram_cbd[11:08];  // off_ram_13
    
    assign off_ram[27:24] = (start_bu_4) ? off_ram_bu[27:24] : off_ram_cbd[15:12];  // off_ram_04
    assign off_ram[31:28] = (start_bu_4) ? off_ram_bu[31:28] : off_ram_cbd[15:12];  // off_ram_14
    
    
    assign ctl_bu = {  mode_bu_4,  mode_bu_3,  mode_bu_2,  mode_bu_1, 
                        start_bu_4, start_bu_3, start_bu_2, start_bu_1};
    
endmodule

module GLOBAL_CONTROL (
    input clk,
    input rst,
    input [7:0]                 control,
    input                       start_core,
    input                       end_op_core,
    input                       end_op_keccak,
    output [11:0]               control_keccak,
    output reg                  sel_global,
    output reg [7:0]            i_global,
    output                      start_op,
    output                      start_read_ek,
    input                       start_hek,
    input                       last_hek,
    input                       gmh,
    input                       start_ed,
    output reg                  end_op
);
    
    reg reset_k;
    reg load_k;
    reg start_k;
    reg read_k;
    reg reset_gen;
    reg load_gen;
    reg start_gen;
    reg read_gen;
    reg [3:0] mode_gen;
    
    assign control_keccak = {mode_gen, read_gen, start_gen, load_gen, reset_gen, read_k, start_k, load_k, reset_k};

    // -- Mode signals -- //
    wire [3:0] mode;
    assign mode = control[7:4];
    
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
    
    always @* begin
        if(k_2)         i_global = 8'h02;
        else if(k_3)    i_global = 8'h03;
        else if(k_4)    i_global = 8'h04;
        else            i_global = 8'h02;
    end
   
    
    //--*** STATE declaration **--//
	localparam IDLE            = 8'h00;
	localparam GDK_LOAD_GEN    = 8'h10;
	localparam GDK_LOAD        = 8'h11;
	localparam GDK_START       = 8'h12;
	localparam GDK_SAVE        = 8'h13;
	localparam HEK_START_READ  = 8'h20;
	localparam HEK_SEL_LOAD    = 8'h21;
	localparam HEK_LOAD_BASIC  = 8'h22;
	localparam HEK_LOAD_K_2    = 8'h23;
	localparam HEK_LOAD_K_3    = 8'h24;
	localparam HEK_LOAD_K_4    = 8'h25; 
	localparam HEK_LOAD        = 8'h26; 
	localparam HEK_START       = 8'h27;
	localparam HEK_EVAL        = 8'h28;
	localparam HEK_ADD         = 8'h29;
	localparam HEK_SAVE        = 8'h2A;
	localparam GMH_LOAD_GEN    = 8'h30;
	localparam GMH_LOAD        = 8'h31;
	localparam GMH_START       = 8'h32;
	localparam GMH_SAVE        = 8'h33;
	localparam START_OP        = 8'h40;
	localparam END_OP          = 8'h41;
	localparam START_READ_EK   = 8'h50;
	localparam SAVE_SEED       = 8'h60;
	localparam UPDATE_SEED     = 8'h61;
	
	//--*** STATE register **--//
	reg [7:0] cs; // current_state
	reg [7:0] ns; // current_state
	
	//--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst)    cs <= IDLE;
			else         cs <= ns;
		end
    
    //--*** STATE Transition **--//
	
	assign start_op        =   (cs == START_OP) ? 1 : 0;
	assign start_read_ek   =   (cs == HEK_START_READ) ? 1 : 0; 
	
	reg do_last;
	always @(posedge clk) begin
	   if(cs == IDLE) do_last <= 0;
	   else begin
	       if(cs == HEK_EVAL & last_hek) do_last <= 1;
	       else                          do_last <= do_last;      
	   end
	end
	
	always @* begin
			case (cs)
				IDLE:
				   if (start_core) begin
				        if(gen_keys) 
				            ns = GDK_LOAD_GEN;
				        else if(encap)
				            ns = SAVE_SEED;
				        else if(decap & !gmh)
				            ns = START_OP;
				        else if(decap & gmh)
				            ns = UPDATE_SEED;
				        else
				            ns = IDLE;
				   end
				   else
				        ns = IDLE;
				SAVE_SEED:
				    if(start_ed) 
				        ns = START_OP;
				    else
				        ns = HEK_SEL_LOAD;
				UPDATE_SEED:
				    ns = GMH_LOAD_GEN;
				START_OP:
				   if (end_op_core) begin
				        if(gen_keys) 
				            ns = HEK_START_READ;
				        else if(encap)
				            ns = END_OP;
				        else if(decap & !gmh)
				            ns = END_OP;
				        else if(decap & gmh)
				            ns = GMH_LOAD_GEN;
				        else
				            ns = START_OP;
				   end
				   else
				        ns = START_OP;
				HEK_START_READ:
				    if(start_hek)
				        ns = HEK_SEL_LOAD;
				    else
				        ns = HEK_START_READ;
				HEK_SEL_LOAD:
				    if(last_hek) begin
				        if(k_2) 
				            ns = HEK_LOAD_K_2;
				        else if(k_3)
				            ns = HEK_LOAD_K_3;
				        else
				            ns = HEK_LOAD_K_4;
				    end
				    else
				        ns = HEK_LOAD_BASIC;
				HEK_LOAD_K_2:
				    ns = HEK_LOAD;
				HEK_LOAD_K_3:
				    ns = HEK_LOAD;  
				HEK_LOAD_K_4:
				    ns = HEK_LOAD;
				HEK_LOAD_BASIC:
				    ns = HEK_LOAD;   
				HEK_LOAD:
				    ns = HEK_START;
				HEK_START:
				    if(end_op_keccak)
				        ns = HEK_ADD;
				    else    
				        ns = HEK_START;
				HEK_ADD:
				    ns = HEK_EVAL;
			    HEK_EVAL:
			        if(do_last)
			            ns = HEK_SAVE;
			        else
			            ns = HEK_SEL_LOAD;
			    HEK_SAVE:
			         if(gen_keys)
			            ns = END_OP;
			        else
			            ns = GMH_LOAD_GEN;
				GDK_LOAD_GEN: 
				    ns = GDK_LOAD;
				GDK_LOAD: 
				    ns = GDK_START;
				GDK_START:
				    if(end_op_keccak)
				        ns = GDK_SAVE;
				    else    
				        ns = GDK_START;
				GDK_SAVE:
				    ns = START_OP;
			    GMH_LOAD_GEN:
			         ns = GMH_LOAD;
			    GMH_LOAD:
			         ns = GMH_START;
			    GMH_START:
				    if(end_op_keccak)
				        ns = GMH_SAVE;
				    else    
				        ns = GMH_START;
			    GMH_SAVE:
				    if(encap)
				        ns = START_OP;
			       else 
				        ns = END_OP;
			  default:
					    ns = IDLE;
		  endcase		
		end 
		
		always @* begin
		  case(cs)
		      IDLE:     begin
		                    reset_k       = 1;  
                            load_k        = 0;
                            start_k       = 0;
                            read_k        = 0;
                            reset_gen     = 1;
                            load_gen      = 0;
                            start_gen     = 0;
                            read_gen      = 0;
                            mode_gen      = 4'h0;
                            sel_global    = 0;
                            end_op        = 0;
                        end 
          SAVE_SEED:     begin
		                    reset_k       = 1;  
                            load_k        = 0;
                            start_k       = 0;
                            read_k        = 0;
                            reset_gen     = 0;
                            load_gen      = 1;
                            start_gen     = 0;
                            read_gen      = 0;
                            mode_gen      = 4'h0;
                            sel_global    = 1;
                            end_op        = 0;
                        end 
          UPDATE_SEED:   begin
		                    reset_k       = 1;  
                            load_k        = 0;
                            start_k       = 0;
                            read_k        = 0;
                            reset_gen     = 0;
                            load_gen      = 1;
                            start_gen     = 0;
                            read_gen      = 0;
                            mode_gen      = 4'h0;
                            sel_global    = 1;
                            end_op        = 0;
                        end 
      GDK_LOAD_GEN:     begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h1;
                            sel_global  = 1;
                            end_op      = 0;
                        end 
          GDK_LOAD:     begin
                            reset_k     = 0;  
                            load_k      = 1;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h1;
                            sel_global  = 1;
                            end_op      = 0;
                        end    
          GDK_START:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 1;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h1;
                            sel_global  = 1;
                            end_op      = 0;
                        end   
          GDK_SAVE:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 1;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 1;
                            mode_gen    = 4'h1;
                            sel_global  = 1;
                            end_op      = 0;
                        end  
          HEK_SEL_LOAD:  begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end 
          HEK_LOAD_BASIC:  begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h6;
                            sel_global  = 1;
                            end_op      = 0;
                        end   
          HEK_LOAD_K_2:   begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h7;
                            sel_global  = 1;
                            end_op      = 0;
                        end
          HEK_LOAD_K_3:   begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h8;
                            sel_global  = 1;
                            end_op      = 0;
                        end
          HEK_LOAD_K_4:   begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h9;
                            sel_global  = 1;
                            end_op      = 0;
                        end
          HEK_LOAD:   begin
                            reset_k     = 0;  
                            load_k      = 1;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end             
          HEK_START:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 1;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end  
          HEK_ADD:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 1;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end 
          HEK_EVAL:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 1;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end   
          HEK_SAVE:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 1;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 1;
                            mode_gen    = 4'h7;
                            sel_global  = 1;
                            end_op      = 0;
                        end  
          GMH_LOAD_GEN:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'hA;
                            sel_global  = 1;
                            end_op      = 0;
                        end 
          GMH_LOAD:    begin
                            reset_k     = 0;  
                            load_k      = 1;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'hA;
                            sel_global  = 1;
                            end_op      = 0;
                        end 
          GMH_START:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 1;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 1;
                            end_op      = 0;
                        end     
          GMH_SAVE:    begin
                            reset_k     = 0;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 1;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 1;
                            mode_gen    = 4'hA;
                            sel_global  = 1;
                            end_op      = 0;
                        end   
          START_OP:    begin
                            reset_k     = 1;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 0;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 0;
                            end_op      = 0;
                        end 
          END_OP:    begin
                            reset_k     = 1;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 1;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 0;
                            end_op      = 1;
                        end    
             
		 default:   begin
                            reset_k     = 1;  
                            load_k      = 0;
                            start_k     = 0;
                            read_k      = 0;
                            reset_gen   = 1;
                            load_gen    = 0;
                            start_gen   = 0;
                            read_gen    = 0;
                            mode_gen    = 4'h0;
                            sel_global  = 0;
                            end_op      = 0;
                        end  
		  endcase
		
		end
endmodule
