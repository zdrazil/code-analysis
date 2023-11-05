#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

# Expected variables:
# REPORTS_PATH

# Reports that I currently don't have a use for.
generate_other_reports() {
    local other_reports_path="${REPORTS_PATH}/other-reports"

    mkdir -p "$other_reports_path"

    local other_reports=(fragmentation main-dev main-dev-by-revs refactoring-main-dev)

    for other_report in "${other_reports[@]}"; do
        maat --log "$REPO_LOG_PATH" \
            --version-control git2 \
            --analysis \
            "$other_report" >"${other_reports_path}/${other_report}.csv" &
    done
}

generate_other_reports "$@"
