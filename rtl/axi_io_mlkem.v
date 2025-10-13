`timescale 1ns / 1ps

// ***************************************************************************
// Note for adquiring traces:
// 1. For capturing traces with the simulator, comment the line 364 of gen_shares.v
// // 	if (rst)            lfsr_reg <= SEED; 
// 		if (rst)            lfsr_reg <= $random[31:0] | 32'h1; 
// 2. For capturing traces with the simulator or the FPGA, comment the line 210 of keccak.v:
// // 	o_seed_0 <= do_keccak[255:0];
// 		o_seed_0 <= {32{8'h5A}};
// This will allow to capture traces in constant time. 
// ***************************************************************************


module AXI_IO_MLKEM #(
    parameter MASKED = 1, // If MASKED = 1, N_BU = 4 and N_SHARES = 4. It is only programed this option
	parameter SHUFF = 1, // If SHUFF = 1, the shares are shuffled in the masked implementation
	parameter SHUFF_DELAY = 539, // Number of cycles of delay for the shuffling (recomended: 539)
	parameter KECCAK_PROT = 1, // If KECCAK_PROT = 1, the keccak module is protected with masking
	parameter N_BU = 4 // If MASKED = 0, you can choose N_BU = 1 or 4 
    )(
    input           clk,
    input           rst,
    input   [7:0]   control,
    input   [63:0]  data_in,
    input   [15:0]  add,
    output  [63:0]  data_out,
    output  [1:0]   end_op,
    output          flag_op
    );

	// Global reset signal
	wire g_reset = (control[3:0] == 4'h0) ? 1 : 0;

	// -------------------------------------------------------------------//
    // ---- IO_INTERFACE ---- //

	wire 	[1:0] 			end_op_io;	

	wire 	[255:0]     	i_seed_0, i_seed_1;
    wire 	[255:0]     	o_seed_0, o_seed_1;
    wire 	[255:0]     	i_hek, o_hek, i_ss, o_ss;
	wire    [1087:0]    	ek_in;

	wire   	[15:0]         	mode_encdec;
    wire                  	d_valid_encoder;
    wire                  	start_encoder;
    wire                  	start_decoder;
    wire                  	d_ready_decoder;
    wire                  	d_valid_decoder;
    wire                  	upd_add_decoder;
    wire  	[16*10-1:0]		add_ram;
    wire  	[63:0]          out_encoder;
    wire  	[63:0]          input_decoder;

	wire 					start_keccak;
	wire 					start_read_ek;
	wire 					start_hek;
	wire 					last_hek;

	wire 					start_core;
	wire 					end_op_core;
	wire 					sel_io;

	wire 	[40:0]          control_dmu_io;

	wire 					sel_control;
	wire 	[7:0] 			control_io;

	reg 	[7:0] 			control_decap;
	reg 					encap_decap;	
	reg 					rst_ed;
	reg						start_ed;

	wire 	[7:0] 			control_mlkem;
    wire                    gmh_decap;
    
	assign flag_op = start_core;

	generate 
		if(MASKED == 0) begin
            
            if(N_BU == 4) begin
			IO_INTERFACE IO_INTERFACE (
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),

				// AXI signals
				.control        	(   control_io      ),
				.data_in        	(   data_in         ),
				.add            	(   add             ),
				.data_out       	(   data_out        ),
				.end_op         	(   end_op_io       ),

				// Write/Read RAM signals
				.add_ram            (   add_ram         ),
				.data_in_int        (   out_encoder     ),
				.data_out_int       (   input_decoder   ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.o_hek          	(   o_hek           ),
				.i_ss           	(   i_ss            ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Control Keccak
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),
				.start_keccak   	(   start_keccak   	),

				// Control Core signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_enc        (   d_valid_encoder ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),

				// DMU
				.control_dmu        (   control_dmu_io  ),
				
				// Encap/Decap signals
				.gmh_decap          (	gmh_decap			),
				.encap_decap    	(   encap_decap     	),
				.g_reset_ed         (	rst_ed				)
			);
			end
			else if (N_BU == 2) begin
			 
			 IO_INTERFACE_N_BU_2 IO_INTERFACE_N_BU_2 (
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),

				// AXI signals
				.control        	(   control_io      ),
				.data_in        	(   data_in         ),
				.add            	(   add             ),
				.data_out       	(   data_out        ),
				.end_op         	(   end_op_io       ),

				// Write/Read RAM signals
				.add_ram            (   add_ram         ),
				.data_in_int        (   out_encoder     ),
				.data_out_int       (   input_decoder   ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.o_hek          	(   o_hek           ),
				.i_ss           	(   i_ss            ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Control Keccak
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),
				.start_keccak   	(   start_keccak   	),

				// Control Core signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_enc        (   d_valid_encoder ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),

				// DMU
				.control_dmu        (   control_dmu_io  ),
				
				// Encap/Decap signals
				.gmh_decap          (	gmh_decap			),
				.encap_decap    	(   encap_decap     	),
				.g_reset_ed         (	rst_ed				)
			);
			end
			else begin // We use the masked one since it is implemented as N_BU = 1
			
			 IO_INTERFACE_MASKED #(.N_BU(N_BU)) IO_INTERFACE_N_BU_1 (
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),

				// AXI signals
				.control        	(   control_io      ),
				.data_in        	(   data_in         ),
				.add            	(   add             ),
				.data_out       	(   data_out        ),
				.end_op         	(   end_op_io       ),

				// Write/Read RAM signals
				.add_ram            (   add_ram         ),
				.data_in_int        (   out_encoder     ),
				.data_out_int       (   input_decoder   ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.o_hek          	(   o_hek           ),
				.i_ss           	(   i_ss            ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Control Keccak
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),
				.start_keccak   	(   start_keccak   	),

				// Control Core signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_enc        (   d_valid_encoder ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),

				// DMU
				.control_dmu        (   control_dmu_io  ),
				
				// Encap/Decap signals
				.gmh_decap          (	gmh_decap			),
				.encap_decap    	(   encap_decap     	),
				.g_reset_ed         (	rst_ed				)
			);
			
			end

			// -------------------------------------------------------------------//
			// ---- TOP_MLKEM ---- //

			TOP_MLKEM #(
				.N_BU(N_BU)
			) TOP_MLKEM (
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),
				.control        	(   control_mlkem   ),

				// Control signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Control keccak
				.start_keccak   	(   start_keccak   	),
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.i_ss           	(   i_ss            ),
				.o_hek          	(   o_hek           ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_encoder    (   d_valid_encoder ),
				.out_encoder        (   out_encoder     ),
				.input_decoder      (   input_decoder   ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),
				.add_ram		  	(   add_ram         ),

				// DMU
				.control_dmu_io     (   control_dmu_io  ),

				// Encap/Decap signals
				.rst_ed             (   rst_ed          ),
				.gmh_decap          (	gmh_decap		),
				.start_encap_decap  (   start_ed 		)
			);
		end
		else begin

			IO_INTERFACE_MASKED #(.N_BU(N_BU)) IO_INTERFACE_MASKED (
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),

				// AXI signals
				.control        	(   control_io      ),
				.data_in        	(   data_in         ),
				.add            	(   add             ),
				.data_out       	(   data_out        ),
				.end_op         	(   end_op_io       ),

				// Write/Read RAM signals
				.add_ram            (   add_ram         ),
				.data_in_int        (   out_encoder     ),
				.data_out_int       (   input_decoder   ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.o_hek          	(   o_hek           ),
				.i_ss           	(   i_ss            ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Control Keccak
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),
				.start_keccak   	(   start_keccak   	),

				// Control Core signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_enc        (   d_valid_encoder ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),

				// DMU
				.control_dmu        (   control_dmu_io  ),
				
				// Encap/Decap signals
				.gmh_decap          (	gmh_decap			),
				.encap_decap    	(   encap_decap     	),
				.g_reset_ed         (	rst_ed				)
			);

			localparam N_SHARES = (N_BU-1)*2;
			localparam WIDTH = 24;

			wire 						 en_read_shares;
			wire [N_SHARES*WIDTH-1:0]  	 random_shares;
			wire [WIDTH-1:0]             random_op;

			wire keccak_flag;

			// Random shares for the KECCAK MASKED implementation (KECCAK_PROT)
			wire [1599:0] rand_k_1;
    		wire [1599:0] rand_k_2;
    		wire [1599:0] rand_k_3;
    		wire  [1599:0] rand_chi_1;  //  random share 1
    		wire  [1599:0] rand_chi_2;  //  random share 2
    		wire  [1599:0] rand_chi_3;  //  random share 3
    		wire  [1599:0] rand_chi_4;  //  random share 4
    		wire  [1599:0] rand_chi_5;  //  random share 5
    		wire  [1599:0] rand_chi_6;  //  random share 6

			TOP_MLKEM_MASKED #(
			     .N_BU(N_BU),
				 .N_SHARES(N_SHARES),
				 .SHUFF_DELAY(SHUFF_DELAY),
				 .KECCAK_PROT(KECCAK_PROT)
			)
			TOP_MLKEM_MASKED
			(
				.clk            	(   clk             ),
				.rst            	(   rst & !g_reset  ),
				.control        	(   control_mlkem   ),

				// Control signals
				.start_core     	(   start_core      ),
				.end_op_core    	(   end_op_core     ),
				.sel_io         	(   sel_io          ),

				// Control keccak
				.start_keccak   	(   start_keccak   	),
				.start_read_ek  	(   start_read_ek   ),
				.start_hek      	(   start_hek       ),
				.last_hek       	(   last_hek        ),

				// Input keccak
				.i_seed_0       	(   i_seed_0        ),
				.i_seed_1       	(   i_seed_1        ),
				.o_seed_0       	(   o_seed_0        ),
				.o_seed_1       	(   o_seed_1        ),
				.i_hek          	(   i_hek           ),
				.i_ss           	(   i_ss            ),
				.o_hek          	(   o_hek           ),
				.o_ss           	(   o_ss            ),
				.ek_in              (   ek_in           ),

				// Encoder/Decoder signals
				.mode_encdec        (   mode_encdec    	),
				.start_encoder      (   start_encoder   ),
				.d_valid_encoder    (   d_valid_encoder ),
				.out_encoder        (   out_encoder     ),
				.input_decoder      (   input_decoder   ),
				.start_decoder      (   start_decoder   ),
				.d_valid_decoder    (   d_valid_decoder ),
				.d_ready_decoder    (   d_ready_decoder ),
				.upd_add_decoder    (   upd_add_decoder ),
				.add_ram		  	(   add_ram         ),

				// DMU
				.control_dmu_io     (   control_dmu_io  ),

				// Encap/Decap signals
				.rst_ed             (   rst_ed          ),
				.gmh_decap          (	gmh_decap		),
				.start_encap_decap  (   start_ed 		),
				
				// Shares
				.en_read_shares     (   en_read_shares  ),
				.random_op          (   random_op       ),
				.random_shares      (   random_shares   ),

				.keccak_flag 		(   keccak_flag   ),

				// Keccak random shares
				.rand_k_1 (   rand_k_1      ),
				.rand_k_2 (   rand_k_2      ),
				.rand_k_3 (   rand_k_3      ),
				.rand_chi_1 (   rand_chi_1      ),  //  random share 1
				.rand_chi_2 (   rand_chi_2      ),  //  random share 2
				.rand_chi_3 (   rand_chi_3      ),  //  random share 3
				.rand_chi_4 (   rand_chi_4      ),  //  random share 4
				.rand_chi_5 (   rand_chi_5      ),  //  random share 5
				.rand_chi_6 (   rand_chi_6      )   //  random share 6
			);
			// -------------------------------------------------------------------//
			if(KECCAK_PROT) begin
				GEN_SHARES_KECCAK_DOM #(
					.N_SHARES(N_SHARES),
					.WIDTH(WIDTH),
					.SHUFF(SHUFF)
				)
				GEN_SHARES (
					.clk 			(	clk				),
					.rst 			(	rst				),
					.rst_op 		(	g_reset			),
					.enable_read	(	en_read_shares	),
					.random_op      (   random_op       ),
					.random_shares	(	random_shares	),
					.keccak_flag 	(   keccak_flag    ),
					.rand_k_1 		(   rand_k_1      ),
					.rand_k_2 		(   rand_k_2      ),
					.rand_k_3 		(   rand_k_3      ), 	// (only for N_BU = 4)
					.rand_chi_1 	(   rand_chi_1      ),  //  random share 1 (only for N_BU = 4)
					.rand_chi_2 	(   rand_chi_2      ),  //  random share 2 (only for N_BU = 4)
					.rand_chi_3 	(   rand_chi_3      ),  //  random share 3 (only for N_BU = 4)
					.rand_chi_4 	(   rand_chi_4      ),  //  random share 4 (only for N_BU = 4)	
					.rand_chi_5 	(   rand_chi_5      ),  //  random share 5 (only for N_BU = 4)
					.rand_chi_6 	(   rand_chi_6      )   //  random share 6 (only for N_BU = 4)
				);
			end
			else begin
				GEN_SHARES #(
					.N_SHARES(N_SHARES),
					.WIDTH(WIDTH),
					.SHUFF(SHUFF)
				)
				GEN_SHARES (
					.clk 			(	clk				),
					.rst 			(	rst				),
					.rst_op 		(	g_reset			),
					.enable_read	(	en_read_shares	),
					.random_op      (   random_op       ),
					.random_shares	(	random_shares	)
				);

				assign rand_k_1 = 1600'h0;
				assign rand_k_2 = 1600'h0;
				assign rand_k_3 = 1600'h0;
				assign rand_chi_1 = 1600'h0;
				assign rand_chi_2 = 1600'h0;
				assign rand_chi_3 = 1600'h0;
				assign rand_chi_4 = 1600'h0;
				assign rand_chi_5 = 1600'h0;
				assign rand_chi_6 = 1600'h0;

			end
		end
	endgenerate

	// -------------------------------------------------------------------//
	// ---- Performing encapsulation after decapsulation internally
    
    // To perform encrypt after decap
    
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
	
    reg [1:0] end_op_reg;
    
	// Performing encapsulation after decapsulation
	always @(posedge clk) begin
        if(!rst | g_reset | end_op_reg[0])	encap_decap <= 1'b0;
        else begin
            if(decap & end_op_io[0])   		encap_decap <= 1'b1;
            else                        	encap_decap <= encap_decap;
        end
    end

	// Changing control to perform encapsulation after decapsulation
    always @(posedge clk) begin
        if(!rst | g_reset)              control_decap <= 8'h0;
        else begin
            if(decap & end_op_io[0])    control_decap <= {2'b10, control[5:0]};
            else                        control_decap <= control_decap;
        end
    end

	assign sel_control 		= (decap & encap_decap) ? 1'b1 : 1'b0;
	assign control_io 		= (sel_control) ? control_decap : control;
	assign control_mlkem 	= (sel_control) ? control_decap : control;

	// Start encapsulation after decapsulation
    always @(posedge clk) begin
        if(!rst | g_reset)              start_ed <= 1'b0;
        else begin
            if(encap_decap)             start_ed <= 1'b1;
            else                        start_ed <= start_ed;
        end
    end
    
	// Reset for encapsulation after decapsulation
    always @(posedge clk) begin
        if(!rst | g_reset | start_ed)    rst_ed <= 1'b0;
        else begin
            if(encap_decap)              rst_ed <= 1'b1;
            else                         rst_ed <= rst_ed;
        end
    end
    
    // Modify the end_op signal to include the encapsulation after decapsulation
    always @(posedge clk) begin
        if(!rst | g_reset | rst_ed)    	end_op_reg <= 2'b00;
        else begin
            if(gen_keys | encap)   end_op_reg <= end_op_io;
            else if(decap & start_ed)   end_op_reg <= end_op_io;
            else                        end_op_reg <= 2'b00;
        end
    end
    
    assign end_op           = end_op_reg;
    
    
    /*
    // Only for Sakura evaluation 
    assign end_op           = end_op_io;
	assign control_io 		= control;
	assign control_mlkem 	= control;
	
	always @(posedge clk) begin
	   encap_decap <= 1'b0;
	   start_ed    <= 1'b0;
	   rst_ed      <= 1'b0;
	end

    */
endmodule


module IO_INTERFACE (
    input                       clk,
    input                       rst,
    
    // AXI signals
    input       [7:0]           control,
    input       [63:0]          data_in,
    input       [15:0]          add,
    output reg  [63:0]          data_out, 
    output reg  [1:0]           end_op,

    // Write/Read RAM signals
    input       [63:0]          data_in_int,
    output      [16*10-1:0]     add_ram,
    output      [63:0]          data_out_int,

    // Input keccak
    output reg  [255:0]         i_seed_0, // d / rho
    output reg  [255:0]         i_seed_1, // r
    input       [255:0]         o_seed_0, // rho
    input       [255:0]         o_seed_1, // sigma
    output reg  [255:0]         i_hek,
    output reg  [255:0]         i_ss,
    input       [255:0]         o_hek,
    input       [255:0]         o_ss,
    output      [1087:0]        ek_in,

	// Control keccak
	input                       start_keccak,
    input                       start_read_ek,
    output  reg                 start_hek,
    output  reg                 last_hek,

    
    output reg                  start_core,
    input                       end_op_core,
    output reg                  sel_io,
    output reg                  gmh_decap,
    input                       encap_decap,
    input                       g_reset_ed,
    
    // Encoder/Decoder signals
    output  reg [15:0]          mode_encdec,
    input                       d_valid_enc,
    output  reg                 start_encoder,
    output  reg                 start_decoder,
    input                       d_ready_decoder,
    output                      d_valid_decoder,
    input                       upd_add_decoder,
    
    output  [40:0]              control_dmu
);
    
    reg [8:0] control_dmu_encdec;
    assign control_dmu = {control_dmu_encdec, 32'h0000_0000_0000_0000};
    
    reg  [15:0]       add_int;

    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
    
	wire reset;	
	wire load_r0;
	wire read_r0;
	wire load_r1;
	wire read_r1;
	wire load_hek;
	wire read_hek;
	wire load_ss;
	wire read_ss;
	wire load_dk;
	wire read_dk;
	wire load_ek;
	wire read_ek;
	wire load_ct;
	wire read_ct;
	wire start;

    assign reset        = (op == 4'h0) ? 1 : 0;
    assign load_r0      = (op == 4'h1) ? 1 : 0;
    assign read_r0      = (op == 4'h2) ? 1 : 0;
    assign load_r1      = (op == 4'h3) ? 1 : 0;
    assign read_r1      = (op == 4'h4) ? 1 : 0;
    assign load_hek     = (op == 4'h5) ? 1 : 0;
    assign read_hek     = (op == 4'h6) ? 1 : 0;
    assign load_ss      = (op == 4'h7) ? 1 : 0;
    assign read_ss      = (op == 4'h8) ? 1 : 0;
    assign load_dk      = (op == 4'h9) ? 1 : 0;
    assign read_dk      = (op == 4'hA) ? 1 : 0;
    assign load_ek      = (op == 4'hB) ? 1 : 0;
    assign read_ek      = (op == 4'hC) ? 1 : 0;
    assign load_ct      = (op == 4'hD) ? 1 : 0;
    assign read_ct      = (op == 4'hE) ? 1 : 0;
    assign start        = (op == 4'hF) ? 1 : 0;
    
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
    
   reg          load_ek_int;
   reg          load_dk_int;
   reg          load_ct_int;
   reg          read_ek_int;
   reg          read_dk_int;
   reg          read_ct_int;
   reg          load_ek_reg;
   reg          read_m_int;
   reg          load_m_int;

    reg  [9:0] add_ram_ini;
    reg  [9:0] offset;
    
    assign d_valid_decoder = load_ek_int | load_dk_int | load_ct_int | load_m_int;
    
    assign add_ram = {
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset };
   
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_0 <= 0;
        else if(load_r0) begin
            case(add[1:0]) 
                2'b00:  i_seed_0[063:000] <= data_in;
                2'b01:  i_seed_0[127:064] <= data_in;
                2'b10:  i_seed_0[191:128] <= data_in;
                2'b11:  i_seed_0[255:192] <= data_in;
            endcase
        end 
        else            i_seed_0 <= i_seed_0;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_1 <= 0;
        else if(load_r1) begin
            case(add[1:0]) 
                2'b00:  i_seed_1[063:000] <= data_in;
                2'b01:  i_seed_1[127:064] <= data_in;
                2'b10:  i_seed_1[191:128] <= data_in;
                2'b11:  i_seed_1[255:192] <= data_in;
            endcase
        end 
        else            i_seed_1 <= i_seed_1;
    end
    
    
    always @(posedge clk) begin
        if(!rst | reset)        i_hek <= 0;
        else if(load_hek) begin
            case(add[1:0]) 
                2'b00:  i_hek[063:000] <= data_in;
                2'b01:  i_hek[127:064] <= data_in;
                2'b10:  i_hek[191:128] <= data_in;
                2'b11:  i_hek[255:192] <= data_in;
            endcase
        end 
        else            i_hek <= i_hek;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_ss <= 0;
        else if(load_ss) begin
            case(add[1:0]) 
                2'b00:  i_ss[063:000] <= data_in;
                2'b01:  i_ss[127:064] <= data_in;
                2'b10:  i_ss[191:128] <= data_in;
                2'b11:  i_ss[255:192] <= data_in;
            endcase
        end 
        else if(read_m_int) begin
            case(add_int[1:0]) 
                2'b00:  i_ss[063:000] <= data_in_int;
                2'b01:  i_ss[127:064] <= data_in_int;
                2'b10:  i_ss[191:128] <= data_in_int;
                2'b11:  i_ss[255:192] <= data_in_int;
            endcase
        end 
        else            i_ss <= i_ss;
    end
    
    // RAM - I/O
    wire load;
    assign load     = load_dk       | load_ek       | load_ct       |   load_ss;
    wire load_int;
    assign load_int = read_dk_int   | read_ek_int   | read_ct_int   |   read_m_int;
    wire read;
    assign read = read_dk | read_ek | read_ct;
    
    wire en_w;

    reg  [12:0] addr_w;
    reg  [12:0] addr_r;
    always @* begin
                if(load_ek)     addr_w = add;
        else    if(load_dk)     addr_w = add + 256;    
        else    if(load_ct)     addr_w = add + 512;  
        else    if(load_ss)     addr_w = add + 768; // load m   
        else    if(read_ek_int) addr_w = add_int;
        else    if(read_dk_int) addr_w = add_int + 256; 
        else    if(read_ct_int) addr_w = add_int + 512;   
        else    if(read_m_int)  addr_w = add_int + 768; // read m  
        else                    addr_w = add; 
    end
    
    always @* begin
                if(read_ek)     addr_r = add;
        else    if(read_dk)     addr_r = add + 256;    
        else    if(read_ct)     addr_r = add + 512; 
        else    if(read_ss)     addr_r = add + 768; // It's not going to be used     
        else    if(load_ek_int) addr_r = add_int;
        else    if(load_ek_reg) addr_r = add_int;
        else    if(load_dk_int) addr_r = add_int + 256; 
        else    if(load_ct_int) addr_r = add_int + 512;   
        else    if(load_m_int)  addr_r = add_int + 768; // decoding m
        else    if(read_ct_int) addr_r = add_int + 512; // cmov while reading ct
        else                    addr_r = add; 
    end
    
    wire [63:0] data_in_ram;
    assign data_in_ram = (load_int) ? data_in_int : data_in;
    wire [63:0] data_out_ram;
    assign data_out_int = data_out_ram;
    
    RAM #(.SIZE(8192), .WIDTH(64)) RAM_IO
    (.clk       (   clk             ), 
    .en_write   (   en_w            ),     
    .en_read    (   1               ), 
    .addr_write (   addr_w          ),              
    .addr_read  (   addr_r          ), 
    .data_in    (   data_in_ram     ),
    .data_out   (   data_out_ram    )
    );
    
    // check ct (cmov)
    reg cmov;
    reg [63:0] data_in_ram_cmov;
    reg d_valid_cmov;
    
    reg [63:0] o_seed_0_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_0_reg <= 0;
        else if(read_r0) begin
            case(add[1:0]) 
                2'b00:  o_seed_0_reg <= o_seed_0[063:000];
                2'b01:  o_seed_0_reg <= o_seed_0[127:064];
                2'b10:  o_seed_0_reg <= o_seed_0[191:128];
                2'b11:  o_seed_0_reg <= o_seed_0[255:192];
            endcase
        end 
        else            o_seed_0_reg <= o_seed_0_reg;
    end
    
    reg [63:0] o_seed_1_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_1_reg <= 0;
        else if(read_r1) begin
            case(add[1:0]) 
                2'b00:  o_seed_1_reg <= o_seed_1[063:000];
                2'b01:  o_seed_1_reg <= o_seed_1[127:064];
                2'b10:  o_seed_1_reg <= o_seed_1[191:128];
                2'b11:  o_seed_1_reg <= o_seed_1[255:192];
            endcase
        end 
        else            o_seed_1_reg <= o_seed_1_reg;
    end
    
    reg [63:0] o_hek_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_hek_reg <= 0;
        else if(read_hek) begin
            case(add[1:0]) 
                2'b00:  o_hek_reg <= o_hek[063:000];
                2'b01:  o_hek_reg <= o_hek[127:064];
                2'b10:  o_hek_reg <= o_hek[191:128];
                2'b11:  o_hek_reg <= o_hek[255:192];
            endcase
        end 
        else            o_hek_reg <= o_hek_reg;
    end
    
    reg [63:0] o_ss_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_ss_reg <= 0;
        else if(read_ss) begin
            case(add[1:0]) 
                2'b00:  o_ss_reg <= o_ss[063:000];
                2'b01:  o_ss_reg <= o_ss[127:064];
                2'b10:  o_ss_reg <= o_ss[191:128];
                2'b11:  o_ss_reg <= o_ss[255:192];
            endcase
        end 
        else            o_ss_reg <= o_ss_reg;
    end
    
    always @* begin
                if(!cmov)                   data_out = 64'hFFFF_FFFF_FFFF_FFFF;
        else    if(read_r0)                 data_out = o_seed_0_reg;  
        else    if(read_r1)                 data_out = o_seed_1_reg;  
        else    if(read_hek)                data_out = o_hek_reg;
        else    if(read_ss & encap)         data_out = o_ss_reg;
        else    if(read_ss & decap)         data_out = o_ss_reg;
        else                                data_out = data_out_ram;        
    end
    
    // --- Control Encoder/Decoder --- //
    
    //--*** STATE declaration **--//
	localparam IDLE            = 8'h00;
	localparam LOAD_EK_1       = 8'h10; 
	localparam LOAD_EK_2       = 8'h11; 
	localparam LOAD_EK_3       = 8'h12; 
	localparam LOAD_EK_4       = 8'h13; 
	localparam END_LOAD_EK     = 8'h1F; 
	localparam READ_EK_1       = 8'h20; 
	localparam READ_EK_2       = 8'h21;
	localparam READ_EK_3       = 8'h22;
	localparam READ_EK_4       = 8'h23;
	localparam END_READ_EK     = 8'h2F;
	localparam LOAD_DK_1       = 8'h30; 
	localparam LOAD_DK_2       = 8'h31; 
	localparam LOAD_DK_3       = 8'h32; 
	localparam LOAD_DK_4       = 8'h33; 
	localparam END_LOAD_DK     = 8'h3F;
	localparam READ_DK_1       = 8'h40; 
	localparam READ_DK_2       = 8'h41;
	localparam READ_DK_3       = 8'h42;
	localparam READ_DK_4       = 8'h43;
	localparam END_READ_DK     = 8'h4F;
	localparam LOAD_CT_RESET   = 8'h5F;
	localparam LOAD_CT_L_RESET = 8'h5E;
	localparam LOAD_CT_1       = 8'h50; 
	localparam LOAD_CT_2       = 8'h51; 
	localparam LOAD_CT_3       = 8'h52; 
	localparam LOAD_CT_4       = 8'h53; 
	localparam LOAD_CT_L       = 8'h54;
	localparam READ_CT_1       = 8'h60; 
	localparam READ_CT_2       = 8'h61;
	localparam READ_CT_3       = 8'h62;
	localparam READ_CT_4       = 8'h63;
	localparam END_READ_CT     = 8'h6E;
	localparam RESET_READ_CT   = 8'h6D;
	localparam READ_CT_L       = 8'h64;
	localparam END_READ_CT_L   = 8'h6F;
	localparam START_OP        = 8'h70;
	localparam SEL_READ        = 8'h80;
	localparam LOAD_EK_REG     = 8'h90;
	localparam LOAD_M_RESET    = 8'hA0;
	localparam LOAD_M          = 8'hA1;
	localparam READ_M          = 8'hB0;
	localparam GMH             = 8'hC0;
	localparam END_OP          = 8'hFF;
    
    //--*** STATE register **--//
	reg [7:0] cs_io; // current_state
	reg [7:0] ns_io; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | reset)    cs_io <= IDLE;
			else                 cs_io <= ns_io;
		end
    
    //--*** STATE Transition **--//
    reg end_ek_1, end_ek_2, end_ek_3, end_ek_4;
    reg end_dk_1, end_dk_2, end_dk_3, end_dk_4;
    reg end_ct_1, end_ct_2, end_ct_3, end_ct_4, end_ct_l;
    reg end_ek_reg;
    reg end_m, end_reset_m;
    reg end_read_ek, end_read_dk, end_read_ct, end_read_ct_l;
    reg end_load_ek, end_load_dk, end_load_ct, end_load_ct_l;
	
	always @* begin
			case (cs_io)
				IDLE:
				   if (start) begin
				        if(encap)
				            ns_io = LOAD_EK_REG;
				        else if(decap)
				            ns_io = LOAD_DK_1;
				        else    
				            ns_io = START_OP;
				   end
				   else
				        ns_io = IDLE;
				LOAD_EK_REG:
				    if(end_ek_reg)
				        ns_io = LOAD_EK_1;
				    else
				        ns_io = LOAD_EK_REG;
				// --- LOAD EK --- //
				LOAD_EK_1:
				    if(end_ek_1)
				        ns_io = END_LOAD_EK;
				    else
				        ns_io = LOAD_EK_1;
				LOAD_EK_2:
				    if(end_ek_2)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_2 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_2 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_2;    
				LOAD_EK_3:
				    if(end_ek_3)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_3 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_3 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_3; 
				LOAD_EK_4:
				    if(end_ek_4) 
				        /*
				        begin
				        if(encap)
				            ns_io = LOAD_M_RESET;
				        else // decap
				            ns_io = LOAD_DK_1;
				        end 
				        */
				        ns_io = END_LOAD_EK;
				    else    
				        ns_io = LOAD_EK_4;    
				END_LOAD_EK:
				    if(end_load_ek) begin
                        if(end_ek_1)
                            ns_io = LOAD_EK_2;
                        else if(end_ek_2) begin
                            if(k_2 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_2 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_3;
                            end
                        else if(end_ek_3) begin
                            if(k_3 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_3 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_4;
                        end
                        else begin
                            if(encap)
				                ns_io = LOAD_M_RESET;
				            else // decap
				                ns_io = LOAD_DK_1;
                        end
				    end
				    else
				        ns_io = END_LOAD_EK;
				          
				// --- READ EK --- //
				READ_EK_1: 
				    if(end_ek_1)
				        ns_io = READ_EK_2;
				    else
				        ns_io = READ_EK_1;
				READ_EK_2: 
				    if(end_ek_2) begin
				        if(k_2)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_3;
				    end
				    else
				        ns_io = READ_EK_2;
				READ_EK_3: 
				    if(end_ek_3) begin
				        if(k_3)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_4;
				    end
				    else
				        ns_io = READ_EK_3;
				READ_EK_4: 
				    if(end_ek_4)
				        ns_io = END_READ_EK;
				    else
				        ns_io = READ_EK_4;
				END_READ_EK:
				    if(end_read_ek)
				        ns_io = READ_DK_1;
				    else
				        ns_io = END_READ_EK;    
				// --- LOAD DK --- //
				LOAD_DK_1: 
				    if(end_dk_1)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_1;
				LOAD_DK_2: 
				    if(end_dk_2)
						/*
				        if(k_2)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_2;
				LOAD_DK_3: 
				    if(end_dk_3)
				        /*
				        if(k_3)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_3;
				LOAD_DK_4: 
				    if(end_dk_4)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_4;
				END_LOAD_DK:
				    if(end_load_dk) begin
                        if(end_dk_1)
                            	ns_io = LOAD_DK_2;
                        else if(end_dk_2) begin
                            if(k_2)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_3;
                        end
                        else if(end_dk_3) begin
                            if(k_3)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_4;
                        end
                        else 
								ns_io = LOAD_CT_RESET; 
				    end
				    else
				        ns_io = END_LOAD_DK;
				// --- READ DK --- //
				READ_DK_1: 
				    if(end_dk_1)
				        ns_io = READ_DK_2;
				    else
				        ns_io = READ_DK_1;
				READ_DK_2: 
				    if(end_dk_2) begin
				        if(k_2)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_3;
				    end
				    else
				        ns_io = READ_DK_2;
				READ_DK_3: 
				    if(end_dk_3) begin
				        if(k_3)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_4;
				    end
				    else
				        ns_io = READ_DK_3;
				READ_DK_4: 
				    if(end_dk_4)
				        ns_io = END_READ_DK;
				    else
				        ns_io = READ_DK_4;
				END_READ_DK:
				    if(end_read_dk)
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_DK;         
                // --- LOAD CT --- //
                LOAD_CT_RESET:
                    ns_io = LOAD_CT_1;
				LOAD_CT_1: 
				    if(end_ct_1)
				        ns_io = LOAD_CT_2;
				    else
				        ns_io = LOAD_CT_1;
				LOAD_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_3;
				    else
				        ns_io = LOAD_CT_2;
				LOAD_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_4;
				    else
				        ns_io = LOAD_CT_3;
				LOAD_CT_4: 
				    if(end_ct_4)
				        ns_io = LOAD_CT_L;
				    else
				        ns_io = LOAD_CT_4;
			    LOAD_CT_L: 
				    if(end_ct_l)
				        ns_io = START_OP;
				    else
				        ns_io = LOAD_CT_L;
				        
				// --- READ CT --- //
				READ_CT_1: 
				    if(end_ct_1)
				        ns_io = READ_CT_2;
				    else
				        ns_io = READ_CT_1;
				READ_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_3;
				    else
				        ns_io = READ_CT_2;
				READ_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_4;
				    else
				        ns_io = READ_CT_3;
				READ_CT_4: 
				    if(end_ct_4)
				        ns_io = END_READ_CT;
				    else
				        ns_io = READ_CT_4;
				END_READ_CT:
				    if((k_2 | k_3) & end_read_ct)
				        ns_io = READ_CT_L;
				    else if(k_4 & end_read_ct)
				        ns_io = RESET_READ_CT;
				    else
				        ns_io = END_READ_CT;  
				RESET_READ_CT:
				    ns_io = READ_CT_L;
			    READ_CT_L: 
				    if(end_ct_l)
				        ns_io = END_READ_CT_L;
				    else
				        ns_io = READ_CT_L;
				END_READ_CT_L:
				    if(end_read_ct_l)
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_CT_L; 
                // --- LOAD/READ M --- //
                LOAD_M_RESET:
					if(end_reset_m)
                    	ns_io = LOAD_M;
					else
						ns_io = LOAD_M_RESET;
                LOAD_M:
                    if(end_m)
                        ns_io = START_OP;
                    else
                        ns_io = LOAD_M;
                READ_M:
                    if(end_m)
                        ns_io = GMH;
                    else
                        ns_io = READ_M;
				START_OP:
				    if(end_op_core | start_read_ek)
				        ns_io = SEL_READ;
				    else
				        ns_io = START_OP;
				SEL_READ:
				    if(gen_keys)
				        ns_io = READ_EK_1;
				    else if(encap)
				        ns_io = READ_CT_1;
				    else   
				        ns_io = READ_M;
				GMH:
				    if(end_op_core)
				        ns_io = END_OP;
				    else
				        ns_io = GMH;
				END_OP:
				    if(reset | g_reset_ed)
				        ns_io = IDLE;
				    else
				        ns_io = END_OP;
				default:
					    ns_io = IDLE;
			endcase 		
		end 
		
		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_1:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  if(k_2) control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 1_3
		                  else    control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_2:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  if(k_2) control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 1_4
		                  else    control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 0_2
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_3:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 0_3
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_4:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 0_4
		                  gmh_decap           = 0;
		              end
		   END_LOAD_EK:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                          if(end_ek_1 & k_2)   control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 1_3
		                  else    if(end_ek_1 & !k_2)  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  else    if(end_ek_2 & k_2)   control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 1_4
		                  else    if(end_ek_2 & !k_2)  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  else    if(end_ek_3)         control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 1_3
		                  else                         control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 1_4
		                  gmh_decap           = 0;
		              end
           READ_EK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   END_READ_EK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ek;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
						  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 0_2
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 0_3
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 0_4
		                  gmh_decap           = 0;
		              end
		   END_LOAD_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                          if(end_dk_1)   	control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  else    if(end_dk_2)   	control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  else    if(end_dk_3)      control_dmu_encdec  = 9'b00_11_00_00_0; // RAM 1_3
		                  else                      control_dmu_encdec  = 9'b11_00_00_00_0; // RAM 1_4
		                  gmh_decap           = 0;
		              end
           READ_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end  
		   END_READ_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_dk;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end  
		   LOAD_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_01_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_01_00_0; // RAM 0_2
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_01_00_00_0; // RAM 0_3
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_00_00_00_0; // RAM 0_4
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_00_00_00_0; // RAM 0_4
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_CT_L_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
           READ_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   READ_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end 
		   END_READ_CT:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		  END_READ_CT_L:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct_l;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   RESET_READ_CT: begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_M_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  if(k_2) control_dmu_encdec  = 9'b00_01_00_00_0; // RAM_0_3
		                  else    control_dmu_encdec  = 9'b00_00_00_11_0; // RAM_1_1
		                  gmh_decap           = 0;
		              end   
		   READ_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 1;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   START_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   SEL_READ:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_REG:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 1;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   GMH:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 1;
		              end
		   END_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b1};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		 default:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		  endcase
		
		end

		// Reducing fanout for the control signals
		reg read_ek_1, read_ek_2, read_ek_3, read_ek_4;
		reg read_dk_1, read_dk_2, read_dk_3, read_dk_4;
		reg read_ct_1, read_ct_2, read_ct_3, read_ct_4, read_ct_l;
		reg load_ek_1, load_ek_2, load_ek_3, load_ek_4;
		reg load_dk_1, load_dk_2, load_dk_3, load_dk_4;
		reg load_ct_1, load_ct_2, load_ct_3, load_ct_4, load_ct_l;
		reg load_m, read_m;
		reg end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st;
		reg load_ct_reset;
		reg load_m_reset;
		reg reset_read_ct;

		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct = 0;			
		              end
		   LOAD_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0001;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct  = 0;	
		              end
		   LOAD_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0010;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0100;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b1000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0001;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0010;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0100;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b1000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_READ_EK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b1000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   LOAD_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0001;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0010;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_3:   begin
		                 	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0100;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b1000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0001;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0010;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0100;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b1000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end  
		   END_READ_DK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0100;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end  
		   LOAD_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00010;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00100;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b01000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b10000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 1;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   LOAD_CT_L_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end 
           READ_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00010;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00100;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b01000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b10000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00001;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   END_READ_CT:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0010;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		  END_READ_CT_L:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0001;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   RESET_READ_CT: begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct	= 1;	
		                  end
		   LOAD_M_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 1;
							reset_read_ct   = 0;	
		              	end 
		   LOAD_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 1;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 1;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   START_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   SEL_READ:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_REG:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   GMH:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		 default:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;
		              end
		  endcase
		
		end
		
		

		
		// --- End & Counter signal --- //

		reg uad_0, uad_1, uad_2, uad_3; 
		always @(posedge clk) uad_0 <= upd_add_decoder;
		always @(posedge clk) uad_1 <= uad_0;
		always @(posedge clk) uad_2 <= uad_1;
		always @(posedge clk) uad_3 <= uad_2;

		reg [7:0] c_ek_1, c_ek_2, c_ek_3, c_ek_4;
		reg [7:0] c_dk_1, c_dk_2, c_dk_3, c_dk_4;
		reg [7:0] c_ct_1, c_ct_2, c_ct_3, c_ct_4, c_ct_l; 
		reg [7:0] c_m;
		reg [3:0] c_end_ek, c_end_dk, c_end_ct, c_end_ct_l;
		reg [3:0] c_reset_m;
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      end_ek_1 <= 1'b0;
		      end_ek_2 <= 1'b0;
		      end_ek_3 <= 1'b0;
		      end_ek_4 <= 1'b0;
		      
		      end_dk_1 <= 1'b0;
		      end_dk_2 <= 1'b0;
		      end_dk_3 <= 1'b0;
		      end_dk_4 <= 1'b0;
		      
		      end_ct_1 <= 1'b0;
		      end_ct_2 <= 1'b0;
		      end_ct_3 <= 1'b0;
		      end_ct_4 <= 1'b0;
		      end_ct_l <= 1'b0;
		      
		      end_m    <= 1'b0;  
		  	  end_reset_m <= 1'b0;
		      
		      end_read_ek <= 1'b0;
		      end_read_dk <= 1'b0; 
		      end_read_ct <= 1'b0;
		      end_read_ct_l <= 1'b0;

		  	  end_load_ek <= 1'b0;
			  end_load_dk <= 1'b0;
		  end
		  else begin
		              if(read_ek_int & c_ek_1 == 62)      end_ek_1 <= 1'b1;
		      else    if(load_ek_int & c_ek_1 == 64)      end_ek_1 <= 1'b1;
		      else    if(cs_io == END_LOAD_EK)            end_ek_1 <= end_ek_1;
		      else                                        end_ek_1 <= 1'b0;
		      
		              if(read_ek_int & c_ek_2 == 62)      end_ek_2 <= 1'b1;
		      else    if(load_ek_int & c_ek_2 == 64)      end_ek_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_2 <= end_ek_2;
		      else                                        end_ek_2 <= 1'b0;
		      
		              if(read_ek_int & c_ek_3 == 62)      end_ek_3 <= 1'b1;
		      else    if(load_ek_int & c_ek_3 == 64)      end_ek_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_3 <= end_ek_3;
		      else                                        end_ek_3 <= 1'b0;
		      
		              if(read_ek_int & c_ek_4 == 62)      end_ek_4 <= 1'b1;
		      else    if(load_ek_int & c_ek_4 == 64)      end_ek_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_4 <= end_ek_4;
		      else                                        end_ek_4 <= 1'b0;
		      
		              if(read_dk_int & c_dk_1 == 62)      end_dk_1 <= 1'b1;
		      else    if(load_dk_int & c_dk_1 == 64)      end_dk_1 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_1 <= end_dk_1;
		      else                                        end_dk_1 <= 1'b0;
		      
		              if(read_dk_int & c_dk_2 == 62)      end_dk_2 <= 1'b1;
		      else    if(load_dk_int & c_dk_2 == 64)      end_dk_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_2 <= end_dk_2;
		      else                                        end_dk_2 <= 1'b0;
		      
		              if(read_dk_int & c_dk_3 == 62)      end_dk_3 <= 1'b1;
		      else    if(load_dk_int & c_dk_3 == 64)      end_dk_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_3 <= end_dk_3;
		      else                                        end_dk_3 <= 1'b0;
		      
		              if(read_dk_int & c_dk_4 == 62)      end_dk_4 <= 1'b1;
		      else    if(load_dk_int & c_dk_4 == 64)      end_dk_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_4 <= end_dk_4;
		      else                                        end_dk_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_1 == 62)      end_ct_1 <= 1'b1;
		      else    if(load_ct_int & c_ct_1 == 64)      end_ct_1 <= 1'b1;
		      else                                        end_ct_1 <= 1'b0;
		      
		              if(read_ct_int & c_ct_2 == 62)      end_ct_2 <= 1'b1;
		      else    if(load_ct_int & c_ct_2 == 64)      end_ct_2 <= 1'b1;
		      else                                        end_ct_2 <= 1'b0;
		      
		              if(read_ct_int & c_ct_3 == 62)      end_ct_3 <= 1'b1;
		      else    if(load_ct_int & c_ct_3 == 64)      end_ct_3 <= 1'b1;
		      else                                        end_ct_3 <= 1'b0;
		      
		              if(read_ct_int & c_ct_4 == 62)      end_ct_4 <= 1'b1;
		      else    if(load_ct_int & c_ct_4 == 64)      end_ct_4 <= 1'b1;
		      else                                        end_ct_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_l == 62)      end_ct_l <= 1'b1;
		      else    if(load_ct_int & c_ct_l == 64)      end_ct_l <= 1'b1;
		      else                                        end_ct_l <= 1'b0;
		      
		              if(read_m_int & c_m == 69)          end_m <= 1'b1;
		      else    if(load_m_int & c_m == 64)          end_m <= 1'b1;
		      else                                        end_m <= 1'b0;
		      
		      if(c_end_ek == 5)   end_read_ek <= 1'b1;
		      else                end_read_ek <= 1'b0;
		      
		      if(c_end_ek == 1)   end_load_ek <= 1'b1;
		      else                end_load_ek <= 1'b0;
		      
		      if(c_end_dk == 5)   end_read_dk <= 1'b1;
		      else                end_read_dk <= 1'b0;

			  if(c_end_dk == 1)   end_load_dk <= 1'b1;
		      else                end_load_dk <= 1'b0;
		      
		      if(k_4 & c_end_ct == 6)                 end_read_ct <= 1'b1; // Probably it depens on b
		      else if((k_2 | k_3) & c_end_ct == 7)    end_read_ct <= 1'b1; // Probably it depens on b
		      else                                    end_read_ct <= 1'b0;
		      
		      if(c_end_ct_l == 5) end_read_ct_l <= 1'b1;
		      else                end_read_ct_l <= 1'b0;

			  if(c_reset_m == 3)  end_reset_m <= 1'b1;
		      else                end_reset_m <= 1'b0;
		      
		  end
		end
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      c_ek_1 <= 0;
		      c_ek_2 <= 0;
		      c_ek_3 <= 0;
		      c_ek_4 <= 0;
		      
		      c_dk_1 <= 0;
		      c_dk_2 <= 0;
		      c_dk_3 <= 0;
		      c_dk_4 <= 0;
		      
		      c_ct_1 <= 0;
		      c_ct_2 <= 0;
		      c_ct_3 <= 0;
		      c_ct_4 <= 0;
		      c_ct_l <= 0;
		      
		      c_m <= 0;
		      
		      c_end_ek    <= 0;
		      c_end_dk    <= 0;
		      c_end_ct    <= 0;
		      c_end_ct_l  <= 0;
		      c_reset_m   <= 0;
		  end
		  else begin
		      if(read_ek_1)                          c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & upd_add_decoder)   c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & !upd_add_decoder)  c_ek_1 <= c_ek_1;
		      else                                   c_ek_1 <= 0;
		      
		      if(read_ek_2)                          c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & upd_add_decoder)   c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & !upd_add_decoder)  c_ek_2 <= c_ek_2;
		      else                                   c_ek_2 <= 0;
		      
		      if(read_ek_3)                          c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & upd_add_decoder)   c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & !upd_add_decoder)  c_ek_3 <= c_ek_3;
		      else                                   c_ek_3 <= 0;
		      
		      if(read_ek_4)                          c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & upd_add_decoder)   c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & !upd_add_decoder)  c_ek_4 <= c_ek_4;
		      else                                   c_ek_4 <= 0;
		      
		      if(read_dk_1)                          c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & upd_add_decoder)   c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & !upd_add_decoder)  c_dk_1 <= c_dk_1;
		      else                                   c_dk_1 <= 0;
		      
		      if(read_dk_2)                          c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & upd_add_decoder)   c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & !upd_add_decoder)  c_dk_2 <= c_dk_2;
		      else                                   c_dk_2 <= 0;
		      
		      if(read_dk_3)                          c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & upd_add_decoder)   c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & !upd_add_decoder)  c_dk_3 <= c_dk_3;
		      else                                   c_dk_3 <= 0;
		      
		      if(read_dk_4)                          c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & upd_add_decoder)   c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & !upd_add_decoder)  c_dk_4 <= c_dk_4;
		      else                                   c_dk_4 <= 0;
		      
		      if(read_ct_1)                          c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & upd_add_decoder)   c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & !upd_add_decoder)  c_ct_1 <= c_ct_1;
		      else                                   c_ct_1 <= 0;
		      
		      if(read_ct_2)                          c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & upd_add_decoder)   c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & !upd_add_decoder)  c_ct_2 <= c_ct_2;
		      else                                   c_ct_2 <= 0;
		      
		      if(read_ct_3)                          c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & upd_add_decoder)   c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & !upd_add_decoder)  c_ct_3 <= c_ct_3;
		      else                                   c_ct_3 <= 0;
		      
		      if(read_ct_4)                          c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & upd_add_decoder)   c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & !upd_add_decoder)  c_ct_4 <= c_ct_4;
		      else                                   c_ct_4 <= 0;
		      
		      if(read_ct_l)                          c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & upd_add_decoder)   c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & !upd_add_decoder)  c_ct_l <= c_ct_l;
		      else                                   c_ct_l <= 0;
		      
		      if(read_m)                             c_m <= c_m + 1;
		      else if(load_m & upd_add_decoder)      c_m <= c_m + 1;
		      else if(load_m & !upd_add_decoder)     c_m <= c_m;
		      else                                   c_m <= 0;
		      
		      if(end_read_ek_st | cs_io == END_LOAD_EK)        	c_end_ek <= c_end_ek + 1;
		      else                              	            c_end_ek <= 0;
		      
		      if(end_read_dk_st | cs_io == END_LOAD_DK)        	c_end_dk <= c_end_dk + 1;
		      else                               				c_end_dk <= 0;
		      
		      if(end_read_ct_st)                    c_end_ct <= c_end_ct + 1;
		      else                               	c_end_ct <= 0;
		      
		      if(end_read_ct_l_st)                  c_end_ct_l <= c_end_ct_l + 1;
		      else                               	c_end_ct_l <= 0;

			  if(cs_io == LOAD_M_RESET)        		c_reset_m <= c_reset_m + 1;
		      else                              	c_reset_m <= 0;
		      
		  end
		
		
		end
		
		// --- Encoding / Decoding --- //
		
		always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int | read_m_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_11_00_00; // ek[0] (RAM_1_3) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b11_00_00_00; // ek[1] (RAM_1_4)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b11_00_00_00; // ek[1] (RAM_1_4)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(end_read_dk_st) 	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_11_00_00; // c[0]  (RAM_1_3) offset = 128
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_11_00_00; // c[1]  (RAM_1_3) offset = 256
		          else    if(end_read_ct_st) 	mode_encdec[7:0] = 8'b00_11_00_00; // c[1]  (RAM_1_3) offset = 256
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_11_00_00; // cl    (RAM_1_3) offset = 0
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_11_00_00; // cl    (RAM_1_3) offset = 0
		          else    if(read_m)         	mode_encdec[7:0] = 8'b11_00_00_00; // w     (RAM_1_4) offset = 0
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[0] (RAM_0_1) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_01_00; // ek[1] (RAM_0_2)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_01_00_00; // ek[2] (RAM_0_3)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_01_00_00; // ek[2] (RAM_0_3)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_11_00_00; // dk[2] (RAM_1_3)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b00_11_00_00; // dk[2] (RAM_1_3)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_01_00; // ct[0] (RAM_0_2)   offset = 0
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_01_00_00; // ct[1] (RAM_0_3)   offset = 0
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_00_00_01; // ct[2] (RAM_0_1)   offset = 0
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b00_00_00_01; // ct[2] (RAM_0_1)   offset = 0
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b11_00_00_00; // cl    (RAM_1_4)   offset = 0
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b11_00_00_00; // cl    (RAM_1_4)   offset = 0
		          else    if(read_m)         	mode_encdec[7:0] = 8'b11_00_00_00; // w     (RAM_1_4) offset = 0
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[0] (RAM_1_1)
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // ek[1] (RAM_1_2)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_11_00_00; // ek[2] (RAM_1_3)
		          else    if(read_ek_4)      	mode_encdec[7:0] = 8'b11_00_00_00; // ek[3] (RAM_1_4)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b11_00_00_00; // ek[3] (RAM_1_4)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_11_00_00; // dk[2] (RAM_1_3)
		          else    if(read_dk_4)      	mode_encdec[7:0] = 8'b11_00_00_00; // dk[2] (RAM_1_3)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b11_00_00_00; // dk[2] (RAM_1_3)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[0] (RAM_1_1)   offset = 0
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // ct[1] (RAM_1_2)   offset = 0
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_11_00_00; // ct[2] (RAM_1_3)   offset = 0
		          else    if(read_ct_4)      	mode_encdec[7:0] = 8'b11_00_00_00; // ct[3] (RAM_1_4)   offset = 0
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b11_00_00_00; // ct[3] (RAM_1_4)   offset = 0
		          else    if(reset_read_ct)	 	mode_encdec[7:0] = 8'b11_00_00_00; // ct[3] (RAM_1_4)   offset = 0
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b11_00_00_00; // ctl   (RAM_1_4)   offset = 384
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b11_00_00_00; // ctl   (RAM_1_4)   offset = 384
		          else    if(read_m)         	mode_encdec[7:0] = 8'b11_00_00_00; // w     (RAM_1_4) offset = 0
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		  end
		  else                                        mode_encdec[7:0] = 8'b00_00_00_00; 
		  
        end
        
        always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	offset = 0;     // ek[0] (RAM_1_3) 
		          else    if(read_ek_2)     	offset = 0;     // ek[1] (RAM_1_4)
		          else    if(end_read_ek_st) 	offset = 0;     // ek[1] (RAM_1_4)
		          else    if(read_dk_1)      	offset = 0;     // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_1_2)
		          else    if(end_read_dk_st)    offset = 0;     // dk[1] (RAM_1_2)
		          else    if(read_ct_1)      	offset = 128;   // c[0]  (RAM_1_3) offset = 128
		          else    if(read_ct_2)      	offset = 256;   // c[1]  (RAM_1_3) offset = 256
		          else    if(end_read_ct_st)    offset = 256;   // c[1]  (RAM_1_3) offset = 256
		          else    if(read_ct_l)      	offset = 0;     // cl    (RAM_1_3) offset = 0
		          else    if(end_read_ct_l_st)  offset = 0;     // cl    (RAM_1_3) offset = 0
		          else    if(read_m)         	offset = 0;   // w     (RAM_1_4) offset = 0
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	offset = 0;     // ek[0] (RAM_0_1) 
		          else    if(read_ek_2)      	offset = 0;     // ek[1] (RAM_0_2)
		          else    if(read_ek_3)      	offset = 0;     // ek[2] (RAM_0_3)
		          else    if(end_read_ek_st) 	offset = 0;     // ek[2] (RAM_0_3)
		          else    if(read_dk_1)      	offset = 0;     // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	offset = 0;     // dk[2] (RAM_1_3)
		          else    if(end_read_dk_st)    offset = 0;     // dk[2] (RAM_1_3)
		          else    if(read_ct_1)      	offset = 0;     // ct[0] (RAM_0_2)   offset = 0
		          else    if(read_ct_2)      	offset = 0;     // ct[1] (RAM_0_3)   offset = 0
		          else    if(read_ct_3)      	offset = 0;     // ct[2] (RAM_0_1)   offset = 0
		          else    if(end_read_ct_st)    offset = 0;     // ct[2] (RAM_0_1)   offset = 0
		          else    if(read_ct_l)      	offset = 0;     // cl    (RAM_1_4)   offset = 0
		          else    if(end_read_ct_l_st)  offset = 0;     // cl    (RAM_1_4)   offset = 0
		          else    if(read_m)         	offset = 0;   // w     (RAM_1_4) offset = 0
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	offset = 128;   // ek[0] (RAM_1_1)
		          else    if(read_ek_2)      	offset = 128;   // ek[1] (RAM_1_2)
		          else    if(read_ek_3)      	offset = 128;   // ek[2] (RAM_1_3)
		          else    if(read_ek_4)      	offset = 128;   // ek[3] (RAM_1_4)
		          else    if(end_read_ek_st) 	offset = 128;   // ek[3] (RAM_1_4)
		          else    if(read_dk_1)     	offset = 0;     // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	offset = 0;     // dk[2] (RAM_1_3)
		          else    if(read_dk_4)      	offset = 0;     // dk[2] (RAM_1_3)
		          else    if(end_read_dk_st)    offset = 0;     // dk[2] (RAM_1_3)
		          else    if(read_ct_1)      	offset = 0;     // ct[0] (RAM_1_1)   offset = 0
		          else    if(read_ct_2)      	offset = 0;     // ct[1] (RAM_1_2)   offset = 0
		          else    if(read_ct_3)      	offset = 0;     // ct[2] (RAM_1_3)   offset = 0
		          else    if(read_ct_4)      	offset = 0;     // ct[3] (RAM_1_4)   offset = 0
		          else    if(end_read_ct_st)    offset = 0;     // ct[3] (RAM_1_4)   offset = 0
		          else    if(reset_read_ct) 	offset = 384;   // ctl   (RAM_1_4)   offset = 384
		          else    if(read_ct_l)      	offset = 384;   // ctl   (RAM_1_4)   offset = 384
		          else    if(end_read_ct_l_st)  offset = 384;   // ctl   (RAM_1_4)   offset = 384
		          else    if(read_m)         	offset = 0;   // w     (RAM_0_4) offset = 256
		          else                          offset = 0;     // TO COMPLETE
		      end
		  end
		  else if(load_ek_int | load_dk_int | load_ct_int | load_m_int) begin
		      if(k_2) begin
		                  if(load_ek_1)      offset = 384;     
		          else    if(load_ek_2)      offset = 384;  
		          else    if(cs_io == END_LOAD_EK) offset = 384;   
		          else    if(load_dk_1)      offset = 0;     
		          else    if(load_dk_2)      offset = 0;     
		          else    if(load_ct_1)      offset = 128;   
		          else    if(load_ct_2)      offset = 128;   
		          else    if(load_ct_l)      offset = 256; 
		          else    if(load_m)         offset = 384;    
		          else                       offset = 0;     
		      end
		      else if(k_3) begin
		                  if(load_ek_1)      offset = 384;     
		          else    if(load_ek_2)      offset = 384;     
		          else    if(load_ek_3)      offset = 384; 
		          else    if(cs_io == END_LOAD_EK) offset = 384;   
		          else    if(load_dk_1)      offset = 0;     
		          else    if(load_dk_2)      offset = 0;     
		          else    if(load_dk_3)      offset = 0;     
		          else    if(load_ct_1)      offset = 128;     
		          else    if(load_ct_2)      offset = 128;     
		          else    if(load_ct_3)      offset = 128;     
		          else    if(load_ct_l)      offset = 256;  
		          else    if(load_m)         offset = 512;    
		          else                       offset = 0;     
		      end
		      else begin // k_4
		                  if(load_ek_1)      offset = 256;     
		          else    if(load_ek_2)      offset = 256;     
		          else    if(load_ek_3)      offset = 256;     
		          else    if(load_ek_4)      offset = 256;
		          else    if(cs_io == END_LOAD_EK) offset = 256;   
		          else    if(load_dk_1)      offset = 0;     
		          else    if(load_dk_2)      offset = 0;     
		          else    if(load_dk_3)      offset = 0;     
		          else    if(load_dk_4)      offset = 0;     
		          else    if(load_ct_1)      offset = 128;     
		          else    if(load_ct_2)      offset = 128;     
		          else    if(load_ct_3)      offset = 128;     
		          else    if(load_ct_4)      offset = 128;     
		          else    if(load_ct_l)      offset = 256;     
		          else    if(load_m)         offset = 384; 
		          else                       offset = 0;     
		      end
		  end
		  else                               offset = 0; 
		  
        end
        
		
		always @* begin
		  if(k_2 | k_3) begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(load_ct_int & !load_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		   end
		   else begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(load_ct_int & !load_ct_l)       	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		  end
        end
		
		wire end_ek = end_ek_1 | end_ek_2 | end_ek_3 | end_ek_4 | (end_read_ek_st);		
		wire end_dk = end_dk_1 | end_dk_2 | end_dk_3 | end_dk_4 | (end_read_dk_st);
		wire end_ct = end_ct_1 | end_ct_2 | end_ct_3 | end_ct_4 | end_ct_l | (end_read_ct_st) | (end_read_ct_l_st) | (reset_read_ct);
		
		always @(posedge clk) begin
		  if(!rst | reset | cs_io == START_OP)                                                        add_ram_ini <= 0;
		  else begin
		           if(end_ek & load_ek_int & !end_load_ek)                                            add_ram_ini <= add_ram_ini;
			  else if(end_dk & load_dk_int & !end_load_dk)                                            add_ram_ini <= add_ram_ini;
			  else if(cs_io == LOAD_M_RESET)                                                          add_ram_ini <= 0;
		      else if(end_ek | end_dk | end_ct | end_m)                                               add_ram_ini <= 0; // offset
		      else if(read_ek_int | read_dk_int | read_ct_int | read_m_int)                           add_ram_ini <= add_ram_ini + 2;
		      else if((load_ek_int | load_dk_int | load_ct_int | load_m_int) & uad_1)	  		      add_ram_ini <= add_ram_ini + 2;
		      else                                                                                    add_ram_ini <= add_ram_ini;
		  end
		end

		
		localparam EK_512     = (800  - 32) / 8;
		localparam EK_768     = (1184 - 32) / 8;
		localparam EK_1024    = (1568 - 32) / 8;
		
		always @* begin
		  if(cs_io == LOAD_EK_REG) begin
		              if(k_2 & add_int == EK_512 - 1)     end_ek_reg = 1;
		      else    if(k_3 & add_int == EK_768 - 1)     end_ek_reg = 1;
		      else    if(k_4 & add_int == EK_1024 - 1)    end_ek_reg = 1;
		      else                                        end_ek_reg = 0;
		  end
		  else                                            end_ek_reg = 0;
		 		  
		end
		
		
		wire end_ek_add = end_read_ek;
		wire end_dk_add = end_read_dk;
		wire end_ct_add = end_read_ct_l;
		
		always @(posedge clk) begin
		  if(!rst | reset)                                                                    add_int <= 0;
		  else begin
		      if(end_ek_add | end_dk_add | end_ct_add | end_ek_reg)                           add_int <= 0;
		      else if(load_m_reset | load_ct_reset | cs_io == SEL_READ)     				  add_int <= 0;
		      else if(start_encoder & d_valid_enc)                                            add_int <= add_int + 1;
		      else if(start_decoder & d_ready_decoder)                                        add_int <= add_int + 1;
		      else if(load_ek_reg)                                                            add_int <= add_int + 1;
		      else                                                                            add_int <= add_int;
		  end
		end
    
    // --- CMOV
    assign en_w = load | (read_dk_int   | read_ek_int   | read_m_int | (read_ct_int & d_valid_enc & ~end_read_ct & !reset_read_ct)); // I need that for doing the cmov while reading ct
    
    always @(posedge clk)                               data_in_ram_cmov    <= data_in_ram;
    always @(posedge clk)                               d_valid_cmov        <= (reset_read_ct) ? 1'b0 : d_valid_enc & ~end_read_ct;
    always @(posedge clk) begin
        if(!rst)                                        cmov <= 1'b1;
        else begin
            if(cs_io == RESET_READ_CT)                  cmov <= cmov;
            else if(cmov & encap_decap & read_ct_int & d_valid_cmov) begin
                if(data_out_ram == data_in_ram_cmov)    cmov <= 1'b1;
                else                                    cmov <= 1'b0;
            end
            else                                        cmov <= cmov;
        end
    end
    
    
	// -- ek_in --
	
	reg  [4:0] add_w_ek;
	reg  [4:0] add_w_ek_p;
	always @(posedge clk) add_w_ek_p <= add_w_ek;
	
	reg load_ek_reg_reg;   always @(posedge clk) load_ek_reg_reg <= load_ek_reg;
	reg load_ek_r3;        always @(posedge clk) load_ek_r3 <= (gen_keys) ? load_ek_reg_reg : load_ek_reg;
	reg en_w_p; 
	always @(posedge clk) en_w_p <= (read_ek_int | load_ek_r3);
	
	reg [1087:0]   ek_in_reg;
	
	reg [4:0] sel;
	
	RAMD64_CR #(
    .COLS(17), // 1088
    .ROWS(1)
    ) EK_REG (
    .clk    (   clk                 ),
    .en_w   (   en_w_p              ),
    .add_w  (   add_w_ek_p          ),
    .add_r  (   sel                 ),
    .d_i     (   ek_in_reg           ),
    .d_o     (   ek_in               )
    );
	
	reg act_keccak;
	wire cond_load = (cs_io == START_OP & encap);
	always @(posedge clk) act_keccak <= (read_ek_int | read_dk_int | cond_load) ? start_keccak : 1'b0;
	wire upd_keccak;
	assign upd_keccak = (start_keccak && !act_keccak) ? 1'b1 : 1'b0 ;
	
	always @(posedge clk) begin
	   if(cs_io == IDLE) sel <= 0;
	   else if (read_ek_int | read_dk_int) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else if (cond_load) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else sel <= sel;
	end
	
	wire op_reg = read_ek_int | load_ek_reg;
	
	reg [7:0] add_ek;
	always @(posedge clk) begin
	   if(!op_reg) begin 
	       add_ek      <= 0;
	       add_w_ek    <= 0;
	   end
	   else if (read_ek_int) begin 
	       if(add_ek == 16) begin
	         if(d_valid_enc) begin
                add_ek      <= 0;
                add_w_ek    <= add_w_ek + 1;
             end
             else begin
                add_ek      <= add_ek;
                add_w_ek    <= add_w_ek;
             end
	       end
	       else begin
               if(d_valid_enc) begin
                    add_ek      <= add_ek + 1;
                    add_w_ek    <= add_w_ek;
               end
               else begin
                    add_ek      <= add_ek;
                    add_w_ek    <= add_w_ek;
               end
           end
	   end
	   else if (load_ek_reg_reg) begin
	       if(add_ek == 16) begin
	           add_ek      <= 0;
               add_w_ek    <= add_w_ek + 1;
	       end
	       else begin
	           add_ek      <= add_ek + 1;
               add_w_ek    <= add_w_ek;
	       end
	   end
	
	end
	
	always @(posedge clk) begin 
	   if(cs_io == IDLE) begin
           ek_in_reg <= 0;
	   end
	   else begin
	       if(read_ek_int)             ek_in_reg[add_ek*64+:64] <= data_in_int;
	       else if(load_ek_reg_reg)    ek_in_reg[add_ek*64+:64] <= data_out_ram;
	       else                        ek_in_reg <= ek_in_reg;
	   end
	end 
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)                       start_hek <= 0;
	   else begin
	       if(add_ek[4] & d_valid_enc)         start_hek <= 1;
	       else if(load_ek_int)                start_hek <= 1;
	       else                                        start_hek <= start_hek;     
	   end 
	end
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)               last_hek <= 0;
	   else begin
	       if(k_2 & sel == 5)          last_hek <= 1;
	       else if(k_3 & sel == 8)     last_hek <= 1;
	       else if(k_4 & sel == 11)    last_hek <= 1;
	       else                        last_hek <= last_hek;
	   end
	end
	
endmodule

module IO_INTERFACE_MASKED #(
    parameter N_BU = 2
    )(
    input                       clk,
    input                       rst,
    
    // AXI signals
    input       [7:0]           control,
    input       [63:0]          data_in,
    input       [15:0]          add,
    output reg  [63:0]          data_out, 
    output reg  [1:0]           end_op,

    // Write/Read RAM signals
    input       [63:0]          data_in_int,
    output      [16*10-1:0]     add_ram,
    output      [63:0]          data_out_int,

    // Input keccak
    output reg  [255:0]         i_seed_0, // d / rho
    output reg  [255:0]         i_seed_1, // r
    input       [255:0]         o_seed_0, // rho
    input       [255:0]         o_seed_1, // sigma
    output reg  [255:0]         i_hek,
    output reg  [255:0]         i_ss,
    input       [255:0]         o_hek,
    input       [255:0]         o_ss,
    output      [1087:0]        ek_in,

	// Control keccak
	input                       start_keccak,
    input                       start_read_ek,
    output  reg                 start_hek,
    output  reg                 last_hek,

    
    output reg                  start_core,
    input                       end_op_core,
    output reg                  sel_io,
    output reg                  gmh_decap,
    input                       encap_decap,
    input                       g_reset_ed,
    
    // Encoder/Decoder signals
    output  reg [15:0]          mode_encdec,
    input                       d_valid_enc,
    output  reg                 start_encoder,
    output  reg                 start_decoder,
    input                       d_ready_decoder,
    output                      d_valid_decoder,
    input                       upd_add_decoder,
    
    output  [40:0]              control_dmu
);
    
    reg [8:0] control_dmu_encdec;
    assign control_dmu = {control_dmu_encdec, 32'h0000_0000_0000_0000};
    
    reg  [15:0]       add_int;

    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
    
	wire reset;	
	wire load_r0;
	wire read_r0;
	wire load_r1;
	wire read_r1;
	wire load_hek;
	wire read_hek;
	wire load_ss;
	wire read_ss;
	wire load_dk;
	wire read_dk;
	wire load_ek;
	wire read_ek;
	wire load_ct;
	wire read_ct;
	wire start;

    assign reset        = (op == 4'h0) ? 1 : 0;
    assign load_r0      = (op == 4'h1) ? 1 : 0;
    assign read_r0      = (op == 4'h2) ? 1 : 0;
    assign load_r1      = (op == 4'h3) ? 1 : 0;
    assign read_r1      = (op == 4'h4) ? 1 : 0;
    assign load_hek     = (op == 4'h5) ? 1 : 0;
    assign read_hek     = (op == 4'h6) ? 1 : 0;
    assign load_ss      = (op == 4'h7) ? 1 : 0;
    assign read_ss      = (op == 4'h8) ? 1 : 0;
    assign load_dk      = (op == 4'h9) ? 1 : 0;
    assign read_dk      = (op == 4'hA) ? 1 : 0;
    assign load_ek      = (op == 4'hB) ? 1 : 0;
    assign read_ek      = (op == 4'hC) ? 1 : 0;
    assign load_ct      = (op == 4'hD) ? 1 : 0;
    assign read_ct      = (op == 4'hE) ? 1 : 0;
    assign start        = (op == 4'hF) ? 1 : 0;
    
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
    
   reg          load_ek_int;
   reg          load_dk_int;
   reg          load_ct_int;
   reg          read_ek_int;
   reg          read_dk_int;
   reg          read_ct_int;
   reg          load_ek_reg;
   reg          read_m_int;
   reg          load_m_int;

    reg  [9:0] add_ram_ini;
    reg  [9:0] offset;
    
    assign d_valid_decoder = load_ek_int | load_dk_int | load_ct_int | load_m_int;
    
    assign add_ram = {
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset };
   
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_0 <= 0;
        else if(load_r0) begin
            case(add[1:0]) 
                2'b00:  i_seed_0[063:000] <= data_in;
                2'b01:  i_seed_0[127:064] <= data_in;
                2'b10:  i_seed_0[191:128] <= data_in;
                2'b11:  i_seed_0[255:192] <= data_in;
            endcase
        end 
        else            i_seed_0 <= i_seed_0;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_1 <= 0;
        else if(load_r1) begin
            case(add[1:0]) 
                2'b00:  i_seed_1[063:000] <= data_in;
                2'b01:  i_seed_1[127:064] <= data_in;
                2'b10:  i_seed_1[191:128] <= data_in;
                2'b11:  i_seed_1[255:192] <= data_in;
            endcase
        end 
        else            i_seed_1 <= i_seed_1;
    end
    
    
    always @(posedge clk) begin
        if(!rst | reset)        i_hek <= 0;
        else if(load_hek) begin
            case(add[1:0]) 
                2'b00:  i_hek[063:000] <= data_in;
                2'b01:  i_hek[127:064] <= data_in;
                2'b10:  i_hek[191:128] <= data_in;
                2'b11:  i_hek[255:192] <= data_in;
            endcase
        end 
        else            i_hek <= i_hek;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_ss <= 0;
        else if(load_ss) begin
            case(add[1:0]) 
                2'b00:  i_ss[063:000] <= data_in;
                2'b01:  i_ss[127:064] <= data_in;
                2'b10:  i_ss[191:128] <= data_in;
                2'b11:  i_ss[255:192] <= data_in;
            endcase
        end 
        else if(read_m_int) begin
            case(add_int[1:0]) 
                2'b00:  i_ss[063:000] <= data_in_int;
                2'b01:  i_ss[127:064] <= data_in_int;
                2'b10:  i_ss[191:128] <= data_in_int;
                2'b11:  i_ss[255:192] <= data_in_int;
            endcase
        end 
        else            i_ss <= i_ss;
    end
    
    // RAM - I/O
    wire load;
    assign load     = load_dk       | load_ek       | load_ct       |   load_ss;
    wire load_int;
    assign load_int = read_dk_int   | read_ek_int   | read_ct_int   |   read_m_int;
    wire read;
    assign read = read_dk | read_ek | read_ct;
    
    wire en_w;

    reg  [12:0] addr_w;
    reg  [12:0] addr_r;
    always @* begin
                if(load_ek)     addr_w = add;
        else    if(load_dk)     addr_w = add + 256;    
        else    if(load_ct)     addr_w = add + 512;  
        else    if(load_ss)     addr_w = add + 768; // load m   
        else    if(read_ek_int) addr_w = add_int;
        else    if(read_dk_int) addr_w = add_int + 256; 
        else    if(read_ct_int) addr_w = add_int + 512;   
        else    if(read_m_int)  addr_w = add_int + 768; // read m  
        else                    addr_w = add; 
    end
    
    always @* begin
                if(read_ek)     addr_r = add;
        else    if(read_dk)     addr_r = add + 256;    
        else    if(read_ct)     addr_r = add + 512; 
        else    if(read_ss)     addr_r = add + 768; // It's not going to be used     
        else    if(load_ek_int) addr_r = add_int;
        else    if(load_ek_reg) addr_r = add_int;
        else    if(load_dk_int) addr_r = add_int + 256; 
        else    if(load_ct_int) addr_r = add_int + 512;   
        else    if(load_m_int)  addr_r = add_int + 768; // decoding m
        else    if(read_ct_int) addr_r = add_int + 512; // cmov while reading ct
        else                    addr_r = add; 
    end
    
    wire [63:0] data_in_ram;
    assign data_in_ram = (load_int) ? data_in_int : data_in;
    wire [63:0] data_out_ram;
    assign data_out_int = data_out_ram;
    
    RAM #(.SIZE(8192), .WIDTH(64)) RAM_IO
    (.clk       (   clk             ), 
    .en_write   (   en_w            ),     
    .en_read    (   1               ), 
    .addr_write (   addr_w          ),              
    .addr_read  (   addr_r          ), 
    .data_in    (   data_in_ram     ),
    .data_out   (   data_out_ram    )
    );
    
    // check ct (cmov)
    reg cmov;
    reg [63:0] data_in_ram_cmov;
    reg d_valid_cmov;
    
    reg [63:0] o_seed_0_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_0_reg <= 0;
        else if(read_r0) begin
            case(add[1:0]) 
                2'b00:  o_seed_0_reg <= o_seed_0[063:000];
                2'b01:  o_seed_0_reg <= o_seed_0[127:064];
                2'b10:  o_seed_0_reg <= o_seed_0[191:128];
                2'b11:  o_seed_0_reg <= o_seed_0[255:192];
            endcase
        end 
        else            o_seed_0_reg <= o_seed_0_reg;
    end
    
    reg [63:0] o_seed_1_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_1_reg <= 0;
        else if(read_r1) begin
            case(add[1:0]) 
                2'b00:  o_seed_1_reg <= o_seed_1[063:000];
                2'b01:  o_seed_1_reg <= o_seed_1[127:064];
                2'b10:  o_seed_1_reg <= o_seed_1[191:128];
                2'b11:  o_seed_1_reg <= o_seed_1[255:192];
            endcase
        end 
        else            o_seed_1_reg <= o_seed_1_reg;
    end
    
    reg [63:0] o_hek_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_hek_reg <= 0;
        else if(read_hek) begin
            case(add[1:0]) 
                2'b00:  o_hek_reg <= o_hek[063:000];
                2'b01:  o_hek_reg <= o_hek[127:064];
                2'b10:  o_hek_reg <= o_hek[191:128];
                2'b11:  o_hek_reg <= o_hek[255:192];
            endcase
        end 
        else            o_hek_reg <= o_hek_reg;
    end
    
    reg [63:0] o_ss_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_ss_reg <= 0;
        else if(read_ss) begin
            case(add[1:0]) 
                2'b00:  o_ss_reg <= o_ss[063:000];
                2'b01:  o_ss_reg <= o_ss[127:064];
                2'b10:  o_ss_reg <= o_ss[191:128];
                2'b11:  o_ss_reg <= o_ss[255:192];
            endcase
        end 
        else            o_ss_reg <= o_ss_reg;
    end
    
    always @* begin
                if(!cmov)                   data_out = 64'hFFFF_FFFF_FFFF_FFFF;
        else    if(read_r0)                 data_out = o_seed_0_reg;  
        else    if(read_r1)                 data_out = o_seed_1_reg;  
        else    if(read_hek)                data_out = o_hek_reg;
        else    if(read_ss & encap)         data_out = o_ss_reg;
        else    if(read_ss & decap)         data_out = o_ss_reg;
        else                                data_out = data_out_ram;        
    end
    
    // --- Control Encoder/Decoder --- //
    
    //--*** STATE declaration **--//
	localparam IDLE            = 8'h00;
	localparam LOAD_EK_1       = 8'h10; 
	localparam LOAD_EK_2       = 8'h11; 
	localparam LOAD_EK_3       = 8'h12; 
	localparam LOAD_EK_4       = 8'h13; 
	localparam END_LOAD_EK     = 8'h1F; 
	localparam READ_EK_1       = 8'h20; 
	localparam READ_EK_2       = 8'h21;
	localparam READ_EK_3       = 8'h22;
	localparam READ_EK_4       = 8'h23;
	localparam END_READ_EK     = 8'h2F;
	localparam LOAD_DK_1       = 8'h30; 
	localparam LOAD_DK_2       = 8'h31; 
	localparam LOAD_DK_3       = 8'h32; 
	localparam LOAD_DK_4       = 8'h33; 
	localparam END_LOAD_DK     = 8'h3F;
	localparam READ_DK_1       = 8'h40; 
	localparam READ_DK_2       = 8'h41;
	localparam READ_DK_3       = 8'h42;
	localparam READ_DK_4       = 8'h43;
	localparam END_READ_DK     = 8'h4F;
	localparam LOAD_CT_RESET   = 8'h5F;
	localparam LOAD_CT_L_RESET = 8'h5E;
	localparam LOAD_CT_1       = 8'h50; 
	localparam LOAD_CT_2       = 8'h51; 
	localparam LOAD_CT_3       = 8'h52; 
	localparam LOAD_CT_4       = 8'h53; 
	localparam LOAD_CT_L       = 8'h54;
	localparam READ_CT_1       = 8'h60; 
	localparam READ_CT_2       = 8'h61;
	localparam READ_CT_3       = 8'h62;
	localparam READ_CT_4       = 8'h63;
	localparam END_READ_CT     = 8'h6E;
	localparam RESET_READ_CT   = 8'h6D;
	localparam READ_CT_L       = 8'h64;
	localparam END_READ_CT_L   = 8'h6F;
	localparam START_OP        = 8'h70;
	localparam SEL_READ        = 8'h80;
	localparam LOAD_EK_REG     = 8'h90;
	localparam LOAD_M_RESET    = 8'hA0;
	localparam LOAD_M          = 8'hA1;
	localparam READ_M          = 8'hB0;
	localparam GMH             = 8'hC0;
	// localparam END_HEK         = 8'hC1;
	localparam END_OP          = 8'hFF;
    
    //--*** STATE register **--//
	reg [7:0] cs_io; // current_state
	reg [7:0] ns_io; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | reset)    cs_io <= IDLE;
			else                 cs_io <= ns_io;
		end
    
    //--*** STATE Transition **--//
    reg end_ek_1, end_ek_2, end_ek_3, end_ek_4;
    reg end_dk_1, end_dk_2, end_dk_3, end_dk_4;
    reg end_ct_1, end_ct_2, end_ct_3, end_ct_4, end_ct_l;
    reg end_ek_reg;
    reg end_m, end_reset_m;
    reg end_read_ek, end_read_dk, end_read_ct, end_read_ct_l;
    reg end_load_ek, end_load_dk, end_load_ct, end_load_ct_l;
    // reg end_hek;
	
	always @* begin
			case (cs_io)
				IDLE:
				   if (start) begin
				        if(encap)
				            ns_io = LOAD_EK_REG;
				        else if(decap)
				            ns_io = LOAD_DK_1;
				        else    
				            ns_io = START_OP;
				   end
				   else
				        ns_io = IDLE;
				LOAD_EK_REG:
				    if(end_ek_reg)
				        ns_io = LOAD_EK_1;
				    else
				        ns_io = LOAD_EK_REG;
				// --- LOAD EK --- //
				LOAD_EK_1:
				    if(end_ek_1)
				        ns_io = END_LOAD_EK;
				    else
				        ns_io = LOAD_EK_1;
				LOAD_EK_2:
				    if(end_ek_2)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_2 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_2 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_2;    
				LOAD_EK_3:
				    if(end_ek_3)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_3 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_3 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_3; 
				LOAD_EK_4:
				    if(end_ek_4) 
				        /*
				        begin
				        if(encap)
				            ns_io = LOAD_M_RESET;
				        else // decap
				            ns_io = LOAD_DK_1;
				        end 
				        */
				        ns_io = END_LOAD_EK;
				    else    
				        ns_io = LOAD_EK_4;    
				END_LOAD_EK:
				    if(end_load_ek) begin
                        if(end_ek_1)
                            ns_io = LOAD_EK_2;
                        else if(end_ek_2) begin
                            if(k_2 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_2 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_3;
                            end
                        else if(end_ek_3) begin
                            if(k_3 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_3 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_4;
                        end
                        else begin
                            if(encap)
				                ns_io = LOAD_M_RESET;
				            else // decap
				                ns_io = LOAD_DK_1;
                        end
				    end
				    else
				        ns_io = END_LOAD_EK;
				          
				// --- READ EK --- //
				READ_EK_1: 
				    if(end_ek_1)
				        ns_io = READ_EK_2;
				    else
				        ns_io = READ_EK_1;
				READ_EK_2: 
				    if(end_ek_2) begin
				        if(k_2)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_3;
				    end
				    else
				        ns_io = READ_EK_2;
				READ_EK_3: 
				    if(end_ek_3) begin
				        if(k_3)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_4;
				    end
				    else
				        ns_io = READ_EK_3;
				READ_EK_4: 
				    if(end_ek_4)
				        ns_io = END_READ_EK;
				    else
				        ns_io = READ_EK_4;
				END_READ_EK:
				    if(end_read_ek)
				        ns_io = READ_DK_1;
				    else
				        ns_io = END_READ_EK;    
				// --- LOAD DK --- //
				LOAD_DK_1: 
				    if(end_dk_1)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_1;
				LOAD_DK_2: 
				    if(end_dk_2)
						/*
				        if(k_2)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_2;
				LOAD_DK_3: 
				    if(end_dk_3)
				        /*
				        if(k_3)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_3;
				LOAD_DK_4: 
				    if(end_dk_4)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_4;
				END_LOAD_DK:
				    if(end_load_dk) begin
                        if(end_dk_1)
                            	ns_io = LOAD_DK_2;
                        else if(end_dk_2) begin
                            if(k_2)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_3;
                        end
                        else if(end_dk_3) begin
                            if(k_3)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_4;
                        end
                        else 
								ns_io = LOAD_CT_RESET; 
				    end
				    else
				        ns_io = END_LOAD_DK;
				// --- READ DK --- //
				READ_DK_1: 
				    if(end_dk_1)
				        ns_io = READ_DK_2;
				    else
				        ns_io = READ_DK_1;
				READ_DK_2: 
				    if(end_dk_2) begin
				        if(k_2)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_3;
				    end
				    else
				        ns_io = READ_DK_2;
				READ_DK_3: 
				    if(end_dk_3) begin
				        if(k_3)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_4;
				    end
				    else
				        ns_io = READ_DK_3;
				READ_DK_4: 
				    if(end_dk_4)
				        ns_io = END_READ_DK;
				    else
				        ns_io = READ_DK_4;
				END_READ_DK:
				    if(end_read_dk)
				        // ns_io = END_HEK;
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_DK;         
                // --- LOAD CT --- //
                LOAD_CT_RESET:
                    ns_io = LOAD_CT_1;
				LOAD_CT_1: 
				    if(end_ct_1)
				        ns_io = LOAD_CT_2;
				    else
				        ns_io = LOAD_CT_1;
				LOAD_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_3;
				    else
				        ns_io = LOAD_CT_2;
				LOAD_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_4;
				    else
				        ns_io = LOAD_CT_3;
				LOAD_CT_4: 
				    if(end_ct_4)
				        ns_io = LOAD_CT_L;
				    else
				        ns_io = LOAD_CT_4;
			    LOAD_CT_L: 
				    if(end_ct_l)
				        ns_io = START_OP;
				    else
				        ns_io = LOAD_CT_L;
				        
				// --- READ CT --- //
				READ_CT_1: 
				    if(end_ct_1)
				        ns_io = READ_CT_2;
				    else
				        ns_io = READ_CT_1;
				READ_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_3;
				    else
				        ns_io = READ_CT_2;
				READ_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_4;
				    else
				        ns_io = READ_CT_3;
				READ_CT_4: 
				    if(end_ct_4)
				        ns_io = END_READ_CT;
				    else
				        ns_io = READ_CT_4;
				END_READ_CT:
				    if((k_2 | k_3) & end_read_ct)
				        ns_io = READ_CT_L;
				    else if(k_4 & end_read_ct)
				        ns_io = RESET_READ_CT;
				    else
				        ns_io = END_READ_CT;  
				RESET_READ_CT:
				    ns_io = READ_CT_L;
			    READ_CT_L: 
				    if(end_ct_l)
				        ns_io = END_READ_CT_L;
				    else
				        ns_io = READ_CT_L;
				END_READ_CT_L:
				    if(end_read_ct_l)
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_CT_L; 
                // --- LOAD/READ M --- //
                LOAD_M_RESET:
					if(end_reset_m)
                    	ns_io = LOAD_M;
					else
						ns_io = LOAD_M_RESET;
                LOAD_M:
                    if(end_m)
                        ns_io = START_OP;
                    else
                        ns_io = LOAD_M;
                READ_M:
                    if(end_m)
                        ns_io = GMH;
                    else
                        ns_io = READ_M;
				START_OP:
				    if(end_op_core | start_read_ek)
				        ns_io = SEL_READ;
				    else
				        ns_io = START_OP;
				SEL_READ:
				    if(gen_keys)
				        ns_io = READ_EK_1;
				    else if(encap)
				        ns_io = READ_CT_1;
				    else   
				        ns_io = READ_M;
				GMH:
				    if(end_op_core)
				        ns_io = END_OP;
				    else
				        ns_io = GMH;
				/*
				END_HEK:
				    if(end_hek)
				        ns_io = END_OP;
				    else
				        ns_io = END_HEK;
				*/
				END_OP:
				    if(reset | g_reset_ed)
				        ns_io = IDLE;
				    else
				        ns_io = END_OP;
				default:
					    ns_io = IDLE;
			endcase 		
		end 
		
		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_1:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_10_0; // RAM 1 (NON_MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_2:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_10_0; // RAM 1 (NON_MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_3:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_10_0; // RAM 1 (NON_MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_4:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_10_0; // RAM 1 (NON_MASKED)
		                  gmh_decap           = 0;
		              end
		   END_LOAD_EK:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_10_0; // RAM 1 (NON_MASKED)
		                  gmh_decap           = 0;
		              end
           READ_EK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   END_READ_EK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ek;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
						  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_11_0; // RAM 1 (MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_11_0; // RAM 1 (MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_11_0; // RAM 1 (MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_11_0; // RAM 1 (MASKED)
		                  gmh_decap           = 0;
		              end
		   END_LOAD_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b11_11_11_11_0; // RAM 1 (MASKED)
		                  gmh_decap           = 0;
		              end
           READ_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end  
		   END_READ_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_dk;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end  
		   LOAD_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_00_0; // RAM 0 (NON MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_00_0; // RAM 0 (NON MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_00_0; // RAM 0 (NON MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_00_0; // RAM 0 (NON MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_01_0; // RAM 0 (MASKED)
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_CT_L_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
           READ_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   READ_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end 
		   END_READ_CT:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		  END_READ_CT_L:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct_l;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   RESET_READ_CT: begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_M_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b01_01_01_01_0; // RAM 0 (MASKED)
		                  gmh_decap           = 0;
		              end   
		   READ_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 1;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   START_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   SEL_READ:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_REG:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 1;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   GMH:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 1;
		              end
		   END_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b1};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		 default:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		  endcase
		
		end

		// Reducing fanout for the control signals
		reg read_ek_1, read_ek_2, read_ek_3, read_ek_4;
		reg read_dk_1, read_dk_2, read_dk_3, read_dk_4;
		reg read_ct_1, read_ct_2, read_ct_3, read_ct_4, read_ct_l;
		reg load_ek_1, load_ek_2, load_ek_3, load_ek_4;
		reg load_dk_1, load_dk_2, load_dk_3, load_dk_4;
		reg load_ct_1, load_ct_2, load_ct_3, load_ct_4, load_ct_l;
		reg load_m, read_m;
		reg end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st;
		reg load_ct_reset;
		reg load_m_reset;
		reg reset_read_ct;

		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct = 0;			
		              end
		   LOAD_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0001;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct  = 0;	
		              end
		   LOAD_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0010;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0100;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b1000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0001;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0010;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0100;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b1000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_READ_EK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b1000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   LOAD_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0001;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0010;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_3:   begin
		                 	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0100;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b1000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0001;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0010;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0100;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b1000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end  
		   END_READ_DK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0100;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end  
		   LOAD_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00010;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00100;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b01000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b10000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 1;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   LOAD_CT_L_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end 
           READ_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00010;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00100;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b01000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b10000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00001;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   END_READ_CT:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0010;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		  END_READ_CT_L:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0001;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   RESET_READ_CT: begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct	= 1;	
		                  end
		   LOAD_M_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 1;
							reset_read_ct   = 0;	
		              	end 
		   LOAD_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 1;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 1;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   START_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   SEL_READ:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_REG:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   GMH:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		 default:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;
		              end
		  endcase
		
		end
		
		

		
		// --- End & Counter signal --- //
		
		wire [63:0] END_C;
		wire [63:0] END_M;
		
		generate
		  if(N_BU == 1) begin
		      assign END_C = 5;
		      assign END_M = 69;
		  end
		  else if(N_BU == 2) begin
		      assign END_C = 6;
		      assign END_M = 70;
		  end
		  else begin
		      assign END_C = 7;
		      assign END_M = 71;
		  end
		endgenerate

		reg uad_0, uad_1, uad_2, uad_3; 
		always @(posedge clk) uad_0 <= upd_add_decoder;
		always @(posedge clk) uad_1 <= uad_0;
		always @(posedge clk) uad_2 <= uad_1;
		always @(posedge clk) uad_3 <= uad_2;

		reg [7:0] c_ek_1, c_ek_2, c_ek_3, c_ek_4;
		reg [7:0] c_dk_1, c_dk_2, c_dk_3, c_dk_4;
		reg [7:0] c_ct_1, c_ct_2, c_ct_3, c_ct_4, c_ct_l; 
		reg [7:0] c_m;
		reg [3:0] c_end_ek, c_end_dk, c_end_ct, c_end_ct_l;
		reg [3:0] c_reset_m;
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      end_ek_1 <= 1'b0;
		      end_ek_2 <= 1'b0;
		      end_ek_3 <= 1'b0;
		      end_ek_4 <= 1'b0;
		      
		      end_dk_1 <= 1'b0;
		      end_dk_2 <= 1'b0;
		      end_dk_3 <= 1'b0;
		      end_dk_4 <= 1'b0;
		      
		      end_ct_1 <= 1'b0;
		      end_ct_2 <= 1'b0;
		      end_ct_3 <= 1'b0;
		      end_ct_4 <= 1'b0;
		      end_ct_l <= 1'b0;
		      
		      end_m    <= 1'b0;  
		  	  end_reset_m <= 1'b0;
		      
		      end_read_ek <= 1'b0;
		      end_read_dk <= 1'b0; 
		      end_read_ct <= 1'b0;
		      end_read_ct_l <= 1'b0;

		  	  end_load_ek <= 1'b0;
			  end_load_dk <= 1'b0;
		  end
		  else begin
		              if(read_ek_int & c_ek_1 == 62)      end_ek_1 <= 1'b1;
		      else    if(load_ek_int & c_ek_1 == 64)      end_ek_1 <= 1'b1;
		      else    if(cs_io == END_LOAD_EK)            end_ek_1 <= end_ek_1;
		      else                                        end_ek_1 <= 1'b0;
		      
		              if(read_ek_int & c_ek_2 == 62)      end_ek_2 <= 1'b1;
		      else    if(load_ek_int & c_ek_2 == 64)      end_ek_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_2 <= end_ek_2;
		      else                                        end_ek_2 <= 1'b0;
		      
		              if(read_ek_int & c_ek_3 == 62)      end_ek_3 <= 1'b1;
		      else    if(load_ek_int & c_ek_3 == 64)      end_ek_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_3 <= end_ek_3;
		      else                                        end_ek_3 <= 1'b0;
		      
		              if(read_ek_int & c_ek_4 == 62)      end_ek_4 <= 1'b1;
		      else    if(load_ek_int & c_ek_4 == 64)      end_ek_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_4 <= end_ek_4;
		      else                                        end_ek_4 <= 1'b0;
		      
		              if(read_dk_int & c_dk_1 == 62)      end_dk_1 <= 1'b1;
		      else    if(load_dk_int & c_dk_1 == 64)      end_dk_1 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_1 <= end_dk_1;
		      else                                        end_dk_1 <= 1'b0;
		      
		              if(read_dk_int & c_dk_2 == 62)      end_dk_2 <= 1'b1;
		      else    if(load_dk_int & c_dk_2 == 64)      end_dk_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_2 <= end_dk_2;
		      else                                        end_dk_2 <= 1'b0;
		      
		              if(read_dk_int & c_dk_3 == 62)      end_dk_3 <= 1'b1;
		      else    if(load_dk_int & c_dk_3 == 64)      end_dk_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_3 <= end_dk_3;
		      else                                        end_dk_3 <= 1'b0;
		      
		              if(read_dk_int & c_dk_4 == 62)      end_dk_4 <= 1'b1;
		      else    if(load_dk_int & c_dk_4 == 64)      end_dk_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_4 <= end_dk_4;
		      else                                        end_dk_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_1 == 62)      end_ct_1 <= 1'b1;
		      else    if(load_ct_int & c_ct_1 == 64)      end_ct_1 <= 1'b1;
		      else                                        end_ct_1 <= 1'b0;
		      
		              if(read_ct_int & c_ct_2 == 62)      end_ct_2 <= 1'b1;
		      else    if(load_ct_int & c_ct_2 == 64)      end_ct_2 <= 1'b1;
		      else                                        end_ct_2 <= 1'b0;
		      
		              if(read_ct_int & c_ct_3 == 62)      end_ct_3 <= 1'b1;
		      else    if(load_ct_int & c_ct_3 == 64)      end_ct_3 <= 1'b1;
		      else                                        end_ct_3 <= 1'b0;
		      
		              if(read_ct_int & c_ct_4 == 62)      end_ct_4 <= 1'b1;
		      else    if(load_ct_int & c_ct_4 == 64)      end_ct_4 <= 1'b1;
		      else                                        end_ct_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_l == 62)      end_ct_l <= 1'b1;
		      else    if(load_ct_int & c_ct_l == 64)      end_ct_l <= 1'b1;
		      else                                        end_ct_l <= 1'b0;
		      
		              if(read_m_int & c_m == END_M)       end_m <= 1'b1;
		      else    if(load_m_int & c_m == 64)          end_m <= 1'b1;
		      else                                        end_m <= 1'b0;
		      
		      if(c_end_ek == END_C)   end_read_ek <= 1'b1;
		      else                    end_read_ek <= 1'b0;
		      
		      if(c_end_ek == 1)       end_load_ek <= 1'b1;
		      else                    end_load_ek <= 1'b0;
		      
		      if(c_end_dk == END_C)   end_read_dk <= 1'b1;
		      else                    end_read_dk <= 1'b0;

			  if(c_end_dk == 1)   end_load_dk <= 1'b1;
		      else                end_load_dk <= 1'b0;
		      
		      if(k_4 & c_end_ct == END_C+1)                 end_read_ct <= 1'b1; // Probably it depens on b
		      else if((k_2 | k_3) & c_end_ct == END_C+2)    end_read_ct <= 1'b1; // Probably it depens on b
		      else                                          end_read_ct <= 1'b0;
		      
		      if(c_end_ct_l == END_C) end_read_ct_l <= 1'b1;
		      else                    end_read_ct_l <= 1'b0;

			  if(c_reset_m == 3)  end_reset_m <= 1'b1;
		      else                end_reset_m <= 1'b0;
		      
		  end
		end
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      c_ek_1 <= 0;
		      c_ek_2 <= 0;
		      c_ek_3 <= 0;
		      c_ek_4 <= 0;
		      
		      c_dk_1 <= 0;
		      c_dk_2 <= 0;
		      c_dk_3 <= 0;
		      c_dk_4 <= 0;
		      
		      c_ct_1 <= 0;
		      c_ct_2 <= 0;
		      c_ct_3 <= 0;
		      c_ct_4 <= 0;
		      c_ct_l <= 0;
		      
		      c_m <= 0;
		      
		      c_end_ek    <= 0;
		      c_end_dk    <= 0;
		      c_end_ct    <= 0;
		      c_end_ct_l  <= 0;
		      c_reset_m   <= 0;
		  end
		  else begin
		      if(read_ek_1)                          c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & upd_add_decoder)   c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & !upd_add_decoder)  c_ek_1 <= c_ek_1;
		      else                                   c_ek_1 <= 0;
		      
		      if(read_ek_2)                          c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & upd_add_decoder)   c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & !upd_add_decoder)  c_ek_2 <= c_ek_2;
		      else                                   c_ek_2 <= 0;
		      
		      if(read_ek_3)                          c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & upd_add_decoder)   c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & !upd_add_decoder)  c_ek_3 <= c_ek_3;
		      else                                   c_ek_3 <= 0;
		      
		      if(read_ek_4)                          c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & upd_add_decoder)   c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & !upd_add_decoder)  c_ek_4 <= c_ek_4;
		      else                                   c_ek_4 <= 0;
		      
		      if(read_dk_1)                          c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & upd_add_decoder)   c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & !upd_add_decoder)  c_dk_1 <= c_dk_1;
		      else                                   c_dk_1 <= 0;
		      
		      if(read_dk_2)                          c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & upd_add_decoder)   c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & !upd_add_decoder)  c_dk_2 <= c_dk_2;
		      else                                   c_dk_2 <= 0;
		      
		      if(read_dk_3)                          c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & upd_add_decoder)   c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & !upd_add_decoder)  c_dk_3 <= c_dk_3;
		      else                                   c_dk_3 <= 0;
		      
		      if(read_dk_4)                          c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & upd_add_decoder)   c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & !upd_add_decoder)  c_dk_4 <= c_dk_4;
		      else                                   c_dk_4 <= 0;
		      
		      if(read_ct_1)                          c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & upd_add_decoder)   c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & !upd_add_decoder)  c_ct_1 <= c_ct_1;
		      else                                   c_ct_1 <= 0;
		      
		      if(read_ct_2)                          c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & upd_add_decoder)   c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & !upd_add_decoder)  c_ct_2 <= c_ct_2;
		      else                                   c_ct_2 <= 0;
		      
		      if(read_ct_3)                          c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & upd_add_decoder)   c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & !upd_add_decoder)  c_ct_3 <= c_ct_3;
		      else                                   c_ct_3 <= 0;
		      
		      if(read_ct_4)                          c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & upd_add_decoder)   c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & !upd_add_decoder)  c_ct_4 <= c_ct_4;
		      else                                   c_ct_4 <= 0;
		      
		      if(read_ct_l)                          c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & upd_add_decoder)   c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & !upd_add_decoder)  c_ct_l <= c_ct_l;
		      else                                   c_ct_l <= 0;
		      
		      if(read_m)                             c_m <= c_m + 1;
		      else if(load_m & upd_add_decoder)      c_m <= c_m + 1;
		      else if(load_m & !upd_add_decoder)     c_m <= c_m;
		      else                                   c_m <= 0;
		      
		      if(end_read_ek_st | cs_io == END_LOAD_EK)        	c_end_ek <= c_end_ek + 1;
		      else                              	            c_end_ek <= 0;
		      
		      if(end_read_dk_st | cs_io == END_LOAD_DK)        	c_end_dk <= c_end_dk + 1;
		      else                               				c_end_dk <= 0;
		      
		      if(end_read_ct_st)                    c_end_ct <= c_end_ct + 1;
		      else                               	c_end_ct <= 0;
		      
		      if(end_read_ct_l_st)                  c_end_ct_l <= c_end_ct_l + 1;
		      else                               	c_end_ct_l <= 0;

			  if(cs_io == LOAD_M_RESET)        		c_reset_m <= c_reset_m + 1;
		      else                              	c_reset_m <= 0;
		      
		  end
		
		
		end
		
		// --- Encoding / Decoding FOR MASKING --- //
		
		always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int | read_m_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[0] (RAM_0) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[1] (RAM_0)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_01; // ek[1] (RAM_0)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[1] (RAM_1)
		          else    if(end_read_dk_st) 	mode_encdec[7:0] = 8'b00_00_00_11; // dk[1] (RAM_1)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // c[0]  (RAM_1) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // c[1]  (RAM_1)
		          else    if(end_read_ct_st) 	mode_encdec[7:0] = 8'b00_00_00_11; // c[1]  (RAM_1)
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_00_11; // cl    (RAM_1) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_00_11; // cl    (RAM_1)
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[0] (RAM_1) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[1] (RAM_1)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[2] (RAM_1)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_11; // ek[2] (RAM_1)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[1] (RAM_1)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[0] (RAM_1) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[1] (RAM_1) 
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[2] (RAM_1) 
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b00_00_00_11; // ct[2] (RAM_1) 
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_00_11; // cl    (RAM_1) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_00_11; // cl    (RAM_1) 
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[0] (RAM_0)
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[1] (RAM_0)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[2] (RAM_0)
		          else    if(read_ek_4)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[3] (RAM_0)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_01; // ek[3] (RAM_0)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[1] (RAM_1)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1)
		          else    if(read_dk_4)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[3] (RAM_1)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b00_00_00_11; // dk[3] (RAM_1)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[0] (RAM_1) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[1] (RAM_1) 
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[2] (RAM_1) 
		          else    if(read_ct_4)      	mode_encdec[7:0] = 8'b00_00_00_11; // ct[3] (RAM_1) 
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b00_00_00_11; // ct[3] (RAM_1) 
		          else    if(reset_read_ct)	 	mode_encdec[7:0] = 8'b00_00_00_11; // ct[3] (RAM_1) 
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_00_01; // ctl   (RAM_0) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_00_01; // ctl   (RAM_0) 
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		  end
		  else                                        mode_encdec[7:0] = 8'b00_00_00_00; 
		  
        end
        
        always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	offset = 0;     // ek[0] (RAM_0) 
		          else    if(read_ek_2)     	offset = 128;   // ek[1] (RAM_0)
		          else    if(end_read_ek_st) 	offset = 128;   // ek[1] (RAM_0)
		          else    if(read_dk_1)      	offset = 0;     // dk[0] (RAM_1)
		          else    if(read_dk_2)      	offset = 128;   // dk[1] (RAM_1)
		          else    if(end_read_dk_st)    offset = 128;   // dk[1] (RAM_1)
		          else    if(read_ct_1)      	offset = 768;   // c[0]  (RAM_1) 
		          else    if(read_ct_2)      	offset = 896;   // c[1]  (RAM_1) 
		          else    if(end_read_ct_st)    offset = 896;   // c[1]  (RAM_1) 
		          else    if(read_ct_l)      	offset = 640;   // cl    (RAM_1) 
		          else    if(end_read_ct_l_st)  offset = 640;   // cl    (RAM_1) 
		          else    if(read_m)         	offset = 0;   // w     (RAM_1) 
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	offset = 512;     // ek[0] (RAM_1) 
		          else    if(read_ek_2)      	offset = 640;     // ek[1] (RAM_1)
		          else    if(read_ek_3)      	offset = 768;     // ek[2] (RAM_1)
		          else    if(end_read_ek_st) 	offset = 768;     // ek[2] (RAM_1)
		          else    if(read_dk_1)      	offset = 0;       // dk[0] (RAM_0)
		          else    if(read_dk_2)      	offset = 128;     // dk[1] (RAM_0)
		          else    if(read_dk_3)      	offset = 256;     // dk[2] (RAM_0)
		          else    if(end_read_dk_st)    offset = 256;     // dk[2] (RAM_0)
		          else    if(read_ct_1)      	offset = 512;     // ct[0] (RAM_1)  
		          else    if(read_ct_2)      	offset = 640;     // ct[1] (RAM_1)  
		          else    if(read_ct_3)      	offset = 768;     // ct[2] (RAM_1)  
		          else    if(end_read_ct_st)    offset = 768;     // ct[2] (RAM_1)  
		          else    if(read_ct_l)      	offset = 896;     // cl    (RAM_1)  
		          else    if(end_read_ct_l_st)  offset = 896;     // cl    (RAM_1)  
		          else    if(read_m)         	offset = 0;     // w     (RAM_1)
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	offset = 512;   // ek[0] (RAM_0)
		          else    if(read_ek_2)      	offset = 640;   // ek[1] (RAM_0)
		          else    if(read_ek_3)      	offset = 768;   // ek[2] (RAM_0)
		          else    if(read_ek_4)      	offset = 896;   // ek[3] (RAM_0)
		          else    if(end_read_ek_st) 	offset = 896;   // ek[3] (RAM_0)
		          else    if(read_dk_1)     	offset = 0;       // dk[0] (RAM_1)
		          else    if(read_dk_2)      	offset = 128;     // dk[1] (RAM_1)
		          else    if(read_dk_3)      	offset = 256;     // dk[2] (RAM_1)
		          else    if(read_dk_4)      	offset = 384;     // dk[3] (RAM_1)
		          else    if(end_read_dk_st)    offset = 384;     // dk[3] (RAM_1)
		          else    if(read_ct_1)      	offset = 512;     // ct[0] (RAM_1)   offset = 0
		          else    if(read_ct_2)      	offset = 640;     // ct[1] (RAM_1)   offset = 0
		          else    if(read_ct_3)      	offset = 768;     // ct[2] (RAM_1)   offset = 0
		          else    if(read_ct_4)      	offset = 896;     // ct[3] (RAM_1)   offset = 0
		          else    if(end_read_ct_st)    offset = 896;     // ct[3] (RAM_1)   offset = 0
		          else    if(reset_read_ct) 	offset = 384;   // ctl   (RAM_1)   offset = 384
		          else    if(read_ct_l)      	offset = 384;   // ctl   (RAM_1)   offset = 384
		          else    if(end_read_ct_l_st)  offset = 384;   // ctl   (RAM_1)   offset = 384
		          else    if(read_m)         	offset = 0;   // w     (RAM_1) 
		          else                          offset = 0;     // TO COMPLETE
		      end
		  end
		  else if(load_ek_int | load_dk_int | load_ct_int | load_m_int) begin
		      if(k_2) begin
		                  if(load_ek_1)      offset = 512;     
		          else    if(load_ek_2)      offset = 640;  
		          else    if(cs_io == END_LOAD_EK) offset = 640;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 640;     
		          else    if(load_ct_1)      offset = 0;   
		          else    if(load_ct_2)      offset = 128;   
		          else    if(load_ct_l)      offset = 256; 
		          else    if(load_m)         offset = 384;    
		          else                       offset = 0;     
		      end
		      else if(k_3) begin
		                  if(load_ek_1)      offset = 512;     
		          else    if(load_ek_2)      offset = 640;     
		          else    if(load_ek_3)      offset = 768; 
		          else    if(cs_io == END_LOAD_EK) offset = 768;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 640;     
		          else    if(load_dk_3)      offset = 768;     
		          else    if(load_ct_1)      offset = 0;     
		          else    if(load_ct_2)      offset = 128;     
		          else    if(load_ct_3)      offset = 256;     
		          else    if(load_ct_l)      offset = 384;  
		          else    if(load_m)         offset = 384;    
		          else                       offset = 0;     
		      end
		      else begin // k_4
		                  if(load_ek_1)      offset = 512;     
		          else    if(load_ek_2)      offset = 640;     
		          else    if(load_ek_3)      offset = 768;     
		          else    if(load_ek_4)      offset = 896;
		          else    if(cs_io == END_LOAD_EK) offset = 896;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 640;     
		          else    if(load_dk_3)      offset = 768;     
		          else    if(load_dk_4)      offset = 896;     
		          else    if(load_ct_1)      offset = 0;     
		          else    if(load_ct_2)      offset = 128;     
		          else    if(load_ct_3)      offset = 256;     
		          else    if(load_ct_4)      offset = 384;     
		          else    if(load_ct_l)      offset = 512;     
		          else    if(load_m)         offset = 384; 
		          else                       offset = 0;     
		      end
		  end
		  else                               offset = 0; 
		  
        end
        
		
		always @* begin
		  if(k_2 | k_3) begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(load_ct_int & !load_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		   end
		   else begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(load_ct_int & !load_ct_l)       	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		  end
        end
		
		wire end_ek = end_ek_1 | end_ek_2 | end_ek_3 | end_ek_4 | (end_read_ek_st);		
		wire end_dk = end_dk_1 | end_dk_2 | end_dk_3 | end_dk_4 | (end_read_dk_st);
		wire end_ct = end_ct_1 | end_ct_2 | end_ct_3 | end_ct_4 | end_ct_l | (end_read_ct_st) | (end_read_ct_l_st) | (reset_read_ct);
		
		always @(posedge clk) begin
		  if(!rst | reset | cs_io == START_OP)                                                        add_ram_ini <= 0;
		  else begin
		           if(end_ek & load_ek_int & !end_load_ek)                                            add_ram_ini <= add_ram_ini;
			  else if(end_dk & load_dk_int & !end_load_dk)                                            add_ram_ini <= add_ram_ini;
			  else if(cs_io == LOAD_M_RESET)                                                          add_ram_ini <= 0;
		      else if(end_ek | end_dk | end_ct | end_m)                                               add_ram_ini <= 0; // offset
		      else if(read_ek_int | read_dk_int | read_ct_int | read_m_int)                           add_ram_ini <= add_ram_ini + 2;
		      else if((load_ek_int | load_dk_int | load_ct_int | load_m_int) & uad_1)	  		      add_ram_ini <= add_ram_ini + 2;
		      else                                                                                    add_ram_ini <= add_ram_ini;
		  end
		end

		
		localparam EK_512     = (800  - 32) / 8;
		localparam EK_768     = (1184 - 32) / 8;
		localparam EK_1024    = (1568 - 32) / 8;
		
		always @* begin
		  if(cs_io == LOAD_EK_REG) begin
		              if(k_2 & add_int == EK_512 - 1)     end_ek_reg = 1;
		      else    if(k_3 & add_int == EK_768 - 1)     end_ek_reg = 1;
		      else    if(k_4 & add_int == EK_1024 - 1)    end_ek_reg = 1;
		      else                                        end_ek_reg = 0;
		  end
		  else                                            end_ek_reg = 0;
		 		  
		end
		
		
		wire end_ek_add = end_read_ek;
		wire end_dk_add = end_read_dk;
		wire end_ct_add = end_read_ct_l;
		
		always @(posedge clk) begin
		  if(!rst | reset)                                                                    add_int <= 0;
		  else begin
		      if(end_ek_add | end_dk_add | end_ct_add | end_ek_reg)                           add_int <= 0;
		      else if(load_m_reset | load_ct_reset | cs_io == SEL_READ)     				  add_int <= 0;
		      else if(start_encoder & d_valid_enc)                                            add_int <= add_int + 1;
		      else if(start_decoder & d_ready_decoder)                                        add_int <= add_int + 1;
		      else if(load_ek_reg)                                                            add_int <= add_int + 1;
		      else                                                                            add_int <= add_int;
		  end
		end
    
    // --- CMOV
    assign en_w = load | (read_dk_int   | read_ek_int   | read_m_int | (read_ct_int & d_valid_enc & ~end_read_ct & !reset_read_ct)); // I need that for doing the cmov while reading ct
    
    always @(posedge clk)                               data_in_ram_cmov    <= data_in_ram;
    always @(posedge clk)                               d_valid_cmov        <= (reset_read_ct) ? 1'b0 : d_valid_enc & ~end_read_ct;
    always @(posedge clk) begin
        if(!rst)                                        cmov <= 1'b1;
        else begin
            if(cs_io == RESET_READ_CT)                  cmov <= cmov;
            else if(cmov & encap_decap & read_ct_int & d_valid_cmov) begin
                if(data_out_ram == data_in_ram_cmov)    cmov <= 1'b1;
                else                                    cmov <= 1'b0;
            end
            else                                        cmov <= cmov;
        end
    end
    
    
	// -- ek_in --
	
	reg  [4:0] add_w_ek;
	reg  [4:0] add_w_ek_p;
	always @(posedge clk) add_w_ek_p <= add_w_ek;
	
	reg load_ek_reg_reg;   always @(posedge clk) load_ek_reg_reg <= load_ek_reg;
	reg load_ek_r3;        always @(posedge clk) load_ek_r3 <= (gen_keys) ? load_ek_reg_reg : load_ek_reg;
	reg en_w_p; 
	always @(posedge clk) en_w_p <= (read_ek_int | load_ek_r3);
	
	reg [1087:0]   ek_in_reg;
	
	reg [4:0] sel;
	
	RAMD64_CR #(
    .COLS(17), // 1088
    .ROWS(1)
    ) EK_REG (
    .clk    (   clk                 ),
    .en_w   (   en_w_p              ),
    .add_w  (   add_w_ek_p          ),
    .add_r  (   sel                 ),
    .d_i     (   ek_in_reg           ),
    .d_o     (   ek_in               )
    );
	
	reg act_keccak;
	wire cond_load = (cs_io == START_OP & encap);
	// always @(posedge clk) act_keccak <= (read_ek_int | read_dk_int | cond_load | !end_hek) ? start_keccak : 1'b0;
	always @(posedge clk) act_keccak <= (read_ek_int | read_dk_int | cond_load) ? start_keccak : 1'b0;
	wire upd_keccak;
	assign upd_keccak = (start_keccak && !act_keccak) ? 1'b1 : 1'b0 ;
	
	always @(posedge clk) begin
	   if(cs_io == IDLE) sel <= 0;
	   // else if (read_ek_int | read_dk_int | !end_hek) begin
	   else if (read_ek_int | read_dk_int) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else if (cond_load) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else sel <= sel;
	end
	
	wire op_reg = read_ek_int | load_ek_reg;
	
	reg [7:0] add_ek;
	always @(posedge clk) begin
	   if(!op_reg) begin 
	       add_ek      <= 0;
	       add_w_ek    <= 0;
	   end
	   else if (read_ek_int) begin 
	       if(add_ek == 16) begin
	         if(d_valid_enc) begin
                add_ek      <= 0;
                add_w_ek    <= add_w_ek + 1;
             end
             else begin
                add_ek      <= add_ek;
                add_w_ek    <= add_w_ek;
             end
	       end
	       else begin
               if(d_valid_enc) begin
                    add_ek      <= add_ek + 1;
                    add_w_ek    <= add_w_ek;
               end
               else begin
                    add_ek      <= add_ek;
                    add_w_ek    <= add_w_ek;
               end
           end
	   end
	   else if (load_ek_reg_reg) begin
	       if(add_ek == 16) begin
	           add_ek      <= 0;
               add_w_ek    <= add_w_ek + 1;
	       end
	       else begin
	           add_ek      <= add_ek + 1;
               add_w_ek    <= add_w_ek;
	       end
	   end
	
	end
	
	always @(posedge clk) begin 
	   if(cs_io == IDLE) begin
           ek_in_reg <= 0;
	   end
	   else begin
	       if(read_ek_int)             ek_in_reg[add_ek*64+:64] <= data_in_int;
	       else if(load_ek_reg_reg)    ek_in_reg[add_ek*64+:64] <= data_out_ram;
	       else                        ek_in_reg <= ek_in_reg;
	   end
	end 
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)                       start_hek <= 0;
	   else begin
	       if(add_ek[4] & d_valid_enc)         start_hek <= 1;
	       else if(load_ek_int)                start_hek <= 1;
	       else                                        start_hek <= start_hek;     
	   end 
	end
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)               last_hek <= 0;
	   else begin
	       if(k_2 & sel == 5)          last_hek <= 1;
	       else if(k_3 & sel == 8)     last_hek <= 1;
	       else if(k_4 & sel == 11)    last_hek <= 1;
	       else                        last_hek <= last_hek;
	   end
	end
	/*
	always @(posedge clk) begin
	   if(cs_io == IDLE)                   end_hek <= 1;
	   else if(start_hek & !last_hek)      end_hek <= 0;
	   else if(start_hek & last_hek)       end_hek <= 1;
	   else                                end_hek <= end_hek;
	end
    */

endmodule


module IO_INTERFACE_N_BU_2 (
    input                       clk,
    input                       rst,
    
    // AXI signals
    input       [7:0]           control,
    input       [63:0]          data_in,
    input       [15:0]          add,
    output reg  [63:0]          data_out, 
    output reg  [1:0]           end_op,

    // Write/Read RAM signals
    input       [63:0]          data_in_int,
    output      [16*10-1:0]     add_ram,
    output      [63:0]          data_out_int,

    // Input keccak
    output reg  [255:0]         i_seed_0, // d / rho
    output reg  [255:0]         i_seed_1, // r
    input       [255:0]         o_seed_0, // rho
    input       [255:0]         o_seed_1, // sigma
    output reg  [255:0]         i_hek,
    output reg  [255:0]         i_ss,
    input       [255:0]         o_hek,
    input       [255:0]         o_ss,
    output      [1087:0]        ek_in,

	// Control keccak
	input                       start_keccak,
    input                       start_read_ek,
    output  reg                 start_hek,
    output  reg                 last_hek,

    
    output reg                  start_core,
    input                       end_op_core,
    output reg                  sel_io,
    output reg                  gmh_decap,
    input                       encap_decap,
    input                       g_reset_ed,
    
    // Encoder/Decoder signals
    output  reg [15:0]          mode_encdec,
    input                       d_valid_enc,
    output  reg                 start_encoder,
    output  reg                 start_decoder,
    input                       d_ready_decoder,
    output                      d_valid_decoder,
    input                       upd_add_decoder,
    
    output  [40:0]              control_dmu
);
    
    reg [8:0] control_dmu_encdec;
    assign control_dmu = {control_dmu_encdec, 32'h0000_0000_0000_0000};
    
    reg  [15:0]       add_int;

    // -- Control signals -- //
    wire [3:0] op;
    assign op = control[3:0];
    
	wire reset;	
	wire load_r0;
	wire read_r0;
	wire load_r1;
	wire read_r1;
	wire load_hek;
	wire read_hek;
	wire load_ss;
	wire read_ss;
	wire load_dk;
	wire read_dk;
	wire load_ek;
	wire read_ek;
	wire load_ct;
	wire read_ct;
	wire start;

    assign reset        = (op == 4'h0) ? 1 : 0;
    assign load_r0      = (op == 4'h1) ? 1 : 0;
    assign read_r0      = (op == 4'h2) ? 1 : 0;
    assign load_r1      = (op == 4'h3) ? 1 : 0;
    assign read_r1      = (op == 4'h4) ? 1 : 0;
    assign load_hek     = (op == 4'h5) ? 1 : 0;
    assign read_hek     = (op == 4'h6) ? 1 : 0;
    assign load_ss      = (op == 4'h7) ? 1 : 0;
    assign read_ss      = (op == 4'h8) ? 1 : 0;
    assign load_dk      = (op == 4'h9) ? 1 : 0;
    assign read_dk      = (op == 4'hA) ? 1 : 0;
    assign load_ek      = (op == 4'hB) ? 1 : 0;
    assign read_ek      = (op == 4'hC) ? 1 : 0;
    assign load_ct      = (op == 4'hD) ? 1 : 0;
    assign read_ct      = (op == 4'hE) ? 1 : 0;
    assign start        = (op == 4'hF) ? 1 : 0;
    
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
    
   reg          load_ek_int;
   reg          load_dk_int;
   reg          load_ct_int;
   reg          read_ek_int;
   reg          read_dk_int;
   reg          read_ct_int;
   reg          load_ek_reg;
   reg          read_m_int;
   reg          load_m_int;

    reg  [9:0] add_ram_ini;
    reg  [9:0] offset;
    
    assign d_valid_decoder = load_ek_int | load_dk_int | load_ct_int | load_m_int;
    
    assign add_ram = {
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset, 
        add_ram_ini+1'b1+offset, add_ram_ini+offset, add_ram_ini+1'b1+offset, add_ram_ini+offset };
   
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_0 <= 0;
        else if(load_r0) begin
            case(add[1:0]) 
                2'b00:  i_seed_0[063:000] <= data_in;
                2'b01:  i_seed_0[127:064] <= data_in;
                2'b10:  i_seed_0[191:128] <= data_in;
                2'b11:  i_seed_0[255:192] <= data_in;
            endcase
        end 
        else            i_seed_0 <= i_seed_0;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_seed_1 <= 0;
        else if(load_r1) begin
            case(add[1:0]) 
                2'b00:  i_seed_1[063:000] <= data_in;
                2'b01:  i_seed_1[127:064] <= data_in;
                2'b10:  i_seed_1[191:128] <= data_in;
                2'b11:  i_seed_1[255:192] <= data_in;
            endcase
        end 
        else            i_seed_1 <= i_seed_1;
    end
    
    
    always @(posedge clk) begin
        if(!rst | reset)        i_hek <= 0;
        else if(load_hek) begin
            case(add[1:0]) 
                2'b00:  i_hek[063:000] <= data_in;
                2'b01:  i_hek[127:064] <= data_in;
                2'b10:  i_hek[191:128] <= data_in;
                2'b11:  i_hek[255:192] <= data_in;
            endcase
        end 
        else            i_hek <= i_hek;
    end
    
    always @(posedge clk) begin
        if(!rst | reset)        i_ss <= 0;
        else if(load_ss) begin
            case(add[1:0]) 
                2'b00:  i_ss[063:000] <= data_in;
                2'b01:  i_ss[127:064] <= data_in;
                2'b10:  i_ss[191:128] <= data_in;
                2'b11:  i_ss[255:192] <= data_in;
            endcase
        end 
        else if(read_m_int) begin
            case(add_int[1:0]) 
                2'b00:  i_ss[063:000] <= data_in_int;
                2'b01:  i_ss[127:064] <= data_in_int;
                2'b10:  i_ss[191:128] <= data_in_int;
                2'b11:  i_ss[255:192] <= data_in_int;
            endcase
        end 
        else            i_ss <= i_ss;
    end
    
    // RAM - I/O
    wire load;
    assign load     = load_dk       | load_ek       | load_ct       |   load_ss;
    wire load_int;
    assign load_int = read_dk_int   | read_ek_int   | read_ct_int   |   read_m_int;
    wire read;
    assign read = read_dk | read_ek | read_ct;
    
    wire en_w;

    reg  [12:0] addr_w;
    reg  [12:0] addr_r;
    always @* begin
                if(load_ek)     addr_w = add;
        else    if(load_dk)     addr_w = add + 256;    
        else    if(load_ct)     addr_w = add + 512;  
        else    if(load_ss)     addr_w = add + 768; // load m   
        else    if(read_ek_int) addr_w = add_int;
        else    if(read_dk_int) addr_w = add_int + 256; 
        else    if(read_ct_int) addr_w = add_int + 512;   
        else    if(read_m_int)  addr_w = add_int + 768; // read m  
        else                    addr_w = add; 
    end
    
    always @* begin
                if(read_ek)     addr_r = add;
        else    if(read_dk)     addr_r = add + 256;    
        else    if(read_ct)     addr_r = add + 512; 
        else    if(read_ss)     addr_r = add + 768; // It's not going to be used     
        else    if(load_ek_int) addr_r = add_int;
        else    if(load_ek_reg) addr_r = add_int;
        else    if(load_dk_int) addr_r = add_int + 256; 
        else    if(load_ct_int) addr_r = add_int + 512;   
        else    if(load_m_int)  addr_r = add_int + 768; // decoding m
        else    if(read_ct_int) addr_r = add_int + 512; // cmov while reading ct
        else                    addr_r = add; 
    end
    
    wire [63:0] data_in_ram;
    assign data_in_ram = (load_int) ? data_in_int : data_in;
    wire [63:0] data_out_ram;
    assign data_out_int = data_out_ram;
    
    RAM #(.SIZE(8192), .WIDTH(64)) RAM_IO
    (.clk       (   clk             ), 
    .en_write   (   en_w            ),     
    .en_read    (   1               ), 
    .addr_write (   addr_w          ),              
    .addr_read  (   addr_r          ), 
    .data_in    (   data_in_ram     ),
    .data_out   (   data_out_ram    )
    );
    
    // check ct (cmov)
    reg cmov;
    reg [63:0] data_in_ram_cmov;
    reg d_valid_cmov;
    
    reg [63:0] o_seed_0_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_0_reg <= 0;
        else if(read_r0) begin
            case(add[1:0]) 
                2'b00:  o_seed_0_reg <= o_seed_0[063:000];
                2'b01:  o_seed_0_reg <= o_seed_0[127:064];
                2'b10:  o_seed_0_reg <= o_seed_0[191:128];
                2'b11:  o_seed_0_reg <= o_seed_0[255:192];
            endcase
        end 
        else            o_seed_0_reg <= o_seed_0_reg;
    end
    
    reg [63:0] o_seed_1_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_seed_1_reg <= 0;
        else if(read_r1) begin
            case(add[1:0]) 
                2'b00:  o_seed_1_reg <= o_seed_1[063:000];
                2'b01:  o_seed_1_reg <= o_seed_1[127:064];
                2'b10:  o_seed_1_reg <= o_seed_1[191:128];
                2'b11:  o_seed_1_reg <= o_seed_1[255:192];
            endcase
        end 
        else            o_seed_1_reg <= o_seed_1_reg;
    end
    
    reg [63:0] o_hek_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_hek_reg <= 0;
        else if(read_hek) begin
            case(add[1:0]) 
                2'b00:  o_hek_reg <= o_hek[063:000];
                2'b01:  o_hek_reg <= o_hek[127:064];
                2'b10:  o_hek_reg <= o_hek[191:128];
                2'b11:  o_hek_reg <= o_hek[255:192];
            endcase
        end 
        else            o_hek_reg <= o_hek_reg;
    end
    
    reg [63:0] o_ss_reg;
    
    always @(posedge clk) begin
        if(!rst)        o_ss_reg <= 0;
        else if(read_ss) begin
            case(add[1:0]) 
                2'b00:  o_ss_reg <= o_ss[063:000];
                2'b01:  o_ss_reg <= o_ss[127:064];
                2'b10:  o_ss_reg <= o_ss[191:128];
                2'b11:  o_ss_reg <= o_ss[255:192];
            endcase
        end 
        else            o_ss_reg <= o_ss_reg;
    end
    
    always @* begin
                if(!cmov)                   data_out = 64'hFFFF_FFFF_FFFF_FFFF;
        else    if(read_r0)                 data_out = o_seed_0_reg;  
        else    if(read_r1)                 data_out = o_seed_1_reg;  
        else    if(read_hek)                data_out = o_hek_reg;
        else    if(read_ss & encap)         data_out = o_ss_reg;
        else    if(read_ss & decap)         data_out = o_ss_reg;
        else                                data_out = data_out_ram;        
    end
    
    // --- Control Encoder/Decoder --- //
    
    //--*** STATE declaration **--//
	localparam IDLE            = 8'h00;
	localparam LOAD_EK_1       = 8'h10; 
	localparam LOAD_EK_2       = 8'h11; 
	localparam LOAD_EK_3       = 8'h12; 
	localparam LOAD_EK_4       = 8'h13; 
	localparam END_LOAD_EK     = 8'h1F; 
	localparam READ_EK_1       = 8'h20; 
	localparam READ_EK_2       = 8'h21;
	localparam READ_EK_3       = 8'h22;
	localparam READ_EK_4       = 8'h23;
	localparam END_READ_EK     = 8'h2F;
	localparam LOAD_DK_1       = 8'h30; 
	localparam LOAD_DK_2       = 8'h31; 
	localparam LOAD_DK_3       = 8'h32; 
	localparam LOAD_DK_4       = 8'h33; 
	localparam END_LOAD_DK     = 8'h3F;
	localparam READ_DK_1       = 8'h40; 
	localparam READ_DK_2       = 8'h41;
	localparam READ_DK_3       = 8'h42;
	localparam READ_DK_4       = 8'h43;
	localparam END_READ_DK     = 8'h4F;
	localparam LOAD_CT_RESET   = 8'h5F;
	localparam LOAD_CT_L_RESET = 8'h5E;
	localparam LOAD_CT_1       = 8'h50; 
	localparam LOAD_CT_2       = 8'h51; 
	localparam LOAD_CT_3       = 8'h52; 
	localparam LOAD_CT_4       = 8'h53; 
	localparam LOAD_CT_L       = 8'h54;
	localparam READ_CT_1       = 8'h60; 
	localparam READ_CT_2       = 8'h61;
	localparam READ_CT_3       = 8'h62;
	localparam READ_CT_4       = 8'h63;
	localparam END_READ_CT     = 8'h6E;
	localparam RESET_READ_CT   = 8'h6D;
	localparam READ_CT_L       = 8'h64;
	localparam END_READ_CT_L   = 8'h6F;
	localparam START_OP        = 8'h70;
	localparam SEL_READ        = 8'h80;
	localparam LOAD_EK_REG     = 8'h90;
	localparam LOAD_M_RESET    = 8'hA0;
	localparam LOAD_M          = 8'hA1;
	localparam READ_M          = 8'hB0;
	localparam GMH             = 8'hC0;
	localparam END_OP          = 8'hFF;
    
    //--*** STATE register **--//
	reg [7:0] cs_io; // current_state
	reg [7:0] ns_io; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | reset)    cs_io <= IDLE;
			else                 cs_io <= ns_io;
		end
    
    //--*** STATE Transition **--//
    reg end_ek_1, end_ek_2, end_ek_3, end_ek_4;
    reg end_dk_1, end_dk_2, end_dk_3, end_dk_4;
    reg end_ct_1, end_ct_2, end_ct_3, end_ct_4, end_ct_l;
    reg end_ek_reg;
    reg end_m, end_reset_m;
    reg end_read_ek, end_read_dk, end_read_ct, end_read_ct_l;
    reg end_load_ek, end_load_dk, end_load_ct, end_load_ct_l;
	
	always @* begin
			case (cs_io)
				IDLE:
				   if (start) begin
				        if(encap)
				            ns_io = LOAD_EK_REG;
				        else if(decap)
				            ns_io = LOAD_DK_1;
				        else    
				            ns_io = START_OP;
				   end
				   else
				        ns_io = IDLE;
				LOAD_EK_REG:
				    if(end_ek_reg)
				        ns_io = LOAD_EK_1;
				    else
				        ns_io = LOAD_EK_REG;
				// --- LOAD EK --- //
				LOAD_EK_1:
				    if(end_ek_1)
				        ns_io = END_LOAD_EK;
				    else
				        ns_io = LOAD_EK_1;
				LOAD_EK_2:
				    if(end_ek_2)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_2 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_2 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_2;    
				LOAD_EK_3:
				    if(end_ek_3)
				        ns_io = END_LOAD_EK;
				        /*
				        if(k_3 & encap)
				            ns_io = LOAD_M_RESET;
				        else if(k_3 & decap)
				            ns_io = LOAD_DK_1;
				        else
				            ns_io = LOAD_EK_RESET;
				        */
				    else    
				        ns_io = LOAD_EK_3; 
				LOAD_EK_4:
				    if(end_ek_4) 
				        /*
				        begin
				        if(encap)
				            ns_io = LOAD_M_RESET;
				        else // decap
				            ns_io = LOAD_DK_1;
				        end 
				        */
				        ns_io = END_LOAD_EK;
				    else    
				        ns_io = LOAD_EK_4;    
				END_LOAD_EK:
				    if(end_load_ek) begin
                        if(end_ek_1)
                            ns_io = LOAD_EK_2;
                        else if(end_ek_2) begin
                            if(k_2 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_2 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_3;
                            end
                        else if(end_ek_3) begin
                            if(k_3 & encap)
				                ns_io = LOAD_M_RESET;
				            else if(k_3 & decap)
				                ns_io = LOAD_DK_1;
				            else
				                ns_io = LOAD_EK_4;
                        end
                        else begin
                            if(encap)
				                ns_io = LOAD_M_RESET;
				            else // decap
				                ns_io = LOAD_DK_1;
                        end
				    end
				    else
				        ns_io = END_LOAD_EK;
				          
				// --- READ EK --- //
				READ_EK_1: 
				    if(end_ek_1)
				        ns_io = READ_EK_2;
				    else
				        ns_io = READ_EK_1;
				READ_EK_2: 
				    if(end_ek_2) begin
				        if(k_2)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_3;
				    end
				    else
				        ns_io = READ_EK_2;
				READ_EK_3: 
				    if(end_ek_3) begin
				        if(k_3)
				            ns_io = END_READ_EK;
				        else
				            ns_io = READ_EK_4;
				    end
				    else
				        ns_io = READ_EK_3;
				READ_EK_4: 
				    if(end_ek_4)
				        ns_io = END_READ_EK;
				    else
				        ns_io = READ_EK_4;
				END_READ_EK:
				    if(end_read_ek)
				        ns_io = READ_DK_1;
				    else
				        ns_io = END_READ_EK;    
				// --- LOAD DK --- //
				LOAD_DK_1: 
				    if(end_dk_1)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_1;
				LOAD_DK_2: 
				    if(end_dk_2)
						/*
				        if(k_2)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_2;
				LOAD_DK_3: 
				    if(end_dk_3)
				        /*
				        if(k_3)
				            ns_io = LOAD_CT_RESET;
				        else
				            ns_io = LOAD_DK_RESET;
						*/
						ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_3;
				LOAD_DK_4: 
				    if(end_dk_4)
				        ns_io = END_LOAD_DK;
				    else
				        ns_io = LOAD_DK_4;
				END_LOAD_DK:
				    if(end_load_dk) begin
                        if(end_dk_1)
                            	ns_io = LOAD_DK_2;
                        else if(end_dk_2) begin
                            if(k_2)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_3;
                        end
                        else if(end_dk_3) begin
                            if(k_3)
				                ns_io = LOAD_CT_RESET;
				            else
				                ns_io = LOAD_DK_4;
                        end
                        else 
								ns_io = LOAD_CT_RESET; 
				    end
				    else
				        ns_io = END_LOAD_DK;
				// --- READ DK --- //
				READ_DK_1: 
				    if(end_dk_1)
				        ns_io = READ_DK_2;
				    else
				        ns_io = READ_DK_1;
				READ_DK_2: 
				    if(end_dk_2) begin
				        if(k_2)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_3;
				    end
				    else
				        ns_io = READ_DK_2;
				READ_DK_3: 
				    if(end_dk_3) begin
				        if(k_3)
				            ns_io = END_READ_DK;
				        else
				            ns_io = READ_DK_4;
				    end
				    else
				        ns_io = READ_DK_3;
				READ_DK_4: 
				    if(end_dk_4)
				        ns_io = END_READ_DK;
				    else
				        ns_io = READ_DK_4;
				END_READ_DK:
				    if(end_read_dk)
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_DK;         
                // --- LOAD CT --- //
                LOAD_CT_RESET:
                    ns_io = LOAD_CT_1;
				LOAD_CT_1: 
				    if(end_ct_1)
				        ns_io = LOAD_CT_2;
				    else
				        ns_io = LOAD_CT_1;
				LOAD_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_3;
				    else
				        ns_io = LOAD_CT_2;
				LOAD_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = LOAD_CT_L;
				        else
				            ns_io = LOAD_CT_4;
				    else
				        ns_io = LOAD_CT_3;
				LOAD_CT_4: 
				    if(end_ct_4)
				        ns_io = LOAD_CT_L;
				    else
				        ns_io = LOAD_CT_4;
			    LOAD_CT_L: 
				    if(end_ct_l)
				        ns_io = START_OP;
				    else
				        ns_io = LOAD_CT_L;
				        
				// --- READ CT --- //
				READ_CT_1: 
				    if(end_ct_1)
				        ns_io = READ_CT_2;
				    else
				        ns_io = READ_CT_1;
				READ_CT_2: 
				    if(end_ct_2)
				        if(k_2)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_3;
				    else
				        ns_io = READ_CT_2;
				READ_CT_3: 
				    if(end_ct_3)
				        if(k_3)
				            ns_io = END_READ_CT;
				        else
				            ns_io = READ_CT_4;
				    else
				        ns_io = READ_CT_3;
				READ_CT_4: 
				    if(end_ct_4)
				        ns_io = END_READ_CT;
				    else
				        ns_io = READ_CT_4;
				END_READ_CT:
				    if((k_2 | k_3) & end_read_ct)
				        ns_io = READ_CT_L;
				    else if(k_4 & end_read_ct)
				        ns_io = RESET_READ_CT;
				    else
				        ns_io = END_READ_CT;  
				RESET_READ_CT:
				    ns_io = READ_CT_L;
			    READ_CT_L: 
				    if(end_ct_l)
				        ns_io = END_READ_CT_L;
				    else
				        ns_io = READ_CT_L;
				END_READ_CT_L:
				    if(end_read_ct_l)
				        ns_io = END_OP;
				    else
				        ns_io = END_READ_CT_L; 
                // --- LOAD/READ M --- //
                LOAD_M_RESET:
					if(end_reset_m)
                    	ns_io = LOAD_M;
					else
						ns_io = LOAD_M_RESET;
                LOAD_M:
                    if(end_m)
                        ns_io = START_OP;
                    else
                        ns_io = LOAD_M;
                READ_M:
                    if(end_m)
                        ns_io = GMH;
                    else
                        ns_io = READ_M;
				START_OP:
				    if(end_op_core | start_read_ek)
				        ns_io = SEL_READ;
				    else
				        ns_io = START_OP;
				SEL_READ:
				    if(gen_keys)
				        ns_io = READ_EK_1;
				    else if(encap)
				        ns_io = READ_CT_1;
				    else   
				        ns_io = READ_M;
				GMH:
				    if(end_op_core)
				        ns_io = END_OP;
				    else
				        ns_io = GMH;
				END_OP:
				    if(reset | g_reset_ed)
				        ns_io = IDLE;
				    else
				        ns_io = END_OP;
				default:
					    ns_io = IDLE;
			endcase 		
		end 
		
		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_1:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_2:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_3:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_4:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  gmh_decap           = 0;
		              end
		   END_LOAD_EK:   begin
		                  load_ek_int         = 1;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  gmh_decap           = 0;
		              end
           READ_EK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_EK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   END_READ_EK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 1;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ek;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
						  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
		   LOAD_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_11_00_0; // RAM 1_2
		                  gmh_decap           = 0;
		              end
		   END_LOAD_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 1;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_11_0; // RAM 1_1
		                  gmh_decap           = 0;
		              end
           READ_DK_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_DK_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end  
		   END_READ_DK:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 1;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_dk;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end  
		   LOAD_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_01_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_01_00_0; // RAM 0_2
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_01_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_01_00_0; // RAM 0_2
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_01_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end
		   LOAD_CT_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_CT_L_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 1;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
           READ_CT_1:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_2:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_3:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end
		   READ_CT_4:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   READ_CT_L:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end 
		   END_READ_CT:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		  END_READ_CT_L:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1 & !end_read_ct_l;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   RESET_READ_CT: begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 1;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		                  end
		   LOAD_M_RESET:  begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end 
		   LOAD_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 1;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 1;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_01_0; // RAM 0_1
		                  gmh_decap           = 0;
		              end   
		   READ_M:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 1;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 1;
		                  control_dmu_encdec  = 9'b00_00_00_00_1;
		                  gmh_decap           = 0;
		              end   
		   START_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   SEL_READ:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   LOAD_EK_REG:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 1;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		   GMH:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 1;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 1;
		              end
		   END_OP:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 0;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b1};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		 default:   begin
		                  load_ek_int         = 0;
		                  load_dk_int         = 0;
		                  load_ct_int         = 0;
		                  read_ek_int         = 0;
		                  read_dk_int         = 0;
		                  read_ct_int         = 0;
		                  load_ek_reg         = 0;
		                  load_m_int          = 0;
		                  read_m_int          = 0;
		                  start_core          = 0;
		                  start_encoder       = 1;
		                  start_decoder       = 0;
		                  end_op              = {cmov, 1'b0};
		                  sel_io              = 0;
		                  control_dmu_encdec  = 9'b00_00_00_00_0;
		                  gmh_decap           = 0;
		              end
		  endcase
		
		end

		// Reducing fanout for the control signals
		reg read_ek_1, read_ek_2, read_ek_3, read_ek_4;
		reg read_dk_1, read_dk_2, read_dk_3, read_dk_4;
		reg read_ct_1, read_ct_2, read_ct_3, read_ct_4, read_ct_l;
		reg load_ek_1, load_ek_2, load_ek_3, load_ek_4;
		reg load_dk_1, load_dk_2, load_dk_3, load_dk_4;
		reg load_ct_1, load_ct_2, load_ct_3, load_ct_4, load_ct_l;
		reg load_m, read_m;
		reg end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st;
		reg load_ct_reset;
		reg load_m_reset;
		reg reset_read_ct;

		always @* begin
		  case(cs_io)
		      IDLE:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct = 0;			
		              end
		   LOAD_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0001;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct  = 0;	
		              end
		   LOAD_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0010;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0100;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b1000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_EK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0001;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0010;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0100;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_EK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b1000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_READ_EK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b1000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   LOAD_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0001;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0010;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_3:   begin
		                 	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0100;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b1000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
           READ_DK_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0001;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0010;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0100;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_DK_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b1000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end  
		   END_READ_DK:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0100;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end  
		   LOAD_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00010;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00100;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b01000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b10000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_CT_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 1;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   LOAD_CT_L_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00001;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end 
           READ_CT_1:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00010;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_2:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00100;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_3:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b01000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   READ_CT_4:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b10000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_CT_L:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00001;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end 
		   END_READ_CT:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0010;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		  END_READ_CT_L:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0001;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		                  end
		   RESET_READ_CT: begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct	= 1;	
		                  end
		   LOAD_M_RESET:  begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 1;
							reset_read_ct   = 0;	
		              	end 
		   LOAD_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 1;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   READ_M:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 1;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end   
		   START_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   SEL_READ:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   LOAD_EK_REG:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   GMH:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		   END_OP:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;	
		              end
		 default:   begin
		                  	{read_ek_4, read_ek_3, read_ek_2, read_ek_1}         		= 4'b0000;
						  	{read_dk_4, read_dk_3, read_dk_2, read_dk_1}         		= 4'b0000;
						  	{read_ct_4, read_ct_3, read_ct_2, read_ct_1, read_ct_l} 	= 5'b00000;
							{load_ek_4, load_ek_3, load_ek_2, load_ek_1}         		= 4'b0000;
							{load_dk_4, load_dk_3, load_dk_2, load_dk_1}         		= 4'b0000;
							{load_ct_4, load_ct_3, load_ct_2, load_ct_1, load_ct_l} 	= 5'b00000;
							{end_read_ek_st, end_read_dk_st, end_read_ct_st, end_read_ct_l_st} 		= 4'b0000;
							read_m          = 0;
							load_m          = 0;
							load_ct_reset	= 0;
							load_m_reset	= 0;
							reset_read_ct   = 0;
		              end
		  endcase
		
		end
		
		

		
		// --- End & Counter signal --- //

		reg uad_0, uad_1, uad_2, uad_3; 
		always @(posedge clk) uad_0 <= upd_add_decoder;
		always @(posedge clk) uad_1 <= uad_0;
		always @(posedge clk) uad_2 <= uad_1;
		always @(posedge clk) uad_3 <= uad_2;

		reg [7:0] c_ek_1, c_ek_2, c_ek_3, c_ek_4;
		reg [7:0] c_dk_1, c_dk_2, c_dk_3, c_dk_4;
		reg [7:0] c_ct_1, c_ct_2, c_ct_3, c_ct_4, c_ct_l; 
		reg [7:0] c_m;
		reg [3:0] c_end_ek, c_end_dk, c_end_ct, c_end_ct_l;
		reg [3:0] c_reset_m;
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      end_ek_1 <= 1'b0;
		      end_ek_2 <= 1'b0;
		      end_ek_3 <= 1'b0;
		      end_ek_4 <= 1'b0;
		      
		      end_dk_1 <= 1'b0;
		      end_dk_2 <= 1'b0;
		      end_dk_3 <= 1'b0;
		      end_dk_4 <= 1'b0;
		      
		      end_ct_1 <= 1'b0;
		      end_ct_2 <= 1'b0;
		      end_ct_3 <= 1'b0;
		      end_ct_4 <= 1'b0;
		      end_ct_l <= 1'b0;
		      
		      end_m    <= 1'b0;  
		  	  end_reset_m <= 1'b0;
		      
		      end_read_ek <= 1'b0;
		      end_read_dk <= 1'b0; 
		      end_read_ct <= 1'b0;
		      end_read_ct_l <= 1'b0;

		  	  end_load_ek <= 1'b0;
			  end_load_dk <= 1'b0;
		  end
		  else begin
		              if(read_ek_int & c_ek_1 == 62)      end_ek_1 <= 1'b1;
		      else    if(load_ek_int & c_ek_1 == 64)      end_ek_1 <= 1'b1;
		      else    if(cs_io == END_LOAD_EK)            end_ek_1 <= end_ek_1;
		      else                                        end_ek_1 <= 1'b0;
		      
		              if(read_ek_int & c_ek_2 == 62)      end_ek_2 <= 1'b1;
		      else    if(load_ek_int & c_ek_2 == 64)      end_ek_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_2 <= end_ek_2;
		      else                                        end_ek_2 <= 1'b0;
		      
		              if(read_ek_int & c_ek_3 == 62)      end_ek_3 <= 1'b1;
		      else    if(load_ek_int & c_ek_3 == 64)      end_ek_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_3 <= end_ek_3;
		      else                                        end_ek_3 <= 1'b0;
		      
		              if(read_ek_int & c_ek_4 == 62)      end_ek_4 <= 1'b1;
		      else    if(load_ek_int & c_ek_4 == 64)      end_ek_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_EK)            end_ek_4 <= end_ek_4;
		      else                                        end_ek_4 <= 1'b0;
		      
		              if(read_dk_int & c_dk_1 == 62)      end_dk_1 <= 1'b1;
		      else    if(load_dk_int & c_dk_1 == 64)      end_dk_1 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_1 <= end_dk_1;
		      else                                        end_dk_1 <= 1'b0;
		      
		              if(read_dk_int & c_dk_2 == 62)      end_dk_2 <= 1'b1;
		      else    if(load_dk_int & c_dk_2 == 64)      end_dk_2 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_2 <= end_dk_2;
		      else                                        end_dk_2 <= 1'b0;
		      
		              if(read_dk_int & c_dk_3 == 62)      end_dk_3 <= 1'b1;
		      else    if(load_dk_int & c_dk_3 == 64)      end_dk_3 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_3 <= end_dk_3;
		      else                                        end_dk_3 <= 1'b0;
		      
		              if(read_dk_int & c_dk_4 == 62)      end_dk_4 <= 1'b1;
		      else    if(load_dk_int & c_dk_4 == 64)      end_dk_4 <= 1'b1;
			  else    if(cs_io == END_LOAD_DK)            end_dk_4 <= end_dk_4;
		      else                                        end_dk_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_1 == 62)      end_ct_1 <= 1'b1;
		      else    if(load_ct_int & c_ct_1 == 64)      end_ct_1 <= 1'b1;
		      else                                        end_ct_1 <= 1'b0;
		      
		              if(read_ct_int & c_ct_2 == 62)      end_ct_2 <= 1'b1;
		      else    if(load_ct_int & c_ct_2 == 64)      end_ct_2 <= 1'b1;
		      else                                        end_ct_2 <= 1'b0;
		      
		              if(read_ct_int & c_ct_3 == 62)      end_ct_3 <= 1'b1;
		      else    if(load_ct_int & c_ct_3 == 64)      end_ct_3 <= 1'b1;
		      else                                        end_ct_3 <= 1'b0;
		      
		              if(read_ct_int & c_ct_4 == 62)      end_ct_4 <= 1'b1;
		      else    if(load_ct_int & c_ct_4 == 64)      end_ct_4 <= 1'b1;
		      else                                        end_ct_4 <= 1'b0;
		      
		              if(read_ct_int & c_ct_l == 62)      end_ct_l <= 1'b1;
		      else    if(load_ct_int & c_ct_l == 64)      end_ct_l <= 1'b1;
		      else                                        end_ct_l <= 1'b0;
		      
		              if(read_m_int & c_m == 69)          end_m <= 1'b1;
		      else    if(load_m_int & c_m == 64)          end_m <= 1'b1;
		      else                                        end_m <= 1'b0;
		      
		      if(c_end_ek == 5)   end_read_ek <= 1'b1;
		      else                end_read_ek <= 1'b0;
		      
		      if(c_end_ek == 1)   end_load_ek <= 1'b1;
		      else                end_load_ek <= 1'b0;
		      
		      if(c_end_dk == 5)   end_read_dk <= 1'b1;
		      else                end_read_dk <= 1'b0;

			  if(c_end_dk == 1)   end_load_dk <= 1'b1;
		      else                end_load_dk <= 1'b0;
		      
		      if(k_4 & c_end_ct == 6)                 end_read_ct <= 1'b1; // Probably it depens on b
		      else if((k_2 | k_3) & c_end_ct == 7)    end_read_ct <= 1'b1; // Probably it depens on b
		      else                                    end_read_ct <= 1'b0;
		      
		      if(c_end_ct_l == 5) end_read_ct_l <= 1'b1;
		      else                end_read_ct_l <= 1'b0;

			  if(c_reset_m == 3)  end_reset_m <= 1'b1;
		      else                end_reset_m <= 1'b0;
		      
		  end
		end
		
		always @(posedge clk) begin
		  if(!rst | reset) begin
		      c_ek_1 <= 0;
		      c_ek_2 <= 0;
		      c_ek_3 <= 0;
		      c_ek_4 <= 0;
		      
		      c_dk_1 <= 0;
		      c_dk_2 <= 0;
		      c_dk_3 <= 0;
		      c_dk_4 <= 0;
		      
		      c_ct_1 <= 0;
		      c_ct_2 <= 0;
		      c_ct_3 <= 0;
		      c_ct_4 <= 0;
		      c_ct_l <= 0;
		      
		      c_m <= 0;
		      
		      c_end_ek    <= 0;
		      c_end_dk    <= 0;
		      c_end_ct    <= 0;
		      c_end_ct_l  <= 0;
		      c_reset_m   <= 0;
		  end
		  else begin
		      if(read_ek_1)                          c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & upd_add_decoder)   c_ek_1 <= c_ek_1 + 1;
		      else if(load_ek_1 & !upd_add_decoder)  c_ek_1 <= c_ek_1;
		      else                                   c_ek_1 <= 0;
		      
		      if(read_ek_2)                          c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & upd_add_decoder)   c_ek_2 <= c_ek_2 + 1;
		      else if(load_ek_2 & !upd_add_decoder)  c_ek_2 <= c_ek_2;
		      else                                   c_ek_2 <= 0;
		      
		      if(read_ek_3)                          c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & upd_add_decoder)   c_ek_3 <= c_ek_3 + 1;
		      else if(load_ek_3 & !upd_add_decoder)  c_ek_3 <= c_ek_3;
		      else                                   c_ek_3 <= 0;
		      
		      if(read_ek_4)                          c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & upd_add_decoder)   c_ek_4 <= c_ek_4 + 1;
		      else if(load_ek_4 & !upd_add_decoder)  c_ek_4 <= c_ek_4;
		      else                                   c_ek_4 <= 0;
		      
		      if(read_dk_1)                          c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & upd_add_decoder)   c_dk_1 <= c_dk_1 + 1;
		      else if(load_dk_1 & !upd_add_decoder)  c_dk_1 <= c_dk_1;
		      else                                   c_dk_1 <= 0;
		      
		      if(read_dk_2)                          c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & upd_add_decoder)   c_dk_2 <= c_dk_2 + 1;
		      else if(load_dk_2 & !upd_add_decoder)  c_dk_2 <= c_dk_2;
		      else                                   c_dk_2 <= 0;
		      
		      if(read_dk_3)                          c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & upd_add_decoder)   c_dk_3 <= c_dk_3 + 1;
		      else if(load_dk_3 & !upd_add_decoder)  c_dk_3 <= c_dk_3;
		      else                                   c_dk_3 <= 0;
		      
		      if(read_dk_4)                          c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & upd_add_decoder)   c_dk_4 <= c_dk_4 + 1;
		      else if(load_dk_4 & !upd_add_decoder)  c_dk_4 <= c_dk_4;
		      else                                   c_dk_4 <= 0;
		      
		      if(read_ct_1)                          c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & upd_add_decoder)   c_ct_1 <= c_ct_1 + 1;
		      else if(load_ct_1 & !upd_add_decoder)  c_ct_1 <= c_ct_1;
		      else                                   c_ct_1 <= 0;
		      
		      if(read_ct_2)                          c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & upd_add_decoder)   c_ct_2 <= c_ct_2 + 1;
		      else if(load_ct_2 & !upd_add_decoder)  c_ct_2 <= c_ct_2;
		      else                                   c_ct_2 <= 0;
		      
		      if(read_ct_3)                          c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & upd_add_decoder)   c_ct_3 <= c_ct_3 + 1;
		      else if(load_ct_3 & !upd_add_decoder)  c_ct_3 <= c_ct_3;
		      else                                   c_ct_3 <= 0;
		      
		      if(read_ct_4)                          c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & upd_add_decoder)   c_ct_4 <= c_ct_4 + 1;
		      else if(load_ct_4 & !upd_add_decoder)  c_ct_4 <= c_ct_4;
		      else                                   c_ct_4 <= 0;
		      
		      if(read_ct_l)                          c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & upd_add_decoder)   c_ct_l <= c_ct_l + 1;
		      else if(load_ct_l & !upd_add_decoder)  c_ct_l <= c_ct_l;
		      else                                   c_ct_l <= 0;
		      
		      if(read_m)                             c_m <= c_m + 1;
		      else if(load_m & upd_add_decoder)      c_m <= c_m + 1;
		      else if(load_m & !upd_add_decoder)     c_m <= c_m;
		      else                                   c_m <= 0;
		      
		      if(end_read_ek_st | cs_io == END_LOAD_EK)        	c_end_ek <= c_end_ek + 1;
		      else                              	            c_end_ek <= 0;
		      
		      if(end_read_dk_st | cs_io == END_LOAD_DK)        	c_end_dk <= c_end_dk + 1;
		      else                               				c_end_dk <= 0;
		      
		      if(end_read_ct_st)                    c_end_ct <= c_end_ct + 1;
		      else                               	c_end_ct <= 0;
		      
		      if(end_read_ct_l_st)                  c_end_ct_l <= c_end_ct_l + 1;
		      else                               	c_end_ct_l <= 0;

			  if(cs_io == LOAD_M_RESET)        		c_reset_m <= c_reset_m + 1;
		      else                              	c_reset_m <= 0;
		      
		  end
		
		
		end
		
		// --- Encoding / Decoding FOR MASKING --- //
		
		always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int | read_m_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_01_00; // ek[0] (RAM_0_2) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[1] (RAM_0_1)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_01; // ek[1] (RAM_0_1)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(end_read_dk_st) 	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // c[0]  (RAM_1_1) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // c[1]  (RAM_1_2)
		          else    if(end_read_ct_st) 	mode_encdec[7:0] = 8'b00_00_11_00; // c[1]  (RAM_1_2)
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_01_00; // cl    (RAM_0_2) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_01_00; // cl    (RAM_0_2)
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[0] (RAM_0_1) 
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // ek[1] (RAM_1_2)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_00_00_01; // ek[2] (RAM_0_1)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_01; // ek[2] (RAM_0_1)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1_1)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1_1)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_01_00; // ct[0] (RAM_0_2) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // ct[1] (RAM_1_2) 
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_00_01_00; // ct[2] (RAM_0_2) 
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b00_00_01_00; // ct[2] (RAM_0_2) 
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_11_00; // cl    (RAM_1_2) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_11_00; // cl    (RAM_1_2) 
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	mode_encdec[7:0] = 8'b00_00_11_00; // ek[0] (RAM_1_2)
		          else    if(read_ek_2)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[1] (RAM_1_1)
		          else    if(read_ek_3)      	mode_encdec[7:0] = 8'b00_00_11_00; // ek[2] (RAM_1_2)
		          else    if(read_ek_4)      	mode_encdec[7:0] = 8'b00_00_00_11; // ek[3] (RAM_1_1)
		          else    if(end_read_ek_st) 	mode_encdec[7:0] = 8'b00_00_00_11; // ek[3] (RAM_0)
		          else    if(read_dk_1)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[0] (RAM_1_1)
		          else    if(read_dk_2)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[1] (RAM_1_2)
		          else    if(read_dk_3)      	mode_encdec[7:0] = 8'b00_00_00_11; // dk[2] (RAM_1_1)
		          else    if(read_dk_4)      	mode_encdec[7:0] = 8'b00_00_11_00; // dk[3] (RAM_1_2)
		          else    if(end_read_dk_st)    mode_encdec[7:0] = 8'b00_00_11_00; // dk[3] (RAM_1_2)
		          else    if(read_ct_1)      	mode_encdec[7:0] = 8'b00_00_01_00; // ct[0] (RAM_0_2) 
		          else    if(read_ct_2)      	mode_encdec[7:0] = 8'b00_00_00_01; // ct[1] (RAM_0_1) 
		          else    if(read_ct_3)      	mode_encdec[7:0] = 8'b00_00_01_00; // ct[2] (RAM_0_2) 
		          else    if(read_ct_4)      	mode_encdec[7:0] = 8'b00_00_00_01; // ct[3] (RAM_0_1) 
		          else    if(end_read_ct_st)    mode_encdec[7:0] = 8'b00_00_00_01; // ct[3] (RAM_0_1) 
		          else    if(reset_read_ct)	 	mode_encdec[7:0] = 8'b00_00_00_01; // ct[3] (RAM_0_1) 
		          else    if(read_ct_l)      	mode_encdec[7:0] = 8'b00_00_11_00; // ctl   (RAM_1_2) 
		          else    if(end_read_ct_l_st)  mode_encdec[7:0] = 8'b00_00_11_00; // ctl   (RAM_1_2) 
		          else    if(read_m)         	mode_encdec[7:0] = 8'b00_00_00_11; // w     (RAM_1)
		          else                          mode_encdec[7:0] = 8'b00_00_00_00; // TO COMPLETE
		      end
		  end
		  else                                        mode_encdec[7:0] = 8'b00_00_00_00; 
		  
        end
        
        always @* begin
		  if(read_ek_int | read_dk_int | read_ct_int) begin
		      if(k_2) begin
		                  if(read_ek_1)      	offset = 0;      // ek[0] (RAM_0) 
		          else    if(read_ek_2)     	offset = 0;      // ek[1] (RAM_0)
		          else    if(end_read_ek_st) 	offset = 0;      // ek[1] (RAM_0)
		          else    if(read_dk_1)      	offset = 0;     // dk[0] (RAM_1)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_1)
		          else    if(end_read_dk_st)    offset = 0;     // dk[1] (RAM_1)
		          else    if(read_ct_1)      	offset = 0;   // c[0]  (RAM_1) 
		          else    if(read_ct_2)      	offset = 0;   // c[1]  (RAM_1) 
		          else    if(end_read_ct_st)    offset = 0;   // c[1]  (RAM_1) 
		          else    if(read_ct_l)      	offset = 896;   // cl    (RAM_1) 
		          else    if(end_read_ct_l_st)  offset = 896;   // cl    (RAM_1) 
		          else    if(read_m)         	offset = 0;   // w     (RAM_1) 
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else if(k_3) begin
		                  if(read_ek_1)      	offset = 0;     // ek[0] (RAM_1) 
		          else    if(read_ek_2)      	offset = 256;     // ek[1] (RAM_1)
		          else    if(read_ek_3)      	offset = 128;     // ek[2] (RAM_1)
		          else    if(end_read_ek_st) 	offset = 0;     // ek[2] (RAM_1)
		          else    if(read_dk_1)      	offset = 0;       // dk[0] (RAM_0)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_0)
		          else    if(read_dk_3)      	offset = 128;     // dk[2] (RAM_0)
		          else    if(end_read_dk_st)    offset = 128;     // dk[2] (RAM_0)
		          else    if(read_ct_1)      	offset = 0;     // ct[0] (RAM_1)  
		          else    if(read_ct_2)      	offset = 128;     // ct[1] (RAM_1)  
		          else    if(read_ct_3)      	offset = 512;     // ct[2] (RAM_1)  
		          else    if(end_read_ct_st)    offset = 512;     // ct[2] (RAM_1)  
		          else    if(read_ct_l)      	offset = 896;     // cl    (RAM_1)  
		          else    if(end_read_ct_l_st)  offset = 896;     // cl    (RAM_1)  
		          else    if(read_m)         	offset = 0;     // w     (RAM_1)
		          else                          offset = 0;     // TO COMPLETE
		      end
		      else begin // k_4
		                  if(read_ek_1)      	offset = 512;   // ek[0] (RAM_0)
		          else    if(read_ek_2)      	offset = 512;   // ek[1] (RAM_0)
		          else    if(read_ek_3)      	offset = 640;   // ek[2] (RAM_0)
		          else    if(read_ek_4)      	offset = 640;   // ek[3] (RAM_0)
		          else    if(end_read_ek_st) 	offset = 640;   // ek[3] (RAM_0)
		          else    if(read_dk_1)     	offset = 0;       // dk[0] (RAM_1)
		          else    if(read_dk_2)      	offset = 0;     // dk[1] (RAM_1)
		          else    if(read_dk_3)      	offset = 128;     // dk[2] (RAM_1)
		          else    if(read_dk_4)      	offset = 128;     // dk[3] (RAM_1)
		          else    if(end_read_dk_st)    offset = 128;     // dk[3] (RAM_1)
		          else    if(read_ct_1)      	offset = 0;     // ct[0] (RAM_1)   offset = 0
		          else    if(read_ct_2)      	offset = 0;     // ct[1] (RAM_1)   offset = 0
		          else    if(read_ct_3)      	offset = 128;     // ct[2] (RAM_1)   offset = 0
		          else    if(read_ct_4)      	offset = 128;     // ct[3] (RAM_1)   offset = 0
		          else    if(end_read_ct_st)    offset = 128;     // ct[3] (RAM_1)   offset = 0
		          else    if(reset_read_ct) 	offset = 128;   // ctl   (RAM_1)   offset = 384
		          else    if(read_ct_l)      	offset = 896;   // ctl   (RAM_1)   offset = 384
		          else    if(end_read_ct_l_st)  offset = 896;   // ctl   (RAM_1)   offset = 384
		          else    if(read_m)         	offset = 0;   // w     (RAM_1) 
		          else                          offset = 0;     // TO COMPLETE
		      end
		  end
		  else if(load_ek_int | load_dk_int | load_ct_int | load_m_int) begin
		      if(k_2) begin
		                  if(load_ek_1)      offset = 640;     
		          else    if(load_ek_2)      offset = 640;  
		          else    if(cs_io == END_LOAD_EK) offset = 640;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 512;     
		          else    if(load_ct_1)      offset = 0;   
		          else    if(load_ct_2)      offset = 0;   
		          else    if(load_ct_l)      offset = 896; 
		          else    if(load_m)         offset = 896;    
		          else                       offset = 0;     
		      end
		      else if(k_3) begin
		                  if(load_ek_1)      offset = 640;     
		          else    if(load_ek_2)      offset = 640;     
		          else    if(load_ek_3)      offset = 768; 
		          else    if(cs_io == END_LOAD_EK) offset = 768;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 512;     
		          else    if(load_dk_3)      offset = 640;     
		          else    if(load_ct_1)      offset = 0;     
		          else    if(load_ct_2)      offset = 0;     
		          else    if(load_ct_3)      offset = 128;     
		          else    if(load_ct_l)      offset = 896;  
		          else    if(load_m)         offset = 896;    
		          else                       offset = 0;     
		      end
		      else begin // k_4
		                  if(load_ek_1)      offset = 640;     
		          else    if(load_ek_2)      offset = 640;     
		          else    if(load_ek_3)      offset = 768;     
		          else    if(load_ek_4)      offset = 768;
		          else    if(cs_io == END_LOAD_EK) offset = 896;   
		          else    if(load_dk_1)      offset = 512;     
		          else    if(load_dk_2)      offset = 512;     
		          else    if(load_dk_3)      offset = 640;     
		          else    if(load_dk_4)      offset = 640;     
		          else    if(load_ct_1)      offset = 0;     
		          else    if(load_ct_2)      offset = 0;     
		          else    if(load_ct_3)      offset = 128;     
		          else    if(load_ct_4)      offset = 128;     
		          else    if(load_ct_l)      offset = 896;     
		          else    if(load_m)         offset = 896; 
		          else                       offset = 0;     
		      end
		  end
		  else                               offset = 0; 
		  
        end
        
		
		always @* begin
		  if(k_2 | k_3) begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h04; // dv: 4
		                              else    if(load_ct_int & !load_ct_l)        	mode_encdec[15:08] = 8'h0A; // du: 10
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		   end
		   else begin
		              if(gen_keys)                                                  mode_encdec[15:08] = 8'h0C; // 12
		      else    if(encap)   begin
		                                      if(load_ek_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(load_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(read_ct_int & read_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & end_read_ct_l_st)    mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(read_ct_int & !read_ct_l)        	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else    if(decap)   begin
		                                      if(load_dk_int)                       mode_encdec[15:08] = 8'h0C; // 12
		                              else    if(read_m_int)                        mode_encdec[15:08] = 8'h01; // 1
		                              else    if(load_ct_int & load_ct_l)        	mode_encdec[15:08] = 8'h05; // dv: 5
		                              else    if(load_ct_int & !load_ct_l)       	mode_encdec[15:08] = 8'h0B; // du: 11
		                              else                                          mode_encdec[15:08] = 8'h00;                                       
		                          end
		      else                                                                  mode_encdec[15:08] = 8'h00;
		  end
        end
		
		wire end_ek = end_ek_1 | end_ek_2 | end_ek_3 | end_ek_4 | (end_read_ek_st);		
		wire end_dk = end_dk_1 | end_dk_2 | end_dk_3 | end_dk_4 | (end_read_dk_st);
		wire end_ct = end_ct_1 | end_ct_2 | end_ct_3 | end_ct_4 | end_ct_l | (end_read_ct_st) | (end_read_ct_l_st) | (reset_read_ct);
		
		always @(posedge clk) begin
		  if(!rst | reset | cs_io == START_OP)                                                        add_ram_ini <= 0;
		  else begin
		           if(end_ek & load_ek_int & !end_load_ek)                                            add_ram_ini <= add_ram_ini;
			  else if(end_dk & load_dk_int & !end_load_dk)                                            add_ram_ini <= add_ram_ini;
			  else if(cs_io == LOAD_M_RESET)                                                          add_ram_ini <= 0;
		      else if(end_ek | end_dk | end_ct | end_m)                                               add_ram_ini <= 0; // offset
		      else if(read_ek_int | read_dk_int | read_ct_int | read_m_int)                           add_ram_ini <= add_ram_ini + 2;
		      else if((load_ek_int | load_dk_int | load_ct_int | load_m_int) & uad_1)	  		      add_ram_ini <= add_ram_ini + 2;
		      else                                                                                    add_ram_ini <= add_ram_ini;
		  end
		end

		
		localparam EK_512     = (800  - 32) / 8;
		localparam EK_768     = (1184 - 32) / 8;
		localparam EK_1024    = (1568 - 32) / 8;
		
		always @* begin
		  if(cs_io == LOAD_EK_REG) begin
		              if(k_2 & add_int == EK_512 - 1)     end_ek_reg = 1;
		      else    if(k_3 & add_int == EK_768 - 1)     end_ek_reg = 1;
		      else    if(k_4 & add_int == EK_1024 - 1)    end_ek_reg = 1;
		      else                                        end_ek_reg = 0;
		  end
		  else                                            end_ek_reg = 0;
		 		  
		end
		
		
		wire end_ek_add = end_read_ek;
		wire end_dk_add = end_read_dk;
		wire end_ct_add = end_read_ct_l;
		
		always @(posedge clk) begin
		  if(!rst | reset)                                                                    add_int <= 0;
		  else begin
		      if(end_ek_add | end_dk_add | end_ct_add | end_ek_reg)                           add_int <= 0;
		      else if(load_m_reset | load_ct_reset | cs_io == SEL_READ)     				  add_int <= 0;
		      else if(start_encoder & d_valid_enc)                                            add_int <= add_int + 1;
		      else if(start_decoder & d_ready_decoder)                                        add_int <= add_int + 1;
		      else if(load_ek_reg)                                                            add_int <= add_int + 1;
		      else                                                                            add_int <= add_int;
		  end
		end
    
    // --- CMOV
    assign en_w = load | (read_dk_int   | read_ek_int   | read_m_int | (read_ct_int & d_valid_enc & ~end_read_ct & !reset_read_ct)); // I need that for doing the cmov while reading ct
    
    always @(posedge clk)                               data_in_ram_cmov    <= data_in_ram;
    always @(posedge clk)                               d_valid_cmov        <= (reset_read_ct) ? 1'b0 : d_valid_enc & ~end_read_ct;
    always @(posedge clk) begin
        if(!rst)                                        cmov <= 1'b1;
        else begin
            if(cs_io == RESET_READ_CT)                  cmov <= cmov;
            else if(cmov & encap_decap & read_ct_int & d_valid_cmov) begin
                if(data_out_ram == data_in_ram_cmov)    cmov <= 1'b1;
                else                                    cmov <= 1'b0;
            end
            else                                        cmov <= cmov;
        end
    end
    
    
	// -- ek_in --
	
	reg  [4:0] add_w_ek;
	reg  [4:0] add_w_ek_p;
	always @(posedge clk) add_w_ek_p <= add_w_ek;
	
	reg load_ek_reg_reg;   always @(posedge clk) load_ek_reg_reg <= load_ek_reg;
	reg load_ek_r3;        always @(posedge clk) load_ek_r3 <= (gen_keys) ? load_ek_reg_reg : load_ek_reg;
	reg en_w_p; 
	always @(posedge clk) en_w_p <= (read_ek_int | load_ek_r3);
	
	reg [1087:0]   ek_in_reg;
	
	reg [4:0] sel;
	
	RAMD64_CR #(
    .COLS(17), // 1088
    .ROWS(1)
    ) EK_REG (
    .clk    (   clk                 ),
    .en_w   (   en_w_p              ),
    .add_w  (   add_w_ek_p          ),
    .add_r  (   sel                 ),
    .d_i     (   ek_in_reg           ),
    .d_o     (   ek_in               )
    );
	
	reg act_keccak;
	wire cond_load = (cs_io == START_OP & encap);
	always @(posedge clk) act_keccak <= (read_ek_int | read_dk_int | cond_load) ? start_keccak : 1'b0;
	wire upd_keccak;
	assign upd_keccak = (start_keccak && !act_keccak) ? 1'b1 : 1'b0 ;
	
	always @(posedge clk) begin
	   if(cs_io == IDLE) sel <= 0;
	   else if (read_ek_int | read_dk_int) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else if (cond_load) begin
	       if(upd_keccak & !last_hek)  sel <= sel + 1;
	       else                        sel <= sel; 
	   end
	   else sel <= sel;
	end
	
	wire op_reg = read_ek_int | load_ek_reg;
	
	reg [7:0] add_ek;
	always @(posedge clk) begin
	   if(!op_reg) begin 
	       add_ek      <= 0;
	       add_w_ek    <= 0;
	   end
	   else if (read_ek_int) begin 
	       if(add_ek == 16) begin
	         if(d_valid_enc) begin
                add_ek      <= 0;
                add_w_ek    <= add_w_ek + 1;
             end
             else begin
                add_ek      <= add_ek;
                add_w_ek    <= add_w_ek;
             end
	       end
	       else begin
               if(d_valid_enc) begin
                    add_ek      <= add_ek + 1;
                    add_w_ek    <= add_w_ek;
               end
               else begin
                    add_ek      <= add_ek;
                    add_w_ek    <= add_w_ek;
               end
           end
	   end
	   else if (load_ek_reg_reg) begin
	       if(add_ek == 16) begin
	           add_ek      <= 0;
               add_w_ek    <= add_w_ek + 1;
	       end
	       else begin
	           add_ek      <= add_ek + 1;
               add_w_ek    <= add_w_ek;
	       end
	   end
	
	end
	
	always @(posedge clk) begin 
	   if(cs_io == IDLE) begin
           ek_in_reg <= 0;
	   end
	   else begin
	       if(read_ek_int)             ek_in_reg[add_ek*64+:64] <= data_in_int;
	       else if(load_ek_reg_reg)    ek_in_reg[add_ek*64+:64] <= data_out_ram;
	       else                        ek_in_reg <= ek_in_reg;
	   end
	end 
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)                       start_hek <= 0;
	   else begin
	       if(add_ek[4] & d_valid_enc)         start_hek <= 1;
	       else if(load_ek_int)                start_hek <= 1;
	       else                                        start_hek <= start_hek;     
	   end 
	end
	
	always @(posedge clk) begin
	   if(cs_io == IDLE)               last_hek <= 0;
	   else begin
	       if(k_2 & sel == 5)          last_hek <= 1;
	       else if(k_3 & sel == 8)     last_hek <= 1;
	       else if(k_4 & sel == 11)    last_hek <= 1;
	       else                        last_hek <= last_hek;
	   end
	end


endmodule