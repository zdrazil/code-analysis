#!/usr/bin/env python

import sys
import re
from typing import TextIO


def extract_left(match: re.Match[str]):
    groups = match.group(0).split(" => ")
    return groups[0][1:]


def extract_right(match: re.Match[str]):
    groups = match.group(0).split(" => ")
    return groups[1][:-1]


file_rename_pattern = re.compile(r"{.+ => .+}")
separator = "\t"


def process(stdin: TextIO, stdout: TextIO):
    renames = {}

    for line in stdin:
        columns = line.split(separator)

        if len(columns) < 2:
            stdout.write(line)
            continue

        column = columns[2].replace("\n", "")

        match = file_rename_pattern.search(column)

        if match is not None:
            left = file_rename_pattern.sub(extract_left, column)
            right = file_rename_pattern.sub(extract_right, column)

            if right in renames:
                columns[2] = renames[right]
                renames[left] = renames[right]
                del renames[right]
            else:
                columns[2] = right
                renames[left] = right

            stdout.write(separator.join(columns) + "\n")
        elif column in renames:
            columns[2] = renames[column]
            stdout.write(separator.join(columns) + "\n")
        else:
            stdout.write(line)


if __name__ == "__main__":
    process(sys.stdin, sys.stdout)


#
# if (isRename) {
#     - Define a variable 'before' and set it to the left part of the third column.
#     - Define a variable 'after' and set it to the right part of the third column.
#     - Replace the entire third column with 'after'.
#     if (after === objBefore) {
#         - Remove objBefore.
#         - Add { before: after }
#     }
# } else {
#     - If the third column equals existing 'objBefore', replace it with 'objAfter'.
# }
