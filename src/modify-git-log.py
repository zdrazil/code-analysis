#!/usr/bin/env python

import sys
import re


def keep_left(match):
    groups = match.group(0).split(" => ")
    return groups[0][1:]


def keep_right(match):
    groups = match.group(0).split(" => ")
    return groups[1][:-1]


rename_regex = r"{.+ => .+}"
separator = "\t"

renames = {}

if __name__ == "__main__":
    for line in sys.stdin:
        columns = line.split(separator)

        if len(columns) < 2:
            sys.stdout.write(line)
            continue

        column = columns[2].replace("\n", "")

        match = re.search(rename_regex, column)

        if match is not None:
            left = re.sub(rename_regex, keep_left, column)
            right = re.sub(rename_regex, keep_right, column)

            if right in renames:
                columns[2] = renames[right]
                renames[left] = renames[right]
                del renames[right]
            else:
                columns[2] = right
                renames[left] = right

            print(separator.join(columns))
        elif column in renames:
            columns[2] = renames[column]
            print(separator.join(columns))
        else:
            sys.stdout.write(line)

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
