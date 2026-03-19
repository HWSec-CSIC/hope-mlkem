#==========================================================================
# INITIAL CONFIGURATION
#==========================================================================

TOP_MODULE 			= AXI_IO_MLKEM
CLOCK_SIGNAL		= clk
MAX_SIM_TIME		= 100000000000
#MAX_SIM_TIME		= 30000


#==========================================================================
# SIM CONFIGURATION
#==========================================================================

N_TEST_SIM				= 10 	# Maximum number of tests to run
MASKED_SIM				= 1 	# 0 = Non-Masked, 1 = Masked (Change AXI_IO_MLKEM param MASKED)	

#==========================================================================
# WAVES CONFIGURATION
#==========================================================================

N_TEST				= 1 	# Maximum number of tests to run
K_MLKEM_WAVES		= 2		# K for WAVES
MASKED				= 0 	# 0 = Non-Masked, 1 = Masked (Change AXI_IO_MLKEM param MASKED)	

#==========================================================================
# TRACES CONFIGURATION
#==========================================================================

INIT_TIME_TRACES	= 0
END_TIME_TRACES		= $(MAX_SIM_TIME)
NUM_TRACES 			= 1000	# Number of traces to generate (fixed + random)

#N_TEST_TRACES      = 1 	# Maximum number of tests to run (for TRACES MANDOTORY = 1)
K_MLKEM     		= 2 	# Security Level of ML-KEM (2, 3 or 4)
OPERATION   		= 0 	# 0 = KeyGen, 1 = Encap, 2 = Decap
MASKED_TRACES 		= 1 	# 0 = Non-Masked, 1 = Masked (Change AXI_IO_MLKEM param MASKED)

#==========================================================================
# ASIC SYNTHESIS CONFIGURATION (Available: nangate45, ihp-sg13g2)
#==========================================================================

TECH_NODE				= nangate45

FLATTEN 				= 1
TIMING_RUN 				= 1

CLOCK_PERIOD_NS 		= 5.0
CLOCK_UPRATE_NS			= 3.0
CLOCK_UNCERTAINTY_NS 	= 0.0
CLOCK_LATENCY_NS     	= 0.0
IO_DELAY_PERCENT 		= 20.0

ifeq ($(TECH_NODE), nangate45)
	OUTPUT_LOAD 		= 10.0
	DRIVING_CELL 		= BUF_X2
	REF_NAND2_GATE 		= NAND2_X1
endif

ifeq ($(TECH_NODE), ihp-sg13g2)
	OUTPUT_LOAD 		= 0.010
	DRIVING_CELL 		= sg13g2_buf_2
	REF_NAND2_GATE 		= sg13g2_nand2_1
endif

# STA
STA_PATH_COUNT          = 100

# POWER
POWER_TB_TOP            = $(TOP_MODULE)_tb
POWER_DUT_INSTANCE      = DUT

#==========================================================================
# Directories
#==========================================================================

RTL_DIR    		= rtl
SRC_DIR	   		= src
SIM_DIR			= sim
VOBJ_DIR    	= $(SIM_DIR)/$(SRC_DIR)/obj_dir
SYNTH_DIR		= synth
PNR_DIR			= pnr
PROG_DIR		= prog
TRACES_DIR  	= traces
STA_DIR			= sta
POWER_DIR		= power
TECH_DIR 		= tech

SCRIPTS_DIR		= scripts
TB_DIR 			= tb
OUT_DIR			= out

# This file will store the name of the last configuration used.
LAST_CONFIG_STAMP = $(VOBJ_DIR)/.last_config


#==========================================================================
# FPGA Target
#==========================================================================

BOARD			= ice40hx8k
FPGA_VARIANT 	= hx8k
FPGA_PACKAGE	= ct256
CLOCK_FREQUENCY = 12 


#==========================================================================
# FPGA Synthesis Files
#==========================================================================

# Additional Technology Libraries
TECHLIBS_DIR = ..

# Gather all source files (Verilog/SystemVerilog header and source files)
RTL_FILES = $(shell find $(RTL_DIR) -name '*.vh') \
			$(shell find $(RTL_DIR) -name '*.svh') \
            $(shell find $(RTL_DIR) -name '*.v') \
            $(shell find $(RTL_DIR) -name '*.sv')
				
# Gather all source files (C++ files)
CPP_FILES = $(SIM_DIR)/$(SRC_DIR)/testbench.cpp $(SIM_DIR)/$(SRC_DIR)/sim_utils.cpp

CPPH_FILES = $(SIM_DIR)/$(SRC_DIR)/sim_utils.h

# TECHLIB_FILES = $(TECHLIBS_DIR)/cells_sim.v 

# Derived variable for the simulation binary, built by Verilator
SIM_BIN = $(VOBJ_DIR)/V$(TOP_MODULE)

#==========================================================================
# TVLA Configuration
#==========================================================================

READ_VCD = $(TRACES_DIR)/$(SRC_DIR)/readvcd


#==========================================================================
# Waveform Configuration
#==========================================================================
# This variable controls the output format of the simulation waveform.
# Supported values:
#   - fst: Fast Signal Trace (default, smaller files, faster simulation)
#   - vcd: Value Change Dump (standard, more compatible, but very large files)

WAVEFORM_TYPE			= fst
VERILATOR_TRACE_FLAG   	= --trace-fst
CPP_DEFINES       		= -DWAVEFORM_TYPE_FST

# Automatically determine the full waveform filename based on the type
WAVEFORM_FILE          	= $(SIM_DIR)/waveform.$(WAVEFORM_TYPE)

sim: CFG=sim
sim: VERILATOR_TRACE_FLAG 		:= --trace-fst
sim: CPP_DEFINES     			:= -DN_TEST=$(N_TEST_SIM) -DMASKED=$(MASKED_SIM) 

waves: CFG=waves
waves: VERILATOR_TRACE_FLAG 	:= --trace-fst
waves: CPP_DEFINES     			:= -DWAVEFORM_TYPE_FST -DPRINT_WAVES -DN_TEST=$(N_TEST) -DK_MLKEM=$(K_MLKEM_WAVES) -DOPERATION=$(OPERATION) -DMASKED=$(MASKED_TRACES)

traces: CFG=traces
traces: WAVEFORM_TYPE 			:= vcd
traces: VERILATOR_TRACE_FLAG 	:= --trace-vcd #-O3 --x-assign fast --x-initial fast 
traces: CPP_DEFINES    			:= -DWAVEFORM_TYPE_VCD -DTRACES -DN_TEST=1 -DK_MLKEM=$(K_MLKEM) -DOPERATION=$(OPERATION) -DMASKED=$(MASKED_TRACES) #-O3 -march=native
traces: WAVEFORM_FILE        	:= $(SIM_DIR)/waveform.vcd


#==========================================================================
# PHONY Targets
#==========================================================================

.PHONY: sim waves lint firmware synth-ice40 synth-xilinx synth-generic nextpnr-ice40 traces clean dirs _check_config

#==========================================================================
# Simulation and Build Rules
#==========================================================================

# "sim" produces a VCD by running the simulation binary
sim: _check_config $(SIM_BIN)
	@echo
	@echo "### SIMULATING ###"
	@$(SIM_BIN)

# Build the simulation binary
build: $(SIM_BIN)

# "waves" simulate and opens GTKWave with the generated VCD/FST file
waves: _check_config $(SIM_BIN)
	@echo
	@echo "### SIMULATING ###"
	@$(SIM_BIN)
	@echo
	@echo "### WAVES ###"
	gtkwave $(WAVEFORM_FILE) -a $(SIM_DIR)/waveform.gtkw

# Build the simulation binary
$(SIM_BIN): $(RTL_FILES) $(CPP_FILES) $(CPPH_FILES) Makefile
	@echo
	@echo "### VERILATING ###"
	verilator -Wno-fatal -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC -Wno-IMPLICIT $(VERILATOR_TRACE_FLAG) --timescale-override /100ps -Mdir $(VOBJ_DIR) -cc $(RTL_FILES) $(TECHLIB_FILES) --exe $(CPP_FILES) \
	--top $(TOP_MODULE) -j `nproc` --threads `nproc` -I$(TECHLIBS_DIR) -CFLAGS "$(CPP_DEFINES) -DTOP_HEADER='\"V$(TOP_MODULE).h\"' -DTOP_MODULE=$(TOP_MODULE) \
	-DMAX_SIM_TIME=$(MAX_SIM_TIME) -DINIT_TIME_TRACES=$(INIT_TIME_TRACES) -DEND_TIME_TRACES=$(END_TIME_TRACES) -DCLOCK_SIGNAL=$(CLOCK_SIGNAL)"
	@echo
	@echo "### BUILDING SIM ###"
	$(MAKE) -C $(VOBJ_DIR) -f V$(TOP_MODULE).mk V$(TOP_MODULE)


#==========================================================================
# Linting Rule (for Verilator lint-only check)
#==========================================================================

lint: $(RTL_FILES)
	verilator --lint-only -Wall --top-module $(TOP_MODULE) $(RTL_FILES) $(TECHLIB_FILES) -I$(TECHLIBS_DIR) 


#==========================================================================
# Create SYNTH_DIR, PNR_DIR, PROG_DIR, and TRACES directories
#==========================================================================

dirs:
	@mkdir -p $(SYNTH_DIR) $(SYNTH_DIR)/out/$(TECH_NODE) $(PNR_DIR) $(PROG_DIR) $(TRACES_DIR)/fixed $(TRACES_DIR)/random $(TRACES_DIR)/tvla


#==========================================================================
# Synthesis Rules
#==========================================================================

synth-xilinx: dirs $(RTL_FILES)
	yosys -ql $(SYNTH_DIR)/$(TOP_MODULE).log -p "synth_xilinx -family xc7 -top $(TOP_MODULE); json -noscopeinfo -o $(SYNTH_DIR)/$(TOP_MODULE).json; tee -o $(SYNTH_DIR)/stat.txt stat" $(RTL_FILES)

synth-generic: dirs $(RTL_FILES)
	yosys -ql $(SYNTH_DIR)/$(TOP_MODULE).log -p "synth -top $(TOP_MODULE); tee -o $(SYNTH_DIR)/stat.txt stat" $(RTL_FILES) $(TECHLIB_FILES)


#==========================================================================
# TVLA Rules
#==========================================================================

$(READ_VCD): $(TRACES_DIR)/$(SRC_DIR)/readvcd.c
	@echo "Building readvcd tool..."
	gcc -Wall -O3 $(TRACES_DIR)/$(SRC_DIR)/readvcd.c -o $(TRACES_DIR)/$(SRC_DIR)/readvcd

traces: _check_config $(READ_VCD) $(SIM_BIN) dirs
	@echo
	@echo "### TOGGLE COVERAGE ANALYSIS ###"
	@echo "Generating traces and converting to binary format..."
	@echo "  Fixed  traces: $(NUM_TRACES)"
	@echo "  Random traces: $(NUM_TRACES)"
	@# Generate fixed traces (VCD files will be auto-converted to binary and removed)
	@for i in $$(seq 0 $$(($(NUM_TRACES) - 1))); do \
		echo "Simulating random trace $$i..."; \
		./$(SIM_DIR)/$(SRC_DIR)/obj_dir/V$(TOP_MODULE) --trace_index $$i --trace_random; \
		./$(TRACES_DIR)/$(SRC_DIR)/readvcd $(SIM_DIR)/waveform_$$i.vcd NULL $(TRACES_DIR)/random/trace_$$i.bin; \
		rm $(SIM_DIR)/waveform_$$i.vcd;\
		echo "Simulating fixed  trace $$i..."; \
		./$(SIM_DIR)/$(SRC_DIR)/obj_dir/V$(TOP_MODULE) --trace_index $$i; \
		./$(TRACES_DIR)/$(SRC_DIR)/readvcd $(SIM_DIR)/waveform_$$i.vcd NULL $(TRACES_DIR)/fixed/trace_$$i.bin; \
		rm $(SIM_DIR)/waveform_$$i.vcd;\
	done

#==========================================================================
# Open PDK & STA & Power Configuration
#==========================================================================

# --- Technological Library Path --- 
TECH_PLATFORM_DIR 		= $(TECH_DIR)/$(TECH_NODE)
LIBERTY_FILE 			= $(shell find $(TECH_PLATFORM_DIR) -name '*.lib*')
TECHMAP_FILES 			= $(shell find $(TECH_PLATFORM_DIR)/techmap/ -name '*.v')
STDCELL_FILES			= $(shell find $(TECH_PLATFORM_DIR)/stdcell/ -name '*.v')
YOSYS_SCRIPT 			= $(SYNTH_DIR)/$(SCRIPTS_DIR)/synth_asic.tcl
SYNTH_NETLIST	 		= $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE).v
SYNTH_NETLIST_STA		= $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_sta.v

# --- SDC file path ---
SDC_FILE 				= $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE).sdc

# --- SDF file path ---
SDF_FILE 				= $(STA_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE).sdf

# --- Kilo Gate Equivalent (kGE) Script --- 
KGE_SCRIPT 				= $(SYNTH_DIR)/$(SCRIPTS_DIR)/get_kge.py

# --- STA Scripts --- 
STA_SCRIPT 				= $(STA_DIR)/$(SCRIPTS_DIR)/run_sta.tcl
STA_TRANSLATE_SCRIPT 	= $(STA_DIR)/$(SCRIPTS_DIR)/sta_translate_names.py
STA_LOG_FILE      		= $(STA_DIR)/$(OUT_DIR)/$(TECH_NODE)/sta.log

# --- Power Testbench Files
POWER_TB_FILE			= $(POWER_DIR)/$(TB_DIR)/$(TOP_MODULE)_tb.v
ICARUS_SIM_BINARY       = $(POWER_DIR)/$(OUT_DIR)/$(TECH_NODE)/power_sim.vvp

# --- Power Scripts ---
POWER_STATIC_SCRIPT		= $(POWER_DIR)/$(SCRIPTS_DIR)/run_power_static.tcl
POWER_STATIC_REPORT		= $(POWER_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_power_static.rpt
POWER_VCD_SCRIPT		= $(POWER_DIR)/$(SCRIPTS_DIR)/run_power_vcd.tcl
POWER_VCD_REPORT		= $(POWER_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_power_vcd.rpt
POWER_VCD_FILE			= $(POWER_DIR)/$(OUT_DIR)/$(TECH_NODE)/power_activity.vcd

# --- SYNTH-ASIC TARGET ---
synth-asic: $(SYNTH_NETLIST_STA)

$(SYNTH_NETLIST_STA): $(RTL_FILES) $(SDC_FILE) $(YOSYS_SCRIPT) Makefile
	@echo "### SYNTHESIZING FOR $(TECH_NODE) ###"
	@echo "Configuration: FLATTEN=$(FLATTEN), TIMING_RUN=$(TIMING_RUN)"
	@if [ ! -f "$(LIBERTY_FILE)" ]; then \
		echo "Error: LIBERTY_FILE path is invalid."; exit 1; \
	fi
	@# Export all configuration as environment variables for the Tcl script
	export TOP_MODULE=$(TOP_MODULE); \
	export RTL_FILES="$(RTL_FILES)"; \
	export LIBERTY_FILE=$(LIBERTY_FILE); \
	export PRE_MAP_NETLIST=$(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_pre_map.v; \
	export OUTPUT_NETLIST=$(SYNTH_NETLIST); \
	export STA_NETLIST=$(SYNTH_NETLIST_STA); \
	export OUTPUT_REPORT=$(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_area.rpt; \
	export CLOCK_PERIOD_PS=$(shell echo "$(CLOCK_PERIOD_NS) * 1000 - $(CLOCK_UPRATE_NS) * 1000" | bc); \
	export FLATTEN=$(FLATTEN); \
	export TIMING_RUN=$(TIMING_RUN); \
	export SDC_FILE=$(SDC_FILE); \
	export TECHMAP_FILES="$(TECHMAP_FILES)"; \
	yosys -ql $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE).log -c $(YOSYS_SCRIPT)
	@python3 $(KGE_SCRIPT) $(LIBERTY_FILE) $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_area.rpt $(REF_NAND2_GATE) | tee -a $(SYNTH_DIR)/$(OUT_DIR)/$(TECH_NODE)/$(TOP_MODULE)_$(TECH_NODE)_area.rpt

$(SDC_FILE): dirs Makefile
	@# This SDC is now minimal. The logic is in the Tcl script.
	@TMP_SDC_FILE="$(SDC_FILE).tmp"; \
	\
	echo "################################################################" > $$TMP_SDC_FILE; \
	echo "# SDC for Synthesis and STA (Target: $(CLOCK_PERIOD_NS)ns)" >> $$TMP_SDC_FILE; \
	echo "################################################################" >> $$TMP_SDC_FILE; \
	echo "" >> $$TMP_SDC_FILE; \
	echo "set_load $(OUTPUT_LOAD) [all_outputs]" >> $$TMP_SDC_FILE; \
	echo "set_driving_cell $(DRIVING_CELL)" >> $$TMP_SDC_FILE; \
	echo "" >> $$TMP_SDC_FILE; \
	\
	if [ ! -f "$(SDC_FILE)" ] || ! cmp -s "$$TMP_SDC_FILE" "$(SDC_FILE)"; then \
		echo "--- Regenerating Minimal SDC file ---"; \
		mv "$$TMP_SDC_FILE" "$(SDC_FILE)"; \
	else \
		rm "$$TMP_SDC_FILE"; \
	fi

#==========================================================================
# Static Timing Analysis and Power Rules
#==========================================================================

# This target runs the main STA report generation.
sta-asic: $(STA_LOG_FILE)

$(STA_LOG_FILE): $(SYNTH_NETLIST_STA) $(STA_SCRIPT) $(STA_TRANSLATE_SCRIPT) Makefile 
	@echo
	@echo "### RUNNING STATIC TIMING ANALYSIS ###"
	@if [ ! -f "$(LIBERTY_FILE)" ]; then \
		echo "Error: LIBERTY_FILE path is invalid."; exit 1; \
	fi
	@# Export config as environment variables for the Tcl script
	export LIBERTY_FILE=$(LIBERTY_FILE); \
	export SDF_FILE=$(SDF_FILE); \
	export NETLIST=$(SYNTH_NETLIST_STA); \
	export SDC_FILE=$(SDC_FILE); \
	export TOP_MODULE=$(TOP_MODULE); \
	export REPORT_DIR=$(STA_DIR)/$(OUT_DIR)/$(TECH_NODE); \
	export PATH_COUNT=$(STA_PATH_COUNT); \
	export CLOCK_SIGNAL=$(CLOCK_SIGNAL); \
	export RESET_SIGNAL=$(RESET_SIGNAL); \
	export CLOCK_PERIOD_NS=$(CLOCK_PERIOD_NS); \
	export CLOCK_UNCERTAINTY_NS=$(CLOCK_UNCERTAINTY_NS); \
	export CLOCK_LATENCY_NS=$(CLOCK_LATENCY_NS); \
	export OUTPUT_LOAD=$(OUTPUT_LOAD); \
	export IO_DELAY_NS=$$(echo "$(CLOCK_PERIOD_NS) * $(IO_DELAY_PERCENT) / 100" | bc -l); \
	export DRIVING_CELL=$(DRIVING_CELL); \
	sta -no_splash -exit $(STA_SCRIPT) | tee $(STA_LOG_FILE)
	@echo "SDF file created at $(SDF_FILE)"
	@echo "STA finished. Check reports in $(STA_DIR)/$(OUT_DIR)/$(TECH_NODE)/"
	@echo
	@echo "### TRANSLATING STA REPORTS TO HUMAN-READABLE NAMES ###"
	@CSV_FILES=$$(find $(STA_DIR)/$(OUT_DIR)/$(TECH_NODE)/ -name '*.csv'); \
	if [ -z "$$CSV_FILES" ]; then \
		echo "  No CSV reports found to translate."; \
	else \
		python3 $(STA_TRANSLATE_SCRIPT) \
			$(SYNTH_NETLIST_STA) \
			$$CSV_FILES; \
	fi

#==========================================================================
# Power Analysis Rules
#==========================================================================

# --- Target for Static Power Analysis (fast, estimated) ---
power-asic-static: $(POWER_STATIC_REPORT)

$(POWER_STATIC_REPORT): $(SYNTH_NETLIST_STA) $(POWER_STATIC_SCRIPT) Makefile
	@echo
	@echo "### RUNNING STATIC POWER ANALYSIS (DEFAULT ACTIVITY) ###"
	@if [ ! -f "$(LIBERTY_FILE)" ]; then \
		echo "Error: LIBERTY_FILE path is invalid."; exit 1; \
	fi
	export LIBERTY_FILE=$(LIBERTY_FILE); \
	export NETLIST=$(SYNTH_NETLIST_STA); \
	export TOP_MODULE=$(TOP_MODULE); \
	export REPORT_FILE=$(POWER_STATIC_REPORT); \
	export CLOCK_SIGNAL=$(CLOCK_SIGNAL); \
	export RESET_SIGNAL=$(RESET_SIGNAL); \
	export CLOCK_PERIOD_NS=$(CLOCK_PERIOD_NS); \
	export CLOCK_UNCERTAINTY_NS=$(CLOCK_UNCERTAINTY_NS); \
	export CLOCK_LATENCY_NS=$(CLOCK_LATENCY_NS); \
	export OUTPUT_LOAD=$(OUTPUT_LOAD); \
	export IO_DELAY_NS=$$(echo "$(CLOCK_PERIOD_NS) * $(IO_DELAY_PERCENT) / 100" | bc -l); \
	export DRIVING_CELL=$(DRIVING_CELL); \
	sta -no_splash -exit $(POWER_STATIC_SCRIPT) | tee $(POWER_DIR)/$(OUT_DIR)/$(TECH_NODE)/power_static.log
	@echo "Static power report generated: $(POWER_STATIC_REPORT)"

#==========================================================================
# Check Previous Configuration 
#==========================================================================

_check_config:
	@mkdir -p $(VOBJ_DIR)
	@if [ ! -f "$(LAST_CONFIG_STAMP)" ] || [ "$$(cat $(LAST_CONFIG_STAMP))" != "$(CFG)" ]; then \
		echo "Configuration changed to '$(CFG)'. Forcing a rebuild."; \
		rm -rf $(VOBJ_DIR)/*; \
		echo "$(CFG)" > $(LAST_CONFIG_STAMP); \
	fi


#==========================================================================
# Clean generated files
#==========================================================================

clean:
	rm -rf $(VOBJ_DIR)
	rm -rf $(SIM_DIR)/waveform.fst*
	rm -rf $(SIM_DIR)/waveform.vcd*
	rm -rf $(SIM_DIR)/waveform_*
	rm -rf $(SYNTH_DIR)/out/*
	rm -rf $(PNR_DIR)/*
	rm -rf $(PROG_DIR)/*
	rm -rf $(TRACES_DIR)/$(SRC_DIR)/readvcd
	rm -rf $(TRACES_DIR)/fixed/*
	rm -rf $(TRACES_DIR)/random/*

 
