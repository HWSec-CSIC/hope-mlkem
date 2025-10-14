`timescale 1ns / 1ps

// (*blackbox*) // synthesis syn_black_box
module MEM_ZETAS_COMPLETE #(
    parameter DATA_WIDTH    =   36,
    parameter ADDR_WIDTH    =   7
    )(
    input clk,
    input [(ADDR_WIDTH-1):0] addr_zeta, 
	output [(DATA_WIDTH-1):0] data_out_zeta
    );
    
    ROM_ZETAS_COMPLETE ROM_ZETAS_COMPLETE (.clk(clk), .addr(addr_zeta), .data_out(data_out_zeta));
    
endmodule
 
 module ROM_ZETAS_COMPLETE #(
    parameter DATA_WIDTH    =   36, 
    parameter ADDR_WIDTH    =   7
    )(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output [(DATA_WIDTH-1):0] data_out
);
 
	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] Mem [2**ADDR_WIDTH-1:0];
    
    reg [(DATA_WIDTH-1):0] reg_out;
 
	always @ (posedge clk)
	begin
		reg_out <= Mem[addr];
	end
	
	assign data_out = reg_out;
	
	initial
	begin
		Mem[0] = {12'h011, 12'h001, 12'h001};
        Mem[1] = {12'hCF0, 12'h497, 12'h6C1};
        Mem[2] = {12'hAC9, 12'h98C, 12'hA14};
        Mem[3] = {12'h238, 12'h18A, 12'hCD9};
        Mem[4] = {12'h247, 12'h4C3, 12'hA52};
        Mem[5] = {12'hABA, 12'h8FC, 12'h276};
        Mem[6] = {12'hA59, 12'h5AF, 12'h769};
        Mem[7] = {12'h2A8, 12'h845, 12'h350};
        Mem[8] = {12'h665, 12'h647, 12'h426};
        Mem[9] = {12'h69C, 12'h98B, 12'h77F};
        Mem[10] = {12'h2D3, 12'h22A, 12'h0C1};
        Mem[11] = {12'hA2E, 12'h49B, 12'h31D};
        Mem[12] = {12'h8F0, 12'h88A, 12'hAE2};
        Mem[13] = {12'h411, 12'h8FF, 12'hCBC};
        Mem[14] = {12'h44C, 12'hB6E, 12'h239};
        Mem[15] = {12'h8B5, 12'h8BD, 12'h6D2};
        Mem[16] = {12'h581, 12'h20D, 12'h128};
        Mem[17] = {12'h780, 12'h2DF, 12'h98F};
        Mem[18] = {12'hA66, 12'h35F, 12'h53B};
        Mem[19] = {12'h29B, 12'hAD0, 12'h5C4};
        Mem[20] = {12'hCD1, 12'h4CE, 12'hBE6};
        Mem[21] = {12'h030, 12'hA0C, 12'h038};
        Mem[22] = {12'h0E9, 12'h22C, 12'h8C0};
        Mem[23] = {12'hC18, 12'hBC2, 12'h535};
        Mem[24] = {12'h2F4, 12'h8DA, 12'h592};
        Mem[25] = {12'hA0D, 12'h694, 12'h82E};
        Mem[26] = {12'h86C, 12'h4D7, 12'h217};
        Mem[27] = {12'h495, 12'h30C, 12'hB42};
        Mem[28] = {12'hBC7, 12'hB8A, 12'h959};
        Mem[29] = {12'h13A, 12'h06D, 12'hB3F};
        Mem[30] = {12'hBEA, 12'h50C, 12'h7B6};
        Mem[31] = {12'h117, 12'h407, 12'h335};
        
        Mem[32] = {12'h6A7, 12'h6D1, 12'h121};
        Mem[33] = {12'h65A, 12'hA80, 12'h14B};
        Mem[34] = {12'h673, 12'hBF5, 12'hCB5};
        Mem[35] = {12'h68E, 12'h3E0, 12'h6DC};
        Mem[36] = {12'hAE5, 12'hA24, 12'h4AD};
        Mem[37] = {12'h21C, 12'h3AD, 12'h900};
        Mem[38] = {12'h6FD, 12'h37C, 12'h8E5};
        Mem[39] = {12'h604, 12'h3FD, 12'h807};
        Mem[40] = {12'h737, 12'h956, 12'h28A};
        Mem[41] = {12'h5CA, 12'h282, 12'h7B9};
        Mem[42] = {12'h3B8, 12'h74C, 12'h9D1};
        Mem[43] = {12'h949, 12'h949, 12'h278};
        Mem[44] = {12'h5B5, 12'h5CA, 12'hB31};
        Mem[45] = {12'h74C, 12'h604, 12'h021};
        Mem[46] = {12'hA7F, 12'h21C, 12'h528};
        Mem[47] = {12'h282, 12'h68E, 12'h77B};
        Mem[48] = {12'h3AB, 12'h65A, 12'h90F};
        Mem[49] = {12'h956, 12'h117, 12'h59B};
        Mem[50] = {12'h904, 12'h13A, 12'h327};
        Mem[51] = {12'h3FD, 12'h495, 12'h1C4};
        Mem[52] = {12'h985, 12'hA0D, 12'h59E};
        Mem[53] = {12'h37C, 12'hC18, 12'hB34};
        Mem[54] = {12'h954, 12'h030, 12'h5FE};
        Mem[55] = {12'h3AD, 12'h29B, 12'h962};
        Mem[56] = {12'h2DD, 12'h780, 12'hA57};
        Mem[57] = {12'hA24, 12'h8B5, 12'hA39};
        Mem[58] = {12'h921, 12'h411, 12'h5C9};
        Mem[59] = {12'h3E0, 12'hA2E, 12'h288};
        Mem[60] = {12'h10C, 12'h69C, 12'h9AA};
        Mem[61] = {12'hBF5, 12'h2A8, 12'hC26};
        Mem[62] = {12'h281, 12'hABA, 12'h4CB};
        Mem[63] = {12'hA80, 12'h238, 12'h38E};
        
        Mem[64] = {12'h630, 12'hCF0, 12'h11};
        Mem[65] = {12'h6D1, 12'h973, 12'hAC9};
        Mem[66] = {12'h8FA, 12'h836, 12'h247};
        Mem[67] = {12'h407, 12'hDB , 12'hA59};
        Mem[68] = {12'h7F5, 12'h357, 12'h665};
        Mem[69] = {12'h50C, 12'hA79, 12'h2D3};
        Mem[70] = {12'hC94, 12'h738, 12'h8F0};
        Mem[71] = {12'h6D , 12'h2C8, 12'h44C};
        Mem[72] = {12'h177, 12'h2AA, 12'h581};
        Mem[73] = {12'hB8A, 12'h39F, 12'hA66};
        Mem[74] = {12'h9F5, 12'h703, 12'hCD1};
        Mem[75] = {12'h30C, 12'h1CD, 12'hE9};
        Mem[76] = {12'h82A, 12'h763, 12'h2F4};
        Mem[77] = {12'h4D7, 12'hB3D, 12'h86C};
        Mem[78] = {12'h66D, 12'h9DA, 12'hBC7};
        Mem[79] = {12'h694, 12'h766, 12'hBEA};
        Mem[80] = {12'h427, 12'h3F2, 12'h6A7};
        Mem[81] = {12'h8DA, 12'h586, 12'h673};
        Mem[82] = {12'h13F, 12'h7D9, 12'hAE5};
        Mem[83] = {12'hBC2, 12'hCE0, 12'h6FD};
        Mem[84] = {12'hAD5, 12'h1D0, 12'h737};
        Mem[85] = {12'h22C, 12'hA89, 12'h3B8};
        Mem[86] = {12'h2F5, 12'h330, 12'h5B5};
        Mem[87] = {12'hA0C, 12'h548, 12'hA7F};
        Mem[88] = {12'h833, 12'hA77, 12'h3AB};
        Mem[89] = {12'h4CE, 12'h4FA, 12'h904};
        Mem[90] = {12'h231, 12'h41C, 12'h985};
        Mem[91] = {12'hAD0, 12'h401, 12'h954};
        Mem[92] = {12'h9A2, 12'h854, 12'h2DD};
        Mem[93] = {12'h35F, 12'h625, 12'h921};
        Mem[94] = {12'hA22, 12'h4C , 12'h10C};
        Mem[95] = {12'h2DF, 12'hBB6, 12'h281};
        
        Mem[96] = {12'hAF4, 12'hBE0, 12'h630};
        Mem[97] = {12'h20D, 12'h9CC, 12'h8FA};
        Mem[98] = {12'h444, 12'h54B, 12'h7F5};
        Mem[99] = {12'h8BD, 12'h1C2, 12'hC94};
        Mem[100] = {12'h193, 12'h3A8, 12'h177};
        Mem[101] = {12'hB6E, 12'h1BF, 12'h9F5};
        Mem[102] = {12'h402, 12'hAEA, 12'h82A};
        Mem[103] = {12'h8FF, 12'h4D3, 12'h66D};
        Mem[104] = {12'h477, 12'h76F, 12'h427};
        Mem[105] = {12'h88A, 12'h7CC, 12'h13F};
        Mem[106] = {12'h866, 12'h441, 12'hAD5};
        Mem[107] = {12'h49B, 12'hCC9, 12'h2F5};
        Mem[108] = {12'hAD7, 12'h11B, 12'h833};
        Mem[109] = {12'h22A, 12'h73D, 12'h231};
        Mem[110] = {12'h376, 12'h7C6, 12'h9A2};
        Mem[111] = {12'h98B, 12'h372, 12'hA22};
        Mem[112] = {12'h6BA, 12'hBD9, 12'hAF4};
        Mem[113] = {12'h647, 12'h62F, 12'h444};
        Mem[114] = {12'h4BC, 12'hAC8, 12'h193};
        Mem[115] = {12'h845, 12'h45 , 12'h402};
        Mem[116] = {12'h752, 12'h21F, 12'h477};
        Mem[117] = {12'h5AF, 12'h9E4, 12'h866};
        Mem[118] = {12'h405, 12'hC40, 12'hAD7};
        Mem[119] = {12'h8FC, 12'h582, 12'h376};
        Mem[120] = {12'h83E, 12'h8DB, 12'h6BA};
        Mem[121] = {12'h4C3, 12'h9B1, 12'h4BC};
        Mem[122] = {12'hB77, 12'h598, 12'h752};
        Mem[123] = {12'h18A, 12'hA8B, 12'h405};
        Mem[124] = {12'h375, 12'h2AF, 12'h83E};
        Mem[125] = {12'h98C, 12'h28 , 12'hB77};
        Mem[126] = {12'h86A, 12'h2ED, 12'h375};
        Mem[127] = {12'h497, 12'h640, 12'h86A};
	end
 endmodule
