#include <stdlib.h> 
#include <iostream>
#include <cstdarg>
#include <cstdio>
#include <verilated.h>
#include "sim_utils.h"          // Contains the configuration, sim_time, and simulation helper prototypes


// Global variables for the testbench
uint8_t RESET         = 0x00;
uint8_t LOAD_R0       = 0x01;
uint8_t READ_R0       = 0x02;
uint8_t LOAD_R1       = 0x03;
uint8_t READ_R1       = 0x04;
uint8_t LOAD_HEK      = 0x05;
uint8_t READ_HEK      = 0x06;
uint8_t LOAD_SS       = 0x07;
uint8_t READ_SS       = 0x08;
uint8_t LOAD_DK       = 0x09;
uint8_t READ_DK       = 0x0A;
uint8_t LOAD_EK       = 0x0B;
uint8_t READ_EK       = 0x0C;
uint8_t LOAD_CT       = 0x0D;
uint8_t READ_CT       = 0x0E; 
uint8_t START         = 0x0F;

uint8_t GEN_KEYS_512  = 0x05; // 01_01 (5)
uint8_t GEN_KEYS_768  = 0x06; // 01_10 (6)
uint8_t GEN_KEYS_1024 = 0x07; // 01_11 (7)
uint8_t ENCAP_512     = 0x09; // 10_01 (9)
uint8_t ENCAP_768     = 0x0A; // 10_10 (10)
uint8_t ENCAP_1024    = 0x0B; // 10_11 (11)
uint8_t DECAP_512     = 0x0D; // 11_01 (13)
uint8_t DECAP_768     = 0x0E; // 11_10 (14)
uint8_t DECAP_1024    = 0x0F; // 11_11 (15)

uint8_t CYCLES        = 10;    
unsigned int PASS_TEST = 0; // Counter for passed tests
unsigned int TEST = 0; // Counter for current test

// Clock Cycles Counters
uint16_t cc_key     = 0;
uint16_t cc_encap   = 0;
uint16_t cc_decap   = 0;
char char_key[10];
char char_encap[10];
char char_decap[10];

// ----------------------------------------------------------------------------------------------------
// K testbench
// -----------------------------------------------------------------------------------------------------
static void gen_seed(unsigned long long int d[4], unsigned long long int m[4], unsigned long long int z[4], uint8_t sel_random) {
    
    #if defined(TRACES)
        // --- Gen Keys --- // Depency on d
        #if(OPERATION == 0)

            if(sel_random) {
                d[0] =  verilog_random(); // Random seed for d[0]
                d[1] =  verilog_random(); // Random seed for d[1]
                d[2] =  verilog_random(); // Random seed for d[2]
                d[3] =  verilog_random(); // Random seed for d[3]

                z[0] =  verilog_random(); // Random seed for z[0]
                z[1] =  verilog_random(); // Random seed for z[1]
                z[2] =  verilog_random(); // Random seed for z[2]
                z[3] =  verilog_random(); // Random seed for z[3]
            }
            else {
                d[0] = 0x519d62010a40b41e;
                d[1] = 0xf5deb985cde27479;
                d[2] = 0x2b9c6f8e50de8290;
                d[3] = 0xca555996121e340e;

                z[0] = 0xfe0338161141391a;
                z[1] = 0x7586a635c319852e;
                z[2] = 0x5f2ba2afad8e3356;
                z[3] = 0x93d6cc60054357c5;
            }
        
            m[0] = 0x72407c18ae6c9baf;
            m[1] = 0x1070e33b3f9dfc56;
            m[2] = 0x28a187e6d055afff;
            m[3] = 0xd38468eb627f7cf1;

        // --- Encaps --- // Depency on m
        #elif(OPERATION == 1)
            if(sel_random) {
                m[0] =  verilog_random(); // Random seed for m[0]
                m[1] =  verilog_random(); // Random seed for m[1]
                m[2] =  verilog_random(); // Random seed for m[2]
                m[3] =  verilog_random(); // Random seed for m[3]
            }
            else {
                m[0] = 0x72407c18ae6c9baf;
                m[1] = 0x1070e33b3f9dfc56;
                m[2] = 0x28a187e6d055afff;
                m[3] = 0xd38468eb627f7cf1;
            }
        
            d[0] = 0x519d62010a40b41e;
            d[1] = 0xf5deb985cde27479;
            d[2] = 0x2b9c6f8e50de8290;
            d[3] = 0xca555996121e340e;

            z[0] = 0xfe0338161141391a;
            z[1] = 0x7586a635c319852e;
            z[2] = 0x5f2ba2afad8e3356;
            z[3] = 0x93d6cc60054357c5;

        #elif(OPERATION == 2)

            

        #endif

    #else
    if(sel_random) {
        
        d[0] =  verilog_random(); // Random seed for d[0]
        d[1] =  verilog_random(); // Random seed for d[1]
        d[2] =  verilog_random(); // Random seed for d[2]
        d[3] =  verilog_random(); // Random seed for d[3]

        m[0] =  verilog_random(); // Random seed for m[0]
        m[1] =  verilog_random(); // Random seed for m[1]
        m[2] =  verilog_random(); // Random seed for m[2]
        m[3] =  verilog_random(); // Random seed for m[3]

        z[0] =  verilog_random(); // Random seed for z[0]
        z[1] =  verilog_random(); // Random seed for z[1]
        z[2] =  verilog_random(); // Random seed for z[2]
        z[3] =  verilog_random(); // Random seed for z[3]

    }
    else {
        d[0] = 0x519d62010a40b41e;
	    d[1] = 0xf5deb985cde27479;
	    d[2] = 0x2b9c6f8e50de8290;
	    d[3] = 0xca555996121e340e;

        m[0] = 0x72407c18ae6c9baf;
	    m[1] = 0x1070e33b3f9dfc56;
	    m[2] = 0x28a187e6d055afff;
	    m[3] = 0xd38468eb627f7cf1;

        z[0] = 0xfe0338161141391a;
	    z[1] = 0x7586a635c319852e;
	    z[2] = 0x5f2ba2afad8e3356;
	    z[3] = 0x93d6cc60054357c5;
    }
    #endif
}

static void test(Vsim* dut, Vtrace *m_trace, uint8_t K, uint8_t masked, uint8_t sel_random, uint8_t verb, uint8_t verb_random) {

    cc_key      = 0;
    cc_encap    = 0;
    cc_decap    = 0;

    unsigned int i;
    unsigned int off;
    uint8_t ek_array[1568];
    uint8_t dk_array[3168];
    uint8_t ct_array[1568];
    uint8_t ss_array[32];
    uint8_t ss2_array[32];

    // Initialize seed arrays
    unsigned long long int d[4];
    unsigned long long int m[4];  
    unsigned long long int z[4];

    gen_seed(d, m, z, sel_random);

    if(verb_random) {
        printf("Random seed values:\n");
        printf("d[0] = 0x%016llx\n", d[0]);
        printf("d[1] = 0x%016llx\n", d[1]);
        printf("d[2] = 0x%016llx\n", d[2]);
        printf("d[3] = 0x%016llx\n", d[3]);
        printf("m[0] = 0x%016llx\n", m[0]);
        printf("m[1] = 0x%016llx\n", m[1]);
        printf("m[2] = 0x%016llx\n", m[2]);
        printf("m[3] = 0x%016llx\n", m[3]);
        printf("z[0] = 0x%016llx\n", z[0]);
        printf("z[1] = 0x%016llx\n", z[1]);
        printf("z[2] = 0x%016llx\n", z[2]);
        printf("z[3] = 0x%016llx\n", z[3]);
    }

    uint32_t mode;
    uint32_t LEN_EK;
    uint32_t LEN_DK;
    uint32_t LEN_CT;

    if(K == 2) mode = GEN_KEYS_512;
    if(K == 3) mode = GEN_KEYS_768;
    if(K == 4) mode = GEN_KEYS_1024;
            
    if(K == 2) LEN_EK = 800 - 32;
    if(K == 3) LEN_EK = 1184 - 32;
    if(K == 4) LEN_EK = 1568 - 32;
            
    if(K == 2) LEN_DK = 1632 - LEN_EK - 32 - 32 - 32; // rho, H(ek), z
    if(K == 3) LEN_DK = 2400 - LEN_EK - 32 - 32 - 32;
    if(K == 4) LEN_DK = 3168 - LEN_EK - 32 - 32 - 32;

    if(K == 2) LEN_CT = 768;
    if(K == 3) LEN_CT = 1088;
    if(K == 4) LEN_CT = 1568;

    // RESET MODULE
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "RESET: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES * 10, dut, m_trace);

    // ----------------- //
    // ---- Key Gen ---- //
    // ----------------- //

    // ---- LOAD D ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_R0);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD D: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace);

    if(masked) verilog_delay(1000 * CYCLES, dut, m_trace); // Setting up internal DRBG

    for (i = 0; i < 4; i = i + 1) {
        dut->add 	    = i;        verilog_delay(CYCLES, dut, m_trace);
        dut->data_in 	= d[i];     verilog_delay(CYCLES, dut, m_trace);
    }

     #if defined(TRACES)
        if(OPERATION == 0)  op_trace = 1;
        else                op_trace = 0;
    #endif

    // ---- START ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | START);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 4) verilog_display(false, "START: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace);

    while(!(dut->end_op & 0x01)) {
        if(verb >= 4) verilog_display(false, "0x%016llx\n", dut->end_op);
        verilog_delay(1, dut, m_trace);

        if(dut->flag_op) cc_key++;
    }

    verilog_delay(CYCLES * 10, dut, m_trace);

    // ---- READ EK ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_EK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);
    for (i = 0; i < LEN_EK / 8; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                             
        ek_array[8*i + 0] = (dut->data_out & 0x00000000000000FF);     
        ek_array[8*i + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        ek_array[8*i + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;      
        ek_array[8*i + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        ek_array[8*i + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        ek_array[8*i + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;  
        ek_array[8*i + 6] = (dut->data_out & 0x00FF000000000000) >> 48;      
        ek_array[8*i + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        off = LEN_DK / 8;
        dk_array[8*(off+i) + 0] = (dut->data_out & 0x00000000000000FF);    
        dk_array[8*(off+i) + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        dk_array[8*(off+i) + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;      
        dk_array[8*(off+i) + 3] = (dut->data_out & 0x00000000FF000000) >> 24;         
        dk_array[8*(off+i) + 4] = (dut->data_out & 0x000000FF00000000) >> 32;      
        dk_array[8*(off+i) + 5] = (dut->data_out & 0x0000FF0000000000) >> 40; 
        dk_array[8*(off+i) + 6] = (dut->data_out & 0x00FF000000000000) >> 48;      
        dk_array[8*(off+i) + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }
    // READ_EK (RHO)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_R0);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);

    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                
        ek_array[8*(LEN_EK/8 + i) + 0] = (dut->data_out & 0x00000000000000FF);     
        ek_array[8*(LEN_EK/8 + i) + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        ek_array[8*(LEN_EK/8 + i) + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        ek_array[8*(LEN_EK/8 + i) + 3] = (dut->data_out & 0x00000000FF000000) >> 24;       
        ek_array[8*(LEN_EK/8 + i) + 4] = (dut->data_out & 0x000000FF00000000) >> 32;    
        ek_array[8*(LEN_EK/8 + i) + 5] = (dut->data_out & 0x0000FF0000000000) >> 40; 
        ek_array[8*(LEN_EK/8 + i) + 6] = (dut->data_out & 0x00FF000000000000) >> 48;    
        ek_array[8*(LEN_EK/8 + i) + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        off = (LEN_DK + LEN_EK) / 8;
        dk_array[8*(off + i) + 0] = (dut->data_out & 0x00000000000000FF);     
        dk_array[8*(off + i) + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        dk_array[8*(off + i) + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        dk_array[8*(off + i) + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        dk_array[8*(off + i) + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        dk_array[8*(off + i) + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        dk_array[8*(off + i) + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        dk_array[8*(off + i) + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }
            
            
    // ---- READ DK ---- //
    // READ_DK (DK_PKE)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_DK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace); 
    
    for (i = 0; i < (LEN_DK / 8); i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        dk_array[8*i + 0] = (dut->data_out & 0x00000000000000FF);     
        dk_array[8*i + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        dk_array[8*i + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        dk_array[8*i + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        dk_array[8*i + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        dk_array[8*i + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        dk_array[8*i + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        dk_array[8*i + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }

    // READ_DK (HEK)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_HEK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace); 
    
    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace); 
        off = (LEN_DK + LEN_EK + 32) / 8;                                                                 
        dk_array[8*(off + i) + 0] = (dut->data_out & 0x00000000000000FF);     
        dk_array[8*(off + i) + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        dk_array[8*(off + i) + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        dk_array[8*(off + i) + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        dk_array[8*(off + i) + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        dk_array[8*(off + i) + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        dk_array[8*(off + i) + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        dk_array[8*(off + i) + 7] = (dut->data_out & 0xFF00000000000000) >> 56;
        
        verilog_delay(CYCLES, dut, m_trace);
    }

    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace); 
        off = (LEN_DK + LEN_EK + 32 + 32) / 8;                                                                 
        dk_array[8*(off + i) + 0] = (z[i] & 0x00000000000000FF);     
        dk_array[8*(off + i) + 1] = (z[i] & 0x000000000000FF00) >> 8; 
        dk_array[8*(off + i) + 2] = (z[i] & 0x0000000000FF0000) >> 16;     
        dk_array[8*(off + i) + 3] = (z[i] & 0x00000000FF000000) >> 24;        
        dk_array[8*(off + i) + 4] = (z[i] & 0x000000FF00000000) >> 32;     
        dk_array[8*(off + i) + 5] = (z[i] & 0x0000FF0000000000) >> 40;
        dk_array[8*(off + i) + 6] = (z[i] & 0x00FF000000000000) >> 48;     
        dk_array[8*(off + i) + 7] = (z[i] & 0xFF00000000000000) >> 56;
        
        verilog_delay(CYCLES, dut, m_trace);
    }
            
    if(verb >= 2) {
        // ---- PRINT ek ---- //
        printf("\n\n ek: %d\n", LEN_EK);

        for (i = 0; i < (LEN_EK+32); i = i + 1) {
            // printf("\n ek[%d]: ", i);
            if(i % 32 == 0)  printf("\n");
            printf("%02x",ek_array[i]);
        }

        // ---- PRINT dk ---- //
        printf("\n\n dk: \n");
        for (i = 0; i < (LEN_DK+LEN_EK+32+32+32); i = i + 1) {
            if(i % 32 == 0)  printf("\n");
            printf("%02x",dk_array[i]);
        }

    }

    // ------------------------------------------------- //
    // ---- Encap ----- //
    // ---------------- //

    if(K == 2) mode = ENCAP_512;
    if(K == 3) mode = ENCAP_768;
    if(K == 4) mode = ENCAP_1024;

    // RESET MODULE
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "RESET: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES * 10, dut, m_trace);

    // LOAD_EK 
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_EK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_EK: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    if(masked) verilog_delay(1000 * CYCLES, dut, m_trace); // Setting up internal DRBG

    for (i = 0; i < ((LEN_EK) / 8); i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        dut->data_in     = (
                            ((unsigned long long)ek_array[8*i+7] << 56) | 
                            ((unsigned long long)ek_array[8*i+6] << 48) | 
                            ((unsigned long long)ek_array[8*i+5] << 40) | 
                            ((unsigned long long)ek_array[8*i+4] << 32) | 
                            ((unsigned long long)ek_array[8*i+3] << 24) | 
                            ((unsigned long long)ek_array[8*i+2] << 16) | 
                            ((unsigned long long)ek_array[8*i+1] << 8) | 
                            ((unsigned long long)ek_array[8*i+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }
    
    // LOAD_SEED
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_R0);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_SEED: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);      
        off   = 8*i + (LEN_EK);                                                            
        dut->data_in     =  (
                            ((unsigned long long)ek_array[off+7] << 56) | 
                            ((unsigned long long)ek_array[off+6] << 48) | 
                            ((unsigned long long)ek_array[off+5] << 40) | 
                            ((unsigned long long)ek_array[off+4] << 32) | 
                            ((unsigned long long)ek_array[off+3] << 24) | 
                            ((unsigned long long)ek_array[off+2] << 16) | 
                            ((unsigned long long)ek_array[off+1] << 8) | 
                            ((unsigned long long)ek_array[off+0] << 0)
                            );
        verilog_delay(CYCLES, dut, m_trace);
    }
        
    // LOAD_M
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_SS);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_M: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < 4; i = i + 1) {
        dut->add            = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                 
        dut->data_in        = m[i];
        verilog_delay(CYCLES, dut, m_trace);
    }

     #if defined(TRACES)
        if(OPERATION == 1)  op_trace = 1;
        else                op_trace = 0;
    #endif

    // ---- START ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | START);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "START: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace);

    
    while(!(dut->end_op & 0x01)) {
        if(verb >= 4) verilog_display(false, "0x%016llx\n", dut->end_op);
        verilog_delay(1, dut, m_trace);

        if(dut->flag_op) cc_encap++;
    }

    // ---- READ CT ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_CT);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);    

    for (i = 0; i < (LEN_CT / 8); i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        ct_array[8*i + 0] = (dut->data_out & 0x00000000000000FF);     
        ct_array[8*i + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        ct_array[8*i + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        ct_array[8*i + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        ct_array[8*i + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        ct_array[8*i + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        ct_array[8*i + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        ct_array[8*i + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }
  
    // ---- READ SS ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_SS);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);    

    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        ss_array[8*i + 0] = (dut->data_out & 0x00000000000000FF);     
        ss_array[8*i + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        ss_array[8*i + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        ss_array[8*i + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        ss_array[8*i + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        ss_array[8*i + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        ss_array[8*i + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        ss_array[8*i + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }
        
    if(verb >= 2) {
        // ---- PRINT CT ---- //
        printf("\n\n ct: \n");
        for (i = 0; i < (LEN_CT); i = i + 1) {
            if(i % 32 == 0)  printf("\n");
            printf("%02x",ct_array[i]);
        }
    }
    if(verb >= 1) {
        for (i = 0; i < 32; i = i + 1) {
            if(i % 32 == 0) printf("\n ss_ori: ");
            printf("%02x",ss_array[i]);
        }
    }


    // ------------------------------------------------- //
    // ---- Decap ----- //
    // ---------------- //

    #if defined(TRACES)
    memset(ct_array, 0x5A, sizeof(ct_array));
    #endif

    if(K == 2) mode = DECAP_512;
    if(K == 3) mode = DECAP_768;
    if(K == 4) mode = DECAP_1024;

    // RESET MODULE
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "RESET: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES * 10, dut, m_trace);

    // LOAD_DK (DK_PKE)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_DK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_DK: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    if(masked) verilog_delay(1000 * CYCLES, dut, m_trace); // Setting up internal DRBG    

    for (i = 0; i < ((LEN_DK) / 8); i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        dut->data_in     = (
                            ((unsigned long long)dk_array[8*i+7] << 56) | 
                            ((unsigned long long)dk_array[8*i+6] << 48) | 
                            ((unsigned long long)dk_array[8*i+5] << 40) | 
                            ((unsigned long long)dk_array[8*i+4] << 32) | 
                            ((unsigned long long)dk_array[8*i+3] << 24) | 
                            ((unsigned long long)dk_array[8*i+2] << 16) | 
                            ((unsigned long long)dk_array[8*i+1] << 8) | 
                            ((unsigned long long)dk_array[8*i+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

    // LOAD_EK (DK)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_EK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_EK: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < ((LEN_EK) / 8); i = i + 1) {
        dut->add        = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        off             = LEN_DK / 8;
        dut->data_in    = (
                            ((unsigned long long)dk_array[8*(off+i)+7] << 56) | 
                            ((unsigned long long)dk_array[8*(off+i)+6] << 48) | 
                            ((unsigned long long)dk_array[8*(off+i)+5] << 40) | 
                            ((unsigned long long)dk_array[8*(off+i)+4] << 32) | 
                            ((unsigned long long)dk_array[8*(off+i)+3] << 24) | 
                            ((unsigned long long)dk_array[8*(off+i)+2] << 16) | 
                            ((unsigned long long)dk_array[8*(off+i)+1] << 8) | 
                            ((unsigned long long)dk_array[8*(off+i)+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

    // LOAD_CT
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_CT);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_CT: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < ((LEN_CT) / 8); i = i + 1) {
        dut->add        = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        dut->data_in     = (
                            ((unsigned long long)ct_array[8*i+7] << 56) | 
                            ((unsigned long long)ct_array[8*i+6] << 48) | 
                            ((unsigned long long)ct_array[8*i+5] << 40) | 
                            ((unsigned long long)ct_array[8*i+4] << 32) | 
                            ((unsigned long long)ct_array[8*i+3] << 24) | 
                            ((unsigned long long)ct_array[8*i+2] << 16) | 
                            ((unsigned long long)ct_array[8*i+1] << 8) | 
                            ((unsigned long long)ct_array[8*i+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

    // LOAD_SEED (DK)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_R0);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_R0: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < 4; i = i + 1) {
        dut->add        = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        off             = (LEN_DK+LEN_EK) / 8;
        dut->data_in    = (
                            ((unsigned long long)dk_array[8*(off+i)+7] << 56) | 
                            ((unsigned long long)dk_array[8*(off+i)+6] << 48) | 
                            ((unsigned long long)dk_array[8*(off+i)+5] << 40) | 
                            ((unsigned long long)dk_array[8*(off+i)+4] << 32) | 
                            ((unsigned long long)dk_array[8*(off+i)+3] << 24) | 
                            ((unsigned long long)dk_array[8*(off+i)+2] << 16) | 
                            ((unsigned long long)dk_array[8*(off+i)+1] << 8) | 
                            ((unsigned long long)dk_array[8*(off+i)+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

    // LOAD_HEK (DK)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_HEK);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_HEK: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < 4; i = i + 1) {
        dut->add        = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        off             = (LEN_DK+LEN_EK+32) / 8;
        dut->data_in    = (
                            ((unsigned long long)dk_array[8*(off+i)+7] << 56) | 
                            ((unsigned long long)dk_array[8*(off+i)+6] << 48) | 
                            ((unsigned long long)dk_array[8*(off+i)+5] << 40) | 
                            ((unsigned long long)dk_array[8*(off+i)+4] << 32) | 
                            ((unsigned long long)dk_array[8*(off+i)+3] << 24) | 
                            ((unsigned long long)dk_array[8*(off+i)+2] << 16) | 
                            ((unsigned long long)dk_array[8*(off+i)+1] << 8) | 
                            ((unsigned long long)dk_array[8*(off+i)+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

    // LOAD_Z (DK)
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | LOAD_R1);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "LOAD_R1: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace); 

    for (i = 0; i < 4; i = i + 1) {
        dut->add        = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        off             = (LEN_DK+LEN_EK+32+32) / 8;
        dut->data_in    = (
                            ((unsigned long long)dk_array[8*(off+i)+7] << 56) | 
                            ((unsigned long long)dk_array[8*(off+i)+6] << 48) | 
                            ((unsigned long long)dk_array[8*(off+i)+5] << 40) | 
                            ((unsigned long long)dk_array[8*(off+i)+4] << 32) | 
                            ((unsigned long long)dk_array[8*(off+i)+3] << 24) | 
                            ((unsigned long long)dk_array[8*(off+i)+2] << 16) | 
                            ((unsigned long long)dk_array[8*(off+i)+1] << 8) | 
                            ((unsigned long long)dk_array[8*(off+i)+0] << 0)
                            );
        if(verb >= 4) printf("\n data_in[%d]: 0x%08lx\n", i, dut->data_in);
        verilog_delay(CYCLES, dut, m_trace);
    }

     #if defined(TRACES)
        if(OPERATION == 2)  op_trace = 1;
        else                op_trace = 0;
    #endif

    // ---- START ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | START);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(verb >= 3) verilog_display(false, "START: 0x%08llx\n", dut->control);
    verilog_delay(CYCLES, dut, m_trace);

    while(!(dut->end_op & 0x01)) {
        if(verb >= 4) verilog_display(false, "0x%016llx\n", dut->end_op);
        verilog_delay(1, dut, m_trace);

        if(dut->flag_op) cc_decap++;
    }

    // ---- READ SS ---- //
    dut->rst 	    = 1; // rst off
    dut->control 	= (mode << 4 | READ_SS);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);    

    for (i = 0; i < 4; i = i + 1) {
        dut->add          = i;                      verilog_delay(CYCLES, dut, m_trace);                                                                  
        ss2_array[8*i + 0] = (dut->data_out & 0x00000000000000FF);     
        ss2_array[8*i + 1] = (dut->data_out & 0x000000000000FF00) >> 8; 
        ss2_array[8*i + 2] = (dut->data_out & 0x0000000000FF0000) >> 16;     
        ss2_array[8*i + 3] = (dut->data_out & 0x00000000FF000000) >> 24;        
        ss2_array[8*i + 4] = (dut->data_out & 0x000000FF00000000) >> 32;     
        ss2_array[8*i + 5] = (dut->data_out & 0x0000FF0000000000) >> 40;
        ss2_array[8*i + 6] = (dut->data_out & 0x00FF000000000000) >> 48;     
        ss2_array[8*i + 7] = (dut->data_out & 0xFF00000000000000) >> 56; 
        
        verilog_delay(CYCLES, dut, m_trace);
    }

    // ---- PRINT SS ---- //
    unsigned int comp = 0; 
    for (i = 0; i < 32; i = i + 1) {
            if(ss_array[i] != ss2_array[i]) comp = 1; 
    }
        
    if(verb >= 1) {
        for (i = 0; i < 32; i = i + 1) {
            if(i % 32 == 0) printf("\n ss_rec: ");
            printf("%02x",ss2_array[i]);
        }
    }

    /* if(comp) printf("\t COMP: FAIL");
    else     printf("\t COMP: OK");
    
    if(dut->end_op == 0x01) printf("\t RESULT: FAIL");
    else printf("\t RESULT: OK"); */

    if(dut->end_op == 0x01){
        printf("FAILED TEST:\n");
        printf("d64[0] = 0x%016llx\n", d[0]);
        printf("d64[1] = 0x%016llx\n", d[1]);
        printf("d64[2] = 0x%016llx\n", d[2]);
        printf("d64[3] = 0x%016llx\n", d[3]);
        printf("m64[0] = 0x%016llx\n", m[0]);
        printf("m64[1] = 0x%016llx\n", m[1]);
        printf("m64[2] = 0x%016llx\n", m[2]);
        printf("m64[3] = 0x%016llx\n", m[3]);
        printf("z64[0] = 0x%016llx\n", z[0]);
        printf("z64[1] = 0x%016llx\n", z[1]);
        printf("z64[2] = 0x%016llx\n", z[2]);
        printf("z64[3] = 0x%016llx\n", z[3]);
        printf("d_array[0] = 64'h%016llx;\n", d[0]);
        printf("d_array[1] = 64'h%016llx;\n", d[1]);
        printf("d_array[2] = 64'h%016llx;\n", d[2]);
        printf("d_array[3] = 64'h%016llx;\n", d[3]);
        printf("m_array[0] = 64'h%016llx;\n", m[0]);
        printf("m_array[1] = 64'h%016llx;\n", m[1]);
        printf("m_array[2] = 64'h%016llx;\n", m[2]);
        printf("m_array[3] = 64'h%016llx;\n", m[3]);
        printf("z_array[0] = 64'h%016llx;\n", z[0]);
        printf("z_array[1] = 64'h%016llx;\n", z[1]);
        printf("z_array[2] = 64'h%016llx;\n", z[2]);
        printf("z_array[3] = 64'h%016llx;\n", z[3]);
    }
    else {
        PASS_TEST++;
    }

    /* if (verb != 0) printf("\n\n");
    else printf("\t PASS: %5d / %5d", PASS_TEST, TEST+1); */
}

//----------------------------------------------------------------------------------------------------
// Main testbench
//----------------------------------------------------------------------------------------------------
int main(int argc, char** argv, char** env) {

    int trace_index = 0;
    bool is_random  = false;

    for (int i = 1; i < argc; i++) 
    {
        std::string arg = argv[i];
        if (arg == "--trace_index") 
        {
            if (i + 1 < argc) 
            {
                trace_index = std::atoi(argv[++i]);
                if (trace_index < 0) 
                {
                    std::cerr << "Error: trace_index must be a non-negative integer" << std::endl;
                    exit(EXIT_FAILURE);
                }
            } 
            else 
            {
                std::cerr << "Error: --trace_index requires a value" << std::endl;
                exit(EXIT_FAILURE);
            }
        } 
        else if (arg == "--trace_random") 
        {
            is_random = true;
        }
        else 
        {
            std::cerr << "Error: Unknown argument " << arg << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    //------------------------------------------------------------------------------------------------
    // Initial Configuration
    //------------------------------------------------------------------------------------------------

    // Construct design object, and trace object
	Vsim *dut       = new Vsim;         // Design Top Module
    Vtrace *m_trace = new Vtrace;       // Trace

    // Trace configuration
    if (TRACE_SIGNALS)
    {
        Verilated::traceEverOn(true);     			                // Turn on trace switch in context
        dut->trace(m_trace, DEPTH_LEVELS);        		            // Set depth levels of the trace
        
        char waveform_file[256];
        char index[32];
        dec_2_char(trace_index, index);
        
        strcpy(waveform_file, "sim/waveform");
        #if defined(WAVEFORM_TYPE_VCD)
            strcat(waveform_file, "_");
            strcat(waveform_file, (const char*) index);
        #endif
        strcat(waveform_file, (const char*) WAVEFORM_EXTENSION);

        m_trace->open((const char*) waveform_file); 		        // Open the Waveform file to store data
    }

    //------------------------------------------------------------------------------------------------
    // Test Values
    //------------------------------------------------------------------------------------------------
 
    Verilated::randSeed(verilog_random());

    // verilog_display(true, "\n\nStarting simulation...\n");

    // INIT MODULE
    dut->rst 	    = 1; // rst off
    dut->control 	= (0x00 << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);

    // RESET MODULE
    dut->rst 	    = 0; // rst on
    dut->control 	= (0x00 << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    if(MASKED) verilog_delay(1000 * CYCLES, dut, m_trace); // RESET FOR MASKING SEED

    // INIT OPERATION
    dut->rst 	    = 1; // rst off
    dut->control 	= (0x00 << 4 | RESET);
    dut->add 	    = 0;
    dut->data_in 	= 0;
    verilog_delay(CYCLES, dut, m_trace);

    #if defined(TRACES)

    test(dut, m_trace, K_MLKEM, MASKED, is_random, 0, 0); // Call the test function with K=2, sel_random=0, verb=2, verb_random=0

    #else
    
    // Test k = 2;
    PASS_TEST = 0;
    for (TEST = 0; TEST < N_TEST; TEST++) {
        if(MASKED)  printf("\n Test %5d with K = %d MASKED \t", TEST + 1, 2);
        else        printf("\n Test %5d with K = %d NON-MASKED \t", TEST + 1, 2);
        test(dut, m_trace, 2, MASKED, 1, 0, 0); // Call the test function with K=2, sel_random=0, verb=2, verb_random=0
        printf("\t CC_KeyGen: %5d \t CC_Encap: %5d \t CC_Decap: %5d", cc_key, cc_encap, cc_decap);
    }
    
    // Test k = 3;
    PASS_TEST = 0;
    for (TEST = 0; TEST < N_TEST; TEST++) {
        if(MASKED)  printf("\n Test %5d with K = %d MASKED \t", TEST + 1, 3);
        else        printf("\n Test %5d with K = %d NON-MASKED \t", TEST + 1, 3);
        test(dut, m_trace, 3, MASKED, 1, 0, 0); // Call the test function with K=3, sel_random=0, verb=2, verb_random=0
        printf("\t CC_KeyGen: %5d \t CC_Encap: %5d \t CC_Decap: %5d", cc_key, cc_encap, cc_decap);
    }

    // Test k = 4;
    PASS_TEST = 0;
    for (TEST = 0; TEST < N_TEST; TEST++) {
        if(MASKED)  printf("\n Test %5d with K = %d MASKED \t", TEST + 1, 4);
        else        printf("\n Test %5d with K = %d NON-MASKED \t", TEST + 1, 4);
        test(dut, m_trace, 4, MASKED, 1, 0, 0); // Call the test function with K=4, sel_random=0, verb=2, verb_random=0
        printf("\t CC_KeyGen: %5d \t CC_Encap: %5d \t CC_Decap: %5d", cc_key, cc_encap, cc_decap);
    }

    #endif
    

    printf("\n\n");



    //------------------------------------------------------------------------------------------------
    // End Simulation
    //------------------------------------------------------------------------------------------------

    // Remember to close the trace object to save data in the file
    if (TRACE_SIGNALS) m_trace->close();

    // Free memory
    delete dut;
    delete m_trace;
    exit(EXIT_SUCCESS);
}
