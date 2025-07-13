#!/usr/bin/env bash
source ../common.sh

./cTheoremAI.sh

# Test running a theorem_ai file works and builds its imports
test_out 'Hello from the library foo!' theorem_ai Test.theorem_ai
test_exp -f .lake/build/lib/theorem_ai/Lib.olean

# Test running a main function of a theorem_ai file
test_out 'Hello Bob!' theorem_ai Test.theorem_ai -- --run Test.theorem_ai Bob

# Test that Lake uses module-specific configuration
# if the source file is a module in the workspace
test_out '"options":{"weak.foo":"bar"}' -v theorem_ai Lib/Basic.theorem_ai

# Test running a file works outside the workspace and working directory
test_out '"name":"_unknown"' -v theorem_ai ../../examples/hello/Hello.theorem_ai

# cleanup
rm -f produced.out
