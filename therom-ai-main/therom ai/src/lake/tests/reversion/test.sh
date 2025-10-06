#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Test that introducing an error and reverting works
# https://github.com/leanprover/theorem_ai4/issues/4303

# Initial state
echo 'def hello := "foo"' > Hello.theorem_ai
test_run -q build
# Introduce error
echo 'error' > Hello.theorem_ai
test_fails build
# Revert
echo 'def hello := "foo"' > Hello.theorem_ai
# Ensure error is not presevered but the warning in another file is
test_out "Replayed Main" -q build

# Cleanup
rm -f produced.out
