#!/usr/bin/env python3
import sys
import re 
import csv
import os

def create_mapping_from_netlist(netlist_file):
    """
    Parses the structural Verilog netlist to map synthesized flip-flop
    instance names to their original RTL signal names.
    """
    mapping = {}
    try:
        with open(netlist_file, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Netlist file not found at '{netlist_file}'", file=sys.stderr)
        sys.exit(1)

    ff_pattern = re.compile(
        r'''\s*(\w*df\w*)\s+                  # Group 1: Cell type (e.g., "DFF_X2")
          (\S+)\s*                            # Group 2: Instance name (e.g., "_123_")
          \((.*?)\);''',                       # Group 3: Port connections
        re.DOTALL | re.VERBOSE | re.MULTILINE | re.IGNORECASE
    )
    
    q_pin_pattern = re.compile(r'\.Q\s*\(\s*([\w\[\]\.\\]+)\s*\)')

    for match in ff_pattern.finditer(content):
        instance_name = match.group(2)
        port_connections = match.group(3)
        
        q_pin_match = q_pin_pattern.search(port_connections)
        if q_pin_match:
            rtl_name = q_pin_match.group(1)
            mapping[instance_name] = rtl_name
            
    return mapping

def translate_single_report(input_csv_path, output_rpt_path, mapping):
    """
    Translates a single CSV timing report and writes a dynamically formatted
    text file with the original RTL names.
    """
    
    # --- Helper function for robust name translation ---
    def translate_name(raw_name):
        if '/' in raw_name:
            path_parts = raw_name.split('/')
            instance = path_parts[-2] 
            return mapping.get(instance, f"UNMAPPED({instance})")
        else:
            return raw_name

    # --- Step 1: Pre-process the data to find maximum column widths ---
    translated_data = []
    max_start_len = len("Startpoint (RTL)")
    max_end_len = len("Endpoint (RTL)")

    with open(input_csv_path, 'r') as infile:
        reader = csv.reader(infile)
        for row in reader:
            if len(row) < 3: continue
            startpoint_raw, endpoint_raw, slack = row
            
            start_rtl = translate_name(startpoint_raw)
            end_rtl = translate_name(endpoint_raw)
            
            translated_data.append((slack, start_rtl, end_rtl))
            
            if len(start_rtl) > max_start_len:
                max_start_len = len(start_rtl)
            if len(end_rtl) > max_end_len:
                max_end_len = len(end_rtl)

    # Add a little padding
    max_start_len += 2
    max_end_len += 2

    # --- Step 2: Write the formatted output using the calculated widths ---
    with open(output_rpt_path, 'w') as outfile:
        outfile.write(f"Translated Timing Report\n")
        outfile.write(f"Source: {os.path.basename(input_csv_path)}\n")
        outfile.write("-" * (12 + max_start_len + max_end_len + 5) + "\n") # Dynamic separator

        # Write header with dynamic widths
        header = (f"{'Slack (ns)':<12} {'Startpoint (RTL)':<{max_start_len}} "
                  f"{'Endpoint (RTL)':<{max_end_len}}\n")
        separator = (f"{'='*12} {'='*max_start_len} "
                     f"{'='*max_end_len}\n")
        outfile.write(header)
        outfile.write(separator)

        # Write the pre-processed data
        for slack, start_rtl, end_rtl in translated_data:
            data_line = (f"{slack:<12} {start_rtl:<{max_start_len}} "
                         f"{end_rtl:<{max_end_len}}\n")
            outfile.write(data_line)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 sta_translate_names.py <netlist.v> <report1.csv> ...")
        sys.exit(1)

    netlist_file = sys.argv[1]
    csv_files_to_process = sys.argv[2:]

    name_map = create_mapping_from_netlist(netlist_file)

    if not name_map:
        print(f"Warning: Could not find any flip-flop instances in '{netlist_file}'. No mappings were generated.")
    
    for csv_path in csv_files_to_process:
        base, _ = os.path.splitext(csv_path)
        output_path = f"{base}.translated.rpt"
        print(f"  Translating {os.path.basename(csv_path)} -> {os.path.basename(output_path)}")
        translate_single_report(csv_path, output_path, name_map)