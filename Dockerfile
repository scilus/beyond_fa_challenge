FROM scilus/scilus:2.1.0 as beyond_fa_scil_team

ENV NEXTFLOW_VERSION=${NEXTFLOW_VERSION:-24.04.5}
ENV NXF_HOME=/nextflow/.nextflow

RUN apt-get update && apt-get -y install \
        git \
        openjdk-17-jre \
    && rm -rf /var/lib/apt/lists/*

ADD --link https://github.com/nextflow-io/nextflow/releases/download/v${NEXTFLOW_VERSION}/nextflow-${NEXTFLOW_VERSION}-all /nextflow/nextflow
WORKDIR /nextflow
RUN bash nextflow && \
    chmod ugo+rx nextflow && \
    chmod -R ugo+rx .nextflow && \
    mv nextflow /usr/bin/nextflow && \
    apt-get -y autoremove

RUN pip install SimpleITK 

ADD --link https://github.com/scilus/beyond_fa_challenge.git /beyond_fa_challenge
# Copies for dev purpose only, if you need to instanciate the pipeline from local modifications
# COPY main.nf nextflow.config /beyond_fa_challenge/
# COPY modules /beyond_fa_challenge/modules/
# COPY subworkflows /beyond_fa_challenge/subworkflows/
# COPY data /beyond_fa_challenge/data/
COPY --chmod=755 /submission/entrypoint.sh /code/entrypoint.sh
ENTRYPOINT [ "/code/entrypoint.sh" ]
