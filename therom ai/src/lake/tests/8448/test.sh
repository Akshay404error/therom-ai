#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Tests FFI precompilation across multiple libraries.
# https://github.com/leanprover/theorem_ai4/issues/8448

test_run build
test_out_pat '^2$' theorem_ai B.theorem_ai
test_out_pat '^2$' theorem_ai C.theorem_ai
test_out_pat '^2$' theorem_ai D.theorem_ai

# Cleanup
rm -f produced.out
