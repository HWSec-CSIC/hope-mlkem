# ============================================================================
# HWSEC-OSS Yosys Synthesis Script
# ============================================================================

# --- 1. Read Configuration from Environment Variables ---
puts "--- Reading Configuration from Environment ---"
set TOP_MODULE      $::env(TOP_MODULE)
# Trim whitespace from the file list variables before splitting
set RTL_FILES       [split [string trim $::env(RTL_FILES)]]
set LIBERTY_FILE    $::env(LIBERTY_FILE)
set PRE_MAP_NETLIST $::env(PRE_MAP_NETLIST)
set OUTPUT_NETLIST  $::env(OUTPUT_NETLIST)
set STA_NETLIST     $::env(STA_NETLIST)
set OUTPUT_REPORT   $::env(OUTPUT_REPORT)
set CLOCK_PERIOD_PS $::env(CLOCK_PERIOD_PS)
set FLATTEN         $::env(FLATTEN)
set TIMING_RUN      $::env(TIMING_RUN)
set SDC_FILE        $::env(SDC_FILE)
set TECHMAP_FILES   [split [string trim $::env(TECHMAP_FILES)]]

puts "--- Synthesis Starting ---"

yosys "read_liberty -lib $LIBERTY_FILE"

# --- 2. Read RTL and Perform High-Level Synthesis ---
# Each command passed to the Yosys engine is wrapped in yosys "..."
yosys "read_verilog -defer -sv $RTL_FILES"

if { $FLATTEN } { set flatten_opt "-flatten" } else { set flatten_opt "" }
yosys "synth $flatten_opt -top $TOP_MODULE"

yosys "opt -purge"
yosys "write_verilog $PRE_MAP_NETLIST"

# --- 3. Technology Mapping and Optimization ---
if { ![string equal [join $TECHMAP_FILES] ""] } {
    puts "INFO: Performing technology mapping..."
    foreach map_file $TECHMAP_FILES {
        puts "  -> Applying map file: $map_file"
        yosys "techmap -map $map_file"
    }
}

yosys "dfflibmap -liberty $LIBERTY_FILE"
yosys "opt"

if { $TIMING_RUN } {
    puts "INFO: Performing TIMING-DRIVEN synthesis (ABC)..."
    yosys "abc -liberty $LIBERTY_FILE -constr $SDC_FILE -D $CLOCK_PERIOD_PS"
} else {
    puts "INFO: Performing AREA-DRIVEN synthesis (ABC)..."
    yosys "abc -liberty $LIBERTY_FILE"
}

yosys "clean"

# --- 4. Validation and Main Output Generation ---

# Now, generate the primary outputs from this verified design.
puts "================================================="
puts "INFO: Generating Area and Cell Statistics Report..."
yosys "tee -o $OUTPUT_REPORT stat -liberty $LIBERTY_FILE"
puts "================================================="

puts "INFO: Saving final mapped netlist to: $OUTPUT_NETLIST"
yosys "write_verilog $OUTPUT_NETLIST"


# --- 5. Post-process to Generate STA-specific Netlist ---

# This is the final step. We modify the in-memory design for STA
# and write it out. We do not run 'check' again after this.
if { $TIMING_RUN } {
    puts "INFO: Generating STA-friendly netlist..."
    yosys "setundef -zero"
    yosys "splitnets"
    yosys "clean"
    yosys "write_verilog -noattr -noexpr -nohex -nodec $STA_NETLIST"
}

yosys "check"

puts "Synthesis complete."