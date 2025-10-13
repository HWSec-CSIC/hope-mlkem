`timescale 1ns / 1ps

module GEN_SHARES #(
    parameter N_SHARES = 4,
    parameter WIDTH = 24,
    parameter SHUFF = 0
)(
    input clk,
    input rst,
    input rst_op,
    input enable_read,
    output  [WIDTH-1:0]             random_op,
    output  [N_SHARES*WIDTH-1:0]    random_shares
);
    
    wire [255:0] lfsr_out;
    wire rst_lfsr;
    wire enable_lfsr;
    
    lfsr256x32 lfsr256x32 (
        .clk        (   clk         ),
        .rst        (   rst_lfsr    ),
        .enable     (   enable_lfsr ),
        .lfsr_out   (   lfsr_out    )
    );
    
    reg [1599:0] in_keccak;
    always @(posedge clk) in_keccak <= {{32{8'h00}},8'h80,{134{8'h00}},8'h1F, lfsr_out}; // SHAKE_128

    wire load_k;
    wire start_k;
    wire read_k;
    wire end_op_k;
    wire [1599:0] out_keccak;
    
    keccak keccak (   
        .clk        (   clk         ), 
        .rst        (   rst         ), 
        .input_data (   in_keccak   ), 
        .load       (   load_k      ),
        .start      (   start_k     ),
        .read       (   read_k      ),
        .keccak_out (   out_keccak  ),
        .end_op     (   end_op_k    )
    );
    
    (* DONT_TOUCH = "TRUE" *)
    control_shares
    #(.SIZE_MEM(3096), .N_SHARES(N_SHARES), .WIDTH(WIDTH), .SHUFF(SHUFF))
    control_shares (
        .clk            (   clk             ),
        .rst            (   rst             ),
        .rst_op         (   rst_op          ),
        .enable_read    (   enable_read     ),
        .rst_lfsr       (   rst_lfsr        ),
        .enable_lfsr    (   enable_lfsr     ),
        .load_k         (   load_k          ),
        .start_k        (   start_k         ),
        .read_k         (   read_k          ),
        .end_op_k       (   end_op_k        ),
        .keccak_in      (   out_keccak      ),
        .out_shares     (   random_shares   ),
        .random_op      (   random_op       )
    );

endmodule


module control_shares #(
    parameter Q = 3329,
    parameter SIZE_MEM = 1024,
    parameter WIDTH = 24,
    parameter N_SHARES = 4,
    parameter SHUFF = 0
)(
    input                           clk,
    input                           rst,
    input                           rst_op,
    input                           enable_read,
    output reg                      rst_lfsr,
    output reg                      enable_lfsr,
    output reg                      load_k,
    output reg                      start_k,
    output reg                      read_k,
    input                           end_op_k,
    input   [1599:0]                keccak_in,
    output  [N_SHARES*WIDTH-1:0]    out_shares,
    output  reg [WIDTH-1:0]         random_op

);
    
    // rst = 0, poner a actuar el LFSR
    reg         read_mem;
    reg         mem_full;

    //--*** STATE declaration **--//
	localparam IDLE                = 4'h0; 
	localparam LOAD_KECCAK         = 4'h1;
	localparam START_KECCAK        = 4'h2;
	localparam IDLE_START          = 4'h3;
	localparam READ_KECCAK         = 4'h4; 
	localparam RESET_LFSR          = 4'h5; 
	
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
				    ns_h = LOAD_KECCAK;
				LOAD_KECCAK:
				    ns_h = START_KECCAK;
				START_KECCAK:
				    if(end_op_k)
				        ns_h = IDLE_START;
				    else
				        ns_h = START_KECCAK;
				IDLE_START:
				    if(read_mem | mem_full)
				        ns_h = IDLE_START;
				    else
				        ns_h = READ_KECCAK;
				READ_KECCAK:
				    if(mem_full)
				        ns_h = READ_KECCAK;
				    else
				        ns_h = START_KECCAK;
				default:
					    ns_h = IDLE;
			endcase 		
		end 
		
    always @* begin
        case(cs_h)
            IDLE:           begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            LOAD_KECCAK:    begin
                                load_k  = 1;
                                start_k = 0;
                                read_k  = 0;
                            end 
            START_KECCAK:   begin
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            IDLE_START:     begin
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            READ_KECCAK:    begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end 
            default:        begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end

        endcase
    end
    
    
    // --- LFSR seed generation --- //
        
    reg rst_shares;
    always @(posedge clk) begin
        if(!rst)    rst_shares <= 1'b1;
        else        rst_shares <= 1'b0;
    end
    
    reg rst_trig;
    always @(posedge clk) begin
        if(rst_shares & !rst_trig)  rst_lfsr <= 1'b1;
        else                        rst_lfsr <= 1'b0;
    end
    
    always @(posedge clk) begin
        if(!rst & rst_shares)  rst_trig <= 1'b1;
        else                   rst_trig <= 1'b0;
    end
    
    always @(posedge clk) begin
        if(rst | rst_lfsr | !rst_trig)      enable_lfsr <= 1'b0;
        else                                enable_lfsr <= 1'b1;
    end
    
    // --- GEN SHARES --- //
    
    reg [1599:0] FIFO_REG;
    reg fifo_empty; 
    reg [7:0] c_fifo;
    
    always @(posedge clk) begin
        if(!rst | rst_op)               FIFO_REG <= 0;
        else if(read_k)                 FIFO_REG <= keccak_in;
        else if(read_mem & !mem_full)   FIFO_REG <= FIFO_REG >> N_SHARES*WIDTH;
        else                            FIFO_REG <= FIFO_REG;
    end    
    
    always @(posedge clk) begin
        if(!rst | rst_op | mem_full)    read_mem <= 0;
        else if(read_k)                 read_mem <= 1;
        else if(fifo_empty)             read_mem <= 0;
        else                            read_mem <= read_mem;
    end  
    
    always @(posedge clk) begin
        if(!rst | rst_op)                                   fifo_empty <= 1;
        else if(read_k)                                     fifo_empty <= 0;
        else if(c_fifo == (1600/(N_SHARES*WIDTH))-2)        fifo_empty <= 1;
        else                                                fifo_empty <= fifo_empty;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op | fifo_empty)  c_fifo <= 0;
        else if(read_mem & !mem_full)   c_fifo <= c_fifo + 1;
        else                            c_fifo <= c_fifo;
    end 
    
    (* DONT_TOUCH = "TRUE" *) reg [15:0] addr_w;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] addr_r;
    (* DONT_TOUCH = "TRUE" *) wire [N_SHARES*WIDTH-1:0] data_in_ram;
    (* DONT_TOUCH = "TRUE" *) wire [N_SHARES*WIDTH-1:0] data_out_ram;
    (* DONT_TOUCH = "TRUE" *) reg en_w;

    genvar ram_i;
    generate
        for (ram_i = 0; ram_i < N_SHARES; ram_i = ram_i + 1) begin
            
            wire [WIDTH-1:0] fifo_out;
            wire [11:0] fifo_out_1;
            wire [11:0] fifo_out_2;

            RAM #(.SIZE(SIZE_MEM), .WIDTH(WIDTH)) RAM_SHARES
            (.clk       (   clk                                     ), 
            .en_write   (   en_w                                    ),     
            .en_read    (   1                                       ), 
            .addr_write (   addr_w                                  ),              
            .addr_read  (   addr_r                                        ), 
            .data_in    (   data_in_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH]    ),
            .data_out   (   data_out_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH]   )
            );

            assign fifo_out = FIFO_REG[(ram_i+1)*WIDTH-1:ram_i*WIDTH];
            assign fifo_out_1 = (fifo_out[11:00] < Q) ? fifo_out[11:00] : (fifo_out[11:00] - Q);
            assign fifo_out_2 = (fifo_out[23:12] < Q) ? fifo_out[23:12] : (fifo_out[23:12] - Q);

            assign data_in_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH] = {fifo_out_2, fifo_out_1};
        end
    endgenerate
    
    always @(posedge clk) begin
        if(!rst | rst_op)               mem_full <= 0;
        else if(addr_w == SIZE_MEM-2)   mem_full <= 1;
        else                            mem_full <= mem_full;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op)               en_w <= 1;
        else if(mem_full)               en_w <= 0;
        else                            en_w <= en_w;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op)               addr_w <= 0;
        else if(read_mem & !mem_full)   addr_w <= addr_w + 1;
        else                            addr_w <= addr_w;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op)               addr_r <= 0;
        else if(addr_r == SIZE_MEM - 1) addr_r <= 0;
        else if(enable_read)            addr_r <= addr_r + 1;
        else                            addr_r <= addr_r;
    end 
    
    reg [WIDTH-1:0] random_op_reg;
    reg store_random_op;
    always @(posedge clk) begin
        if(!rst | rst_op)               random_op_reg <= 0;
        else begin
            if(!store_random_op)        random_op_reg <= FIFO_REG[WIDTH-1:0];
            else                        random_op_reg <= random_op_reg;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | rst_op)               store_random_op <= 1'b0;
        else begin
            if(read_mem)                store_random_op <= 1'b1;
            else                        store_random_op <= store_random_op;
        end
    end
    
    generate 
        if(N_SHARES == 2) begin
            if(SHUFF) begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else begin
                        case(random_op_reg[0])
                        1'b0: random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0001, 4'b0000};
                        1'b1: random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0000, 4'b0001}; 
                        endcase
                    end
                end
            end 
            else begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else                            random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0001, 4'b0000};
                end
            end
        end
        else begin
            if(SHUFF) begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else begin
                        case(random_op_reg[1:0])
                        2'b00: random_op <= {8'h00, 4'b0011, 4'b0010, 4'b0001, 4'b0000};
                        2'b01: random_op <= {8'h00, 4'b0000, 4'b0011, 4'b0010, 4'b0001};
                        2'b10: random_op <= {8'h00, 4'b0001, 4'b0000, 4'b0011, 4'b0010};
                        2'b11: random_op <= {8'h00, 4'b0010, 4'b0001, 4'b0000, 4'b0011}; 
                        endcase
                    end
                end
            end 
            else begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else                            random_op <= {8'h00, 4'b0011, 4'b0010, 4'b0001, 4'b0000};
                end
            end
        end
    endgenerate
    
    assign out_shares = data_out_ram;
    // assign out_shares = {(N_SHARES){24'h000_000}};
   
endmodule


module lfsr32x32 #( 
    parameter [31:0] SEED = 32'h5A5A_A5A5 )(
    input           clk,
    input           rst,  
    input           enable,  
    output [31:0]   lfsr_out
    );
    
    genvar mod;
    generate
        for (mod = 0; mod < 32; mod = mod + 1) begin
            (* DONT_TOUCH = "TRUE" *)
            lfsr32 #(.SEED(SEED*mod + mod)) 
            lfsr32 (.clk(clk), .rst(rst), .enable(enable), .lfsr_out(lfsr_out[mod]));
        end
    endgenerate
endmodule

module lfsr256x32 #( 
    parameter [31:0] SEED = 32'h5A5A_A5A5 )(
    input           clk,
    input           rst,  
    input           enable,  
    output [255:0]  lfsr_out
    );
    
    genvar mod;
    generate
        for (mod = 0; mod < 256; mod = mod + 1) begin
            (* DONT_TOUCH = "TRUE" *)
            lfsr32 #(.SEED(SEED*mod + mod)) 
            lfsr32 (.clk(clk), .rst(rst), .enable(enable), .lfsr_out(lfsr_out[mod]));
        end
    endgenerate
endmodule

module lfsr1600x32 #( 
    parameter [31:0] SEED = 32'h5A5A_A5A5 )(
    input           clk,
    input           rst,  
    input           enable,  
    output [1599:0]  lfsr_out
    );
    
    genvar mod;
    generate
        for (mod = 0; mod < 1600; mod = mod + 1) begin
            (* DONT_TOUCH = "TRUE" *)
            lfsr32 #(.SEED(SEED*mod + mod)) 
            lfsr32 (.clk(clk), .rst(rst), .enable(enable), .lfsr_out(lfsr_out[mod]));
        end
    endgenerate
endmodule
 
module lfsr32 #(
    parameter [31:0] SEED = 32'h5A5A_A5A5
    )(
    input           clk,
    input           rst,  
    input           enable,  
    output          lfsr_out
);

    (* DONT_TOUCH = "TRUE" *) reg [31:0] lfsr_reg;

    // Polynomial: x^32 + x^22 + x^2 + x^1 + 1 (Taps at 32,22,2,1)
    (* DONT_TOUCH = "TRUE" *) wire feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always @(posedge clk) begin
        if (rst)            lfsr_reg <= SEED; 
        // if (rst)            lfsr_reg <= $random[31:0] | 32'h1; // Only for simulation purposes
        else if(enable)     lfsr_reg <= {lfsr_reg[30:0], feedback}; // Shift left and insert feedback
        else                lfsr_reg <= lfsr_reg;
    end

    assign lfsr_out = lfsr_reg[0];
endmodule


module GEN_SHARES_KECCAK_DOM #(
    parameter N_SHARES = 6,
    parameter WIDTH = 24,
    parameter SHUFF = 0
)(
    input clk,
    input rst,
    input rst_op,
    input enable_read,
    input keccak_flag,
    output  [WIDTH-1:0]             random_op,
    output  [N_SHARES*WIDTH-1:0]    random_shares,
    output [1599:0] rand_k_1,
    output [1599:0] rand_k_2,
    output [1599:0] rand_k_3,
    output [1599:0] rand_chi_1,  //  random
    output [1599:0] rand_chi_2,  //  random share 2
    output [1599:0] rand_chi_3,  //  random
    output [1599:0] rand_chi_4,  //  random share 4
    output [1599:0] rand_chi_5,  //  random
    output [1599:0] rand_chi_6   //  random share 6
);
    
    wire [1599:0] lfsr_out;
    wire [255:0] seed_lfsr;
    wire rst_lfsr;
    wire enable_lfsr;

    generate
    if(N_SHARES == 2) begin
        lfsr1600x32 lfsr1600x32 (
            .clk        (   clk         ),
            .rst        (   rst_lfsr    ),
            .enable     (   enable_lfsr ),
            .lfsr_out   (   lfsr_out    )
        );
    end
    else begin
        wire [31:0] lfsr_out_32;
        lfsr32x32 lfsr32x32 (
            .clk        (   clk         ),
            .rst        (   rst_lfsr    ),
            .enable     (   enable_lfsr ),
            .lfsr_out   (   lfsr_out_32 )
        );
        assign lfsr_out = {50{lfsr_out_32}};
    end  
    endgenerate

    
    reg [1599:0] in_keccak;
    always @(posedge clk) in_keccak <= {{32{8'h00}},8'h80,{134{8'h00}},8'h1F, seed_lfsr}; // SHAKE_128

    wire load_k;
    wire start_k;
    wire read_k;
    wire end_op_k;
    wire [1599:0] out_keccak;
    
    keccak keccak (   
        .clk        (   clk         ), 
        .rst        (   rst         ), 
        .input_data (   in_keccak   ), 
        .load       (   load_k      ),
        .start      (   start_k     ),
        .read       (   read_k      ),
        .keccak_out (   out_keccak  ),
        .end_op     (   end_op_k    )
    );
    
    (* DONT_TOUCH = "TRUE" *)
    control_shares_with_keccak_DOM
    #(.SIZE_MEM(3096), .N_SHARES(N_SHARES), .WIDTH(WIDTH), .SHUFF(SHUFF))
    control_shares_with_keccak_DOM (
        .clk            (   clk             ),
        .rst            (   rst             ),
        .rst_op         (   rst_op          ),
        .enable_read    (   enable_read     ),
        .rst_lfsr       (   rst_lfsr        ),
        .enable_lfsr    (   enable_lfsr     ),
        .lfsr_out       (   lfsr_out        ),  
        .seed_lfsr      (   seed_lfsr       ),
        .load_k         (   load_k          ),
        .start_k        (   start_k         ),
        .read_k         (   read_k          ),
        .end_op_k       (   end_op_k        ),
        .keccak_in      (   out_keccak      ),
        .out_shares     (   random_shares   ),
        .random_op      (   random_op       ),
        .keccak_flag    (   keccak_flag     ),
        .rand_k_1       (   rand_k_1       ),
        .rand_k_2       (   rand_k_2       ),
        .rand_k_3       (   rand_k_3       ),
        .rand_chi_1     (   rand_chi_1     ),  //  random share 1
        .rand_chi_2     (   rand_chi_2     ),  //  random share 2
        .rand_chi_3     (   rand_chi_3     ),  //  random share 3
        .rand_chi_4     (   rand_chi_4     ),  //  random share 4
        .rand_chi_5     (   rand_chi_5     ),  //  random share 5
        .rand_chi_6     (   rand_chi_6     )   //  random share 6
    );

endmodule

module control_shares_with_keccak_DOM #(
    parameter Q = 3329,
    parameter SIZE_MEM = 1024,
    parameter WIDTH = 24,
    parameter SHUFF = 0,
    parameter N_SHARES = 4
)(
    input                           clk,
    input                           rst,
    input                           rst_op,
    input                           enable_read,
    output reg                      rst_lfsr,
    output reg                      enable_lfsr,
    output reg                      load_k,
    output reg                      start_k,
    output reg                      read_k,
    input                           end_op_k,
    input   [1599:0]                keccak_in,
    output  [N_SHARES*WIDTH-1:0]    out_shares,
    output  reg [WIDTH-1:0]         random_op,
    input       [1599:0]             lfsr_out,
    output  reg [255:0]              seed_lfsr,
    input                           keccak_flag,

    output reg [1599:0] rand_k_1,
    output reg [1599:0] rand_k_2,
    output reg [1599:0] rand_k_3,
    output reg [1599:0] rand_chi_1,  //  random
    output reg [1599:0] rand_chi_2,  //  random share 2
    output reg [1599:0] rand_chi_3,  //  random
    output reg [1599:0] rand_chi_4,  //  random share 4
    output reg [1599:0] rand_chi_5,  //  random
    output reg [1599:0] rand_chi_6   //  random share 6

);

    reg [3:0] addr_rand_keccak;
    reg rand_keccak_done;
    
    // rst = 0, poner a actuar el LFSR
    reg         read_mem;
    reg         mem_full;

    //--*** STATE declaration **--//
	localparam IDLE                = 4'h0; 
	localparam LOAD_KECCAK         = 4'h1;
	localparam START_KECCAK        = 4'h2;
	localparam IDLE_START          = 4'h3;
	localparam READ_KECCAK         = 4'h4; 
	localparam RESET_LFSR          = 4'h5; 
    localparam READ_RAND_KECCAK    = 4'h6; // New state for reading random shares from keccak output
	
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
				    ns_h = LOAD_KECCAK;
				LOAD_KECCAK:
				    ns_h = START_KECCAK;
				START_KECCAK:
				    if(end_op_k & rand_keccak_done)
				        ns_h = IDLE_START;
                    else if(end_op_k & !rand_keccak_done)
                        ns_h = READ_RAND_KECCAK;
				    else
				        ns_h = START_KECCAK;
				IDLE_START:
				    if(read_mem)
				        ns_h = IDLE_START;
				    else
				        ns_h = READ_KECCAK;
				READ_KECCAK:
				    ns_h = START_KECCAK;
                READ_RAND_KECCAK:
                    ns_h = START_KECCAK;
				default:
					    ns_h = IDLE;
			endcase 		
		end 
		
    always @* begin
        case(cs_h)
            IDLE:           begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end 
            LOAD_KECCAK:    begin
                                load_k  = 1;
                                start_k = 0;
                                read_k  = 0;
                            end 
            START_KECCAK:   begin
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            IDLE_START:     begin
                                load_k  = 0;
                                start_k = 1;
                                read_k  = 0;
                            end 
            READ_KECCAK:    begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end 
            READ_RAND_KECCAK: begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 1;
                            end
            default:        begin
                                load_k  = 0;
                                start_k = 0;
                                read_k  = 0;
                            end

        endcase
    end
    
    
    // --- LFSR seed generation --- //
        
    reg rst_shares;
    always @(posedge clk) begin
        if(!rst)    rst_shares <= 1'b1;
        else        rst_shares <= 1'b0;
    end
    
    reg rst_trig;
    always @(posedge clk) begin
        if(rst_shares & !rst_trig)  rst_lfsr <= 1'b1;
        else                        rst_lfsr <= 1'b0;
    end
    
    always @(posedge clk) begin
        if(!rst & rst_shares)  rst_trig <= 1'b1;
        else                   rst_trig <= 1'b0;
    end
    
    always @(posedge clk) begin
        if(rst_lfsr)            enable_lfsr <= 1'b1;
        else                    enable_lfsr <= enable_lfsr;
    end
    
    always @(posedge clk) begin
        if(rst_trig)                      seed_lfsr <= lfsr_out[255:0];
        else                              seed_lfsr <= seed_lfsr;
    end
    // --- GEN SHARES --- //
    
    reg [1599:0] FIFO_REG;
    reg fifo_empty; 
    reg [7:0] c_fifo;
    
    always @(posedge clk) begin
        if(!rst | rst_op | !rand_keccak_done)       FIFO_REG <= 0;
        else if(read_k)                             FIFO_REG <= keccak_in;
        else if(read_mem & !mem_full)               FIFO_REG <= FIFO_REG >> N_SHARES*WIDTH;
        else                                        FIFO_REG <= FIFO_REG;
    end    
    
    always @(posedge clk) begin
        if(!rst | rst_op | mem_full | !rand_keccak_done)    read_mem <= 0;
        else if(read_k)                                     read_mem <= 1;
        else if(fifo_empty)                                 read_mem <= 0;
        else                                                read_mem <= read_mem;
    end  
    
    always @(posedge clk) begin
        if(!rst | rst_op | !rand_keccak_done)               fifo_empty <= 1;
        else if(read_k)                                     fifo_empty <= 0;
        else if(c_fifo == (1600/(N_SHARES*WIDTH))-2)        fifo_empty <= 1;
        else                                                fifo_empty <= fifo_empty;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op | fifo_empty | !rand_keccak_done)  c_fifo <= 0;
        else if(read_mem & !mem_full)                       c_fifo <= c_fifo + 1;
        else                                                c_fifo <= c_fifo;
    end 
    
    (* DONT_TOUCH = "TRUE" *) reg [15:0] addr_w;
    (* DONT_TOUCH = "TRUE" *) reg [15:0] addr_r;
    (* DONT_TOUCH = "TRUE" *) wire [N_SHARES*WIDTH-1:0] data_in_ram;
    (* DONT_TOUCH = "TRUE" *) wire [N_SHARES*WIDTH-1:0] data_out_ram;
    (* DONT_TOUCH = "TRUE" *) reg en_w;

    genvar ram_i;
    generate
        for (ram_i = 0; ram_i < N_SHARES; ram_i = ram_i + 1) begin
            
            wire [WIDTH-1:0] fifo_out;
            wire [11:0] fifo_out_1;
            wire [11:0] fifo_out_2;

            RAM #(.SIZE(SIZE_MEM), .WIDTH(WIDTH)) RAM_SHARES
            (.clk       (   clk                                     ), 
            .en_write   (   en_w                                    ),     
            .en_read    (   1                                       ), 
            .addr_write (   addr_w                                  ),              
            .addr_read  (   addr_r                                        ), 
            .data_in    (   data_in_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH]    ),
            .data_out   (   data_out_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH]   )
            );

            assign fifo_out = FIFO_REG[(ram_i+1)*WIDTH-1:ram_i*WIDTH];
            assign fifo_out_1 = (fifo_out[11:00] < Q) ? fifo_out[11:00] : (fifo_out[11:00] - Q);
            assign fifo_out_2 = (fifo_out[23:12] < Q) ? fifo_out[23:12] : (fifo_out[23:12] - Q);

            assign data_in_ram[(ram_i+1)*WIDTH-1:ram_i*WIDTH] = {fifo_out_2, fifo_out_1};
        end
    endgenerate
    
    always @(posedge clk) begin
        if(!rst | rst_op | !rand_keccak_done)               mem_full <= 0;
        else if(addr_w == SIZE_MEM-2)                       mem_full <= 1;
        else                                                mem_full <= mem_full;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op  | !rand_keccak_done)              en_w <= 1;
        else if(mem_full)                                   en_w <= 0;
        else                                                en_w <= en_w;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op  | !rand_keccak_done)              addr_w <= 0;
        else if(read_mem & !mem_full)                       addr_w <= addr_w + 1;
        else                                                addr_w <= addr_w;
    end 
    
    always @(posedge clk) begin
        if(!rst | rst_op  | !rand_keccak_done)              addr_r <= 0;
        else if(addr_r == SIZE_MEM - 1)                     addr_r <= 0;
        else if(enable_read)                                addr_r <= addr_r + 1;
        else                                                addr_r <= addr_r;
    end 
    
    reg [WIDTH-1:0] random_op_reg;
    reg store_random_op;
    always @(posedge clk) begin
        if(!rst | rst_op  | !rand_keccak_done)              random_op_reg <= 0;
        else begin
            if(!store_random_op)                            random_op_reg <= FIFO_REG[WIDTH-1:0];
            else                                            random_op_reg <= random_op_reg;
        end
    end
    
    always @(posedge clk) begin
        if(!rst | rst_op | !rand_keccak_done)               store_random_op <= 1'b0;
        else begin
            if(read_mem)                                    store_random_op <= 1'b1;
            else                                            store_random_op <= store_random_op;
        end
    end

    
    generate 
        if(N_SHARES == 2) begin
            if(SHUFF) begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else begin
                        case(random_op_reg[0])
                        1'b0: random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0001, 4'b0000};
                        1'b1: random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0000, 4'b0001}; 
                        endcase
                    end
                end
            end 
            else begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else                            random_op <= {8'h00, 4'b0000, 4'b0000, 4'b0001, 4'b0000};
                end
            end
        end
        else begin
            if(SHUFF) begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else begin
                        case(random_op_reg[1:0])
                        2'b00: random_op <= {8'h00, 4'b0011, 4'b0010, 4'b0001, 4'b0000};
                        2'b01: random_op <= {8'h00, 4'b0000, 4'b0011, 4'b0010, 4'b0001};
                        2'b10: random_op <= {8'h00, 4'b0001, 4'b0000, 4'b0011, 4'b0010};
                        2'b11: random_op <= {8'h00, 4'b0010, 4'b0001, 4'b0000, 4'b0011}; 
                        endcase
                    end
                end
            end 
            else begin
                always @(posedge clk) begin
                    if(!rst | rst_op)               random_op <= 0;
                    else                            random_op <= {8'h00, 4'b0011, 4'b0010, 4'b0001, 4'b0000};
                end
            end
        end
    endgenerate

    
    // --- GEN SHARES FROM KECCAK OUTPUT --- //

    // random keccak initialization
    always @(posedge clk) begin
        if(!rst | rst_op)                   addr_rand_keccak <= 0;
        else begin
            if(cs_h == READ_RAND_KECCAK)    addr_rand_keccak <= addr_rand_keccak + 1;
            else                            addr_rand_keccak <= addr_rand_keccak;
        end
    end

    generate 
        if(N_SHARES == 2) begin
            always @(posedge clk) begin
                if(!rst | rst_op)                   rand_keccak_done <= 1'b0;
                else begin
                    if(addr_rand_keccak == 4'h2)    rand_keccak_done <= 1'b1;
                    else                            rand_keccak_done <= rand_keccak_done;
                end
            end
        end
        else begin
            always @(posedge clk) begin
                if(!rst | rst_op)                   rand_keccak_done <= 1'b0;
                else begin
                    if(addr_rand_keccak == 4'h9)    rand_keccak_done <= 1'b1;
                    else                            rand_keccak_done <= rand_keccak_done;
                end
            end
        end
    endgenerate

    generate 
        if(N_SHARES == 2) begin
            localparam COLS = 25;   // (1600 / 64 = 25) * 2 SHARES = 50
            localparam ROWS = 2;    // 2^5 = 32 already 32

            reg [1599:0] keccak_s;

            wire [1600*(COLS/25)-1:0]    r_in;
            wire [1600*(COLS/25)-1:0]    r_out;
            reg  [5:0]                   add_w_rk;
            reg  [5:0]                   add_r_rk;

            assign r_in = keccak_s;

            // Store New Shares everytime SHAKE is ready

            always @(posedge clk) begin
                if(!rst | rst_op) begin
                    keccak_s <= 0;
                end 
                else if(read_k) begin
                    keccak_s <= keccak_in;
                end 
                else begin
                    keccak_s <= keccak_s;
                end
            end

            always @(posedge clk) begin
                if(!rst | rst_op)                   add_w_rk <= 0;
                else begin
                    if(read_k)                      add_w_rk <= add_w_rk + 1;
                    else                            add_w_rk <= add_w_rk;
                end
            end 

            // Read everytime is needed
            always @(posedge clk) begin
                if(!rst | rst_op)                   add_r_rk <= 0;
                else begin
                    if(keccak_flag)                 add_r_rk <= add_r_rk + 1;
                    else                            add_r_rk <= add_r_rk;
                end
            end 

            reg [3:0] sel_rand;
            always @(posedge clk) begin
                if(!rst | rst_op)               sel_rand <= 0;
                else if(read_k)                 sel_rand <= ~sel_rand;
                else                            sel_rand <= sel_rand;
            end 

            always @(posedge clk) begin
                if(!rst | rst_op) begin
                    rand_k_1 <= lfsr_out;
                    rand_k_2 <= lfsr_out;
                    rand_k_3 <= 0;
                    rand_chi_1 <= 0;
                    rand_chi_2 <= 0;
                    rand_chi_3 <= 0;
                    rand_chi_4 <= 0;
                    rand_chi_5 <= 0;
                    rand_chi_6 <= 0;
                end 
                else if(cs_h == READ_RAND_KECCAK) begin // random init
                    case(addr_rand_keccak)
                        4'h0: rand_k_1 <= keccak_in;
                        4'h1: rand_k_2 <= keccak_in;
                        default: ;
                    endcase
                end 
                else begin
                    if(keccak_flag) begin
                        if(!sel_rand[0]) begin
                            rand_k_1 <= rand_k_1 ^ r_out;
                            rand_k_2 <= rand_k_2 ^ lfsr_out; 
                        end
                        else begin
                            rand_k_1 <= rand_k_1 ^ lfsr_out;
                            rand_k_2 <= rand_k_2 ^ r_out; 
                        end                  
                    end
                    else begin
                        rand_k_1 <= rand_k_1;
                        rand_k_2 <= rand_k_2;
                    end        
                end
            end

            // Shares memory
            RAMD64_CR #(
            .COLS(COLS),    // 1600 / 64 = 25
            .ROWS(ROWS)     // 2^8 = 256
            ) SHARES_KECCAK_REG (
            .clk    (   clk             ),
            .en_w   (   read_k          ), // Store when read from keccak
            .add_w  (   add_w_rk        ),
            .add_r  (   add_r_rk        ),
            .d_i     (   r_in           ),
            .d_o     (   r_out          )
            );

        end
        else begin

            always @(posedge clk) begin
                if(!rst | rst_op) begin
                    rand_k_1    <= 0;
                    rand_k_2    <= 0;
                    rand_k_3    <= 0;
                    rand_chi_1  <= 0;
                    rand_chi_2  <= 0;
                    rand_chi_3  <= 0;
                    rand_chi_4  <= 0;
                    rand_chi_5  <= 0;
                    rand_chi_6  <= 0;
                end
                else begin
                    rand_k_1   <= keccak_in; // new value every cycle
                    rand_k_2   <= rand_k_1;
                    rand_k_3   <= rand_k_2;
                    rand_chi_1 <= rand_k_3;
                    rand_chi_2 <= rand_chi_1;
                    rand_chi_3 <= rand_chi_2;
                    rand_chi_4 <= rand_chi_3;
                    rand_chi_5 <= rand_chi_4;
                    rand_chi_6 <= rand_chi_5;  
                end
            end

            /*

            localparam N_RAMS = 25*9; // (1600 / 64 = 25) * 9 SHARES = 225
            localparam SIZE_MEM_S = 1024; // 2^5 = 32
            
            wire [1600*(N_RAMS/25)-1:0]     r_in;
            wire [1600*(N_RAMS/25)-1:0]     r_out;
            reg  [9:0]                      add_w_rk;
            reg  [9:0]                      add_r_rk;
            
            
            wire    [1600*(2)-1:0]      keccak_out;
            
            reg [1599:0] s1, s2, s3, s4, s5, s6, s7, s8, s9;
            assign r_in = {s1, s2, s3, s4, s5, s6, s7, s8, s9};
            
            reg [1:0] sel_s;
            always @(posedge clk) begin
                if(!rst) sel_s <= 0;
                else if(read_k & sel_s == 2'b10)    sel_s <= 0;
                else if(read_k)                     sel_s <= sel_s + 1;
                else                                sel_s <= sel_s;
            end
            
            reg read_k_clk;
            always @(posedge clk) read_k_clk <= read_k;
            
            always @(posedge clk) begin
                if(!rst) begin
                    s1 <= 0;
                    s2 <= 0;
                    s3 <= 0;
                    s4 <= 0;
                    s5 <= 0;
                    s6 <= 0;
                    s7 <= 0;
                    s8 <= 0;
                    s9 <= 0;
                end
                else if(read_k) begin
                    if(sel_s == 2'b00) begin
                        s1 <= keccak_in;
                        s2 <= keccak_out[1600*1-1:1600*0];
                        s3 <= keccak_out[1600*2-1:1600*1];
                        s4 <= s4;
                        s5 <= s5;
                        s6 <= s6;
                        s7 <= s7;
                        s8 <= s8;
                        s9 <= s9;
                    end
                    else if(sel_s == 2'b01) begin
                        s1 <= s1;
                        s2 <= s2;
                        s3 <= s3;
                        s4 <= keccak_in;                  
                        s5 <= keccak_out[1600*1-1:1600*0];
                        s6 <= keccak_out[1600*2-1:1600*1];
                        s7 <= s7;
                        s8 <= s8;
                        s9 <= s9;
                    end
                    else begin
                        s1 <= s1;
                        s2 <= s2;
                        s3 <= s3;
                        s4 <= s4;
                        s5 <= s5;
                        s6 <= s6;
                        s7 <= keccak_in;                  
                        s8 <= keccak_out[1600*1-1:1600*0];
                        s9 <= keccak_out[1600*2-1:1600*1];
                    end
                end
                else begin
                    s1 <= s1;
                    s2 <= s2;
                    s3 <= s3;
                    s4 <= s4;
                    s5 <= s5;
                    s6 <= s6;
                    s7 <= s7;
                    s8 <= s8;
                    s9 <= s9;
                end
            
            
            end
            // Store New Shares everytime SHAKE is ready

            always @(posedge clk) begin
                if(!rst | rst_op)                   add_w_rk <= 0;
                else begin
                    if(read_k & sel_s == 2'b10)     add_w_rk <= add_w_rk + 1;
                    else                            add_w_rk <= add_w_rk;
                end
            end 

            always @(posedge clk) begin
                if(!rst | rst_op)                   add_r_rk <= 1024-1;
                else begin
                    if(keccak_flag)                 add_r_rk <= add_r_rk + 1;
                    else                            add_r_rk <= add_r_rk;
                end
            end 
            
            always @(posedge clk) begin
                if(!rst | rst_op) begin
                    rand_k_1 <= 0;
                    rand_k_2 <= 0;
                    rand_k_3 <= 0;
                    rand_chi_1 <= 0;
                    rand_chi_2 <= 0;
                    rand_chi_3 <= 0;
                    rand_chi_4 <= 0;
                    rand_chi_5 <= 0;
                    rand_chi_6 <= 0;
                end 
                else if(cs_h == READ_RAND_KECCAK) begin
                    case(addr_rand_keccak)
                        4'h0: rand_k_1 <= keccak_in;
                        4'h1: rand_k_2 <= keccak_in;
                        4'h2: rand_k_3 <= keccak_in;
                        4'h3: rand_chi_1 <= keccak_in;
                        4'h4: rand_chi_2 <= keccak_in;
                        4'h5: rand_chi_3 <= keccak_in;
                        4'h6: rand_chi_4 <= keccak_in;
                        4'h7: rand_chi_5 <= keccak_in;
                        4'h8: rand_chi_6 <= keccak_in;
                        default: ;
                    endcase
                end 
                else begin
                    rand_k_1 <=     rand_k_1 ^ r_out[1600*1-1:1600*0];
                    rand_k_2 <=     rand_k_2 ^ r_out[1600*2-1:1600*1];
                    rand_k_3 <=     rand_k_3 ^ r_out[1600*3-1:1600*2];
                    rand_chi_1 <=   rand_chi_1 ^ r_out[1600*4-1:1600*3];
                    rand_chi_2 <=   rand_chi_2 ^ r_out[1600*5-1:1600*4];
                    rand_chi_3 <=   rand_chi_3 ^ r_out[1600*6-1:1600*5];
                    rand_chi_4 <=   rand_chi_4 ^ r_out[1600*7-1:1600*6];
                    rand_chi_5 <=   rand_chi_5 ^ r_out[1600*8-1:1600*7];
                    rand_chi_6 <=   rand_chi_6 ^ r_out[1600*9-1:1600*8];
                end
            end
            
            always @(posedge clk) begin
                if(!rst | rst_op) begin
                    rand_k_1 <= 0;
                    rand_k_2 <= 0;
                    rand_k_3 <= 0;
                    rand_chi_1 <= 0;
                    rand_chi_2 <= 0;
                    rand_chi_3 <= 0;
                    rand_chi_4 <= 0;
                    rand_chi_5 <= 0;
                    rand_chi_6 <= 0;
                end else if(cs_h == READ_RAND_KECCAK) begin
                    case(addr_rand_keccak)
                        4'h0: rand_k_1 <= keccak_in;
                        4'h1: rand_k_2 <= keccak_in;
                        4'h2: rand_k_3 <= keccak_in;
                        4'h3: rand_chi_1 <= keccak_in;
                        4'h4: rand_chi_2 <= keccak_in;
                        4'h5: rand_chi_3 <= keccak_in;
                        4'h6: rand_chi_4 <= keccak_in;
                        4'h7: rand_chi_5 <= keccak_in;
                        4'h8: rand_chi_6 <= keccak_in;
                        default: ;
                    endcase
                end 
                else begin
                    if(keccak_flag) begin
                        rand_k_1 <=     r_out[1600*1-1:1600*0];
                        rand_k_2 <=     r_out[1600*2-1:1600*1];
                        rand_k_3 <=     r_out[1600*3-1:1600*2];
                        rand_chi_1 <=   r_out[1600*4-1:1600*3];
                        rand_chi_2 <=   r_out[1600*5-1:1600*4];
                        rand_chi_3 <=   r_out[1600*6-1:1600*5];
                        rand_chi_4 <=   r_out[1600*7-1:1600*6];
                        rand_chi_5 <=   r_out[1600*8-1:1600*7];
                        rand_chi_6 <=   r_out[1600*9-1:1600*8];
                       
                        if(read_k)  rand_k_1 <= rand_k_1 ^ {8{keccak_in[200*1-1:200*0]}};
                        else        rand_k_1 <= rand_k_1 ^ {2{r_out[800*1-1:800*0]}};
                        
                        if(read_k)  rand_k_2 <= rand_k_2 ^ {8{keccak_in[200*2-1:200*1]}};
                        else        rand_k_2 <= rand_k_2 ^ {2{r_out[800*2-1:800*1]}};
                        
                        if(read_k)  rand_k_3 <= rand_k_3 ^ {8{keccak_in[200*3-1:200*2]}};
                        else        rand_k_3 <= rand_k_3 ^ {2{r_out[800*3-1:800*2]}};
                        
                        if(read_k)  rand_chi_1 <= rand_chi_1 ^ {8{keccak_in[200*4-1:200*3]}};
                        else        rand_chi_1 <= rand_chi_1 ^ {2{r_out[800*4-1:800*3]}};
                        
                        if(read_k)  rand_chi_2 <= rand_chi_2 ^ {8{keccak_in[200*5-1:200*4]}};
                        else        rand_chi_2 <= rand_chi_2 ^ {2{r_out[800*5-1:800*4]}};
                        
                        if(read_k)  rand_chi_3 <= rand_chi_3 ^ {8{keccak_in[200*6-1:200*5]}};
                        else        rand_chi_3 <= rand_chi_3 ^ {2{r_out[800*6-1:800*5]}};
                        
                        if(read_k)  rand_chi_4 <= rand_chi_4 ^ {8{keccak_in[200*7-1:200*6]}};
                        else        rand_chi_4 <= rand_chi_4 ^ {2{r_out[800*7-1:800*6]}};
                        
                        if(read_k)  rand_chi_5 <= rand_chi_5 ^ {8{keccak_in[200*8-1:200*7]}};
                        else        rand_chi_5 <= rand_chi_5 ^ {2{r_out[800*8-1:800*7]}};
                        
                        if(read_k)  rand_chi_6 <= rand_chi_6 ^ {8{keccak_in[49:00], keccak_in[849:800], keccak_in[1549:1500], keccak_in[349:300]}};      
                        else        rand_chi_6 <= rand_chi_6 ^ {2{r_out[800*9-1:800*8]}};

                        rand_k_1    <= rand_k_1     ^ rotate_right(r_out, 000)      ^ rotate_left(lfsr_out, 000) ;
                        rand_k_2    <= rand_k_2     ^ rotate_right(r_out, 150)      ^ rotate_left(lfsr_out, 150) ;
                        rand_k_3    <= rand_k_3     ^ rotate_right(r_out, 300)      ^ rotate_left(lfsr_out, 300) ;
                        rand_chi_1  <= rand_chi_1   ^ rotate_right(r_out, 450)      ^ rotate_left(lfsr_out, 450) ;
                        rand_chi_2  <= rand_chi_2   ^ rotate_right(r_out, 600)      ^ rotate_left(lfsr_out, 600) ;
                        rand_chi_3  <= rand_chi_3   ^ rotate_right(r_out, 750)      ^ rotate_left(lfsr_out, 750) ;
                        rand_chi_4  <= rand_chi_4   ^ rotate_right(r_out, 900)      ^ rotate_left(lfsr_out, 900) ;
                        rand_chi_5  <= rand_chi_5   ^ rotate_right(r_out, 1050)     ^ rotate_left(lfsr_out, 1050);
                        rand_chi_6  <= rand_chi_6   ^ rotate_right(r_out, 1200)     ^ rotate_left(lfsr_out, 1200);

                        if(sel_rand == 4'b0000) rand_k_1 <= rand_k_1 ^ r_out;
                        else                    rand_k_1 <= rand_k_1 ^ {8{lfsr_out[200*1-1:200*0]}};
                        
                        if(sel_rand == 4'b0001) rand_k_2 <= rand_k_2 ^ r_out;
                        else                    rand_k_2 <= rand_k_2 ^ {8{lfsr_out[200*2-1:200*1]}};
                        
                        if(sel_rand == 4'b0010) rand_k_3 <= rand_k_3 ^ r_out;
                        else                    rand_k_3 <= rand_k_3 ^ {8{lfsr_out[200*3-1:200*2]}};
                        
                        if(sel_rand == 4'b0011) rand_chi_1 <= rand_chi_1 ^ r_out;
                        else                    rand_chi_1 <= rand_chi_1 ^ {8{lfsr_out[200*4-1:200*3]}};
                        
                        if(sel_rand == 4'b0100) rand_chi_2 <= rand_chi_2 ^ r_out;
                        else                    rand_chi_2 <= rand_chi_2 ^ {8{lfsr_out[200*5-1:200*4]}};
                        
                        if(sel_rand == 4'b0101) rand_chi_3 <= rand_chi_3 ^ r_out;
                        else                    rand_chi_3 <= rand_chi_3 ^ {8{lfsr_out[200*6-1:200*5]}};
                        
                        if(sel_rand == 4'b0110) rand_chi_4 <= rand_chi_4 ^ r_out;
                        else                    rand_chi_4 <= rand_chi_4 ^ {8{lfsr_out[200*7-1:200*6]}};
                        
                        if(sel_rand == 4'b0111) rand_chi_5 <= rand_chi_5 ^ r_out;
                        else                    rand_chi_5 <= rand_chi_5 ^ {8{lfsr_out[200*8-1:200*7]}};
                        
                        if(sel_rand == 4'b1000) rand_chi_6 <= rand_chi_6 ^ r_out;
                        else                    rand_chi_6 <= rand_chi_6 ^ {8{lfsr_out[49:00], lfsr_out[849:800], lfsr_out[1549:1500], lfsr_out[349:300]}};      
                                 
                    end
                    else begin
                        rand_k_1 <= rand_k_1;
                        rand_k_2 <= rand_k_2;
                        rand_k_3 <= rand_k_3;
                        rand_chi_1 <= rand_chi_1;
                        rand_chi_2 <= rand_chi_2;
                        rand_chi_3 <= rand_chi_3;
                        rand_chi_4 <= rand_chi_4;
                        rand_chi_5 <= rand_chi_5;
                        rand_chi_6 <= rand_chi_6;
                    end        
                end
                
            end
            
            // Shares memory
            genvar ram_s;
            for (ram_s = 0; ram_s < N_RAMS; ram_s = ram_s + 1) begin

                RAMB36E11024x64 #(.SIZE(SIZE_MEM_S), .WIDTH(64)) RAM_KECCAK_SHARES
                (.clk       (   clk                                    ), 
                .en_write   (   read_k_clk                             ),     
                .en_read    (   1                                      ), 
                .addr_write (   add_w_rk                               ),              
                .addr_read  (   add_r_rk                               ), 
                .data_in    (   r_in[(ram_s+1)*64-1:ram_s*64]           ),
                .data_out   (   r_out[(ram_s+1)*64-1:ram_s*64]          )
                );
            end
            
            // Shares Keccak
            genvar ks;
            for (ks = 0; ks < 2; ks = ks + 1) begin
                
                wire [1599:0] in_seed;

                keccak keccak_shares (   
                .clk        (   clk             ), 
                .rst        (   rst             ), 
                .input_data (   in_seed         ), 
                .load       (   load_k          ),
                .start      (   start_k         ),
                .read       (   read_k                              ),
                .keccak_out (   keccak_out[1600*(ks+1)-1:1600*ks]   ),
                .end_op     (                                       )
                );
                
                assign in_seed = {{32{8'h00}},8'h80,{134{8'h00}},8'h1F, (seed_lfsr >> ks)};
                
            end
            
            */
            
        end
    endgenerate

    assign out_shares = data_out_ram;
    // assign out_shares = {(N_SHARES){24'h000_000}};

    function [1599:0] rotate_left;
        input [1599:0] in;
        input integer bits;
        integer i;
        begin
            for (i = 0; i < 1600; i = i + 1) begin
                rotate_left[i] = in[(i + bits) % 1600];
            end
        end
    endfunction

    function [1599:0] rotate_right;
        input [1599:0] in;
        input integer bits;
        integer i;
        begin
            for (i = 0; i < 1600; i = i + 1) begin
                rotate_right[i] = in[(i - bits + 1600) % 1600];
            end
        end
    endfunction
   
endmodule

