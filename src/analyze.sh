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
# shellcheck disable=SC2046
my_dir=$(cd -- "$(dirname -- $(readlink -f "${BASH_SOURCE[0]}"))" &>/dev/null && pwd)

reports_path="$(pwd)/reports"
supporting_files_path="${reports_path}/supporting-files"
scripts_path="${my_dir}/../scripts"

# Hotspots
hotspots_path="${reports_path}/hotspots"
hotspots_json_path="${hotspots_path}/hotspots.json"

# Supporting files
code_lines_path="${supporting_files_path}/lines.csv"
repo_log_path="${supporting_files_path}/repo.log"
revisions_path="${supporting_files_path}/revisions.csv"

source "$my_dir/constants/reports-paths.sh"

run_python() {
    "${my_dir}/../.venv/bin/python" "$@"
}

maat_analysis() {
    maat -l "$repo_log_path" -c git2 -a "$@"
}

format_and_output() {
    echo
    echo reports/"$(basename "$report_file")"
    head -n $((rows + 1)) "$report_file" | tr ',' '\t' | column -t
}

save_report() {
    file_path="${reports_path}/$1.csv"
    cat - >"$file_path"
    echo "$file_path"
}

# Generate supporting files
{
    generate_supporting_files() {
        mkdir -p "$supporting_files_path"

        git log \
            --follow \
            --numstat \
            --date=short \
            --pretty=format:'--%h--%ad--%aN' \
            --after="${after}" \
            --before="${before}" \
            -- "${folder}" |
            run_python "${my_dir}/git/modify_git_log.py" >"$repo_log_path"

        if [[ ! -s $repo_log_path ]]; then
            die "ERROR: No commits were found in the given date range, before: ${before}, after: ${after}. Please try a different date range."
        fi
    }
}

# Generate important reports
{

    analyze() {
        mkdir -p "$reports_path"

        maat_analysis entity-ownership |
            filter_folders |
            save_report entity-ownership 1>/dev/null &

        create_entity_effort |
            filter_folders |
            save_report author-entity-effort 1>/dev/null &

        summary=$(maat_analysis summary | save_report summary &)

        sum_of_coupling=$(maat_analysis soc |
            filter_folders | save_report sum-of-coupling &)

        coupling=$(maat_analysis coupling \
            --min-coupling 1 |
            filter_folders | save_report temporal-coupling &)

        complexity_effort=$(create_complexity_effort &)

        wait

        output_reports "$summary" "$sum_of_coupling" "$coupling" "$complexity_effort"
    }

    create_complexity_effort() {
        maat_analysis revisions | filter_folders >"$revisions_path" &

        cloc "${folder}" \
            --vcs git \
            --by-file \
            --csv \
            --quiet >"$code_lines_path" &

        wait

        local path
        path=$(
            run_python "${scripts_path}/merge/merge_comp_freqs.py" \
                "$revisions_path" \
                "$code_lines_path" |
                filter_folders |
                save_report hotspots
        )

        echo "$path"
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
            cat - | sed -i '' "s%${folder}%%g"
        else
            cat -
        fi
    }

    output_reports() {
        echo "Displaying the first" "$rows" "results in the most interesting reports."
        echo "Full reports are in ${reports_path}"

        for report_file in "$@"; do
            format_and_output "$report_file"
        done
    }
}

# Hotspots
{

    prepare_hotspots() {
        mkdir -p "$hotspots_path"
        run_python "${scripts_path}/transform/csv_as_enclosure_json.py" \
            --structure "$code_lines_path" \
            --weights "$complexity_effort_path" >"$hotspots_json_path"
    }

    copy_hotspots() {
        hotspots_files=(crime-scene-hotspots.css crime-scene-hotspots.html crime-scene-hotspots.js LICENSE d3)

        mkdir -p "$hotspots_path"

        for hotspots_file in "${hotspots_files[@]}"; do
            cp -R "${my_dir}/visualization/${hotspots_file}" "$hotspots_path"
        done
    }
}

# Other reports
{
    # Reports that I currently don't have a use for.
    generate_other_reports() {
        local other_reports_path="${reports_path}/other-reports"

        mkdir -p "$other_reports_path"

        local other_reports=(fragmentation main-dev main-dev-by-revs refactoring-main-dev)

        for other_report in "${other_reports[@]}"; do
            maat_analysis \
                "$other_report" >"${other_reports_path}/${other_report}.csv" &
        done
    }
}

main() {
    generate_supporting_files

    analyze
    prepare_hotspots &
    copy_hotspots $

    if [[ $report_all -ne 0 ]]; then
        generate_other_reports &
    fi

    wait

    if [[ $disable_server -eq 0 ]]; then
        cd "$hotspots_path"
        echo
        echo "Running on http://localhost:8888/crime-scene-hotspots.html" &&
            run_python -m http.server 8888
    fi

}

main
