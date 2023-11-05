#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset

# Usage info
show_help() {
    cat <<EOF
Example usage:
    ${0##*/} --rows 10 "scripts/"

Specify the path you want to focus on. The command will
create a copy of the reports with filtered results.

Make sure you run the command inside the root of your repository. It expects reports folder to exist.

You can generate reports folder with maat-analyze.
    -h, --help           Print this help information.

    -n, --rows <int>     Number of rows to display for each report in stdout.
                         Reports in the "reports" are not affected by this.
                         They will always have all the rows.
                         Defaults to 10.
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.

rows="10"

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    -n | --rows) # Takes an option argument; ensure it has been specified.
        if [[ -n $2 ]]; then
            rows=$2
            shift
        else
            die 'ERROR: "--rows" requires a non-empty option argument.'
        fi
        ;;
    --rows=?*)
        rows=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --rows=) # Handle the case of an empty --rows=
        die 'ERROR: "--after" requires a non-empty option argument.'
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

if [[ -z ${filter} ]]; then
    filter="."
fi

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

my_dir=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)

source "$my_dir/constants/reports-paths.sh"

get_filtered_file_path() {
    local file=$1
    local extension="${file##*.}"
    local filename="${file%.*}"
    echo "${filename}-filtered.${extension}"
}

filter_reports() {
    report_files=("$COMPLEXITY_EFFORT_PATH" "$sum_of_coupling_path" "$temporal_coupling_path")

    echo "Displaying the first $rows results in each report."
    echo "Full reports are in $REPORTS_PATH "
    echo

    for report_file in "${report_files[@]}"; do
        filtered_file=$(get_filtered_file_path "$report_file")

        head -n 1 "$report_file" >"$filtered_file"
        grep -F "${filter}" "$report_file" >>"$filtered_file"

        # Output
        echo reports/"$(basename "$filtered_file")"
        head -n $((rows + 1)) "$filtered_file" | tr ',' '\t' | column -t
        echo
    done
}

filter_reports
