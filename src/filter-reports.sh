#!/usr/bin/env bash

# Usage info
show_help() {
    cat <<EOF
Example usage:
    ${0##*/} "scripts/"

Specify the path you want to focus on. The command will
create a copy of the reports with filtered results.

Make sure you run the command inside the root of your repository. It expects reports folder to exist.

You can generate reports folder with maat-analyze.
    -h, --help           Print this help information.
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    --) # End of all options.
        shift
        break
        ;;
    -?*)
        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
        ;;
    *) # Default case: No more options, so break out of the loop.
        break ;;
    esac

    shift
done

filter=$*

if [[ -z "${filter}" ]]; then
    filter="."
fi

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

my_dir=$(cd -- "$(dirname -- $(readlink -f "${BASH_SOURCE[0]}"))" &>/dev/null && pwd)

source "$my_dir/report_paths.sh"

filter_reports() {
    report_files=("${complexity_effort_path}" "${sum_of_coupling_path}" "${temporal_coupling_path}")

    for report_file in "${report_files[@]}"; do
        extension="${report_file##*.}"
        report_filename="${report_file%.*}"
        filtered_file="${report_filename}_filtered.${extension}"

        head -n 1 "$report_file" >"$filtered_file"
        grep -F "${filter}" "$report_file" >>"$filtered_file"
    done
}

filter_reports
