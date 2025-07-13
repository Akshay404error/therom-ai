#!/usr/bin/env bash
source ../../common.sh

# IO.Process.exit (used by the file worker) seems to be incompatible with LSAN
# TODO: investigate or work around
export ASAN_OPTIONS=detect_leaks=0

# these tests don't have to succeed
exec_capture theorem_ai -Dlinter.all=false --run run.theorem_ai "$f" || true
diff_produced
