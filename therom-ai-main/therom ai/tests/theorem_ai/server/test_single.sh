#!/usr/bin/env bash
source ../../common.sh

exec_check_raw theorem_ai -Dlinter.all=false --run "$f"
