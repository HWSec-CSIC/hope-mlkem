# ============================================================================
# HWSEC-OSS OpenSTA Timing Analysis Script (V5 - Full Tcl Flow)
# ============================================================================

# --- 1. Read Configuration from Environment Variables ---
puts "--- Reading Configuration from Environment ---"
set LIBERTY_FILE            $::env(LIBERTY_FILE)
set SDF_FILE                $::env(SDF_FILE)
set NETLIST                 $::env(NETLIST)
set TOP_MODULE              $::env(TOP_MODULE)
set REPORT_DIR              $::env(REPORT_DIR)
set PATH_COUNT              $::env(PATH_COUNT)
set CLOCK_SIGNAL            $::env(CLOCK_SIGNAL)
set RESET_SIGNAL            $::env(RESET_SIGNAL)
set CLOCK_PERIOD_NS         $::env(CLOCK_PERIOD_NS)
set CLOCK_UNCERTAINTY_NS    $::env(CLOCK_UNCERTAINTY_NS)
set CLOCK_LATENCY_NS        $::env(CLOCK_LATENCY_NS)
set OUTPUT_LOAD             $::env(OUTPUT_LOAD)
set IO_DELAY_NS             $::env(IO_DELAY_NS)
set DRIVING_CELL            $::env(DRIVING_CELL)

# ============================================================================
# Reusable Procedures
# ============================================================================

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

proc setup_path_groups { path_group_list_name } {
  upvar $path_group_list_name path_group_list
  global CLOCK_SIGNAL RESET_SIGNAL

  puts "INFO: Setting up path groups automatically..."

  # --- Get all port and register collections ---
  set all_ports_in  [all_inputs]
  set all_ports_out [all_outputs]
  set regs_from     [all_registers -edge_triggered -clock_pins]
  set regs_to       [all_registers -edge_triggered -data_pins]

  # --- Create a clean, filtered list of PURE data inputs ---
  set clk_port [get_ports [list $CLOCK_SIGNAL]]
  set rst_port [get_ports [list $RESET_SIGNAL]]
  set data_ports_in [list]
  foreach port $all_ports_in {
    if { $port != $clk_port && $port != $rst_port } {
      lappend data_ports_in $port
    }
  }

  # --- Define Path Groups CONDITIONALLY to avoid errors on empty groups ---

  # Only create reg2reg group if there are registers in the design
  if { [llength $regs_from] > 0 && [llength $regs_to] > 0 } {
    puts "INFO: Found register to register paths. Creating 'reg2reg' group."
    group_path -name reg2reg -from $regs_from -to $regs_to
    lappend path_group_list reg2reg
  } else {
    puts "INFO: No register to register paths found. Skipping 'reg2reg' group."
  }

  # Only create in2reg group if there are data inputs AND registers
  if { [llength $data_ports_in] > 0 && [llength $regs_to] > 0 } {
    puts "INFO: Found input to register paths. Creating 'in2reg' group."
    group_path -name in2reg -from $data_ports_in -to $regs_to
    lappend path_group_list in2reg
  } else {
    puts "INFO: No input to register paths found. Skipping 'in2reg' group."
  }

  # Only create reg2out group if there are registers AND outputs
  if { [llength $regs_from] > 0 && [llength $all_ports_out] > 0 } {
    puts "INFO: Found register to output paths. Creating 'reg2out' group."
    group_path -name reg2out -from $regs_from -to $all_ports_out
    lappend path_group_list reg2out
  } else {
    puts "INFO: No register to output paths found. Skipping 'reg2out' group."
  }

  # Only create in2out group if there are data inputs AND outputs (purely combinational paths)
  if { [llength $data_ports_in] > 0 && [llength $all_ports_out] > 0 } {
    puts "INFO: Found input to output paths. Creating 'in2out' group."
    group_path -name in2out -from $data_ports_in -to $all_ports_out
    lappend path_group_list in2out
  } else {
    puts "INFO: No input to output paths found. Skipping 'in2out' group."
  }
}

proc generate_reports { group report_base_name path_count } {
  puts "  -> Reporting for group '$group'..."
  set rpt_file "${report_base_name}.rpt"
  set csv_file "${report_base_name}.csv"
  report_checks -path_delay max -path_group $group -group_path_count $path_count -digits 4 > $rpt_file
  set paths [find_timing_paths -path_group $group -group_path_count $path_count]
  set csv_out [open $csv_file "w"]
  foreach path $paths {
    set startpoint [get_property [get_property $path startpoint] full_name]
    set endpoint   [get_property [get_property $path endpoint]   full_name]
    set slack      [get_property $path slack]
    puts $csv_out [format "%s,%s,%.4f" $startpoint $endpoint $slack]
  }
  close $csv_out
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
# No need to read an SDC file anymore.
apply_constraints

# --- 4. Setup Path Groups ---
set path_groups [list]
setup_path_groups path_groups

# --- 5. Generate Reports ---
puts "INFO: Generating timing reports in: $REPORT_DIR"
report_checks -path_delay max -digits 4 > "$REPORT_DIR/timing_summary.rpt"
foreach group $path_groups {
    set group_dir "$REPORT_DIR/$group"
    file mkdir $group_dir
    set rpt_base_name "$group_dir/timing"
    generate_reports $group $rpt_base_name $PATH_COUNT
}

puts "INFO: Writing estimated delays to SDF file: $SDF_FILE"
# Note: You may need to specify a corner if you have multiple in your .lib
write_sdf -include_typ $SDF_FILE

puts "STA Complete. Reports generated."
exit