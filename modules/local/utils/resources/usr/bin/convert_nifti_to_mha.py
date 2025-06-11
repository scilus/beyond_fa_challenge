#!/usr/bin/env python3

import SimpleITK as sitk
import sys

def convert_nifti_to_mha(nifti_file: str, mha_file: str) -> None:
    """
    Converts a NIfTI image file to an MHA image file.

    Args:
        nifti_file (str): Path to the input NIfTI file (.nii or .nii.gz).
        mha_file (str): Path for the output MHA file.
    """
    try:
        # Read the NIfTI file
        image = sitk.ReadImage(nifti_file)
        # Write to MHA format
        sitk.WriteImage(image, mha_file)
        print(f"Successfully converted '{nifti_file}' to '{mha_file}'.")
    except Exception as e:
        print(f"Error during NIfTI to MHA conversion: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python convert_nifti_to_mha.py <input_nifti_file> <output_mha_file>")
        sys.exit(1)

    # Get input and output filenames from arguments
    input_nifti_file = sys.argv[1]
    output_mha_file = sys.argv[2]
    convert_nifti_to_mha(input_nifti_file, output_mha_file)