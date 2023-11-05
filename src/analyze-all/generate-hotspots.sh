#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

my_dir=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)

# Expected variables:
# HOTSPOTS_PATH
# SCRIPTS_PATH
# CODE_LINES_PATH
# COMPLEXITY_EFFORT_PATH

prepare_hotspots() {

    local hotspots_json_path="${HOTSPOTS_PATH}/hotspots.json"

    mkdir -p "$HOTSPOTS_PATH"

    python3 "${SCRIPTS_PATH}/transform/csv_as_enclosure_json.py" \
        --structure "$CODE_LINES_PATH" \
        --weights "$COMPLEXITY_EFFORT_PATH" >"$hotspots_json_path"
}

copy_hotspots() {
    hotspots_files=(crime-scene-hotspots.css crime-scene-hotspots.html crime-scene-hotspots.js LICENSE d3)

    mkdir -p "$HOTSPOTS_PATH"

    for hotspots_file in "${hotspots_files[@]}"; do
        cp -R "${my_dir}/../visualization/${hotspots_file}" "$HOTSPOTS_PATH"
    done
}

prepare_hotspots &
copy_hotspots $

wait
