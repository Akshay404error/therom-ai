#!/usr/bin/env bash
source ../../tests/common.sh

exec_check_raw theorem_ai -Dlinter.all=false "$f"
