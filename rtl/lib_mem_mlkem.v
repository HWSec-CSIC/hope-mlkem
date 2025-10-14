`timescale 1ns / 1ps

// (*blackbox*) // synthesis syn_black_box
module RAM  # 
  (
    parameter SIZE = 64,
    parameter WIDTH = 32
  )( 
    input clk,
    input en_write,
    input en_read,
    input [clog2(SIZE-1)-1:0] addr_write,
    input [clog2(SIZE-1)-1:0] addr_read,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
  );

 
	reg [WIDTH-1:0] Mem [SIZE-1:0];
	reg [WIDTH-1:0] out_reg;

 	always @(posedge clk) 
	begin
        if(en_write)  Mem[addr_write] <= data_in;
	end
	
	always @(posedge clk) 
	begin
		if(en_read)   out_reg <= Mem[addr_read];
	end
	
    assign data_out = out_reg;
    /*
    genvar i;
        generate 
         for(i = 0; i < SIZE; i = i+1) begin
            initial Mem[i] = 0;
         end
        endgenerate
    */
    
	
  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule


// (*blackbox*) // synthesis syn_black_box
module RAM_DUAL  # 
  (
    parameter integer SIZE = 51200 / 32,
    parameter WIDTH = 32
  )( 
    input clk,
    input enable_1,
    input enable_2,
    input [clog2(SIZE-1)-1:0] addr_1,
    input [clog2(SIZE-1)-1:0] addr_2,
    input [WIDTH-1:0] data_in_1,
    input [WIDTH-1:0] data_in_2,
    output [WIDTH-1:0] data_out_1,
    output [WIDTH-1:0] data_out_2
  );
      
	reg [WIDTH-1:0] Mem [SIZE-1:0];
	reg [WIDTH-1:0] out_reg_1;
	reg [WIDTH-1:0] out_reg_2;
	
 	always @(posedge clk) 
	begin
        if(enable_1) Mem[addr_1] <= data_in_1;
        out_reg_1 <= Mem[addr_1];
	end
    assign data_out_1 = out_reg_1 ;
    
    always @(posedge clk) 
	begin
        if(enable_2) Mem[addr_2] <= data_in_2;
        out_reg_2 <= Mem[addr_2];
	end
    assign data_out_2 = out_reg_2 ;
    
    /*
    genvar i;
        generate 
         for(i = 0; i < SIZE; i = i+1) begin
            initial Mem[i] = 0;
         end
        endgenerate
    */

  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction
    
    function integer ceiling;
        input integer n;
        ceiling = n;
    endfunction

endmodule

// (*blackbox*) // synthesis syn_black_box
module RAMD (
    input clk,
    input               en_w,
    input   [4:0]       add_w,
    input   [4:0]       add_r,
    input   [31:0]        d_i,
    output  [31:0]        d_o
);
    
    reg [31:0] REG [0:31];
    
    assign d_o = REG[add_r];

    always @(posedge clk) begin
        if (en_w)
            REG[add_w] <= d_i;
    end

endmodule

// (*blackbox*) // synthesis syn_black_box
module RAMD64 (
    input clk,
    input               en_w,
    input   [4:0]       add_w,
    input   [4:0]       add_r,
    input   [63:0]        d_i,
    output  [63:0]        d_o
);
    
    RAMD RAMD_0 (
        .clk        (   clk         ),
        .en_w       (   en_w        ),
        .add_w      (   add_w       ),
        .add_r      (   add_r       ),
        .d_i        (   d_i[31:0]    ),
        .d_o        (   d_o[31:0]    )
    );
    
    
    RAMD RAMD_1 (
        .clk        (   clk          ),
        .en_w       (   en_w         ),
        .add_w      (   add_w        ),
        .add_r      (   add_r        ),
        .d_i        (   d_i[63:32]    ),
        .d_o        (   d_o[63:32]    )
    );

endmodule

// (*blackbox*) // synthesis syn_black_box
module RAMD64_CR #(
    parameter COLS = 17,
    parameter ROWS = 1
    ) (
    input clk,
    input                                     en_w,
    input   [clog2(ROWS*32-1)-1:0]            add_w,
    input   [clog2(ROWS*32-1)-1:0]            add_r,
    input   [COLS*64-1:0]                     d_i,
    output  reg [COLS*64-1:0]                 d_o
) ;

    wire [COLS*64-1:0] do_d [ROWS-1:0];
    wire [ROWS-1:0] en_w_d; 
    wire [ROWS-1:0] sel_r;
    
    genvar c, r;
    generate
    for (r = 0; r < ROWS; r = r + 1) begin
        for (c = 0; c < COLS; c = c + 1) begin
            RAMD64 RAMD64 (
                .clk        (   clk                     ),
                .en_w       (   en_w_d[r]               ),
                .add_w      (   add_w[4:0]              ),
                .add_r      (   add_r[4:0]              ),
                .d_i         (   d_i[(c+1)*64-1:c*64]     ),
                .d_o         (   do_d[r][(c+1)*64-1:c*64]                 )
            );
        end
        
        if(ROWS != 1) begin
            assign en_w_d[r]    = en_w & (add_w[clog2(ROWS*32-1)-1:5] == r);
            assign sel_r        = (add_r[clog2(ROWS*32-1)-1:5]);
            
            always @* begin
                d_o = do_d[sel_r];
            end  
        end
        else begin
            assign en_w_d[r]    = en_w;
            assign sel_r[r]     = 1'b1;
            
            always @* begin
                d_o = do_d[0];
            end 
        end
            
        
    end
    
    endgenerate
    
    
    // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule
