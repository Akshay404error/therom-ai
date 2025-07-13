#!/usr/bin/env bash
source ../common.sh

# these tests don't have to succeed
exec_capture theorem_ai -DprintMessageEndPos=true -Dlinter.all=false -Dexperimental.module=true "$f" || true
diff_produced
