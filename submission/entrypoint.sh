#!/bin/bash

mkdir -p /in_pipeline/data
ln -s /input/*.json /in_pipeline/data/.
ln -s /input/images/dwi-4d-brain-mri/* /in_pipeline/data/.
NXF_DISABLE_CHECK_LATEST=true NXF_OFFLINE=true nextflow run /beyond_fa_challenge \
    --input /in_pipeline \
    --output /output
