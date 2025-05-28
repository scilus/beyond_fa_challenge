ARG BASE_IMAGE=scilus/scilus:latest
FROM $BASE_IMAGE

RUN apt-get update && apt-get -y install \
        git \
        openjdk-17-jre \
    && rm -rf /var/lib/apt/lists/*
