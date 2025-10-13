# ============================================================================
# HWSEC-OSS OpenSTA STATIC Power Analysis Script
# Estimates power based on default activities, no VCD required.
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

proc apply_constraints { } {
    global CLOCK_SIGNAL RESET_SIGNAL CLOCK_PERIOD_NS CLOCK_UNCERTAINTY_NS CLOCK_LATENCY_NS OUTPUT_LOAD IO_DELAY_NS DRIVING_CELL

    puts "INFO: Applying all SDC constraints procedurally..."

    # --- Step 1: Get Port Objects ---
    set all_ins  [all_inputs]
    set all_outs [all_outputs]
    set clk_port [get_ports [list $CLOCK_SIGNAL]]
    set rst_port [get_ports [list $RESET_SIGNAL]]

    # --- Step 2: Create the Clock ---
    # The clock must be created before it can be referenced by other commands.
    puts "INFO: Creating clock '$CLOCK_SIGNAL' with period ${CLOCK_PERIOD_NS}ns..."
    create_clock -name $CLOCK_SIGNAL -period $CLOCK_PERIOD_NS $clk_port

    # --- Step 3: Get Clock Object (now that it exists) ---
    set clk [get_clocks [list $CLOCK_SIGNAL]]

    set_clock_uncertainty $CLOCK_UNCERTAINTY_NS $clk
    set_clock_latency $CLOCK_LATENCY_NS $clk

    # --- Step 4: Filter Data Inputs ---
    # Create a list of pure data inputs, excluding clk and rst
    set data_inputs [list]
    foreach port $all_ins {
        if { $port != $clk_port && $port != $rst_port } {
            lappend data_inputs $port
        }
    }

    # --- Step 5: Apply All Other Constraints ---
    puts "INFO: Applying I/O constraints..."
    puts "INFO: I/O Delay value: $IO_DELAY_NS ns"

    if { [llength $data_inputs] > 0} {
      set_driving_cell -lib_cell $DRIVING_CELL $data_inputs
    }
    set_load $OUTPUT_LOAD $all_outs
    set_input_delay $IO_DELAY_NS -clock $clk $data_inputs
    set_output_delay $IO_DELAY_NS -clock $clk $all_outs
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

apply_constraints

# --- 3. Set Switching Activity ---
puts "INFO: Setting default input activity..."
# Set activity for ALL inputs first. We will override specific ones next.
# An activity of 2.0 means two transitions per clock period (0->1 and 1->0),
# which is the maximum for a data signal. 0.1 to 0.2 is a more typical estimate.
set clk [get_clocks [list $CLOCK_SIGNAL]]

set_propagated_clock $clk
set_power_activity -input -activity 0.15

# Specifically set reset activity to 0, as it does not toggle during operation.
set rst_port [get_ports [list $RESET_SIGNAL]]
if { [llength $rst_port] > 0 } {
    puts "INFO: Setting reset port activity to 0."
    set_power_activity -input_port $rst_port -activity 0.0
}

# --- 4. Generate the Power Report ---
puts "INFO: Generating static power report to: $REPORT_FILE"
report_power > $REPORT_FILE

puts "Static power analysis complete."
exit