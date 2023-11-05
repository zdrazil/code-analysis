#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

# Expected variables:
# REPO_LOG_PATH

# shellcheck disable=SC2046
my_dir=$(cd -- "$(dirname -- $(readlink -f "${BASH_SOURCE[0]}"))" &>/dev/null && pwd)

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

generate_supporting_files() {
    mkdir -p "$SUPPORTING_FILES_PATH"

    local before=$1
    local after=$2
    local folder=$3

    git log \
        --follow \
        --numstat \
        --date=short \
        --pretty=format:'--%h--%ad--%aN' \
        --after="${after}" \
        --before="${before}" \
        -- "${folder}" |
        python3 "${my_dir}/../git/modify_git_log.py" >"$REPO_LOG_PATH"

    if [[ ! -s $REPO_LOG_PATH ]]; then
        die "ERROR: No commits were found in the given date range and for a given folder, before: ${before}, after: ${after}, folder: ${folder}. Please try changing them."
    fi
}

generate_supporting_files "$@"
