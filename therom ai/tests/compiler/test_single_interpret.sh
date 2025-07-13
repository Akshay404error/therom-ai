#!/usr/bin/env bash
source ../common.sh

exec_check theorem_ai -Dlinter.all=false --run "$f"
diff_produced
