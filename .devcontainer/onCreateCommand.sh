#!/usr/bin/env bash

# Setup for NF-CORE

SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history"
echo "$SNIPPET" >> "${HOME:-/root}/.bashrc"

echo "export NFCORE_MODULES_GIT_REMOTE=\"https://github.com/scilus/nf-neuro.git\"" >> ~/.bashrc
echo "export NFCORE_MODULES_BRANCH=main" >> ~/.bashrc
echo "export NFCORE_SUBWORKFLOWS_GIT_REMOTE=\"https://github.com/scilus/nf-neuro.git\"" >> ~/.bashrc
echo "export NFCORE_SUBWORKFLOWS_BRANCH=main" >> ~/.bashrc
echo "export PROFILE=docker" >> ~/.bashrc

python3 -m pip install nf-core==3.2.1
