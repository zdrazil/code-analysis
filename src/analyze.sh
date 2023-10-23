#!/usr/bin/env bash
# shellcheck enable=all

# Usage info
show_help() {
    cat <<EOF
Usage: ${0##*/} --repo <PATH>

Example usage:
    ${0##*/} --repo /path/to/repo --folder src --after "6 months" --before "3 months"

Analyzes code in your git repository via code-maat. Once you run the analysis, you’ll find several reports in the "generated" folder.

You can also visit http://localhost:8888/crime-scene-hotspots.html to visually analyze the hotspots in your code. The more complex a module, as measured by lines of code, the larger the circle. The more effort you spend on a module, as measured by its number of revisions, the more intense its color.

Reading Your Code as a Crime Scene is highly recommended to understand the reports (https://pragprog.com/titles/atcrime/your-code-as-a-crime-scene/).

You can also visit 

    -h, --help           Print this help information.

    -r, --repo <PATH>    Specify the path to the repository you 
                         want to analyze.
    
    -f, --folder <PATH>  Specify a path relative to your repository
                         that you want to analyze. If not specified
                         the entire repository will be analyzed.

    
    --after <date>       Analyze commits more recent than the specified date. 
                         Date should be in the same format as git log --after. 
                         Defaults to 6 months ago.
    
    --before <date>      Analyze commits older than the specified date.
                         Date should be in the same format as git log --before. 
                         Defaults to include even today.
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
folder="."
repo_dir=""

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
    -f | --folder) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            folder=$2
            shift
        else
            die 'ERROR: "--folder" requires a non-empty option argument.'
        fi
        ;;
    --folder=?*)
        folder=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --folder=) # Handle the case of an empty --folder=
        die 'ERROR: "--folder" requires a non-empty option argument.'
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

if [[ -z "${repo_dir}" ]]; then
    die 'ERROR: "--repo" is a required argument.'
fi

# echo $folder
# echo $repo_dir
# echo $after

# Rest of the program here.
# If there are input files (for example) that follow the options, they
# will remain in the "$@" positional parameters.

my_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

generated_path="${my_dir}/../generated"

repo_log_path="${generated_path}/repo.log"

code_lines_path="${generated_path}/lines.csv"
revisions_path="${generated_path}/revisions.csv"
complexity_effort_path="${generated_path}/complexity_effort.csv"

scripts_path="${my_dir}/../scripts"

sum_of_coupling_path="${generated_path}/sum_of_coupling.csv"
temporal_coupling_path="${generated_path}/temporal_coupling"

hotspots_json_path="${scripts_path}/transform/hotspots.json"

generate() {
    mkdir -p "${generated_path}" || exit

    cd "${repo_dir}" || exit

    git log \
        --all \
        --numstat \
        --date=short \
        --pretty=format:'--%h--%ad--%aN' \
        --no-renames \
        --after="${after}" \
        --before="${before}" \
        -- "${folder}" >"${repo_log_path}" || exit

    cloc "${folder}" --vcs git --by-file --csv --quiet >"${code_lines_path}" || exit

    cd "${my_dir}" || exit
}

inspect() {
    echo Summary

    maat -l "${repo_log_path}" -c git2 -a summary || exit

    maat -l "${repo_log_path}" -c git2 -a revisions >"${revisions_path}" || exit

    python "${scripts_path}/merge/merge_comp_freqs.py" \
        "${revisions_path}" \
        "${code_lines_path}" >"${complexity_effort_path}" || exit

    python "${scripts_path}/transform/csv_as_enclosure_json.py" \
        --structure "${code_lines_path}" \
        --weights "${complexity_effort_path}" >"${hotspots_json_path}" || exit

    # coupling
    maat -l "${repo_log_path}" -c git2 -a soc >"${sum_of_coupling_path}" || exit

    coupling_command="maat -l ${repo_log_path} -c git2 -a coupling"
    ${coupling_command} --min-coupling 0 >"${temporal_coupling_path}"-0.csv
    ${coupling_command} --min-coupling 10 >"${temporal_coupling_path}"-10.csv
    ${coupling_command} --min-coupling 20 >"${temporal_coupling_path}"-20.csv
    ${coupling_command} >"${temporal_coupling_path}"-30.csv
}

generate &&
    inspect &&
    cd "${scripts_path}/transform" &&
    echo "Running on http://localhost:8888/crime-scene-hotspots.html" &&
    python -m http.server 8888
