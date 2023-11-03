#!/usr/bin/env bash
# shellcheck disable=SC2034

reports_path="$(pwd)/reports"

complexity_effort_path="${reports_path}/hotspots.csv"
sum_of_coupling_path="${reports_path}/sum-of-coupling.csv"
temporal_coupling_path="${reports_path}/temporal-coupling.csv"
