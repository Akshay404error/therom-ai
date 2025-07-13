#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# ---
# Tests aspects of Lake tracing
# ---

# Tests that a build produces a trace
test_exp ! -f .lake/build/lib/theorem_ai/Foo.trace
test_out "Built Foo" build
test_exp -f .lake/build/lib/theorem_ai/Foo.trace

# Tests that a proper trace prevents a rebuild
test_run build --no-build

# Tests that Lake accepts pure numerical traces
if command -v jq > /dev/null; then # skip if no jq found
  jq -r '.depHash' .lake/build/lib/theorem_ai/Foo.trace > .lake/build/lib/theorem_ai/Foo.trace.hash
  test_cmd mv .lake/build/lib/theorem_ai/Foo.trace.hash .lake/build/lib/theorem_ai/Foo.trace
  test_run build --no-build
fi

# Tests that removal of the trace does not cause a rebuild
# (if the modification time of the artifact is still newer than the inputs)
test_cmd rm .lake/build/lib/theorem_ai/Foo.trace
test_run build --no-build

# Tests that an invalid trace does cause a rebuild
test_cmd touch .lake/build/lib/theorem_ai/Foo.trace
test_out "Built Foo" build
test_run build --no-build

# Cleanup
rm -f produced.out
