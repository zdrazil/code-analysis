#!/usr/bin/env bash
# shellcheck disable=SC2034

pwd=$(pwd)
export REPORTS_PATH="$pwd/reports"

export COMPLEXITY_EFFORT_PATH="${REPORTS_PATH}/hotspots.csv"

sum_of_coupling_path="${REPORTS_PATH}/sum-of-coupling.csv"
temporal_coupling_path="${REPORTS_PATH}/temporal-coupling.csv"
