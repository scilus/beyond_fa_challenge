#!/bin/bash

mkdir -p /workdir/data
ln -s /input/*.json /workdir/data/.
ln -s /input/images/dwi-4d-brain-mri/* /workdir/data/.
ls -lha /workdir/data
DIPY_HOME=/tmp/.dipy SCILPY_HOME=/tmp/.scilpy NXF_DISABLE_CHECK_LATEST=true NXF_OFFLINE=true nextflow run /beyond_fa_challenge \
    --input /workdir \
    --output /output $@