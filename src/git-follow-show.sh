#!/usr/bin/env bash

# Works like git show --follow, which doesn't exist.

filename=$(git log --follow "$1"^..HEAD \
    --name-only --oneline -- "$2" | tail -n1)

git show "$1":"${filename}"
