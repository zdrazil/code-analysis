#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

# Command works like git show --follow would, if it existed.

filename=$(git log --follow "$1"^..HEAD \
    --name-only --oneline -- "$2" | tail -n1)

git show "$1":"${filename}"
