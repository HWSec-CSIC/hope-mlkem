# ============================================================================
# HWSEC-OSS OpenSTA VCD-BASED Power Analysis Script
# ============================================================================

# --- 1. Read Configuration from Environment ---
puts "--- Reading Configuration from Environment ---"
set LIBERTY_FILE            $::env(LIBERTY_FILE)
set NETLIST                 $::env(NETLIST)
set TOP_MODULE              $::env(TOP_MODULE)
set REPORT_FILE             $::env(REPORT_FILE)
set CLOCK_SIGNAL            $::env(CLOCK_SIGNAL)
set RESET_SIGNAL            $::env(RESET_SIGNAL)
set CLOCK_PERIOD_NS         $::env(CLOCK_PERIOD_NS)
set CLOCK_UNCERTAINTY_NS    $::env(CLOCK_UNCERTAINTY_NS)
set CLOCK_LATENCY_NS        $::env(CLOCK_LATENCY_NS)
set OUTPUT_LOAD             $::env(OUTPUT_LOAD)
set IO_DELAY_NS             $::env(IO_DELAY_NS)
set DRIVING_CELL            $::env(DRIVING_CELL)
# VCD-specific variables
set VCD_FILE                $::env(VCD_FILE)
set VCD_SCOPE               [format "%s.%s" $::env(VCD_TB_TOP) $::env(VCD_DUT_INSTANCE)]

# ============================================================================
# Reusable Procedures
# ============================================================================

# This procedure is identical to the one in your STA script.
# It defines the clock and sets up the I/O environment.
proc apply_constraints { } {
    global CLOCK_SIGNAL RESET_SIGNAL CLOCK_PERIOD_NS CLOCK_UNCERTAINTY_NS CLOCK_LATENCY_NS OUTPUT_LOAD IO_DELAY_NS DRIVING_CELL

    puts "INFO: Applying all SDC constraints procedurally..."

    # Step 1: Get Port Objects
    set all_ins  [all_inputs]
    set all_outs [all_outputs]
    set clk_port [get_ports [list $CLOCK_SIGNAL]]
    set rst_port [get_ports [list $RESET_SIGNAL]]

    # Step 2: Create the Clock
    puts "INFO: Creating clock '$CLOCK_SIGNAL' with period ${CLOCK_PERIOD_NS}ns..."
    create_clock -name $CLOCK_SIGNAL -period $CLOCK_PERIOD_NS $clk_port

    # Step 3: Get Clock Object and apply clock constraints
    set clk [get_clocks [list $CLOCK_SIGNAL]]
    if { $CLOCK_UNCERTAINTY_NS != "" } { set_clock_uncertainty $CLOCK_UNCERTAINTY_NS $clk }
    if { $CLOCK_LATENCY_NS != "" } { set_clock_latency $CLOCK_LATENCY_NS $clk }

    # Step 4: Filter Data Inputs
    set data_inputs [list]
    foreach port $all_ins {
        if { $port != $clk_port && $port != $rst_port } {
            lappend data_inputs $port
        }
    }

    # Step 5: Apply I/O Constraints
    puts "INFO: Applying I/O constraints..."
    if { [llength $data_inputs] > 0 } {
      set_driving_cell -lib_cell $DRIVING_CELL $data_inputs
      set_input_delay $IO_DELAY_NS -clock $clk $data_inputs
    }
    if { [llength $all_outs] > 0 } {
      set_load $OUTPUT_LOAD $all_outs
      set_output_delay $IO_DELAY_NS -clock $clk $all_outs
    }
}

# ============================================================================
# Main Script Execution
# ============================================================================

# --- 2. Load the Design ---
puts "INFO: Reading liberty file: $LIBERTY_FILE"
read_liberty $LIBERTY_FILE
puts "INFO: Reading netlist: $NETLIST"
read_verilog $NETLIST
puts "INFO: Linking design to top module: $TOP_MODULE"
link_design $TOP_MODULE

# --- 3. APPLY ALL CONSTRAINTS PROCEDURALLY ---
# This sets up the clock and I/O environment.
apply_constraints

# --- 4. Read the VCD for Switching Activity ---
# This is the key difference from the static script.
# Instead of setting default activities, we read them from the simulation.
puts "INFO: Reading VCD file: $VCD_FILE with scope: $VCD_SCOPE"
read_vcd -scope $VCD_SCOPE $VCD_FILE

# --- 5. Generate the Power Report ---
puts "INFO: Generating VCD-based power report to: $REPORT_FILE"
# The 'report_power' command will now use the switching counts from the VCD
# instead of relying on default propagation.
report_power > $REPORT_FILE

puts "VCD-based power analysis complete."
exit