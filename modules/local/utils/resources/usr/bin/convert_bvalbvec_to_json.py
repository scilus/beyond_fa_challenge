#!/usr/bin/env python3

import json
import sys
import numpy as np

def convert_bvalbvec_to_json(bval_file_path: str, bvec_file_path: str, output_json_path: str) -> None:
    """
    Converts separate .bval and .bvec files into a single JSON file.

    Args:
        bval_file_path (str): Path to the input .bval file.
        bvec_file_path (str): Path to the input .bvec file.
        output_json_path (str): Path for the output JSON file.
    """
    bvals = []
    bvecs = []

    try:
        with open(bval_file_path, 'r') as f:
            for line in f:
                # Assuming bvals are space-separated or newline-separated numbers on a single line
                # If each bval is on its own line, this will still work
                bvals.extend([float(val) for val in line.strip().split()])

        with open(bvec_file_path, 'r') as f:
            for line in f:
                bvecs.append([float(val) for val in line.strip().split()])
        bvals = np.array(bvals)
        bvecs = np.array(bvecs).T
    except FileNotFoundError:
        print("Error: One or both input files not found.")
        sys.exit(1)
    except ValueError:
        print("Error: Could not parse numerical data from bval or bvec files. Ensure they contain valid numbers.")
        sys.exit(1)

    if len(bvals) != len(bvecs):
        print("Error: The number of entries in bval and bvec files do not match.")
        sys.exit(1)

    json_data = []
    for i in range(len(bvals)):
        json_data.append({"BVAL": bvals[i].tolist(), "BVEC": bvecs[i].tolist()})

    with open(output_json_path, 'w') as f:
        json.dump(json_data, f, indent=4)

    print(f"Successfully converted '{bval_file_path}' and '{bvec_file_path}' to '{output_json_path}'.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python convert_bvalbvec_to_json.py <bval_file> <bvec_file> <output_json>")
        sys.exit(1)

    bval_file = sys.argv[1]
    bvec_file = sys.argv[2]
    output_json = sys.argv[3]

    convert_bvalbvec_to_json(bval_file, bvec_file, output_json)