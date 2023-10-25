#!/usr/bin/env bash

# Command works like git show --follow would, if it existed.

filename=$(git log --follow "$1"^..HEAD \
    --name-only --oneline -- "$2" | tail -n1)

git show "$1":"${filename}"
