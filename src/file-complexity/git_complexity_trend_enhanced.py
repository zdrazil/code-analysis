#!/usr/bin/env python3

######################################################################
# This program calculates the complexity trend over a range of
# revisions in a Git repo.
# Based on https://github.com/adamtornhill/maat-scripts/blob/python3/miner/git_complexity_trend.py
######################################################################

import os
import sys

DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
sys.path.insert(0, DIR + "/scripts/miner")

import argparse

import complexity_calculations
import git_complexity_trend
import git_interactions
import language_preprocessors

# Get the path of the current directory
current_directory = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
git_follow_show = os.path.join(current_directory, "git", "git-follow-show.sh")


def calculate_complexity_over_range(file_name, revision_range):
    preprocessor = language_preprocessors.create_for(file_name)
    start_rev, end_rev = revision_range
    revs = git_interactions._read_revisions_matching(
        git_arguments=[
            "git",
            "log",
            "--follow",
            "--oneline",
            start_rev + ".." + end_rev,
            file_name,
        ]
    )

    complexity_by_rev = []
    for rev in revs:
        historic_version = git_interactions._run_git_cmd(
            [git_follow_show, rev, file_name]
        )
        complexity_by_line = complexity_calculations.calculate_complexity_in(
            historic_version, preprocessor
        )
        complexity_by_rev.append(git_complexity_trend.as_stats(rev, complexity_by_line))
    return complexity_by_rev


def run(args):
    revision_range = args.start, args.end
    complexity_trend = calculate_complexity_over_range(args.file, revision_range)
    git_complexity_trend.as_csv(complexity_trend)


if __name__ == "__main__":
    desc = "Calculates whitespace complexity trends over a range of revisions."
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument(
        "--start", required=True, help="The first commit hash to include"
    )
    parser.add_argument("--end", required=True, help="The last commit hash to include")
    parser.add_argument(
        "--file", required=True, type=str, help="The file to calculate complexity on"
    )

    args = parser.parse_args()
    run(args)
