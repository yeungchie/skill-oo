#!/bin/bash
set -u

unset LD_LIBRARY_PATH

exec 3>&1
sqlite3 "$@" 2> >(
    while IFS= read -r line; do
        printf '\n' >&2
        sleep 0.1
        printf '%s\n' "$line" >&2
    done
) 1>&3 3>&-
status=$?
exit $status
