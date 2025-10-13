`timescale 1ns / 1ps

// 3 CYCLES DECODER_DECOMPRESS
module DECODER_DECOMPRESS_4 (
    input                           clk,
    input                           rst,
    input           [63:0]          input_data,
    input                           start_decod,
    input           [15:0]          mode,
    input                           d_valid,
    output reg                      d_ready,
    output reg                      upd_add,
    output          [2*24-1:0]      out_data
    );
    
    wire [07:00] mode_decoder;
    wire [07:00] mode_decompress;
    
    assign mode_decoder     = mode[07:00];
    assign mode_decompress  = mode[15:08];
    
    wire [3:0] b;
    assign b = mode_decompress[3:0];
    
    
    //--*** STATE declaration **--//
	localparam IDLE            = 4'h0;
	localparam WAIT_NEXT       = 4'h1;
	localparam LOAD_NEXT       = 4'h2; 
	localparam OPERATE         = 4'h3;
	localparam LOAD_MEM        = 4'h4;
	localparam LOAD_MEM_POS    = 4'h5;
	localparam SAVE_DATA       = 4'h6;
	localparam UPDATE_POS      = 4'h7;
    
    //--*** STATE register **--//
	reg [3:0] cs; // current_state
	reg [3:0] ns; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | !start_decod)     cs <= IDLE;
			else                         cs <= ns;
		end
    
    reg end_read;
    
    reg [7:0] counter_op;
    always @(posedge clk) begin
        if(!rst | !start_decod)     counter_op <= 0;
        else begin
            if(b == 4'b1010 | b == 4'b1011 | b == 4'b0101) begin
                if(end_read)                        counter_op <= 0;
                else if(cs == OPERATE)              counter_op <= counter_op + 1;
                else                                counter_op <= counter_op;
            end
            else begin
                if(end_read)                        counter_op <= 0;
                else if(cs == OPERATE)              counter_op <= counter_op + 1;
                else                                counter_op <= counter_op;
            end
        end    
    end
    
    
    always @* begin
			case (cs)
				IDLE:
				   if (start_decod)
				     ns = WAIT_NEXT;
				   else
				     ns = IDLE;
			    WAIT_NEXT:
			       if (d_ready & d_valid)
			         ns = LOAD_NEXT;
			       else
			         ns = WAIT_NEXT;
			    LOAD_NEXT:
			         ns = SAVE_DATA;
			    SAVE_DATA:
			         ns = OPERATE;
			    OPERATE:
			       if (!end_read)
			         ns = LOAD_MEM;
			       else if ((b == 4'b1010 | b == 4'b0100 | b == 4'b1011 | b == 4'b0101) & end_read)
			         ns = UPDATE_POS;  
			       else if (b != 4'b1010 & end_read)
			         ns = LOAD_MEM_POS;
			       else if (end_read)
			         ns = UPDATE_POS;
			       else
			         ns = OPERATE;
			    LOAD_MEM:
			      if(end_read)
			         ns = UPDATE_POS;
			      else
			         ns = OPERATE;
			    LOAD_MEM_POS:
			         ns = UPDATE_POS;
			    UPDATE_POS:
			         ns = WAIT_NEXT;
				default:
					 ns = IDLE;
			endcase 		
		end 
    
    reg [63:0] register_in;
    always @(posedge clk) begin
            if(!rst | !start_decod)     register_in <= 0;
            else begin
                if(cs == LOAD_NEXT)     register_in <= input_data;
                else                    register_in <= register_in;
            end
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod | d_ready)                   d_ready <= 1'b0;
        else begin
            if(cs == WAIT_NEXT)                             d_ready <= 1'b1;
            else                                            d_ready <= 1'b0;
        end
    end
    
    reg [3:0] pos;
    
    always @(posedge clk) begin
        if(!rst | !start_decod)                     pos <= 0;
        else begin
            if(cs == UPDATE_POS) begin
                        if(b == 4'b0001)                pos <= 0;   // b = 1
                else    if(b == 4'b0100)                pos <= 0;   // b = 4       
                else    if(b == 4'b0101 & pos == 4)     pos <= 0;   // b = 5      
                else    if(b == 4'b1010 & pos == 4)     pos <= 0;   // b = 10
                else    if(b == 4'b1011 & pos == 10)    pos <= 0;   // b = 11
                else    if(b == 4'b1100 & pos == 2)     pos <= 0;   // b = 12
                else                                    pos <= pos + 1;
            end                 
            else                                    pos <= pos;
        end 
    end
    
    reg [109:00] FIFO_REG;
    
    reg [7:0] b_desp;
    always @* begin   
        case(b)
        4'b0001: b_desp = 4; // 1 -> 4
        4'b0100: b_desp = 16; // 4 -> 16
        4'b0101: b_desp = 20; // 5 -> 20
        4'b1010: b_desp = 40; // 10 -> 40
        4'b1011: b_desp = 44; // 11 -> 44
        4'b1100: b_desp = 48; // 12 -> 48
        default: b_desp = 4;
        endcase
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod) FIFO_REG <= 0;
        else begin
            if(cs == SAVE_DATA) begin
                case(b)
                    4'b0001: FIFO_REG <= {46'h0000, register_in};
                    4'b0100: FIFO_REG <= {46'h0000, register_in};
                    4'b0101:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{46{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{42{1'b0}}, register_in, FIFO_REG[03:0]}; // 68 -- 64 % 20 = 4
                                        4'b0010: FIFO_REG <= {{38{1'b0}}, register_in, FIFO_REG[07:0]}; // 72 -- 68 % 20 = 8
                                        4'b0011: FIFO_REG <= {{34{1'b0}}, register_in, FIFO_REG[11:0]}; // 76 -- 72 % 20 = 12
                                        4'b0100: FIFO_REG <= {{30{1'b0}}, register_in, FIFO_REG[15:0]};             // 80 -- 76 % 20 = 16
                                        default: FIFO_REG <= {{46{1'b0}}, register_in}; // 64
                                    endcase
                                end
                    4'b1010:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{46{1'b0}}, register_in};                     // 64
                                        4'b0001: FIFO_REG <= {{32{1'b0}}, register_in, FIFO_REG[23:0]};     // 88 -- 64 % 40 = 24
                                        4'b0010: FIFO_REG <= {{38{1'b0}}, register_in, FIFO_REG[7:0]};      // 72 -- 88 % 40 = 8
                                        4'b0011: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[31:0]};     // 96 -- 72 % 40 = 32
                                        4'b0100: FIFO_REG <= {{30{1'b0}}, register_in, FIFO_REG[15:0]};     // 80 -- 96 % 40 = 16
                                        default: FIFO_REG <= {{26{1'b0}}, register_in};                     // 64
                                    endcase
                                end
                    4'b1011:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{46{1'b0}}, register_in};                     // 64
                                        4'b0001: FIFO_REG <= {{26{1'b0}}, register_in, FIFO_REG[19:0]};     // 84 -- 64 % 44 = 20
                                        4'b0010: FIFO_REG <= {{06{1'b0}}, register_in, FIFO_REG[39:0]};     // 104 -- 84 % 44 = 40
                                        4'b0011: FIFO_REG <= {{30{1'b0}}, register_in, FIFO_REG[15:0]};     // 80 -- 104 % 44 = 16
                                        4'b0100: FIFO_REG <= {{10{1'b0}}, register_in, FIFO_REG[35:0]};     // 100 -- 80 % 44 = 36
                                        4'b0101: FIFO_REG <= {{34{1'b0}}, register_in, FIFO_REG[11:0]};     // 76 -- 100 % 44 = 12
                                        4'b0110: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[31:0]};     // 96 -- 76 % 44 = 32
                                        4'b0111: FIFO_REG <= {{38{1'b0}}, register_in, FIFO_REG[07:0]};     // 72 -- 96 % 44 = 8
                                        4'b1000: FIFO_REG <= {{18{1'b0}}, register_in, FIFO_REG[27:0]};     // 92 -- 72 % 44 = 28
                                        4'b1001: FIFO_REG <= {{42{1'b0}}, register_in, FIFO_REG[03:0]};     // 68 -- 92 % 44 = 4
                                        4'b1010: FIFO_REG <= {{22{1'b0}}, register_in, FIFO_REG[23:0]};     // 88 -- 68 % 44 = 24
                                        default: FIFO_REG <= {{46{1'b0}}, register_in}; // 64
                                    endcase
                                end
                   4'b1100:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{46{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{30{1'b0}}, register_in, FIFO_REG[15:0]};     // 80 -- 64 % 48 = 16
                                        4'b0010: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[31:0]};     // 96 -- 80 % 48 = 32
                                        default: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                    endcase
                                end
                    default: FIFO_REG <= FIFO_REG; // No change
                endcase
            end
            else if(cs == OPERATE & !end_read)      FIFO_REG <= FIFO_REG >> b_desp;
            else                                    FIFO_REG <= FIFO_REG;
        end
    end
    
    reg [11:0] xsel0, xsel1, xsel2, xsel3;
    always @* begin
        case(b)
        4'b0001: xsel0 = FIFO_REG[11:0] & 12'h001; // (1 << 1 - 1) = 1     
        4'b0100: xsel0 = FIFO_REG[11:0] & 12'h00F; // (1 << 4 - 1) = 15 
        4'b0101: xsel0 = FIFO_REG[11:0] & 12'h01F; // (1 << 5 - 1) = 31 
        4'b1010: xsel0 = FIFO_REG[11:0] & 12'h3FF; // (1 << 10 - 1) = 1023
        4'b1011: xsel0 = FIFO_REG[11:0] & 12'h7FF; // (1 << 11 - 1) = 2047
        4'b1100: xsel0 = FIFO_REG[11:0];
        default: xsel0 = FIFO_REG[11:0] & 12'h001; // (1 << 1 - 1) = 1 
        endcase         
    end
    always @* begin
        case(b)
        4'b0001: xsel1 = FIFO_REG[12:01] & 12'h001; // (1 << 1 - 1) = 1     
        4'b0100: xsel1 = FIFO_REG[15:04] & 12'h00F; // (1 << 4 - 1) = 15 
        4'b0101: xsel1 = FIFO_REG[16:05] & 12'h01F; // (1 << 5 - 1) = 31 
        4'b1010: xsel1 = FIFO_REG[21:10] & 12'h3FF; // (1 << 10 - 1) = 1023
        4'b1011: xsel1 = FIFO_REG[22:11] & 12'h7FF; // (1 << 11 - 1) = 2047
        4'b1100: xsel1 = FIFO_REG[23:12];
        default: xsel1 = FIFO_REG[12:01] & 12'h001; // (1 << 1 - 1) = 1     
        endcase         
    end
    
    always @* begin
        case(b)
        4'b0001: xsel2 = FIFO_REG[13:02] & 12'h001; // (1 << 1 - 1) = 1     
        4'b0100: xsel2 = FIFO_REG[19:08] & 12'h00F; // (1 << 4 - 1) = 15 
        4'b0101: xsel2 = FIFO_REG[21:10] & 12'h01F; // (1 << 5 - 1) = 31 
        4'b1010: xsel2 = FIFO_REG[31:20] & 12'h3FF; // (1 << 10 - 1) = 1023
        4'b1011: xsel2 = FIFO_REG[33:22] & 12'h7FF; // (1 << 11 - 1) = 2047
        4'b1100: xsel2 = FIFO_REG[35:24];
        default: xsel2 = FIFO_REG[13:02] & 12'h001; // (1 << 1 - 1) = 1     
        endcase         
    end
    
    always @* begin
        case(b)
        4'b0001: xsel3 = FIFO_REG[14:03] & 12'h001; // (1 << 1 - 1) = 1     
        4'b0100: xsel3 = FIFO_REG[23:12] & 12'h00F; // (1 << 4 - 1) = 15 
        4'b0101: xsel3 = FIFO_REG[36:15] & 12'h01F; // (1 << 5 - 1) = 31 
        4'b1010: xsel3 = FIFO_REG[41:30] & 12'h3FF; // (1 << 10 - 1) = 1023
        4'b1011: xsel3 = FIFO_REG[44:33] & 12'h7FF; // (1 << 11 - 1) = 2047
        4'b1100: xsel3 = FIFO_REG[47:36];
        default: xsel3 = FIFO_REG[14:03] & 12'h001; // (1 << 1 - 1) = 1   
        endcase         
    end
    
    wire [11:0] data_decod_0, data_decod_1, data_decod_2, data_decod_3;
    DECOMPRESS DECOMPRESS_0 (.clk(clk), .x(xsel0), .b(b), .o(data_decod_0));
    DECOMPRESS DECOMPRESS_1 (.clk(clk), .x(xsel1), .b(b), .o(data_decod_1));
    DECOMPRESS DECOMPRESS_2 (.clk(clk), .x(xsel2), .b(b), .o(data_decod_2));
    DECOMPRESS DECOMPRESS_3 (.clk(clk), .x(xsel3), .b(b), .o(data_decod_3));
    
    always @* begin
            case(b)
                4'b0001:    begin
                                if(counter_op == 16)    end_read = 1'b1;
                                else                    end_read = 0;
                            end
                4'b0100:    begin
                                if(counter_op == 4)     end_read = 1'b1;
                                else                    end_read = 0;
                            end
                4'b0101:    begin // 20
                                        if(pos == 0 & counter_op == 3)      end_read = 1'b1; // 64 / 20 = 3
                                else    if(pos == 1 & counter_op == 3)      end_read = 1'b1; // 68 / 20 = 3
                                else    if(pos == 2 & counter_op == 3)      end_read = 1'b1; // 72 / 20 = 3
                                else    if(pos == 3 & counter_op == 3)      end_read = 1'b1; // 76 / 20 = 3
                                else    if(pos == 4 & counter_op == 4)      end_read = 1'b1; // 80 / 20 = 4
                                else                                        end_read = 1'b0;
                            end
                4'b1010:    begin // 40
                                        if(pos == 0 & counter_op == 1)      end_read = 1'b1; // 64 / 40 = 1
                                else    if(pos == 1 & counter_op == 2)      end_read = 1'b1; // 88 / 40 = 2
                                else    if(pos == 2 & counter_op == 1)      end_read = 1'b1; // 72 / 40 = 1
                                else    if(pos == 3 & counter_op == 2)      end_read = 1'b1; // 96 / 40 = 2
                                else    if(pos == 4 & counter_op == 2)      end_read = 1'b1; // 80 / 40 = 2
                                else                                        end_read = 1'b0; 
                            end
                4'b1011:    begin // 44
                                        if(pos == 0 & counter_op == 1)      end_read = 1'b1; // 64 / 44     = 1
                                else    if(pos == 1 & counter_op == 1)      end_read = 1'b1; // 84 / 44     = 1
                                else    if(pos == 2 & counter_op == 2)      end_read = 1'b1; // 104 / 44    = 2
                                else    if(pos == 3 & counter_op == 1)      end_read = 1'b1; // 80 / 44     = 1
                                else    if(pos == 4 & counter_op == 2)      end_read = 1'b1; // 100 / 44    = 2
                                else    if(pos == 5 & counter_op == 1)      end_read = 1'b1; // 76 / 44     = 1
                                else    if(pos == 6 & counter_op == 2)      end_read = 1'b1; // 96 / 44     = 2
                                else    if(pos == 7 & counter_op == 1)      end_read = 1'b1; // 72 / 44     = 1
                                else    if(pos == 8 & counter_op == 2)      end_read = 1'b1; // 92 / 44     = 2
                                else    if(pos == 9 & counter_op == 1)      end_read = 1'b1; // 68 / 44     = 1
                                else    if(pos == 10 & counter_op == 2)     end_read = 1'b1; // 88 // 44    = 2
                                else                                        end_read = 1'b0;
                            end
                4'b1100:    begin // 48
                                        if(pos == 0 & counter_op == 1)      end_read = 1'b1; // 64 / 48 = 1
                                else    if(pos == 1 & counter_op == 1)      end_read = 1'b1; // 80 / 48 = 1
                                else    if(pos == 2 & counter_op == 2)      end_read = 1'b1; // 96 / 48 = 2
                                else                                        end_read = 1'b0;
                            end
                default: end_read = 1'b0;
            endcase
        end    
    
    reg [11:0] o_0_0;
    reg [11:0] o_1_0;
    reg [11:0] o_0_1;
    reg [11:0] o_1_1;
    assign out_data = {o_1_1, o_0_1, o_1_0, o_0_0};
   
    
    reg op_0, op_1, op_2, op_3;
    // wire op = (b == 4'b1100) ? (cs == OPERATE) : op_3;
    wire op = op_2;
    always @ (posedge clk) begin
        op_0 <= (cs == OPERATE) ? 1'b1: 1'b0;
        op_1 <= op_0; 
        op_2 <= op_1;
        op_3 <= op_2;
    end
    
    reg [11:0] xsel0_0, xsel0_1, xsel0_2, xsel0_3;
    reg [11:0] xsel1_0, xsel1_1, xsel1_2, xsel1_3;
    reg [11:0] xsel2_0, xsel2_1, xsel2_2, xsel2_3;
    reg [11:0] xsel3_0, xsel3_1, xsel3_2, xsel3_3;
    always @(posedge clk) begin
        xsel0_0 <= xsel0;
        xsel0_1 <= xsel0_0;
        xsel0_2 <= xsel0_1;
        
        xsel1_0 <= xsel1;
        xsel1_1 <= xsel1_0;
        xsel1_2 <= xsel1_1;
        
        xsel2_0 <= xsel2;
        xsel2_1 <= xsel2_0;
        xsel2_2 <= xsel2_1;
        
        xsel3_0 <= xsel3;
        xsel3_1 <= xsel3_0;
        xsel3_2 <= xsel3_1;
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod) begin 
            o_0_0 <= 0;
            o_1_0 <= 0;
            o_0_1 <= 0;
            o_1_1 <= 0;
        end 
        else begin
            if(op)    o_0_0 <= (b == 4'b1100) ? xsel0_2 : data_decod_0;
            else      o_0_0 <= o_0_0;
                
            if(op)    o_1_0 <= (b == 4'b1100) ? xsel1_2 : data_decod_1;
            else      o_1_0 <= o_1_0;
            
            if(op)    o_0_1 <= (b == 4'b1100) ? xsel2_2 : data_decod_2;
            else      o_0_1 <= o_0_1;
            
            if(op)    o_1_1 <= (b == 4'b1100) ? xsel3_2 : data_decod_3;
            else      o_1_1 <= o_1_1;
        end
    
    end
    
    reg cond_1, cond_2, cond_3;
    // wire cond = (b == 4'b1100) ? (cs == LOAD_MEM | cs == LOAD_MEM_POS) : cond_3;
    wire cond = (cs == LOAD_MEM | cs == LOAD_MEM_POS);
    
    always @(posedge clk) begin
        cond_1 <= (cs == LOAD_MEM | cs == LOAD_MEM_POS) ? 1'b1 : 1'b0;
        cond_2 <= cond_1;
        cond_3 <= cond_2;
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod)                                 upd_add <= 1'b0;
        else begin
            if(cond)                                            upd_add <= 1'b1;
            else                                                upd_add <= 1'b0;   
        end
    end
endmodule

// 3 CYCLES DECODER_DECOMPRESS
module DECODER_DECOMPRESS (
    input                           clk,
    input                           rst,
    input           [63:0]          input_data,
    input                           start_decod,
    input           [15:0]          mode,
    input                           d_valid,
    output reg                      d_ready,
    output reg                      upd_add,
    output          [2*24-1:0]      out_data
    );
    
    wire [07:00] mode_decoder;
    wire [07:00] mode_decompress;
    
    assign mode_decoder     = mode[07:00];
    assign mode_decompress  = mode[15:08];
    
    wire [3:0] b;
    assign b = mode_decompress[3:0];
    
    
    //--*** STATE declaration **--//
	localparam IDLE            = 4'h0;
	localparam WAIT_NEXT       = 4'h1;
	localparam LOAD_NEXT       = 4'h2; 
	localparam OPERATE         = 4'h3;
	localparam LOAD_MEM        = 4'h4;
	localparam LOAD_MEM_POS    = 4'h5;
	localparam SAVE_DATA       = 4'h6;
	localparam UPDATE_POS      = 4'h7;
    
    //--*** STATE register **--//
	reg [3:0] cs; // current_state
	reg [3:0] ns; // current_state
    
    //--*** STATE initialization **--//
	 always @(posedge clk)
		begin
			if (!rst | !start_decod)     cs <= IDLE;
			else                         cs <= ns;
		end
    
    reg end_read;
    reg [1:0] counter; 
    reg [1:0] counter_0, counter_1, counter_2, counter_3;
    always @(posedge clk) begin
        counter_0 <= counter;
        counter_1 <= counter_0;
        counter_2 <= counter_1;
        counter_3 <= counter_2;
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod)             counter <= 0;
        else begin
            if(b == 4'b1010 | b == 4'b1011 | b == 4'b0101) begin
                if(end_read)                    counter <= counter;
                else if(cs == OPERATE)          counter <= counter + 1;
                else                            counter <= counter;
            end
            else begin
                if(end_read & counter == 2'b11) counter <= 0;
                else if(end_read)               counter <= counter;
                else if(cs == OPERATE)          counter <= counter + 1;
                else                            counter <= counter;
            end
        end    
    end
    
    reg [7:0] counter_op;
    always @(posedge clk) begin
        if(!rst | !start_decod)     counter_op <= 0;
        else begin
            if(b == 4'b1010 | b == 4'b1011 | b == 4'b0101) begin
                if(end_read)                        counter_op <= 0;
                else if(cs == OPERATE)              counter_op <= counter_op + 1;
                else                                counter_op <= counter_op;
            end
            else begin
                if(counter == 2'b11 & !end_read)    counter_op <= counter_op;
                else if(end_read)                   counter_op <= 0;
                else if(cs == OPERATE)              counter_op <= counter_op + 1;
                else                                counter_op <= counter_op;
            end
        end    
    end
    
    
    always @* begin
			case (cs)
				IDLE:
				   if (start_decod)
				     ns = WAIT_NEXT;
				   else
				     ns = IDLE;
			    WAIT_NEXT:
			       if (d_ready & d_valid)
			         ns = LOAD_NEXT;
			       else
			         ns = WAIT_NEXT;
			    LOAD_NEXT:
			         ns = SAVE_DATA;
			    SAVE_DATA:
			         ns = OPERATE;
			    OPERATE:
			       if (counter == 2'b11 & !end_read)
			         ns = LOAD_MEM;
			       else if ((b == 4'b1010 | b == 4'b0100 | b == 4'b1011 | b == 4'b0101) & counter == 2'b11 & end_read)
			         ns = UPDATE_POS;  
			       else if (b != 4'b1010 & counter == 2'b11 & end_read)
			         ns = LOAD_MEM_POS;
			       else if (end_read)
			         ns = UPDATE_POS;
			       else
			         ns = OPERATE;
			    LOAD_MEM:
			      if(end_read)
			         ns = UPDATE_POS;
			      else
			         ns = OPERATE;
			    LOAD_MEM_POS:
			         ns = UPDATE_POS;
			    UPDATE_POS:
			         ns = WAIT_NEXT;
				default:
					 ns = IDLE;
			endcase 		
		end 
    
    reg [63:0] register_in;
    always @(posedge clk) begin
            if(!rst | !start_decod)     register_in <= 0;
            else begin
                if(cs == LOAD_NEXT)     register_in <= input_data;
                else                    register_in <= register_in;
            end
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod | d_ready)                   d_ready <= 1'b0;
        else begin
            if(cs == WAIT_NEXT)                             d_ready <= 1'b1;
            else                                            d_ready <= 1'b0;
        end
    end
    
    reg [3:0] pos;
    
    always @(posedge clk) begin
        if(!rst | !start_decod)                     pos <= 0;
        else begin
            if(cs == UPDATE_POS) begin
                        if(b == 4'b0001)                pos <= 0;   // b = 1
                else    if(b == 4'b0100)                pos <= 0;   // b = 4       
                else    if(b == 4'b0101 & pos == 4)     pos <= 0;   // b = 5      
                else    if(b == 4'b1010 & pos == 4)     pos <= 0;   // b = 10
                else    if(b == 4'b1011 & pos == 10)    pos <= 0;   // b = 11
                else    if(b == 4'b1100 & pos == 2)     pos <= 0;   // b = 12
                else                                    pos <= pos + 1;
            end                 
            else                                    pos <= pos;
        end 
    end
    
    reg [79:00] FIFO_REG;
    
    always @(posedge clk) begin
        if(!rst | !start_decod) FIFO_REG <= 0;
        else begin
            if(cs == SAVE_DATA) begin
                case(b)
                    4'b0001: FIFO_REG <= {16'h0000, register_in};
                    4'b0100: FIFO_REG <= {16'h0000, register_in};
                    4'b0101:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{12{1'b0}}, register_in, FIFO_REG[3:0]}; // 68 -- 64 % 5 = 4
                                        4'b0010: FIFO_REG <= {{13{1'b0}}, register_in, FIFO_REG[2:0]}; // 67 -- 68 % 5 = 3
                                        4'b0011: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[1:0]}; // 66 -- 67 % 5 = 2
                                        4'b0100: FIFO_REG <= {{15{1'b0}}, register_in, FIFO_REG[0]};   // 65 -- 66 % 5 = 1
                                        default: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                    endcase
                                end
                    4'b1010:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{12{1'b0}}, register_in, FIFO_REG[3:0]}; // 68 -- 64 % 10 = 4
                                        4'b0010: FIFO_REG <= {{08{1'b0}}, register_in, FIFO_REG[7:0]}; // 72 -- 68 % 10 = 8
                                        4'b0011: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[1:0]}; // 66 -- 72 % 10 = 2
                                        4'b0100: FIFO_REG <= {{10{1'b0}}, register_in, FIFO_REG[5:0]}; // 70 -- 66 % 10 = 6
                                        default: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                    endcase
                                end
                    4'b1011:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{07{1'b0}}, register_in, FIFO_REG[8:0]};  // 73 -- 64 % 11 = 9
                                        4'b0010: FIFO_REG <= {{09{1'b0}}, register_in, FIFO_REG[6:0]};  // 71 -- 73 % 11 = 7
                                        4'b0011: FIFO_REG <= {{11{1'b0}}, register_in, FIFO_REG[4:0]};  // 69 -- 71 % 11 = 5
                                        4'b0100: FIFO_REG <= {{13{1'b0}}, register_in, FIFO_REG[2:0]};  // 67 -- 69 % 11 = 3
                                        4'b0101: FIFO_REG <= {{15{1'b0}}, register_in, FIFO_REG[0]};    // 65 -- 67 % 11 = 1
                                        4'b0110: FIFO_REG <= {{06{1'b0}}, register_in, FIFO_REG[9:0]};  // 74 -- 65 % 11 = 10
                                        4'b0111: FIFO_REG <= {{08{1'b0}}, register_in, FIFO_REG[7:0]};  // 72 -- 74 % 11 = 8
                                        4'b1000: FIFO_REG <= {{10{1'b0}}, register_in, FIFO_REG[5:0]};  // 70 -- 72 % 11 = 6
                                        4'b1001: FIFO_REG <= {{12{1'b0}}, register_in, FIFO_REG[3:0]};  // 68 -- 70 % 11 = 4
                                        4'b1010: FIFO_REG <= {{14{1'b0}}, register_in, FIFO_REG[1:0]};  // 66 -- 68 % 11 = 2
                                        default: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                    endcase
                                end
                   4'b1100:    begin
                                    case(pos)
                                        4'b0000: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                        4'b0001: FIFO_REG <= {{12{1'b0}}, register_in, FIFO_REG[3:0]};  // 68 -- 64 % 12 = 4
                                        4'b0010: FIFO_REG <= {{08{1'b0}}, register_in, FIFO_REG[7:0]};  // 72 -- 68 % 12 = 8
                                        default: FIFO_REG <= {{16{1'b0}}, register_in}; // 64
                                    endcase
                                end
                    default: FIFO_REG <= FIFO_REG; // No change
                endcase
            end
            else if(cs == OPERATE & !end_read)      FIFO_REG <= FIFO_REG >> b;
            else                                    FIFO_REG <= FIFO_REG;
        end
    end
    
    wire [11:0] xsel;
    assign xsel = FIFO_REG[11:0] & ((1 << b) - 1);
    
    wire [11:0] data_decod;
    DECOMPRESS DECOMPRESS (.clk(clk), .x(xsel), .b(b), .o(data_decod));
    
    always @* begin
            case(b)
                4'b0001:    begin
                                if(counter_op == 48)    end_read = 1'b1;
                                else                    end_read = 0;
                            end
                4'b0100:    begin
                                if(counter_op == 15)    end_read = 1'b1;
                                else                    end_read = 0;
                            end
                4'b0101:    begin
                                        if(pos == 0 & counter_op == 12)     end_read = 1'b1; // 64
                                else    if(pos == 1 & counter_op == 13)     end_read = 1'b1; // 68
                                else    if(pos == 2 & counter_op == 13)     end_read = 1'b1; // 67
                                else    if(pos == 3 & counter_op == 13)     end_read = 1'b1; // 66
                                else    if(pos == 4 & counter_op == 13)     end_read = 1'b1; // 65
                                else                                        end_read = 1'b0;
                            end
                4'b1010:    begin
                                        if(pos == 0 & counter_op == 6)      end_read = 1'b1; // 64
                                else    if(pos == 1 & counter_op == 6)      end_read = 1'b1; // 68
                                else    if(pos == 2 & counter_op == 7)      end_read = 1'b1; // 72
                                else    if(pos == 3 & counter_op == 6)      end_read = 1'b1; // 66
                                else    if(pos == 4 & counter_op == 7)      end_read = 1'b1; // 70
                                else                                        end_read = 1'b0;
                            end
                4'b1011:    begin
                                        if(pos == 0 & counter_op == 5)      end_read = 1'b1; // 64
                                else    if(pos == 1 & counter_op == 6)      end_read = 1'b1; // 73
                                else    if(pos == 2 & counter_op == 6)      end_read = 1'b1; // 71
                                else    if(pos == 3 & counter_op == 6)      end_read = 1'b1; // 69
                                else    if(pos == 4 & counter_op == 6)      end_read = 1'b1; // 67
                                else    if(pos == 5 & counter_op == 5)      end_read = 1'b1; // 65
                                else    if(pos == 6 & counter_op == 6)      end_read = 1'b1; // 74
                                else    if(pos == 7 & counter_op == 6)      end_read = 1'b1; // 72
                                else    if(pos == 8 & counter_op == 6)      end_read = 1'b1; // 70
                                else    if(pos == 9 & counter_op == 6)      end_read = 1'b1; // 68
                                else    if(pos == 10 & counter_op == 6)     end_read = 1'b1; // 66
                                else                                        end_read = 1'b0;
                            end
                4'b1100:    begin
                                        if(pos == 0 & counter_op == 4)      end_read = 1'b1; // 64
                                else    if(pos == 1 & counter_op == 4)      end_read = 1'b1; // 68
                                else    if(pos == 2 & counter_op == 4)      end_read = 1'b1; // 72
                                else                                        end_read = 1'b0;
                            end
                default: end_read = 1'b0;
            endcase
        end    
    
    reg [11:0] o_0_0;
    reg [11:0] o_1_0;
    reg [11:0] o_0_1;
    reg [11:0] o_1_1;
    assign out_data = {o_1_1, o_0_1, o_1_0, o_0_0};
    
    
    wire [1:0] sel_counter = (b == 4'b1100) ? counter_2 : counter_2;
    
    reg op_0, op_1, op_2, op_3;
    // wire op = (b == 4'b1100) ? (cs == OPERATE) : op_3;
    wire op = op_2;
    always @ (posedge clk) begin
        op_0 <= (cs == OPERATE) ? 1'b1: 1'b0;
        op_1 <= op_0; 
        op_2 <= op_1;
        op_3 <= op_2;
    end
    
    reg [11:0] xsel_0, xsel_1, xsel_2, xsel_3;
    always @(posedge clk) begin
        xsel_0 <= xsel;
        xsel_1 <= xsel_0;
        xsel_2 <= xsel_1;
        xsel_3 <= xsel_2;
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod) begin 
            o_0_0 <= 0;
            o_1_0 <= 0;
            o_0_1 <= 0;
            o_1_1 <= 0;
        end 
        else begin
            if(sel_counter == 2'b00 & op)    o_0_0 <= (b == 4'b1100) ? xsel_2 : data_decod;
            else                             o_0_0 <= o_0_0;
                
            if(sel_counter == 2'b01 & op)    o_1_0 <= (b == 4'b1100) ? xsel_2 : data_decod;
            else                             o_1_0 <= o_1_0;
            
            if(sel_counter == 2'b10 & op)    o_0_1 <= (b == 4'b1100) ? xsel_2 : data_decod;
            else                             o_0_1 <= o_0_1;
            
            if(sel_counter == 2'b11 & op)    o_1_1 <= (b == 4'b1100) ? xsel_2 : data_decod;
            else                             o_1_1 <= o_1_1;
        end
    
    end
    
    reg cond_1, cond_2, cond_3;
    // wire cond = (b == 4'b1100) ? (cs == LOAD_MEM | cs == LOAD_MEM_POS) : cond_3;
    wire cond = (cs == LOAD_MEM | cs == LOAD_MEM_POS);
    
    always @(posedge clk) begin
        cond_1 <= (cs == LOAD_MEM | cs == LOAD_MEM_POS) ? 1'b1 : 1'b0;
        cond_2 <= cond_1;
        cond_3 <= cond_2;
    end
    
    always @(posedge clk) begin
        if(!rst | !start_decod)                                 upd_add <= 1'b0;
        else begin
            if(cond)                                            upd_add <= 1'b1;
            else                                                upd_add <= 1'b0;   
        end
    end
endmodule

// 2 CYCLES DECOMPRESS
module DECOMPRESS (
    input clk,
    input   [11:0] x,
    input   [3:0] b,
    output  [11:0] o);
    
    
    // (x * 3329)

    wire [23:0] xm;
    mult_by_3329 mult_by_3329 (.x({12'h000, x}) , .result(xm)); 
    
    // Stage 1: Register xm
    reg [23:0] xm_reg;
    always @(posedge clk) xm_reg <= xm;

    // Stage 2: Register rem and low
    reg [23:0] rem, low;
    reg [11:0] mask;
    always @* begin
        case(b)
            4'd0:       mask = 12'h000;
            4'd1:       mask = 12'h001;
            4'd2:       mask = 12'h003;
            4'd3:       mask = 12'h007;
            4'd4:       mask = 12'h00F;
            4'd5:       mask = 12'h01F;
            4'd6:       mask = 12'h03F;
            4'd7:       mask = 12'h07F;
            4'd8:       mask = 12'h0FF;
            4'd9:       mask = 12'h1FF;
            4'd10:      mask = 12'h3FF;
            4'd11:      mask = 12'h7FF;
            4'd12:      mask = 12'hFFF;
            default:    mask = 12'hFFF;
        endcase
    end

    always @(posedge clk) begin
        rem <= xm_reg & {12'b0, mask};
        low <= xm_reg >> b;
    end
    
    // Stage 3: Register output sum
    reg [23:0] o_reg;
    always @(posedge clk) o_reg <= low + (rem >> (b-1));
    
    assign o = o_reg[11:0]; 

endmodule

module mult_by_3329 (
    input  wire [23:0] x,         
    output wire [23:0] result    
);

    // 3329 = 2048 + 1024 + 256 + 1
    
    wire [23:0] x_shift_11 = x << 11; // x * 2048
    wire [23:0] x_shift_10 = x << 10; // x * 1024
    wire [23:0] x_shift_8  = x << 8;  // x * 256
    wire [23:0] x_shift_0  = x;       // x * 1
    
    assign result = x_shift_11 + x_shift_10 + x_shift_8 + x_shift_0;

endmodule
