#!/usr/bin/env bash
source ../common.sh

# LEAN_EXPORTING needs to be defined for .c files included in shared libraries
compile_lean_c_backend -shared -o "${f%.theorem_ai}.so" -DLEAN_EXPORTING
expected_ret=1
exec_check theorem_ai -Dlinter.all=false --plugin="${f%.theorem_ai}.so" "$f"
diff_produced
