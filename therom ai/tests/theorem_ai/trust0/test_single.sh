#!/usr/bin/env bash
source ../../common.sh

exec_check_raw theorem_ai -t0 -Dlinter.all=false "$f"
