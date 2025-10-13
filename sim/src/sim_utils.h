#ifndef SIM_UTILS_H
#define SIM_UTILS_H
 
#include <cstdarg>
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <termios.h>
#include <unistd.h>
#include <string.h>
#include <cstring>
#include <cassert>

#include <verilated.h>

extern unsigned int op_trace; // Flag to the operation to trace

#define PASTE_IMPL(a, b) a##b
#define PASTE(a, b) PASTE_IMPL(a, b)

#if defined(TOP_HEADER) && defined(TOP_MODULE)
    #include TOP_HEADER
    // V<the_value_of_the_macro>, e.g., VLED_counter
    using Vsim = PASTE(V, TOP_MODULE);

#else
    #error "TOP_HEADER and/or TOP_MODULE_NAME not defined. Please check the Makefile."
#endif

#if defined(WAVEFORM_TYPE_FST)
    #include <verilated_fst_c.h>
    // Define VTrace as an alias for the FST tracer class
    using Vtrace = VerilatedFstC;
    #define WAVEFORM_EXTENSION ".fst"
    #define TRACE_SIGNALS       true
#elif defined(WAVEFORM_TYPE_VCD)
    #include <verilated_vcd_c.h>
    // Define VTrace as an alias for the VCD tracer class
    using Vtrace = VerilatedVcdC;
    #define WAVEFORM_EXTENSION ".vcd"
    #define TRACE_SIGNALS       true
#else
    #include <verilated_fst_c.h>
    using Vtrace = VerilatedFstC;
    #define WAVEFORM_EXTENSION ".fst"
    #define TRACE_SIGNALS       false
#endif

#ifndef CLOCK_SIGNAL
    #define CLOCK_SIGNAL clk
#endif


//----------------------------------------------------------------------------------------------------
// Waveform Configuration
//----------------------------------------------------------------------------------------------------
#define DEPTH_LEVELS    10

//----------------------------------------------------------------------------------------------------
// Clock Timing Parameters
//----------------------------------------------------------------------------------------------------
// Clock Frequency (in MHz)
#define CLOCK_FREQ      1000
// Clock Period (in ns)
#define CLOCK_PERIOD    (1000 / CLOCK_FREQ)
// Time precision is 100ps --> 10 time units is one clock cycle
#define HALF_CYCLE      5 * CLOCK_PERIOD
// Total simulation duration (in Clock Cycles)
// #define MAX_SIM_TIME    100

//----------------------------------------------------------------------------------------------------
// Global Simulation Time Declaration
//----------------------------------------------------------------------------------------------------
extern vluint64_t sim_time;

//----------------------------------------------------------------------------------------------------
// Verilog-like $display and $monitor Prototypes
//----------------------------------------------------------------------------------------------------
void verilog_display(bool prepend_time, const char* format, ...);
void verilog_monitor(const char* format, int current_value, int* last_value);

//----------------------------------------------------------------------------------------------------
// Get a Single Character
//----------------------------------------------------------------------------------------------------
int getch(void);

//----------------------------------------------------------------------------------------------------
// Simulation Control Prototypes
//----------------------------------------------------------------------------------------------------
void sim_step(Vsim* dut, Vtrace* m_trace);
void verilog_delay(vluint64_t delay, Vsim* dut, Vtrace* m_trace);

//----------------------------------------------------------------------------------------------------
// Progress Bar
//----------------------------------------------------------------------------------------------------
void clear_progress_bar();
void update_progress_bar();

//----------------------------------------------------------------------------------------------------
// Int Decimal to Char array
//----------------------------------------------------------------------------------------------------
void dec_2_char(int dec, char* dec_char);

//----------------------------------------------------------------------------------------------------
// Random Generation Function
//----------------------------------------------------------------------------------------------------
uint64_t verilog_random();


#endif // SIM_UTILS_H
