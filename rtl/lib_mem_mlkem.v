/**
  * @file  lib_mem_mlkem.v
  * @brief RAM Module
  *
  * @section License
  *
  * Secure Element for QUBIP Project
  *
  * This Secure Element repository for QUBIP Project is subject to the
  * BSD 3-Clause License below.
  *
  * Copyright (c) 2024,
  *         Eros Camacho-Ruiz
  *         Pablo Navarro-Torrero
  *         Pau Ortega-Castro
  *         Apurba Karmakar
  *         Macarena C. Martínez-Rodríguez
  *         Piedad Brox
  *
  * All rights reserved.
  *
  * This Secure Element was developed by Instituto de Microelectrónica de
  * Sevilla - IMSE (CSIC/US) as part of the QUBIP Project, co-funded by the
  * European Union under the Horizon Europe framework programme
  * [grant agreement no. 101119746].
  *
  * -----------------------------------------------------------------------
  *
  * Redistribution and use in source and binary forms, with or without
  * modification, are permitted provided that the following conditions are met:
  *
  * 1. Redistributions of source code must retain the above copyright notice, this
  *    list of conditions and the following disclaimer.
  *
  * 2. Redistributions in binary form must reproduce the above copyright notice,
  *    this list of conditions and the following disclaimer in the documentation
  *    and/or other materials provided with the distribution.
  *
  * 3. Neither the name of the copyright holder nor the names of its
  *    contributors may be used to endorse or promote products derived from
  *    this software without specific prior written permission.
  *
  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
  *
  *
  *
  *
  * @author Eros Camacho-Ruiz (camacho@imse-cnm.csic.es)
  * @version 1.0
  **/

`timescale 1ns / 1ps

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


module RAMB36E11024x64  # 
  (
    parameter SIZE = 1024,
    parameter WIDTH = 64,
    parameter SIM = 0
  )( 
    input clk,
    input en_write,
    input en_read,
    input [clog2(SIZE-1)-1:0] addr_write,
    input [clog2(SIZE-1)-1:0] addr_read,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
  );
    
    generate 
    if(SIM) begin
        RAM #(.SIZE(SIZE), .WIDTH(WIDTH)) RAM
                (.clk       (   clk               ), 
                .en_write   (   en_write          ),     
                .en_read    (   en_read           ), 
                .addr_write (   addr_write        ),              
                .addr_read  (   addr_read         ), 
                .data_in    (   data_in           ),
                .data_out   (   data_out          )
        );
    
    end
    else begin
        RAMB36E1 #(
       // Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
       .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
       // Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
       .SIM_COLLISION_CHECK("NONE"),
       // DOA_REG, DOB_REG: Optional output register (0 or 1)
       .DOA_REG(0),
       .DOB_REG(0),
       .EN_ECC_READ("FALSE"),                                                            // Enable ECC decoder,
                                                                                         // FALSE, TRUE
       .EN_ECC_WRITE("FALSE"),                                                           // Enable ECC encoder,
                                                                                         // FALSE, TRUE
       // INITP_00 to INITP_0F: Initial contents of the parity memory array
       .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       // INIT_00 to INIT_7F: Initial contents of the data memory array
       .INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_10(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_11(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_12(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_20(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_21(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_22(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_23(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_24(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_25(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_26(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_27(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_28(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_29(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_2F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_30(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_31(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_32(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_33(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_34(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_35(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_36(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_37(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_40(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_41(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_42(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_43(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_44(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_45(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_46(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_47(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_48(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_49(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_4F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_50(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_51(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_52(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_53(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_54(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_55(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_56(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_57(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_58(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_59(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_5F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_60(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_61(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_62(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_63(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_64(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_65(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_66(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_67(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_68(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_69(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_6F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_70(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_71(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_72(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_73(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_74(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_75(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_76(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_77(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_78(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_79(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7A(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7B(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7C(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7D(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7E(256'h0000000000000000000000000000000000000000000000000000000000000000),
       .INIT_7F(256'h0000000000000000000000000000000000000000000000000000000000000000),
       // INIT_A, INIT_B: Initial values on output ports
       .INIT_A(36'h000000000),
       .INIT_B(36'h000000000),
       // Initialization File: RAM initialization file
       .INIT_FILE("NONE"),
       // RAM Mode: "SDP" or "TDP"
       .RAM_MODE("SDP"),
       // RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
       .RAM_EXTENSION_A("NONE"),
       .RAM_EXTENSION_B("NONE"),
       // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
       .READ_WIDTH_A(72),                                                                 // 0-72
       .READ_WIDTH_B(0),                                                                 // 0-36
       .WRITE_WIDTH_A(0),                                                                // 0-36
       .WRITE_WIDTH_B(72),                                                                // 0-72
       // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
       .RSTREG_PRIORITY_A("RSTREG"),
       .RSTREG_PRIORITY_B("RSTREG"),
       // SRVAL_A, SRVAL_B: Set/reset value for output
       .SRVAL_A(36'h000000000),
       .SRVAL_B(36'h000000000),
       // Simulation Device: Must be set to "7SERIES" for simulation behavior
       .SIM_DEVICE("7SERIES"),
       // WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
       .WRITE_MODE_A("WRITE_FIRST"),
       .WRITE_MODE_B("WRITE_FIRST")
    )
    RAMB36E1_inst (
        
        // -- Read Port
        // Port A Data: 32-bit (each) output: Port A data
       .DOADO(data_out[31:0]),                 // 32-bit output: A port data/LSB data
       .DOPADOP(),             // 4-bit output: A port parity/LSB parity
       // Port B Data: 32-bit (each) output: Port B data
       .DOBDO(data_out[63:32]),                 // 32-bit output: B port data/MSB data
       .DOPBDOP(),             // 4-bit output: B port parity/MSB parity
       // Port A Address/Control Signals: 16-bit (each) input: Port A address and control signals (read port
       // when RAM_MODE="SDP")
       .ADDRARDADDR({1'b1, addr_read, 5'b11111}),   // 16-bit input: A port address/Read address
       .CLKARDCLK(clk),                             // 1-bit input: A port clock/Read clock
       .ENARDEN(1'b1),                           // 1-bit input: A port enable/Read enable
       
       // --- Write Port
        // Port A Data: 32-bit (each) input: Port A data
       .DIADI(data_in[31:0]),                           // 32-bit input: A port data/LSB data
       .DIPADIP(4'b0000),                                      // 4-bit input: A port parity/LSB parity
       // Port B Data: 32-bit (each) input: Port B data
       .DIBDI(data_in[63:32]),                          // 32-bit input: B port data/MSB data
       .DIPBDIP(4'b0000),                                      // 4-bit input: B port parity/MSB parity
       .ADDRBWRADDR({1'b1, addr_write, 5'b11111}),      // 16-bit input: B port address/Write address
       .CLKBWRCLK(clk),                                 // 1-bit input: B port clock/Write clock
       .ENBWREN(1'b1),                                  // 1-bit input: B port enable/Write enable
       .WEBWE({8{en_write}}),                           // 8-bit input: B port write enable/Write enable
     
    
        
       // --- No connected
       // Cascade Signals: 1-bit (each) input: BRAM cascade ports (to create 64kx1)
       .CASCADEINA(),       // 1-bit input: A port cascade
       .CASCADEINB(),       // 1-bit input: B port cascade
       // Cascade Signals: 1-bit (each) output: BRAM cascade ports (to create 64kx1)
       .CASCADEOUTA(),     // 1-bit output: A port cascade
       .CASCADEOUTB(),     // 1-bit output: B port cascade
       
       // ECC Signals: 1-bit (each) input: Error Correction Circuitry ports
       .INJECTDBITERR(),        // 1-bit input: Inject a double bit error
       .INJECTSBITERR(),        // 1-bit input: Inject a single bit error
       .DBITERR(),              // 1-bit output: Double bit error status
       .ECCPARITY(),            // 8-bit output: Generated error correction parity
       .RDADDRECC(),            // 9-bit output: ECC read address
       .SBITERR(),              // 1-bit output: Single bit error status
       
       .WEA(),                     // 4-bit input: A port write enable (not used in SDP)
    
       .REGCEAREGCE(1'b0),          // 1-bit input: A port register enable/Register enable
       .REGCEB(1'b0),               // 1-bit input: B port register enable
       .RSTRAMARSTRAM(1'b0),        // 1-bit input: A port set/reset
       .RSTREGARSTREG(1'b0),            // 1-bit input: A port register set/reset
       .RSTRAMB(1'b0),             // 1-bit input: B port set/reset
       .RSTREGB(1'b0)               // 1-bit input: B port register set/reset
    
    );
    
    // End of RAMB36E1_inst instantiation
    end
    endgenerate
    
	
  // clog2 function 
    function integer clog2;
      input integer n;
        for (clog2=0; n>0; clog2=clog2+1)
          n = n >> 1;
    endfunction

endmodule


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
