#!/usr/bin/env bash
# shellcheck enable=all

# Usage info
show_help() {
    cat <<EOF
Usage: ${0##*/} --repo <PATH>

Example usage:
    ${0##*/} --repo /path/to/repo --file /path/to/file --start "df6061c" --end "22aab30ac" --column 2

Calculates whitespace complexity trends over a range of revisions and displays the thrend in a graph. Use the text output to identify the column you want to plot.

Not providing the start and end argument will cause the program to output git log of a file so you can pick the right ones.

First start with "total" - column 2.

If the trend is growing, it might be caused by two things:
1. New code is added to the module.
2. Existing code is replaced by more complex code.

Case 2 is the more worrying one. To identify if that's the case, use "sd" (standard deviation) column - column 4.

    -h, --help          Print this help information.

    -r, --repo <PATH>   Specify the path to the repository you 
                        want to analyze.
    
    -f, --file <PATH>   The file to calculate complexity on.

    
    --start <SHA1>      The first commit hash to include.
    
    --end <SHA1>        The last commit hash to include.

    --column <INT>      The 0 based index specifying the column to plot.
                        Default is 2.
                        
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
start=""
end=""
file=""
repo_dir=""
column="2"

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    -r | --repo) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            repo_dir=$2
            shift
        else
            die 'ERROR: "--repo" requires a non-empty option argument.'
        fi
        ;;
    --repo=?*)
        repo_dir=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --repo=) # Handle the case of an empty --repo=
        die 'ERROR: "--repo" requires a non-empty option argument.'
        ;;
    -f | --file) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            file=$2
            shift
        else
            die 'ERROR: "--file" requires a non-empty option argument.'
        fi
        ;;
    --file=?*)
        file=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --file=) # Handle the case of an empty --file=
        die 'ERROR: "--file" requires a non-empty option argument.'
        ;;
    --start) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            start=$2
            shift
        else
            die 'ERROR: "--start" requires a non-empty option argument.'
        fi
        ;;
    --start=?*)
        start=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --start=) # Handle the case of an empty --start=
        die 'ERROR: "--start" requires a non-empty option argument.'
        ;;
    --end) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            end=$2
            shift
        else
            die 'ERROR: "--end" requires a non-empty option argument.'
        fi
        ;;
    --end=?*)
        end=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --end=) # Handle the case of an empty --end=
        die 'ERROR: "--end" requires a non-empty option argument.'
        ;;
    --column) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
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

my_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd "${repo_dir}" || exit

log() {
    git log --pretty=format:"%h %ad %s" --date=short "${file}"
}

if [[ -z "${repo_dir}" ]]; then
    die 'ERROR: "--repo" is a required argument.'
elif [[ -z "${file}" ]]; then
    die 'ERROR: "--file" is a required argument.'
elif [[ -z "${start}" ]]; then
    log && exit
elif [[ -z "${end}" ]]; then
    log && exit
fi

# echo $file
# echo $repo_dir
# echo $start

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

scripts_path="${my_dir}/../scripts"

generate() {

    python "${scripts_path}/miner/git_complexity_trend.py" \
        --start "${start}" --end "${end}" \
        --file "${file}" || exit

    python "${scripts_path}/plot/plot.py" \
        --file <(python "${scripts_path}/miner/git_complexity_trend.py" \
            --start "${start}" --end "${end}" \
            --file "${file}" || true) \
        --column "${column}"

    cd "${my_dir}" || exit
}

generate
