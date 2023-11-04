#!/usr/bin/env bash

set -o errexit  # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o pipefail
# set -o xtrace # Turn on traces, useful while debugging but commented out by default

# Command works like git show --follow would, if it existed.

filename=$(git log --follow "$1"^..HEAD \
    --name-only --oneline -- "$2" | tail -n1)

git show "$1":"${filename}"
