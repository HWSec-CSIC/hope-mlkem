#!/usr/bin/python3

import argparse
import sys
import re

def read_lib_and_get_weights(lib_file_path, ref_cell_name):
    """
    Robustly parses a Liberty file by correctly handling nested braces and various
    syntactical differences to find the area of each cell and calculate its weight.
    """
    try:
        with open(lib_file_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: Liberty file not found at '{lib_file_path}'", file=sys.stderr)
        sys.exit(1)

    # General regex for cell name, handles optional space and any characters in name
    cell_start_pattern = re.compile(r'cell\s*\(([^)]+)\)')
    # General regex for area, handles floats and scientific notation
    area_pattern = re.compile(r'area\s*:\s*([0-9.eE+-]+)\s*;')
    
    cell_areas = {}
    
    for match in cell_start_pattern.finditer(content):
        cell_name = match.group(1).strip()
        
        start_brace_index = content.find('{', match.end())
        if start_brace_index == -1:
            continue

        brace_level = 1
        current_index = start_brace_index + 1
        end_brace_index = -1
        
        while current_index < len(content):
            if content[current_index] == '{':
                brace_level += 1
            elif content[current_index] == '}':
                brace_level -= 1
            
            if brace_level == 0:
                end_brace_index = current_index
                break
            current_index += 1

        if end_brace_index == -1:
            continue

        cell_body = content[start_brace_index + 1 : end_brace_index]
        
        area_match = area_pattern.search(cell_body)
        if area_match:
            try:
                cell_areas[cell_name] = float(area_match.group(1))
            except (IndexError, ValueError):
                pass

    if ref_cell_name not in cell_areas:
        raise RuntimeError(
            f"Error: The specified reference cell '{ref_cell_name}' was not found "
            f"or has no 'area' attribute in the library '{lib_file_path}'."
        )

    ref_area = cell_areas[ref_cell_name]
    if ref_area == 0:
        raise RuntimeError(f"Error: Reference cell '{ref_cell_name}' has an area of 0, cannot be used as a divisor.")
        
    weighted_dict = {cell: area / ref_area for cell, area in cell_areas.items()}
    
    return weighted_dict

def calculate_kge(report_path, weighted_dict):
    """Calculates and prints the total area in kilo-Gate Equivalents (kGE)."""
    try:
        with open(report_path, 'r') as f:
            report_lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: Area report file not found at '{report_path}'", file=sys.stderr)
        sys.exit(1)

    total_ge = 0.0
    report_started = False
    
    for line_idx, line in enumerate(report_lines):
        if "Number of cells:" in line:
            report_started = True
            continue
        
        if not report_started or not line.strip() or line.startswith('-'):
            continue

        parts = line.split()
        if len(parts) < 2:
            continue
            
        cell_type = parts[0]
        try:
            cell_count = int(parts[1])
        except ValueError:
            continue

        weight = weighted_dict.get(cell_type)
        if weight is not None:
            total_ge += cell_count * weight
        else:
            print(f"Warning: Cell '{cell_type}' from report not found in library weights. Area contribution will be 0.", file=sys.stderr)

    print(f"\n### Area in kGE = {round(total_ge / 1000, 3)} ###")

def main():
    parser = argparse.ArgumentParser(
        description="Calculate kGE from a Yosys area report and a Liberty file.")
    parser.add_argument('lib_file_path', help='Path to the Liberty (.lib) file')
    parser.add_argument('report_path', help='Path to the Yosys area report')
    parser.add_argument('ref_cell', help='Name of the reference 2-input NAND gate (e.g., NAND2_X1)')

    args = parser.parse_args()

    weighted_dict = read_lib_and_get_weights(args.lib_file_path, args.ref_cell)
    calculate_kge(args.report_path, weighted_dict)

if __name__ == "__main__":
    main()