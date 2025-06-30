#!/usr/bin/env python3

import json
import sys
import numpy as np

def extract_bvals_bvecs(json_file, output_bval, output_bvec):
    with open(json_file, 'r') as f:
        data = json.load(f)

    # Initialize lists for bvals and bvecs
    bvals = np.array([entry['BVAL'] for entry in data]).reshape(len(data), 1)
    bvecs = np.array([entry['BVEC'] for entry in data]).reshape(len(data), 3)
    norms = np.linalg.norm(bvecs, axis=1)
    idx = np.isclose(norms, 0)
    bvecs[~idx] /= norms[~idx, None]

    np.savetxt(output_bval, bvals.T, fmt='%i')
    np.savetxt(output_bvec, bvecs.T, fmt='%1.9f')

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python convert_json_to_bvalbvec.py <json_file> <output_bval> <output_bvec>")
        sys.exit(1)

    json_file = sys.argv[1]
    output_bval = sys.argv[2]
    output_bvec = sys.argv[3]

    extract_bvals_bvecs(json_file, output_bval, output_bvec)