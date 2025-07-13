#!/usr/bin/env bash
source ../common.sh

# Ensure Lake thinks there is a elan environment configured
export ELAN_HOME=

# Tests the toolchain update functionality of `lake update`

RESTART_CODE=4

test_update(){
   ELAN=true test_out "updating toolchain to '$1'" update
   cat theorem_ai-toolchain | diff - <(echo -n "$1")
}

# Test toolchain version API
test_run theorem_ai test.theorem_ai

# Test no toolchain information
./cTheoremAI.sh
test_out "toolchain not updated; no toolchain information found" update

# Test a single unknown candidate
./cTheoremAI.sh
echo theorem_ai-a > a/theorem_ai-toolchain
test_update theorem_ai-a

# Test a single known (PR) candidate
./cTheoremAI.sh
echo pr-release-101 > a/theorem_ai-toolchain
test_update leanprover/theorem_ai4-pr-releases:pr-release-101

# Test release comparison
./cTheoremAI.sh
echo v4.4.0 > a/theorem_ai-toolchain
echo v4.8.0 > b/theorem_ai-toolchain
test_update leanprover/theorem_ai4:v4.8.0

# Test nightly comparison
./cTheoremAI.sh
echo nightly-2024-10-01 > a/theorem_ai-toolchain
echo nightly-2024-01-10 > b/theorem_ai-toolchain
test_update leanprover/theorem_ai4:nightly-2024-10-01

# Test up-to-date root
./cTheoremAI.sh
echo v4.4.0 > a/theorem_ai-toolchain
echo v4.8.0 > b/theorem_ai-toolchain
echo v4.10.0 > theorem_ai-toolchain
test_out "toolchain not updated; already up-to-date" update

# Test multiple candidates
./cTheoremAI.sh
echo theorem_ai-a > a/theorem_ai-toolchain
echo theorem_ai-b > b/theorem_ai-toolchain
test_out "toolchain not updated; multiple toolchain candidates" update

# Test manual restart
./cTheoremAI.sh
echo theorem_ai-a > a/theorem_ai-toolchain
ELAN= test_status $RESTART_CODE update

# Test elan restart
./cTheoremAI.sh
echo theorem_ai-a > a/theorem_ai-toolchain
ELAN=echo test_out "run --install theorem_ai-a lake update" update

# Cleanup
rm -f produced.out
