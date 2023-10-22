#!/usr/bin/env bash
# shellcheck enable=all
# Usage info
show_help() {
    cat <<EOF
Usage: ${0##*/} --repo <PATH>

Analyzes code in git repository via code-maat.

    -h, --help           Prints help information.

    -r, --repo <PATH>    Path to a repo you want to analyze.
    
    -f, --folder <PATH>  Relative path to a folder in your repo 
                         you want to analyze.
                         If not specified, whole repo is analyzed.
    
    --since <date>       Analyze commits more recent than a specific date.
                         Supports same formats as git log --since. Defaults to 6 months.
    
    --until <date>       Analyze commits older than a specific date.
                         Supports same date formats as git log --until.
                         Defaults includes even today.
EOF
}

die() {
    printf '%s\n' "$1" >&2
    exit 1
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
since="6 months"
until="tomorrow"
folder="."
repo_dir="${HOME}/projects/my-project"

while :; do
    case $1 in
    -h | -\? | --help)
        show_help # Display a usage synopsis.
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
    --since) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            since=$2
            shift
        else
            die 'ERROR: "--since" requires a non-empty option argument.'
        fi
        ;;
    --since=?*)
        since=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --since=) # Handle the case of an empty --since=
        die 'ERROR: "--since" requires a non-empty option argument.'
        ;;
    --until) # Takes an option argument; ensure it has been specified.
        if [[ -n "$2" ]]; then
            until=$2
            shift
        else
            die 'ERROR: "--until" requires a non-empty option argument.'
        fi
        ;;
    --until=?*)
        until=${1#*=} # Delete everything up to "=" and assign the remainder.
        ;;
    --until=) # Handle the case of an empty --until=
        die 'ERROR: "--until" requires a non-empty option argument.'
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

# echo $folder
# echo $repo_dir
# echo $since

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
hotspots_json_path="${scripts_path}/transform/hotspots.json"

generate() {
    mkdir -p "${generated_path}" || exit

    cd "${repo_dir}" || exit

    git log \
        --follow \
        --pretty=format:'[%h] %an %ad %s' \
        --date=short \
        --after="${since}" \
        --until="${until}" \
        --numstat \
        -- "${folder}" >"${repo_log_path}" || exit

    cloc "${folder}" --vcs git --by-file --csv --quiet >"${code_lines_path}" || exit

    cd "${my_dir}" || exit
}

inspect() {
    echo Summary

    maat -l "${repo_log_path}" -c git -a summary || exit

    maat -l "${repo_log_path}" -c git -a revisions >"${revisions_path}" || exit

    python "${scripts_path}/merge/merge_comp_freqs.py" \
        "${revisions_path}" \
        "${code_lines_path}" >"${complexity_effort_path}" || exit

    python "${scripts_path}/transform/csv_as_enclosure_json.py" \
        --structure "${code_lines_path}" \
        --weights "${complexity_effort_path}" >"${hotspots_json_path}" || exit
}

generate &&
    inspect &&
    cd "${scripts_path}/transform" &&
    echo "Running on http://localhost:8888/crime-scene-hotspots.html." &&
    python -m http.server 8888
