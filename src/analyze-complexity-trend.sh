#!/usr/bin/env bash

trap 'pkill -P $$; exit' SIGINT SIGTERM

set -o errexit  # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o pipefail
# set -o xtrace # Turn on traces, useful while debugging but commented out by default

# Usage info
show_help() {
    cat <<EOF
Usage: ${0##*/} <FILE_PATH>

Example usage:
    ${0##*/} --after "6 months" --before "3 months" --column sd path/to/file

Run the command inside the root of your repository.

Calculates whitespace complexity trends over a range of revisions and displays the trend in a graph. Use the text output to identify the column you want to plot.

First start with "total" column.

If the trend is growing, it might be caused by two things:
1. New code is added to the module.
2. Existing code is replaced by more complex code.

Case 2 is the more worrying one. To identify if that's the case, use "sd" (standard deviation) column.

    -h, --help          Print this help information.
    
    --after <date>      Analyze commits more recent than the specified date.
                        Date should be in the same format as git log --after.
                        Defaults to 6 months ago.
    
    --before <date>     Analyze commits older than the specified date.
                        Date should be in the same format as git log --before.
                        Defaults to include even today.

    --column <name>     Name of  the column to plot.
                        Column names: n, total, mean, sd.
                        Default "total".
    
    --disable-server    Generate reports without enabling the server.
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
after="6 months"
before=tomorrow
column=total
disable_server=0

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    --after) # Takes an option argument; ensure it has been specified.
        if [[ -n $2 ]]; then
            after=$2
            shift
        else
            die 'ERROR: "--after" requires a non-empty option argument.'
        fi
        ;;
    --after=?*)
        after=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --after=) # Handle the case of an empty --after=
        die 'ERROR: "--after" requires a non-empty option argument.'
        ;;
    --before) # Takes an option argument; ensure it has been specified.
        if [[ -n $2 ]]; then
            before=$2
            shift
        else
            die 'ERROR: "--before" requires a non-empty option argument.'
        fi
        ;;
    --before=?*)
        before=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --before=) # Handle the case of an empty --before=
        die 'ERROR: "--before" requires a non-empty option argument.'
        ;;
    -c | --column) # Takes an option argument; ensure it has been specified.
        if [[ -n $2 ]]; then
            column=$2
            shift
        else
            die 'ERROR: "--column" requires a non-empty option argument.'
        fi
        ;;
    --column=?*)
        column=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --column=) # Handle the case of an empty --column=
        die 'ERROR: "--column" requires a non-empty option argument.'
        ;;
    --disable-server)
        disable_server=$((disable_server + 1))
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

# shellcheck disable=SC2046
my_dir=$(cd -- "$(dirname -- $(readlink -f "${BASH_SOURCE[0]}"))" &>/dev/null && pwd)

file=$*

if [[ -z $file ]]; then
    die 'ERROR: file path not provided.'
fi

# echo $file
# echo $after

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

run_python() {
    "${my_dir}/../.venv/bin/python" "$@"
}

run_complexity_trend() {
    log=$(
        git log --follow \
            --pretty=format:"%h" \
            --date=short \
            --before "${before}" \
            --after "${after}" \
            -- "${file}"
    )

    if [[ -z $log ]]; then
        die "ERROR: The date range before: ${before}, after: ${after} contains less than two commits, which is not enough for plotting a trend. Please try a different date range."
    fi

    end=$(echo "${log}" | head -n 1)
    start=$(echo "${log}" | tail -n 1)

    run_python "${my_dir}/file-complexity/git_complexity_trend_enhanced.py" \
        --start "$start" --end "$end" \
        --file "$file"
}

get_column_number() {
    local trend=$1
    local column=$2

    echo "$trend" |
        head -n 1 |
        tr ',' '\t' |
        awk -v b="$column" '{
            for (i = 1; i <= NF; i++) { 
                if ($i == b) { 
                    print i - 1 
                } 
            }
        }'
}

output_trend() {
    local trend=$1
    echo "$1" | nl -v 0 -w2 | tr ',' '\t' | column -t
}

generate() {
    trend=$(run_complexity_trend)

    output_trend "$trend"

    if [[ $disable_server -ne 0 ]]; then
        exit 0
    fi

    column_number=$(get_column_number "$trend" "$column")

    if [[ -z $column_number ]]; then
        die "ERROR: the column name $column is invalid. Supported names are n, sd, total and mean."
    fi

    local scripts_path="${my_dir}/../scripts"

    run_python "${scripts_path}/plot/plot.py" \
        --file <(echo "${trend}") \
        --column "$column_number"
}

generate
