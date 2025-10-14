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
            
        end
    endgenerate

    assign out_shares = data_out_ram;

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

