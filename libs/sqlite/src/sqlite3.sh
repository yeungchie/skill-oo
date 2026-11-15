#!/bin/sh
set -eu

unset LD_LIBRARY_PATH

exec sqlite3 "$@"
