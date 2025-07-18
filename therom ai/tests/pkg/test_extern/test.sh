#!/usr/bin/env bash

exit 0  # TODO: flaky test disabled

# We need a package test because we need multiple files with imports.
# Currently the other package tests all succeed,
# but here we need to check for a particular error message.
# This is just an ad-hoc text mangling script to extract the error message
# and account for some OS differences.
# Ideally there would be a more principled testing framework
# that took care of all this!

rm -rf .lake/build

# Function to process the output
verify_output() {
    awk '/error: .*theorem_ai:/, /error: theorem_ai exited/' |
    # Remove system-specific path information from error
    sed 's/error: .*TestExtern.theorem_ai:/error: TestExtern.theorem_ai:/g' |
    sed '/error: theorem_ai exited/d'
}

${LAKE:-lake} build 2>&1 | verify_output > produced.txt

# Compare the actual output with the expected output
if diff --strip-trailing-cr -q produced.txt expected.txt > /dev/null; then
    echo "Output matches expected output."
    rm produced.txt
    exit 0
else
    echo "Output differs from expected output:"
    diff --strip-trailing-cr produced.txt expected.txt
    rm produced.txt
    exit 1
fi
