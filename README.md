# HOPE-MLKEM Framework

Welcome to the **HOPE-MLKEM** framework. This repository accompanies the CHES article:  
**“A Framework for Designing High-Order Side-Channel Protected Hardware Implementations of ML-KEM.”**

---

## 1. Prerequisites

The following tools are required to use the framework:

1. [**Verilator (v5.035):**](https://github.com/verilator/verilator) Verilog/SystemVerilog simulator.  
2. [**GTKWave (v3.3.116):**](https://github.com/gtkwave/gtkwave) Waveform visualization tool.  
3. [**Yosys (v0.51):**](https://github.com/YosysHQ/yosys) RTL synthesis framework.  
4. [**Nextpnr (v0.6):**](https://github.com/YosysHQ/nextpnr) Vendor-neutral FPGA place-and-route tool.  
5. [**Project Icestorm:**](https://github.com/YosysHQ/icestorm) Tools for Lattice iCE40 FPGA bitstream generation.  

---

## 2. Repository Structure

The main directories and their purposes are summarized below:

    .       
    ├── pnr                            # Place-and-Route outputs
    ├── power                          # Power analysis files
    │   ├── out                        # Power reports and logs
    │   ├── scripts                    # OpenSTA Tcl scripts for power analysis
    │       ├── run_power_static.tcl
    │       └── run_power_vcd.tcl
    ├── prog                           # FPGA programming files
    ├── rtl                            # RTL (Verilog/SystemVerilog) sources and constraint files.
    ├── sim                            # Simulation setup
    │   ├── src   
    │   │   ├── testbench.cpp          # Demo C++ testbench (to be updated/modified for your design)
    │   │   ├── sim_utils.cpp          # Auxiliary simulation functions.
    │   │   └── sim_utils.h            # Declarations for simulation utilities.
    │   └── waveform.gtkw              # Optional GTKWave session file.
    ├── sta                            # Static Timing Analysis files
    │   ├── out                        # STA reports and logs
    │   └── scripts   
    │       ├── run_sta.tcl            # OpenSTA execution script
    │       └── sta_translate_names.py # Script to make reports human-readable
    ├── synth                          # Synthesis files
    │   ├── out                        # Synthesis outputs: netlists, JSON, logs, and stats
    │   └── scripts
    │       ├── get_kge.py             # kGE area calculation script
    │       └── synth_nangate45.tcl    # Yosys script for Nangate45 synthesis
    ├── tech                           # Technology libraries for ASIC flow
    │   ├── nangate45                  # Nangate 45nm
    │   └── ihp-sg13g2                 # IHP 130nm
    ├── traces                         # Side-channel analysis traces and tools
    │   ├── fixed                      # Output for fixed-input traces
    │   ├── random                     # Output for random-input traces
    │   ├── src    
    │   │   └── readvcd.c              # Tool to convert VCD to power traces
    │   └── tvla                       # TVLA analysis results
    │       └── TVLA.ipynb             # Jupyter notebook for TVLA analysis
    ├── Makefile                       # Main Makefile for all workflows
    └── README.md                      # This documentation

---

## 3. Overview

The **HOPE-MLKEM** framework provides a unified environment for simulating, synthesizing, and evaluating hardware implementations of ML-KEM, with support for FPGA and ASIC flows, static timing and power analysis, and side-channel leakage evaluation through TVLA.

Configuration is performed directly in the main `Makefile`. The following parameters must be set prior to execution:

- **`TOP_MODULE`**: Name of the top-level Verilog module (e.g., `TOP_MLKEM`, `TOP_MLKEM_MASKED`, or `AXI_IO_MLKEM`).
- **`CLOCK_SIGNAL`**: Name of the top-level clock signal (e.g., `clk`).
- **`RESET_SIGNAL`**: Name of the top-level reset signal (e.g., `rst`).

---

## 4. Simulation

The framework supports several hardware configurations, corresponding to the implementations reported in the CHES article. These configurations can be defined via parameters in the `AXI_IO_MLKEM` module (`TOP_MODULE=AXI_IO_MLKEM`):

| Implementation | N_BU | MASKED | SHUFF | SHUFF_DELAY | KECCAK_PROT |
|----------------|------|--------|-------|--------------|--------------|
| Unprotected (N_BU=1) | 1 | 0 | 0 | 0 | 0 |
| Unprotected (N_BU=2) | 2 | 0 | 0 | 0 | 0 |
| Unprotected (N_BU=4) | 4 | 0 | 0 | 0 | 0 |
| Protected First-Order | 2 | 1 | 1 | 539 | 1 |
| Protected High-Order | 4 | 1 | 1 | 539 | 1 |

Additional Makefile parameters include:

- **`MASKED_SIM`**: Enables masked implementation simulation.  
- **`N_TEST_SIM`**: Defines the number of test cases to be executed.  

Simulation is performed using:

```bash
make sim
```

---
## 5. TVLA Security Analysis

The framework enables Test Vector Leakage Assessment (TVLA) over simulated traces. Configuration parameters are defined in the Makefile as follows:

   - `TOP_MODULE=AXI_IO_MLKEM`
   - `NUM_TRACES`: Number of traces to generate (fixed + random)
   - `K_MLKEM`: Security Level of ML-KEM (2, 3 or 4)
   - `OPERATION`: 0 = KeyGen, 1 = Encap, 2 = Decap
   - `MASKED_TRACES`: 0 = Non-Masked, 1 = Masked

Once configured, the traces can be generated by executing:

```bash
make traces
```

Fixed and random traces will be stored in the `traces/fixed/` and `traces/random/` directories, respectively. Results can be analyzed using the Jupyter notebook located at `traces/tvla/TVLA.ipynb`. 
>*Please ensure all Python dependencies are installed using the `requirements.txt` file:* `pip install -r requirements.txt`

All parameters within `AXI_IO_MLKEM` may be modified to explore different masking, shuffling, or protection strategies.

>***Note: This process can take anywhere from a few minutes to a few hours, depending on the number of traces and the selected module configuration (K or Masked).***

---
## 6. Waveform Analysis
Waveform generation follows a similar procedure to TVLA analysis. By adjusting the parameters `K_MLKEM_WAVES` and `MASKED` in the Makefile, the user can visualize internal signals and verify design behavior. Execute:

```bash
make waves
```

to perform the simulation and automatically open GTKWave.

---
## 7. FPGA Flow

For this section it is important that users configure: `TOP_MODULE=TOP_MLKEM` for unprotected version or `TOP_MODULE=TOP_MLKEM_MASKED` for protected one.

### 7.1 FPGA Synthesis
   Use Yosys to synthesize your design. Multiple synthesis flows are available:  
   - For Lattice iCE40 devices (e.g., ice40HX8K): execute `make synth-ice40`.  
   - For Xilinx boards: execute `make synth-xilinx`.  
   - For a generic gate-level synthesis flow: execute `make synth-generic`.  
   Outputs are placed in the `synth/out` folder. The synthesis process generates a JSON representation of your design along with synthesis logs and statistics in the `synth` folder, which can help you analyze and refine your implementation.

>*Note: This process can take few hours to complete.*

### 7.2 FPGA Place and Route
   After synthesis, run the place and route process using Nextpnr. Simply execute:  
   ```bash
   make nextpnr-ice40
   ```
   This target uses the synthesized JSON file and the constraints file (such as picosoc.pcf in the rtl folder) to map and route your design onto the FPGA. It subsequently invokes icetime to generate timing reports, providing insights into the performance and closure of your design.

### 7.3 Program the FPGA Board:
   The final step is to program your FPGA board (at the moment only ice40 devices are implemented). Use the target:
   ```bash
   make prog-ice40
   ```
   This target packages your design with icepack to generate a binary image and then programs the device using iceprog.

---
## 8. ASIC Flow

For this section it is important that users configure: `TOP_MODULE=TOP_MLKEM` for unprotected version or `TOP_MODULE=TOP_MLKEM_MASKED` for protected one. In the same way, we recomend to consider all BRAMs as blackboxes, just comenting the specific line in `rtl/lib_mem_mlkem.v` and `rtl/mem_zetas.v`.

### 8.1 ASIC Synthesis

In order to perform ASIC synthesis and power analysis it is mandatory to configure the Makefile as follow:

   - **`TECH_NODE`**: Selects the target ASIC technology library. Supported values are listed (e.g., nangate45, ihp-sg13g2). The framework automatically selects technology-specific parameters based on this choice.
   - **`FLATTEN`**: Set to `1` to flatten the design hierarchy during synthesis, or `0` to preserve it.
   - **`TIMING_RUN`**: Set to `1` to enable timing-driven synthesis, which optimizes the design to meet timing constraints.
   - **`CLOCK_PERIOD_NS`**: The target clock period in nanoseconds. This is the primary constraint for synthesis and Static Timing Analysis (STA).
   - **`CLOCK_UPRATE_NS`**: A value in nanoseconds subtracted from the CLOCK_PERIOD_NS during synthesis to create a tighter timing margin, helping to achieve timing closure.
   - **`CLOCK_UNCERTAINTY_NS`**: Models clock jitter and skew for more realistic timing analysis during STA.
   - **`CLOCK_LATENCY_NS`**: Models the delay from the clock source to the clock definition point in the design.
   - **`IO_DELAY_PERCENT`**: Defines the `set_input_delay` and `set_output_delay` constraints as a percentage of the `CLOCK_PERIOD_NS`.

   The following parameters are automatically configured based on the selected `TECH_NODE`. You can extend this logic to support new technology libraries:
   
   - **`OUTPUT_LOAD:`** The default capacitive load on the output ports of the design.
   - **`DRIVING_CELL:`** The standard cell assumed to be driving the input ports of the design.
   - **`REF_NAND2_GATE`:** The reference 2-input NAND gate used by the `get_kge.py` script to calculate the design's area in kilo-Gate Equivalents (kGE).

   Also for Static Timing Analysis:
   - **`STA_PATH_COUNT:`** The maximum number of critical paths to include in the generated STA reports.

   To synthesize your design for the selected ASIC technology (`TECH_NODE`), run:
   ```bash
   make synth-asic
   ```
   This target uses a dedicated Yosys script to map the RTL to the Nangate45 standard cells, generating a structural Verilog netlist, an area report, and calculating the total area in kilo-gate equivalents (kGE).

### 8.2 Perform Static Timing Analysis (ASIC): 
   After ASIC synthesis, run STA using OpenSTA to verify timing constraints.
   ```bash
   make sta-asic
   ```
   This command analyzes the synthesized netlist against timing constraints. It generates detailed reports on timing paths and slack in the `sta/out/$(TECH_NODE)` directory. It also automatically translates the reports to a human-readable format and, crucially, generates a Standard Delay Format (SDF) file. This SDF file contains accurate timing information essential for gate-level simulations.

### 8.3 Perform Power Analysis (ASIC) 
   ***Note: These power analysis are under evaluation and they should be taken care carefully***  
   The framework includes a two-stage power analysis flow. First, ensure you have a Verilog testbench in power/tb/ that provides realistic stimulus for your design.
   
      - **Static Power Analysis**: For a quick, activity-independent power estimate, run:
         ```bash
         make power-asic-static
         ```
         This command estimates power based on default signal activities and is useful for early-stage analysis.
      - **VCD-Based Power Analysis**: For a much more accurate, activity-dependent analysis, run:
         ```bash
         make power-asic-vcd
         ```
         This target first compiles and runs a gate-level simulation using Icarus Verilog. This simulation uses the synthesized netlist, the standard cell library, and the SDF file (**currently not supported by Icarus Verilog**) from STA for timing accuracy. It generates a VCD (Value Change Dump) file that captures all signal activity. OpenSTA then uses this VCD to perform an accurate power analysis. Reports are saved in `power/out/$(TECH_NODE)/`.
   
## Recap: How to Configure and Use the Framework


### Build/Simulate the Design 

- **`make lint`**: Runs a lint-only check on your RTL sources using Verilator.  *** Note: Several warnings will appear if you run this. "Lint" is very sensitive to warnings. ***

- **`make sim`**: Builds and runs the simulation.  

- **`make waves`**: Builds and runs the simulation, generating a .fst waveform. Opens GTKWave to view the generated waveform, using the session file in sim (.gtkw).

### Side-Channel Trace Generation

- **`make traces`**: Runs multiple simulations with fixed and random inputs. For each run, it generates a .vcd file, processes it with the readvcd tool to create a binary power trace, and cleans up the intermediate .vcd file. Output traces are stored in `traces/fixed/` and `traces/random/`.
> *Note:*  Open and run the traces/tvla/TVLA.ipynb Jupyter Notebook to perform a Test Vector Leakage Assessment (TVLA) on the generated traces.

### Synthesize the Design

- **`make synth-ice40`**: Synthesis for Lattice ice40.   

- **`make synth-xilinx`**: Synthesis for Xilinx.

- **`make synth-generic`**: Synthesis using logic gates.

- **`make synth-asic`**: Synthesis for the ASIC technology specified by the `TECH_NODE` variable.

### Static Timing Analysis (ASIC)

- **`make sta-asic`**: Runs static timing analysis on the synthesized ASIC netlist. Generates timing reports and an SDF file.

### Power Analysis (ASIC)

- **`make power-asic-static`**: Runs a fast, static power analysis with default activity factors.

- **`make power-asic-vcd`**: Runs a more accurate, VCD-based power analysis by performing a timed gate-level simulation.

### Place and Route (FPGA)

- **`make nextpnr-ice40`**: P&R for Lattice ice40. 

### Programming (FPGA)

- **`make prog-ice40`**: Programming Lattice ice40. 

For further details, please refer to:

- [Verilator Documentation](https://veripool.org/verilator/documentation/)
- [GTKWave Documentation](https://gtkwave.sourceforge.net/)
- [Yosys Documentation](https://yosyshq.net/yosys/documentation.html)
- [Nextpnr Documentation](https://github.com/YosysHQ/nextpnr)
- [Icestorm Project](https://clifford.fm/icestorm)
- [RISC‑V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)
- [OpenSTA Documentation](https://github.com/parallaxsw/OpenSTA/blob/master/doc/OpenSTA.pdf)
- [Icarus Verilog Documentation](https://steveicarus.github.io/iverilog/)

## Contact

**Eros Camacho-Ruiz** - (camacho@imse-cnm.csic.es)

_Hardware Cryptography Researcher_ 

_Instituto de Microelectrónica de Sevilla (IMSE-CNM), CSIC, Universidad de Sevilla, Seville, Spain_


