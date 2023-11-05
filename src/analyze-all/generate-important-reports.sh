#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

# Expected variables:
# REPO_LOG_PATH
# REPORTS_PATH
# SUPPORTING_FILES_PATH

folder=$1
rows=$2

maat_analysis() {
    maat --log "$REPO_LOG_PATH" \
        --version-control git2 \
        --analysis "$@"
}

create_report_file_path() {
    echo "${REPORTS_PATH}/$1.csv"
}

save_report() {
    file_path=$(create_report_file_path "$1")
    cat - >"$file_path"
}

create_complexity_effort() {
    local revisions_path="${SUPPORTING_FILES_PATH}/revisions.csv"

    maat_analysis revisions | filter_folders >"$revisions_path" &

    cd "$folder"
    cloc --vcs git \
        --by-file \
        --csv \
        --quiet >"$CODE_LINES_PATH" &
    cd - >/dev/null
    wait

    python3 "${SCRIPTS_PATH}/merge/merge_comp_freqs.py" \
        "$revisions_path" \
        "$CODE_LINES_PATH" |
        filter_folders |
        save_report hotspots

}

create_entity_effort() {
    # In addition to maat output, add percentages
    maat_analysis entity-effort |
        sed '/^entity,/s/$/,percentage/' |
        awk 'BEGIN { FS=OFS="," } { 
                if (NR > 1) { 
                    percentage = ($3 / $4) * 100; 
                    $0 = $0 OFS percentage 
                } 
                print 
            }'
}

filter_folders() {
    if [[ $folder != "." ]]; then
        cat - | sed "s%${folder}%%g"
    else
        cat -
    fi
}

output_reports() {
    echo "Displaying the first" "$rows" "results in the most interesting reports."
    echo "Full reports are in ${REPORTS_PATH}"

    for report_name in "$@"; do
        report_file=$(create_report_file_path "$report_name")

        echo
        echo reports/"$(basename "$report_file")"
        head -n $((rows + 1)) "$report_file" | tr ',' '\t' | column -t
    done
}

generate_important_reports() {
    mkdir -p "$REPORTS_PATH"

    create_complexity_effort &

    maat_analysis entity-ownership |
        filter_folders |
        save_report entity-ownership 1>/dev/null &

    create_entity_effort |
        filter_folders |
        save_report author-entity-effort 1>/dev/null &

    maat_analysis summary | save_report summary &

    maat_analysis soc |
        filter_folders | save_report sum-of-coupling &

    maat_analysis coupling \
        --min-coupling 1 |
        filter_folders | save_report temporal-coupling &

    wait

    output_reports summary hotspots sum-of-coupling temporal-coupling
}

generate_important_reports
