#!/usr/bin/env bash

trap 'pkill -P $$; exit' SIGINT SIGTERM

set -o errexit  # Exit on error. Append "|| true" if you expect an error.
set -o errtrace # Exit on error inside any functions or subshells.
set -o pipefail
# set -o xtrace # Turn on traces, useful while debugging but commented out by default

# Usage info
show_help() {
    cat <<EOF
Example usage:
    ${0##*/} --after "6 months" --before "3 months" --rows 10 src

Run the command inside the root of your repository.

Analyzes code in your git repository via code-maat. Once you run the analysis, you’ll find several reports in the "reports" folder. It also outputs the reports, but truncated, into stdout.

You can also visit http://localhost:8888/crime-scene-hotspots.html to visually analyze the hotspots in your code. The more complex a module, as measured by lines of code, the larger the circle. The more effort you spend on a module, as measured by its number of revisions, the more intense its color.

Reading Your Code as a Crime Scene is highly recommended to understand the reports (https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

    -h, --help           Print this help information.

    --after <date>       Analyze commits more recent than the specified date.
                         Date should be in the same format as git log --after.
                         Defaults to 6 months ago.
    
    --before <date>      Analyze commits older than the specified date.
                         Date should be in the same format as git log --before.
                         Defaults to include even today.

    -n, --rows <int>     Number of rows to display for each report in stdout.
                         Reports in the "reports" are not affected by this.
                         They will always have all the rows.
                         Defaults to 10.

    -a, --all            Output all reports, not just the main ones. Main ones 
                         are the ones I am using.

    --disable-server     Generate reports without enabling the server.
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
after="6 months"
before="tomorrow"
rows="10"
report_all=0
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
    -a | --all)
        report_all=$((report_all + 1))
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

folder=$*

if [[ -z $folder ]]; then
    folder="."
fi

# echo $folder
# echo $after

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

# Base paths

my_dir=$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" &>/dev/null && pwd)

source "$my_dir/constants/reports-paths.sh"

export SUPPORTING_FILES_PATH="${REPORTS_PATH}/supporting-files"
export SCRIPTS_PATH="${my_dir}/../scripts"

# Hotspots
export HOTSPOTS_PATH="${REPORTS_PATH}/hotspots"

# Supporting files
export CODE_LINES_PATH="${SUPPORTING_FILES_PATH}/lines.csv"
export REPO_LOG_PATH="${SUPPORTING_FILES_PATH}/repo.log"

main() {
    export PATH="$PATH:$my_dir/analyze-all"

    generate-supporting-files.sh "$before" "$after" "$folder"

    generate-important-reports.sh "$folder" "$rows"

    if [[ $report_all -ne 0 ]]; then
        generate-other-reports.sh &
    fi

    generate-hotspots.sh &

    wait

    if [[ $disable_server -eq 0 ]]; then
        cd "$HOTSPOTS_PATH"
        echo
        echo "Running on http://localhost:8888/crime-scene-hotspots.html" &&
            python3 -m http.server 8888
    fi
}

main
