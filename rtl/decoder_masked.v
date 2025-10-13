`timescale 1ns / 1ps

// 3 CYCLES DECODER_DECOMPRESS
module DECODER_DECOMPRESS_MASKED (
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

