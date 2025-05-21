#!/usr/bin/env bash

SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history"
echo "$SNIPPET" >> "${HOME:-/root}/.bashrc"
