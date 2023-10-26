#!/usr/bin/env bash

trap 'pkill -P $$; exit' SIGINT SIGTERM

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

while :; do
    case $1 in
    -h | -\? | --help)
        show_help
        exit
        ;;
    --after) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
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
        if [[ -n "$2" ]]; then
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
        if [[ -n "$2" ]]; then
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

folder=$*

if [[ -z "${folder}" ]]; then
    folder="."
fi

# echo $folder
# echo $after

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

my_dir=$(cd -- "$(dirname -- $(readlink -f "${BASH_SOURCE[0]}"))" &>/dev/null && pwd)
reports_path="$(pwd)/reports"

repo_log_path="${reports_path}/repo.log"

code_lines_path="${reports_path}/lines.csv"
revisions_path="${reports_path}/revisions.csv"
summary_path="${reports_path}/summary.csv"

source "$my_dir/report_paths.sh"

scripts_path="${my_dir}/../scripts"

hotspots_json_path="${scripts_path}/transform/hotspots.json"

python_bin="${my_dir}/../.direnv/python-3.11/bin/python"

generate() {
    mkdir -p "${reports_path}" || exit

    git log \
        --numstat \
        --date=short \
        --pretty=format:'--%h--%ad--%aN' \
        --after="${after}" \
        --before="${before}" \
        -- "${folder}" |
        "${python_bin}" "${my_dir}/modify_git_log.py" >"${repo_log_path}" || exit

    cloc "${folder}" --vcs git --by-file --csv --quiet >"${code_lines_path}" || exit
}

inspect() {
    maat -l "${repo_log_path}" -c git2 -a summary >"${summary_path}" &
    maat -l "${repo_log_path}" -c git2 -a revisions >"${revisions_path}" &
    # coupling
    maat -l "${repo_log_path}" -c git2 -a soc >"${sum_of_coupling_path}" &
    coupling_command="maat -l ${repo_log_path} -c git2 -a coupling"
    ${coupling_command} --min-coupling 1 >"${temporal_coupling_path}" &

    wait

    "${python_bin}" "${scripts_path}/merge/merge_comp_freqs.py" \
        "${revisions_path}" \
        "${code_lines_path}" >"${complexity_effort_path}" || exit

    "${python_bin}" "${scripts_path}/transform/csv_as_enclosure_json.py" \
        --structure "${code_lines_path}" \
        --weights "${complexity_effort_path}" >"${hotspots_json_path}" || exit
}

cleanup_reports() {
    report_files=("${complexity_effort_path}" "${sum_of_coupling_path}" "${temporal_coupling_path}")

    for report_file in "${report_files[@]}"; do
        sed -i '' "s%${folder}%%g" "$report_file"
    done
}

output_reports() {
    echo "Displaying the first 10 results in each report."
    echo "Full reports are in ${reports_path}"
    echo

    report_files=("${summary_path}" "${complexity_effort_path}" "${sum_of_coupling_path}" "${temporal_coupling_path}")

    for report_file in "${report_files[@]}"; do
        sed -i '' "s%${folder}%%g" "$report_file"

        echo reports/"$(basename "$report_file")"
        head -n $((rows + 1)) "$report_file" | tr ',' '\t' | column -t
        echo
    done
}

generate &&
    inspect &&
    cleanup_reports &&
    output_reports &&
    cd "${scripts_path}/transform" &&
    echo "Running on http://localhost:8888/crime-scene-hotspots.html" &&
    "${python_bin}" -m http.server 8888
