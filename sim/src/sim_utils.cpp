#include "sim_utils.h"
#include <cstring>

unsigned int op_trace = 0; // Select the operation to trace

//----------------------------------------------------------------------------------------------------
// Global Simulation Time Definition
//----------------------------------------------------------------------------------------------------
vluint64_t sim_time = 0;

//------------------------------------------------------------------------------
// Clears the progress bar line using ANSI escape codes.
//------------------------------------------------------------------------------
void clear_progress_bar() {
    // "\r\33[2K\r" returns to the beginning, clears the line, and resets the cursor.
    printf("\r\33[2K\r");
    fflush(stdout);
}

//------------------------------------------------------------------------------
// update_progress_bar()
//    Computes and displays an interactive progress bar on the same console line.
//------------------------------------------------------------------------------
void update_progress_bar() {
    // Total simulation time (same units as sim_time)
    const vluint64_t TOTAL_SIM = 2 * HALF_CYCLE * MAX_SIM_TIME;
    // Update interval: every 1% of TOTAL_SIM.
    const vluint64_t UPDATE_INTERVAL = TOTAL_SIM / 100;
    
    // Static variable to hold the next simulation time at which to update.
    static vluint64_t next_update = UPDATE_INTERVAL;
    // Static flag so that after finishing we don't update anymore.
    static bool progressActive = true;

    // If the progress bar is done, do nothing.
    if (!progressActive)
        return;
    
    // When the simulation time has reached (or passed) the next threshold:
    if (sim_time >= next_update) {
        double progress = (double)sim_time * 100.0 / TOTAL_SIM;
        const int barWidth = 50; 
        int pos = (int)(progress / 100.0 * barWidth);

        // If we are at or above 100%, it’s time to clear the progress bar.
        if (progress >= 100.0) {
            // Clear the progress line and move to a new line.
            clear_progress_bar();
            progressActive = false;  // Disable further progress updates.
            // (Optionally, you could print a final message here.)
            return;
        }
        
        // Otherwise, print an interactive progress bar on the same line:
        printf("\r[");
        for (int i = 0; i < barWidth; ++i) {
            if (i < pos)
                printf("=");
            else if (i == pos)
                printf(">");
            else
                printf(" ");
        }
        printf("] %6.2f%%", progress);
        fflush(stdout);

        // Set the next update threshold.
        next_update += UPDATE_INTERVAL;
    }
}

//----------------------------------------------------------------------------------------------------
// Get a single character Function
//----------------------------------------------------------------------------------------------------
int getch(void) {
    struct termios oldt, newt;
    int ch;

    // Get current terminal attributes
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    // Disable canonical mode and echo
    newt.c_lflag &= ~(ICANON | ECHO);
    // Disable CR-to-NL conversion: don't map carriage return to newline on input
    newt.c_iflag &= ~(ICRNL);
    // Set VMIN and VTIME so that exactly one character is read immediately.
    newt.c_cc[VMIN] = 1;
    newt.c_cc[VTIME] = 0;
    
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    ch = getchar();
    // Restore original terminal settings
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    return ch;
}

//----------------------------------------------------------------------------------------------------
// Verilog-like $display function.
// The boolean argument determines whether to print the simulation time.
//----------------------------------------------------------------------------------------------------
void verilog_display(bool prepend_time, const char* format, ...) {
    // Clear the progress bar before printing a new message.
    clear_progress_bar();
    
    va_list args;
    va_start(args, format);
    if (prepend_time) {
        printf("[t = %lu ns] ", sim_time / (2*HALF_CYCLE));
    }
    vprintf(format, args);
    printf("\n");
    va_end(args);
}

//----------------------------------------------------------------------------------------------------
// Verilog $monitor equivalent function
//----------------------------------------------------------------------------------------------------
// A simple monitor function that checks if a signal's current value differs
// from the stored value. If so, it prints the change and updates the stored value.
// The 'format' string is used to print the value—for example, you can pass "out = %x".
void verilog_monitor(const char* format, int current_value, int* last_value) {
    if (current_value != *last_value) {
        verilog_display(true, format, current_value);
        *last_value = current_value;
    }
}
// Define the variables to monitorize
// int monitor_leds = 0;

//----------------------------------------------------------------------------------------------------
// Single simulation step: toggle clk, evaluate DUT, dump FST trace,
// and advance simulation time by one half cycle
//----------------------------------------------------------------------------------------------------
void sim_step(Vsim* dut, Vtrace* m_trace) {
    // Toggle clock.
    dut->CLOCK_SIGNAL = !dut->CLOCK_SIGNAL;
    // Evaluate the design model
    dut->eval();

    static bool is_trigger_1 = false;
    static bool is_trigger_2 = false;

    #if defined(TRACES)
    if ((dut->flag_op) == 1 && op_trace)
    {
        is_trigger_1 = true;
    }

    if (is_trigger_1 && (dut->flag_op == 0))
    {
        is_trigger_1 = false;
        is_trigger_2 = true;
    }
    #else
    is_trigger_1 = false; // Always trigger for non-trace simulations
    is_trigger_2 = false; // Always trigger for non-trace simulations
    #endif

    // Dump simulation data for VCD/FST trace (if needed)
    if (TRACE_SIGNALS && ((sim_time / 10) >= INIT_TIME_TRACES) && is_trigger_1) 
    {
        m_trace->dump(sim_time);
    }
    else if ((TRACE_SIGNALS && ((sim_time / 10) >= END_TIME_TRACES)) || is_trigger_2) 
    {
        m_trace->close();
        delete dut;
        delete m_trace;
        
        exit(0);
    }
    // Check monitored signals
    // verilog_monitor("leds = %d", dut->leds, &monitor_leds);
    // Increase simulation time by the half cycle.
    sim_time += HALF_CYCLE;
    // Call the progress bar update function.
    // update_progress_bar();
}

//----------------------------------------------------------------------------------------------------
// Verilog Delay (#) equivalent function
//----------------------------------------------------------------------------------------------------
void verilog_delay(vluint64_t delay, Vsim* dut, Vtrace* m_trace) { 
    // Calculate target time.
    vluint64_t target_time = sim_time + 2 * HALF_CYCLE * delay - HALF_CYCLE;
    // Prevent overflow (simulation time exceeded allowed MAX_SIM_TIME).
    if (target_time > 2 * HALF_CYCLE * MAX_SIM_TIME) {
        std::cout << "\nERROR! MAX_SIM_TIME was reached.\nsim_time = " << sim_time 
                  << "\ntarget_time = " << target_time << "\nEnd of Simulation...\n";
        
        // Remember to close the trace object to save data in the file
        if (TRACE_SIGNALS) m_trace->close();
        // Free memory
        delete dut;
        delete m_trace;
        exit(0);
    }
    // Simulate until the target time is reached.
    while (sim_time <= target_time && sim_time <= 2 * HALF_CYCLE * MAX_SIM_TIME) {
        sim_step(dut, m_trace);
    }
}

//----------------------------------------------------------------------------------------------------
// Int Decimal to Char array
//----------------------------------------------------------------------------------------------------

void dec_2_char(int dec, char* dec_char)
{
    int digits  = dec;
    int pos     = 0;

    char dec_char_inv[32];
    
    if (digits == 0)
    {
        dec_char[0] = 48;
        pos++;
        dec_char[pos] = '\0';
        return;
    }

    while (digits != 0)
    {
        dec_char_inv[pos] = (digits % 10) + 48;
        digits /= 10;
        pos++;
    }

    for (int i = 0; i < pos; i++)
    {
        dec_char[i] = dec_char_inv[pos-1-i];
    }

    dec_char[pos] = '\0';

    return;
}

//----------------------------------------------------------------------------------------------------
// Random Generation Function
//----------------------------------------------------------------------------------------------------
uint64_t verilog_random() {
    // The state is static, so it persists across function calls.
    // It's initialized to 0 only once by the C runtime.
    static uint64_t state = 0;

    // Seed the generator ONCE on the first call when state is 0.
    if (state == 0) {
        // Combine time and Process ID to create a unique seed for this run.
        #ifdef _WIN32
            state = (uint64_t)time(NULL) ^ ((uint64_t)_getpid() << 32);
        #else
            state = (uint64_t)time(NULL) ^ ((uint64_t)getpid() << 32);
        #endif
        // The xorshift algorithm requires a non-zero seed.
        if (state == 0) { state = 1; }
    }

    // A simple and fast xorshift64 pseudo-random number generator.
    uint64_t x = state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    state = x; // Update the state for the next call
    return state;
}