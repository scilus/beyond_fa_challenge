# beyond_fa_challenge
SCIL team project for the beyond_fa_challenge

See [Beyond FA](https://bfa.grand-challenge.org/)

## Running the pipeline

To run the pipeline, you can use the following command:

```bash
wget -q -O data/inputs/sub-003_ses-01/sub-003_ses-01_dir-AP_dwi.mha https://www.dropbox.com/scl/fi/5gv6r7apawtii5pkphr5h/sub-003_ses-01_dir-AP_dwi.mha?rlkey=xe8wu3echl1r0s38xc6xq48hl&st=fp04b2ik&dl=1
wget -q -O data/inputs/sub-003_ses-01/sub-003_ses-01_dir-AP_dwi.json https://www.dropbox.com/scl/fi/nr5th9144hlveoxhlwj9k/sub-003_ses-01_dir-AP_dwi.json?rlkey=0uv4qclczjfaqgofbcssoflox&st=belactyl&dl=1
nextflow run . --input data/inputs
```

Results will be put in the `results` directory, which can be changed using the `--output` option.

References:
[1] Mori, Susumu, et al. "Stereotaxic white matter atlas based on diffusion tensor imaging in an ICBM template." Neuroimage 40.2 (2008): 570-582.